package service

import (
	"testing"

	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

func TestAntiAbuseService(t *testing.T) {
	tmpDir := t.TempDir()
	repo, err := repository.NewFileRepository(tmpDir)
	if err != nil {
		t.Fatalf("failed to create repo: %v", err)
	}

	svc := NewAntiAbuseService(repo)
	inst := model.Installation{
		ID:                "inst_test_001",
		Platform:          "android",
		AppVersion:        "1.0.0",
		AttestationStatus: "VERIFIED",
	}

	// 1. Track installation
	tracked, err := svc.TrackInstallation(inst, "user_abc")
	if err != nil {
		t.Fatalf("failed to track installation: %v", err)
	}
	if tracked.RiskScore > 30 || tracked.Status != "ACTIVE" {
		t.Errorf("Expected active low risk installation, got score %d, status %s", tracked.RiskScore, tracked.Status)
	}

	// 2. Check promotional eligibility (first time)
	eligible, reason, err := svc.CheckPromotionalEligibility("space_001", "inst_test_001", "WELCOME_BONUS")
	if err != nil || !eligible {
		t.Errorf("Expected eligible, got %v (%s)", eligible, reason)
	}

	// 3. Record claim
	err = svc.RecordPromotionalClaim("space_001", "inst_test_001", "WELCOME_BONUS")
	if err != nil {
		t.Fatalf("record claim failed: %v", err)
	}

	// 4. Duplicate claim on same day -> Rejected
	eligible2, reason2, _ := svc.CheckPromotionalEligibility("space_002", "inst_test_001", "WELCOME_BONUS")
	if eligible2 {
		t.Errorf("Expected duplicate claim rejection, got %v (%s)", eligible2, reason2)
	}
}
