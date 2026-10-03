package model

import "time"

// SpaceMode defines the operating mode of a NutritionSpace
type SpaceMode string

const (
	ModePersonal SpaceMode = "PERSONAL"
	ModeFamily   SpaceMode = "FAMILY"
)

// NutritionSpace represents the household container for members, shared credits, and settings.
type NutritionSpace struct {
	ID             string    `json:"id"`
	OwnerUserID    string    `json:"ownerUserId"`
	Mode           SpaceMode `json:"mode"`
	ActiveMemberID string    `json:"activeProfileId"`
	MaxMembers     int       `json:"maxMembers"`
	CreatedAt      string    `json:"createdAt"`
	UpdatedAt      string    `json:"updatedAt"`
}

// Member represents an individual profile belonging to a NutritionSpace.
// Height, Weight, and DateOfBirth are the source inputs (BMI and Age are dynamic).
type Member struct {
	ID            string  `json:"id"`
	SpaceID       string  `json:"spaceId"`
	Name          string  `json:"name"`
	Relationship  string  `json:"relationship"` // "owner", "spouse", "child", "parent", "other"
	Age           int     `json:"age"`          // Direct Age in years
	DateOfBirth   string  `json:"dateOfBirth,omitempty"` // "YYYY-MM-DD" (optional)
	Gender        string  `json:"gender"`       // "male", "female"
	HeightCm      float64 `json:"heightCm"`
	WeightKg      float64 `json:"weightKg"`
	HeightUnit    string  `json:"heightUnit"`   // "cm", "ft"
	WeightUnit    string  `json:"weightUnit"`   // "kg", "lbs"
	Goal                string  `json:"goal"`                // "maintain_weight", "weight_loss", "weight_gain", "healthy_growth", "muscle_gain"
	ActivityLevel       string  `json:"activityLevel"`       // "sedentary", "lightly_active", "moderately_active", "very_active", "extremely_active"
	PregnancyStatus     string  `json:"pregnancyStatus,omitempty"`     // "none", "pregnant", "trimester1", "trimester2", "trimester3"
	BreastfeedingStatus string  `json:"breastfeedingStatus,omitempty"` // "none", "exclusive", "partial"
	DietaryPattern      string  `json:"dietaryPattern,omitempty"`      // "omnivore", "vegetarian", "vegan", "keto", "low_carb"
	ProfileImage        string  `json:"profileImage"`
	CreatedAt           string  `json:"createdAt"`
	UpdatedAt           string  `json:"updatedAt"`
}

// BMIAssessment represents calculated assessment distinguishing adult vs pediatric categories.
type BMIAssessment struct {
	Type           string   `json:"type"`                     // "ADULT" | "PEDIATRIC"
	BMI            float64  `json:"bmi"`                      // Rounded to 1 decimal
	Category       string   `json:"category"`                 // e.g., "Normal", "Underweight", "Overweight"
	Percentile     *float64 `json:"percentile,omitempty"`     // 0-100 for pediatric
	ZScore         *float64 `json:"zScore,omitempty"`         // Standard deviations from median for pediatric
	AssessmentText string   `json:"assessmentText"`
	Version        string   `json:"version"`
}

// TargetSnapshot stores a point-in-time calculation snapshot for historical records.
type TargetSnapshot struct {
	Calories           float64 `json:"calories"`
	Protein            float64 `json:"protein"`
	Carbs              float64 `json:"carbs"`
	Fat                float64 `json:"fat"`
	Fiber              float64 `json:"fiber"`
	HydrationLiters    float64 `json:"hydrationLiters"`
	CalculationVersion string  `json:"calculationVersion"`
	CalculatedAt       string  `json:"calculatedAt"`
}

// MemberEnrichedProfile is returned to clients with dynamically evaluated metrics.
type MemberEnrichedProfile struct {
	Member
	Age           int            `json:"age"`
	BMI           float64        `json:"bmi"`
	BMICategory   string         `json:"bmiCategory"`
	BMIAssessment BMIAssessment  `json:"bmiAssessment"`
	ProfileStatus string         `json:"profileStatus"` // "profile_complete" | "profile_incomplete"
	DailyTargets  map[string]any `json:"dailyTargets,omitempty"`
	Calculation   map[string]any `json:"calculation,omitempty"`
}

// CreditWallet stores shared credit balances for a NutritionSpace.
type CreditWallet struct {
	ID                      string `json:"id"`
	SpaceID                 string `json:"spaceId"`
	DailyBalance            int    `json:"dailyBalance"`
	AdBalance               int    `json:"adBalance"`
	CreditBalance           int    `json:"creditBalance"` // DailyBalance + AdBalance
	LastDailyGrantDate      string `json:"lastDailyGrantDate"`
	RewardedAdsWatchedToday int    `json:"rewardedAdsWatchedToday"`
	LastAdRewardDate        string `json:"lastAdRewardDate"`
	TotalEarnedCredits      int    `json:"totalEarnedCredits"`
	TotalSpentCredits       int    `json:"totalSpentCredits"`
	UpdatedAt               string `json:"updatedAt"`
}

