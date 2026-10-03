package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/repository"
	"github.com/nuto/backend/internal/service"
)

func TestWalletHandlerEndpoints(t *testing.T) {
	gin.SetMode(gin.TestMode)
	tmpDir := t.TempDir()
	repo, err := repository.NewFileRepository(tmpDir)
	if err != nil {
		t.Fatalf("failed to create repo: %v", err)
	}

	ledger := service.NewLedgerService(repo)
	antiAbuse := service.NewAntiAbuseService(repo)
	h := NewWalletHandler(ledger, antiAbuse)

	r := gin.New()
	r.GET("/api/v1/users/:deviceId/wallet", h.Get)
	r.POST("/api/v1/users/:deviceId/wallet/rewarded-ad", h.RewardAd)

	deviceID := "test-device-wallet-001"

	// 1. GET initial wallet
	req := httptest.NewRequest("GET", "/api/v1/users/"+deviceID+"/wallet", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for GET wallet, got %d", w.Code)
	}

	// 2. POST rewarded ad
	reqAd := httptest.NewRequest("POST", "/api/v1/users/"+deviceID+"/wallet/rewarded-ad", nil)
	wAd := httptest.NewRecorder()
	r.ServeHTTP(wAd, reqAd)

	if wAd.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for rewarded ad, got %d", wAd.Code)
	}
}
