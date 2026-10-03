package service

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

const (
	DailyFreeCredits     = 5
	RewardedAdCredit     = 1
	MaxRewardedAdsPerDay = 30
	UnlimitedTestCredits = 99999
)

var (
	ErrInsufficientCredits = errors.New("insufficient credit balance for operation")
	ErrAdRewardLimit       = errors.New("daily ad reward limit reached")
	ErrInvalidAmount       = errors.New("transaction amount must be positive")
)

// isTestSpace checks if a space ID or user belongs to a QA/testing account with unlimited credits.
func isTestSpace(spaceID string) bool {
	lower := strings.ToLower(spaceID)
	return strings.Contains(lower, "test") ||
		strings.Contains(lower, "demo") ||
		strings.Contains(lower, "admin") ||
		strings.Contains(lower, "qa") ||
		strings.Contains(lower, "tester")
}

// LedgerService manages atomic credit deductions, grants, refunds, and immutable audit logs.
type LedgerService struct {
	repo repository.Repository
}

func NewLedgerService(repo repository.Repository) *LedgerService {
	return &LedgerService{repo: repo}
}

// GetOrCreateWallet fetches or initializes the shared wallet for a NutritionSpace.
func (s *LedgerService) GetOrCreateWallet(spaceID string) (model.CreditWallet, error) {
	today := time.Now().UTC().Format("2006-01-02")
	val, err := s.repo.Update("wallets", spaceID, func(raw json.RawMessage, found bool) (any, error) {
		w := decodeWallet(raw, found, spaceID)
		w = refreshDailyAllowance(w, today)
		return w, nil
	})
	if err != nil {
		return model.CreditWallet{}, err
	}
	return val.(model.CreditWallet), nil
}

// DeductCredits atomically spends shared credits for a space, consuming Daily balance first then Ad balance.
func (s *LedgerService) DeductCredits(spaceID, memberID string, amount int, txType model.TransactionType, refID, idempotencyKey string) (model.CreditWallet, model.CreditTransaction, error) {
	if amount <= 0 {
		return model.CreditWallet{}, model.CreditTransaction{}, ErrInvalidAmount
	}

	today := time.Now().UTC().Format("2006-01-02")
	var recordedTx model.CreditTransaction

	val, err := s.repo.Update("wallets", spaceID, func(raw json.RawMessage, found bool) (any, error) {
		w := decodeWallet(raw, found, spaceID)
		w = refreshDailyAllowance(w, today)

		totalAvailable := w.DailyBalance + w.AdBalance
		if totalAvailable < amount && !isTestSpace(spaceID) {
			return nil, ErrInsufficientCredits
		}

		dailyDeducted := min(w.DailyBalance, amount)
		if isTestSpace(spaceID) {
			w.DailyBalance = UnlimitedTestCredits
			w.CreditBalance = UnlimitedTestCredits
			w.AdBalance = UnlimitedTestCredits
		} else {
			w.DailyBalance -= dailyDeducted
			adDeducted := amount - dailyDeducted
			w.AdBalance -= adDeducted
			w.CreditBalance = w.DailyBalance + w.AdBalance
			w.TotalSpentCredits += amount
		}
		w.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

		var bucket model.CreditBucket
		if dailyDeducted > 0 {
			bucket = model.BucketDaily
		} else {
			bucket = model.BucketAd
		}

		txID := fmt.Sprintf("tx_%d", time.Now().UnixNano())
		recordedTx = model.CreditTransaction{
			ID:              txID,
			SpaceID:         spaceID,
			MemberID:        memberID,
			Bucket:          bucket,
			Amount:          -amount,
			TransactionType: txType,
			ReferenceID:     refID,
			IdempotencyKey:  idempotencyKey,
			CreatedAt:       time.Now().UTC().Format(time.RFC3339),
		}

		return w, nil
	})

	if err != nil {
		return model.CreditWallet{}, model.CreditTransaction{}, err
	}

	// Persist ledger transaction audit entry
	if recordedTx.ID != "" {
		_ = s.repo.Put("credit_transactions", spaceID+"__"+recordedTx.ID, recordedTx)
	}

	return val.(model.CreditWallet), recordedTx, nil
}

// RewardAd grants 1 ad credit to the shared space wallet.
func (s *LedgerService) RewardAd(spaceID string) (model.CreditWallet, error) {
	today := time.Now().UTC().Format("2006-01-02")
	var recordedTx model.CreditTransaction

	val, err := s.repo.Update("wallets", spaceID, func(raw json.RawMessage, found bool) (any, error) {
		w := decodeWallet(raw, found, spaceID)
		w = refreshDailyAllowance(w, today)

		watched := w.RewardedAdsWatchedToday
		if w.LastAdRewardDate != today {
			watched = 0
		}

		if watched >= MaxRewardedAdsPerDay && !isTestSpace(spaceID) {
			return nil, ErrAdRewardLimit
		}

		w.AdBalance += RewardedAdCredit
		w.CreditBalance = w.DailyBalance + w.AdBalance
		w.TotalEarnedCredits += RewardedAdCredit
		w.LastAdRewardDate = today
		w.RewardedAdsWatchedToday = watched + 1
		w.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

		txID := fmt.Sprintf("tx_ad_%d", time.Now().UnixNano())
		recordedTx = model.CreditTransaction{
			ID:              txID,
			SpaceID:         spaceID,
			Bucket:          model.BucketAd,
			Amount:          RewardedAdCredit,
			TransactionType: model.TxTypeRewardedAd,
			CreatedAt:       time.Now().UTC().Format(time.RFC3339),
		}

		return w, nil
	})

	if err != nil {
		return model.CreditWallet{}, err
	}

	if recordedTx.ID != "" {
		_ = s.repo.Put("credit_transactions", spaceID+"__"+recordedTx.ID, recordedTx)
	}

	return val.(model.CreditWallet), nil
}

