package service

import (
	"testing"

	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

func TestSharedCreditWalletAndLedger(t *testing.T) {
	tmpDir := t.TempDir()
	repo, err := repository.NewFileRepository(tmpDir)
	if err != nil {
		t.Fatalf("failed to create repo: %v", err)
	}

	svc := NewLedgerService(repo)
	spaceID := "space_test_123"

	// 1. Initial wallet load (Daily=5, Ad=0, Balance=5)
	w, err := svc.GetOrCreateWallet(spaceID)
	if err != nil {
		t.Fatalf("failed to get wallet: %v", err)
	}
	if w.DailyBalance != 5 || w.AdBalance != 0 || w.CreditBalance != 5 {
		t.Errorf("Expected Daily=5, Ad=0, Total=5; got Daily=%d, Ad=%d, Total=%d", w.DailyBalance, w.AdBalance, w.CreditBalance)
	}

	// 2. Watch 1 rewarded ad -> +1 ad credit (Daily=5, Ad=1, Balance=6)
	w, err = svc.RewardAd(spaceID)
	if err != nil {
		t.Fatalf("reward ad failed: %v", err)
	}
	if w.DailyBalance != 5 || w.AdBalance != 1 || w.CreditBalance != 6 {
		t.Errorf("Expected Daily=5, Ad=1, Total=6; got Daily=%d, Ad=%d, Total=%d", w.DailyBalance, w.AdBalance, w.CreditBalance)
	}

	// 3. Member 1 (Mother) logs meal -> deducts 2 credits (Daily: 5->3, Ad: 1, Balance=4)
	w, tx1, err := svc.DeductCredits(spaceID, "mem_mom", 2, model.TxTypeMealAnalysis, "analysis_1", "idem_1")
	if err != nil {
		t.Fatalf("mother deduction failed: %v", err)
	}
	if w.DailyBalance != 3 || w.AdBalance != 1 || w.CreditBalance != 4 {
		t.Errorf("Expected Daily=3, Ad=1, Total=4; got Daily=%d, Ad=%d, Total=%d", w.DailyBalance, w.AdBalance, w.CreditBalance)
	}
	if tx1.Bucket != model.BucketDaily || tx1.Amount != -2 {
		t.Errorf("Expected DAILY bucket tx with amount -2, got %s, %d", tx1.Bucket, tx1.Amount)
	}

	// 4. Member 2 (Child) logs meal -> deducts 2 credits (Daily: 3->1, Ad: 1, Balance=2)
	w, tx2, err := svc.DeductCredits(spaceID, "mem_child", 2, model.TxTypeMealAnalysis, "analysis_2", "idem_2")
	if err != nil {
		t.Fatalf("child deduction failed: %v", err)
	}
	if w.DailyBalance != 1 || w.AdBalance != 1 || w.CreditBalance != 2 {
		t.Errorf("Expected Daily=1, Ad=1, Total=2; got Daily=%d, Ad=%d, Total=%d", w.DailyBalance, w.AdBalance, w.CreditBalance)
	}
	if tx2.Bucket != model.BucketDaily {
		t.Errorf("Expected DAILY bucket, got %s", tx2.Bucket)
	}

	// 5. Member 1 (Mother) logs meal -> deducts 2 credits (Consumes 1 Daily + 1 Ad -> SPLIT bucket, Daily=0, Ad=0, Balance=0)
	w, tx3, err := svc.DeductCredits(spaceID, "mem_mom", 2, model.TxTypeMealAnalysis, "analysis_3", "idem_3")
	if err != nil {
		t.Fatalf("split deduction failed: %v", err)
	}
	if w.DailyBalance != 0 || w.AdBalance != 0 || w.CreditBalance != 0 {
		t.Errorf("Expected Daily=0, Ad=0, Total=0; got Daily=%d, Ad=%d, Total=%d", w.DailyBalance, w.AdBalance, w.CreditBalance)
	}
	if tx3.Bucket != model.BucketSplit {
		t.Errorf("Expected SPLIT bucket, got %s", tx3.Bucket)
	}

	// 6. Insufficient credit check
	_, _, err = svc.DeductCredits(spaceID, "mem_child", 1, model.TxTypeMealAnalysis, "analysis_4", "idem_4")
	if err != ErrInsufficientCredits {
		t.Errorf("Expected ErrInsufficientCredits, got %v", err)
	}

	// 7. Refund 2 credits on AI failure
	w, err = svc.RefundCredits(spaceID, "mem_mom", 2, "analysis_3")
	if err != nil {
		t.Fatalf("refund failed: %v", err)
	}
	if w.DailyBalance != 2 || w.CreditBalance != 2 {
		t.Errorf("Expected Daily=2, Total=2 after refund; got Daily=%d, Total=%d", w.DailyBalance, w.CreditBalance)
	}

	// 8. Midnight rollover simulation: Yesterday's leftovers replaced by 5 daily credits
	w.LastDailyGrantDate = "2020-01-01"
	w.AdBalance = 3
	_ = repo.Put("wallets", spaceID, w)

	wNew, err := svc.GetOrCreateWallet(spaceID)
	if err != nil {
		t.Fatalf("daily rollover failed: %v", err)
	}
	if wNew.DailyBalance != 5 || wNew.AdBalance != 3 || wNew.CreditBalance != 8 {
		t.Errorf("Expected Daily=5, Ad=3, Total=8; got Daily=%d, Ad=%d, Total=%d", wNew.DailyBalance, wNew.AdBalance, wNew.CreditBalance)
	}
}
