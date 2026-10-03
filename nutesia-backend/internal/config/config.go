package config

import (
	"os"
	"strings"
)

// Config holds runtime settings for the API. Secrets stay in environment variables,
// never in the Flutter client.
type Config struct {
	Port                    string
	DataDir                 string
	GroqAPIKey              string
	AllowedOrigin           string
	FirebaseProjectID       string
	FirebaseAPIKey          string
	FirebaseCredentialsFile string
}

func Load() Config {
	loadDotEnv(".env")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	dataDir := os.Getenv("DATA_DIR")
	if dataDir == "" {
		dataDir = "./data"
	}
	allowedOrigin := os.Getenv("ALLOWED_ORIGIN")
	if allowedOrigin == "" {
		allowedOrigin = "*"
	}
	firebaseProjectID := os.Getenv("FIREBASE_PROJECT_ID")
	if firebaseProjectID == "" {
		firebaseProjectID = "nutesia"
	}
	return Config{
		Port:                    port,
		DataDir:                 dataDir,
		GroqAPIKey:              os.Getenv("GROQ_API_KEY"),
		AllowedOrigin:           allowedOrigin,
		FirebaseProjectID:       firebaseProjectID,
		FirebaseAPIKey:          os.Getenv("FIREBASE_API_KEY"),
		FirebaseCredentialsFile: os.Getenv("FIREBASE_CREDENTIALS_FILE"),
	}
}

// loadDotEnv keeps local setup dependency-free. Runtime environment variables
// always take precedence over values from the local .env file.
func loadDotEnv(path string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, found := strings.Cut(line, "=")
		if !found || strings.TrimSpace(key) == "" || os.Getenv(strings.TrimSpace(key)) != "" {
			continue
		}
		_ = os.Setenv(strings.TrimSpace(key), strings.Trim(strings.TrimSpace(value), "\"'"))
	}
}