// RefundCredits restores credits back to the space wallet and writes an audit transaction.
func (s *LedgerService) RefundCredits(spaceID, memberID string, amount int, refID string) (model.CreditWallet, error) {
	if amount <= 0 {
		return model.CreditWallet{}, ErrInvalidAmount
	}
	today := time.Now().UTC().Format("2006-01-02")
	var recordedTx model.CreditTransaction

	val, err := s.repo.Update("wallets", spaceID, func(raw json.RawMessage, found bool) (any, error) {
		w := decodeWallet(raw, found, spaceID)
		w = refreshDailyAllowance(w, today)

		if isTestSpace(spaceID) {
			w.DailyBalance = UnlimitedTestCredits
			w.CreditBalance = UnlimitedTestCredits
			w.AdBalance = UnlimitedTestCredits
			return w, nil
		}

		// Restore daily credits up to 5 if same grant date, remainder to Ad balance
		if w.LastDailyGrantDate == today && w.DailyBalance < DailyFreeCredits {
			dailyRefund := min(amount, DailyFreeCredits-w.DailyBalance)
			w.DailyBalance += dailyRefund
			adRefund := amount - dailyRefund
			w.AdBalance += adRefund
		} else {
			w.AdBalance += amount
		}

		w.CreditBalance = w.DailyBalance + w.AdBalance
		w.TotalSpentCredits -= amount
		if w.TotalSpentCredits < 0 {
			w.TotalSpentCredits = 0
		}
		w.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

		txID := fmt.Sprintf("tx_ref_%d", time.Now().UnixNano())
		recordedTx = model.CreditTransaction{
			ID:              txID,
			SpaceID:         spaceID,
			MemberID:        memberID,
			Bucket:          model.BucketAd,
			Amount:          amount,
			TransactionType: model.TxTypeRefund,
			ReferenceID:     refID,
			CreatedAt:       time.Now().UTC().Format(time.RFC3339),
		}

		return w, nil
	})

	if err != nil {
		return model.CreditWallet{}, err
	}

	if recordedTx.ID != "" {
		_ = s.repo.Put("credit_transactions", spaceID+"__"+recordedTx.ID, recordedTx)
	}

	return val.(model.CreditWallet), nil
}

func decodeWallet(raw json.RawMessage, found bool, spaceID string) model.CreditWallet {
	now := time.Now().UTC().Format(time.RFC3339)
	if isTestSpace(spaceID) {
		return model.CreditWallet{
			ID:                 "wallet_" + spaceID,
			SpaceID:            spaceID,
			DailyBalance:       UnlimitedTestCredits,
			AdBalance:          UnlimitedTestCredits,
			CreditBalance:      UnlimitedTestCredits,
			LastDailyGrantDate: time.Now().UTC().Format("2006-01-02"),
			TotalEarnedCredits: UnlimitedTestCredits,
			UpdatedAt:          now,
		}
	}
	if !found || len(raw) == 0 {
		return model.CreditWallet{
			ID:                 "wallet_" + spaceID,
			SpaceID:            spaceID,
			DailyBalance:       DailyFreeCredits,
			AdBalance:          0,
			CreditBalance:      DailyFreeCredits,
			LastDailyGrantDate: time.Now().UTC().Format("2006-01-02"),
			TotalEarnedCredits: DailyFreeCredits,
			UpdatedAt:          now,
		}
	}
	var w model.CreditWallet
	_ = json.Unmarshal(raw, &w)
	if w.SpaceID == "" {
		w.SpaceID = spaceID
	}
	return w
}

func refreshDailyAllowance(w model.CreditWallet, today string) model.CreditWallet {
	if isTestSpace(w.SpaceID) {
		w.DailyBalance = UnlimitedTestCredits
		w.CreditBalance = UnlimitedTestCredits
		w.AdBalance = UnlimitedTestCredits
		return w
	}
	// Midnight reset: 5 daily free credits reset every day
	if w.LastDailyGrantDate != today {
		w.DailyBalance = DailyFreeCredits
		w.LastDailyGrantDate = today
		w.RewardedAdsWatchedToday = 0
	}
	w.CreditBalance = w.DailyBalance + w.AdBalance
	return w
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

