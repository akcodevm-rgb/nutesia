package middleware

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const (
	googleCertURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
	issuerPrefix  = "https://securetoken.google.com/"
)

type AuthMiddleware struct {
	projectID  string
	publicKeys map[string]*rsa.PublicKey
	certExpiry time.Time
	mu         sync.RWMutex
}

func NewAuthMiddleware(projectID string) *AuthMiddleware {
	return &AuthMiddleware{
		projectID:  projectID,
		publicKeys: make(map[string]*rsa.PublicKey),
	}
}

func (m *AuthMiddleware) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header must be Bearer <token>"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims, err := m.verifyToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": fmt.Sprintf("Invalid token: %v", err)})
			c.Abort()
			return
		}

		uid, _ := claims["sub"].(string)
		if uid == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims: sub (UID) missing"})
			c.Abort()
			return
		}

		c.Set("uid", uid)
		c.Next()
	}
}

func (m *AuthMiddleware) verifyToken(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}

		kid, ok := token.Header["kid"].(string)
		if !ok {
			return nil, errors.New("missing kid header")
		}

		key, err := m.getPublicKey(kid)
		if err != nil {
			return nil, err
		}
		return key, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid claims")
	}

	aud, _ := claims["aud"].(string)
	if aud != m.projectID {
		return nil, fmt.Errorf("invalid audience: expected %s, got %s", m.projectID, aud)
	}

	iss, _ := claims["iss"].(string)
	expectedIss := issuerPrefix + m.projectID
	if iss != expectedIss {
		return nil, fmt.Errorf("invalid issuer: expected %s, got %s", expectedIss, iss)
	}

	if exp, ok := claims["exp"].(float64); ok {
		if time.Now().Unix() > int64(exp) {
			return nil, errors.New("token is expired")
		}
	}

	return claims, nil
}

func (m *AuthMiddleware) getPublicKey(kid string) (*rsa.PublicKey, error) {
	m.mu.RLock()
	if time.Now().Before(m.certExpiry) {
		if key, found := m.publicKeys[kid]; found {
			m.mu.RUnlock()
			return key, nil
		}
	}
	m.mu.RUnlock()

	m.mu.Lock()
	defer m.mu.Unlock()

	if time.Now().Before(m.certExpiry) {
		if key, found := m.publicKeys[kid]; found {
			return key, nil
		}
	}

	if err := m.fetchGoogleCerts(); err != nil {
		return nil, err
	}

	key, found := m.publicKeys[kid]
	if !found {
		return nil, fmt.Errorf("public key not found for kid: %s", kid)
	}
	return key, nil
}

func (m *AuthMiddleware) fetchGoogleCerts() error {
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(googleCertURL)
	if err != nil {
		return fmt.Errorf("fetching Google certs: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status from Google certs endpoint: %d", resp.StatusCode)
	}

	cacheControl := resp.Header.Get("Cache-Control")
	maxAge := 6 * time.Hour
	if cacheControl != "" {
		for _, part := range strings.Split(cacheControl, ",") {
			part = strings.TrimSpace(part)
			if strings.HasPrefix(part, "max-age=") {
				var seconds int64
				if _, err := fmt.Sscanf(part, "max-age=%d", &seconds); err == nil {
					maxAge = time.Duration(seconds) * time.Second
				}
			}
		}
	}
	m.certExpiry = time.Now().Add(maxAge)

	var certs map[string]string
	if err := json.NewDecoder(resp.Body).Decode(&certs); err != nil {
		return fmt.Errorf("decoding Google certs response: %w", err)
	}

	newKeys := make(map[string]*rsa.PublicKey)
	for kid, pemData := range certs {
		block, _ := pem.Decode([]byte(pemData))
		if block == nil {
			continue
		}
		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			continue
		}
		pubKey, ok := cert.PublicKey.(*rsa.PublicKey)
		if ok {
			newKeys[kid] = pubKey
		}
	}

	m.publicKeys = newKeys
	return nil
}