// CreditBucket denotes which credit bucket was touched.
type CreditBucket string

const (
	BucketDaily CreditBucket = "DAILY"
	BucketAd    CreditBucket = "AD"
	BucketSplit CreditBucket = "SPLIT"
	BucketPromo CreditBucket = "PROMO"
)

// TransactionType denotes the kind of credit operation.
type TransactionType string

const (
	TxTypeDailyGrant   TransactionType = "DAILY_GRANT"
	TxTypeMealAnalysis TransactionType = "MEAL_ANALYSIS"
	TxTypeRewardedAd   TransactionType = "REWARDED_AD"
	TxTypeRefund       TransactionType = "REFUND"
	TxTypePromoClaim   TransactionType = "PROMO_CLAIM"
)

// CreditTransaction represents an immutable ledger entry for credit operations.
type CreditTransaction struct {
	ID              string          `json:"id"`
	SpaceID         string          `json:"spaceId"`
	MemberID        string          `json:"memberId,omitempty"`
	Bucket          CreditBucket    `json:"bucket"`
	Amount          int             `json:"amount"` // Negative for spend, positive for grant/reward/refund
	TransactionType TransactionType `json:"transactionType"`
	ReferenceID     string          `json:"referenceId,omitempty"`
	IdempotencyKey  string          `json:"idempotencyKey,omitempty"`
	CreatedAt       string          `json:"createdAt"`
	ExpiresAt       *string         `json:"expiresAt,omitempty"`
}

// NutritionEntry represents a logged food or meal item.
type NutritionEntry struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Calories float64 `json:"calories"`
	Protein  float64 `json:"protein"`
	Carbs    float64 `json:"carbs"`
	Fat      float64 `json:"fat"`
	Fiber    float64 `json:"fiber,omitempty"`
	MealType string  `json:"mealType"`
	LoggedAt string  `json:"loggedAt"`
	ImageURL string  `json:"imageUrl,omitempty"`
	Notes    string  `json:"notes,omitempty"`
}

// NutritionDay represents daily totals and meal entries scoped by space and member.
type NutritionDay struct {
	SpaceID        string             `json:"spaceId"`
	MemberID       string             `json:"memberId"`
	Date           string             `json:"date"`
	TotalNutrition map[string]float64 `json:"totalNutrition"`
	TargetSnapshot *TargetSnapshot    `json:"targetSnapshot,omitempty"`
	Entries        []NutritionEntry   `json:"entries"`
	UpdatedAt      string             `json:"updatedAt"`
}

// Installation represents an installation instance for anti-abuse & risk checks.
type Installation struct {
	ID                  string `json:"id"`
	InstallationKeyHash string `json:"installationKeyHash"`
	Platform            string `json:"platform"` // "android", "ios", "web"
	AppVersion          string `json:"appVersion"`
	FirstSeenAt         string `json:"firstSeenAt"`
	LastSeenAt          string `json:"lastSeenAt"`
	AttestationStatus   string `json:"attestationStatus"` // "VERIFIED", "UNVERIFIED", "SUSPICIOUS"
	RiskScore           int    `json:"riskScore"`          // 0 (trusted) to 100 (high risk)
	Status              string `json:"status"`             // "ACTIVE", "RESTRICTED", "BLOCKED"
}

// InstallationAccount maps installations to accounts.
type InstallationAccount struct {
	InstallationID string `json:"installationId"`
	UserID         string `json:"userId"`
	FirstSeenAt    string `json:"firstSeenAt"`
	LastSeenAt     string `json:"lastSeenAt"`
}

// PromotionalClaim tracks promotional bonus grants per space and installation.
type PromotionalClaim struct {
	ID             string `json:"id"`
	SpaceID        string `json:"spaceId"`
	InstallationID string `json:"installationId"`
	PromotionType  string `json:"promotionType"`
	ClaimDate      string `json:"claimDate"`
	CreatedAt      string `json:"createdAt"`
}

// NewNutritionSpace returns a default NutritionSpace instance.
func NewNutritionSpace(ownerUserID string) NutritionSpace {
	now := time.Now().UTC().Format(time.RFC3339)
	return NutritionSpace{
		ID:             ownerUserID,
		OwnerUserID:    ownerUserID,
		Mode:           ModePersonal,
		ActiveMemberID: "",
		MaxMembers:     3,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}
