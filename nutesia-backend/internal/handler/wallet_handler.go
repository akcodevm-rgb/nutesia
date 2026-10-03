package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/service"
)

// WalletHandler coordinates credit queries, atomic ad rewards, and deductions through the LedgerService.
type WalletHandler struct {
	ledger    *service.LedgerService
	antiAbuse *service.AntiAbuseService
}

func NewWalletHandler(ledger *service.LedgerService, antiAbuse *service.AntiAbuseService) *WalletHandler {
	return &WalletHandler{
		ledger:    ledger,
		antiAbuse: antiAbuse,
	}
}

// Get returns the live shared credit wallet for the NutritionSpace.
func (h *WalletHandler) Get(c *gin.Context) {
	spaceID, ok := validDeviceID(c)
	if !ok {
		return
	}

	w, err := h.ledger.GetOrCreateWallet(spaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load credit wallet"})
		return
	}

	c.JSON(http.StatusOK, w)
}

// RewardAd checks device risk/promotional eligibility and awards 1 shared credit.
func (h *WalletHandler) RewardAd(c *gin.Context) {
	spaceID, ok := validDeviceID(c)
	if !ok {
		return
	}

	installationID := c.GetHeader("X-Installation-ID")
	if h.antiAbuse != nil && installationID != "" {
		eligible, reason, _ := h.antiAbuse.CheckPromotionalEligibility(spaceID, installationID, "REWARDED_AD")
		if !eligible {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Reward not available for this device: " + reason})
			return
		}
	}

	w, err := h.ledger.RewardAd(spaceID)
	if errors.Is(err, service.ErrAdRewardLimit) {
		c.JSON(http.StatusConflict, gin.H{"error": "Daily ad reward limit reached (30 ads/day)"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to reward ad credit"})
		return
	}

	if h.antiAbuse != nil && installationID != "" {
		_ = h.antiAbuse.RecordPromotionalClaim(spaceID, installationID, "REWARDED_AD")
	}

	c.JSON(http.StatusOK, w)
}

// Deduct handles direct credit deductions (e.g. for premium features or external callers).
func (h *WalletHandler) Deduct(spaceID, memberID string, amount int, txType model.TransactionType, refID, idempotencyKey string) (model.CreditWallet, model.CreditTransaction, error) {
	return h.ledger.DeductCredits(spaceID, memberID, amount, txType, refID, idempotencyKey)
}

// Refund handles credit refunds.
func (h *WalletHandler) Refund(spaceID, memberID string, amount int, refID string) (model.CreditWallet, error) {
	return h.ledger.RefundCredits(spaceID, memberID, amount, refID)
}

func validDeviceID(c *gin.Context) (string, bool) {
	deviceID := c.Param("deviceId")
	if !idPattern.MatchString(deviceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid space/deviceId"})
		return "", false
	}
	return deviceID, true
}
