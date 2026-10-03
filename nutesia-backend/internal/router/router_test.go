package router

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestVerifyUserAccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	qa := map[string]bool{"tester@nuto.app": true}

	tests := []struct {
		name     string
		email    string
		deviceID string
		want     int
	}{
		{"own uid", "user@example.com", "uid_123", http.StatusOK},
		{"qa alias for allowlisted email", "tester@nuto.app", "test_uid_123", http.StatusOK},
		{"test alias without allowlisted email", "user@example.com", "test_uid_123", http.StatusForbidden},
		{"test alias without email", "", "test_uid_123", http.StatusForbidden},
		{"another user's uid", "user@example.com", "uid_999", http.StatusForbidden},
		{"another user's test alias", "tester@nuto.app", "test_uid_999", http.StatusForbidden},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := gin.New()
			r.Use(func(c *gin.Context) {
				c.Set("uid", "uid_123")
				if tt.email != "" {
					c.Set("email", tt.email)
				}
			})
			r.Use(verifyUserAccess(qa))
			r.GET("/users/:deviceId", func(c *gin.Context) { c.Status(http.StatusOK) })

			w := httptest.NewRecorder()
			r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/users/"+tt.deviceID, nil))
			if w.Code != tt.want {
				t.Fatalf("GET /users/%s as %q: got %d, want %d", tt.deviceID, tt.email, w.Code, tt.want)
			}
		})
	}
}
