package service

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

// AntiAbuseService manages device installation tracking, risk evaluation, and promotional eligibility.
type AntiAbuseService struct {
	repo repository.Repository
}

func NewAntiAbuseService(repo repository.Repository) *AntiAbuseService {
	return &AntiAbuseService{repo: repo}
}

// TrackInstallation registers or updates device telemetry and risk score.
func (s *AntiAbuseService) TrackInstallation(inst model.Installation, userID string) (model.Installation, error) {
	now := time.Now().UTC().Format(time.RFC3339)
	if inst.ID == "" {
		inst.ID = fmt.Sprintf("inst_%d", time.Now().UnixNano())
	}

	raw, found, err := s.repo.Get("installations", inst.ID)
	var existing model.Installation
	if err == nil && found {
		_ = json.Unmarshal(raw, &existing)
		inst.FirstSeenAt = existing.FirstSeenAt
		inst.RiskScore = existing.RiskScore
	} else {
		inst.FirstSeenAt = now
		inst.RiskScore = 0
		inst.Status = "ACTIVE"
	}
	inst.LastSeenAt = now

	if inst.AttestationStatus == "UNVERIFIED" {
		inst.RiskScore += 15
	} else if inst.AttestationStatus == "SUSPICIOUS" {
		inst.RiskScore += 50
	}

	// Link Account to Installation
	if userID != "" {
		linkKey := inst.ID + "__" + userID
		_ = s.repo.Put("installation_accounts", linkKey, model.InstallationAccount{
			InstallationID: inst.ID,
			UserID:         userID,
			FirstSeenAt:    now,
			LastSeenAt:     now,
		})
	}

	if inst.RiskScore >= 80 {
		inst.Status = "RESTRICTED"
	}

	if err := s.repo.Put("installations", inst.ID, inst); err != nil {
		return inst, err
	}
	return inst, nil
}

// CheckPromotionalEligibility checks whether the device/space is eligible to claim a promo reward.
func (s *AntiAbuseService) CheckPromotionalEligibility(spaceID, installationID, promoType string) (bool, string, error) {
	if installationID == "" {
		return true, "ELIGIBLE", nil
	}

	raw, found, err := s.repo.Get("installations", installationID)
	if err == nil && found {
		var inst model.Installation
		_ = json.Unmarshal(raw, &inst)
		if inst.Status == "BLOCKED" || inst.RiskScore >= 80 {
			return false, "DEVICE_RISK_HIGH", nil
		}
	}

	claimKey := fmt.Sprintf("%s__%s__%s", installationID, promoType, time.Now().UTC().Format("2006-01-02"))
	_, claimFound, _ := s.repo.Get("promotional_claims", claimKey)
	if claimFound {
		return false, "PROMOTION_ALREADY_CLAIMED_FOR_DEVICE", nil
	}

	return true, "ELIGIBLE", nil
}

// RecordPromotionalClaim records an executed promotional grant.
func (s *AntiAbuseService) RecordPromotionalClaim(spaceID, installationID, promoType string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	today := time.Now().UTC().Format("2006-01-02")
	claimKey := fmt.Sprintf("%s__%s__%s", installationID, promoType, today)

	claim := model.PromotionalClaim{
		ID:             fmt.Sprintf("claim_%d", time.Now().UnixNano()),
		SpaceID:        spaceID,
		InstallationID: installationID,
		PromotionType:  promoType,
		ClaimDate:      today,
		CreatedAt:      now,
	}

	return s.repo.Put("promotional_claims", claimKey, claim)
}
