package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/nuto/backend/internal/config"
	"github.com/nuto/backend/internal/handler"
	"github.com/nuto/backend/internal/repository"
	"github.com/nuto/backend/internal/router"
	"github.com/nuto/backend/internal/service"
)

func main() {
	cfg := config.Load()

	var repo repository.Repository
	var err error

	if cfg.FirebaseProjectID != "" && os.Getenv("USE_FILE_STORAGE") != "true" {
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		repo, err = repository.NewFirestoreRepository(ctx, cfg.FirebaseProjectID, cfg.FirebaseCredentialsFile)
		if err != nil {
			log.Fatalf("initialize Firebase Firestore storage: %v", err)
		}
		log.Printf("Connected to Firebase Firestore storage (Project: %s)", cfg.FirebaseProjectID)
	} else {
		repo, err = repository.NewFileRepository(cfg.DataDir)
		if err != nil {
			log.Fatalf("initialize local file storage: %v", err)
		}
		log.Printf("Using local file storage at %s", cfg.DataDir)
	}

	ledger := service.NewLedgerService(repo)
	antiAbuse := service.NewAntiAbuseService(repo)

	wallet := handler.NewWalletHandler(ledger, antiAbuse)
	data := handler.NewDataHandler(repo)
	ai := handler.NewAIHandler(cfg.GroqAPIKey, repo, wallet)
	installation := handler.NewInstallationHandler(antiAbuse)
	health := handler.NewHealthHandler()

	r := router.New(health, data, ai, wallet, installation, cfg.AllowedOrigin, cfg.FirebaseProjectID)

	// ✅ New:
log.Printf("Nuto API listening on 0.0.0.0:%s", cfg.Port)
if err := r.Run(":" + cfg.Port); err != nil {
    log.Fatal(err)
}

}
