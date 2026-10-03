package engine

import "time"

// SafetyStatus represents the clinical and product safety gating classification.
type SafetyStatus string

const (
	SafetySafe               SafetyStatus = "SAFE"
	SafetyWarning            SafetyStatus = "WARNING"
	SafetyProfessionalReview SafetyStatus = "PROFESSIONAL_REVIEW"
	SafetyUnsupported        SafetyStatus = "UNSUPPORTED"
	SafetyInvalidInput       SafetyStatus = "INVALID_INPUT"
)

// CalculationStatus represents whether quantitative targets were generated.
type CalculationStatus string

const (
	CalcCalculated          CalculationStatus = "CALCULATED"
	CalcNotCalculated       CalculationStatus = "NOT_CALCULATED"
	CalcPartiallyCalculated CalculationStatus = "PARTIALLY_CALCULATED"
)

// TargetType defines the precise scientific meaning of a nutrient recommendation (e.g. DRI standards).
type TargetType string

const (
	TargetTypeRDA TargetType = "RDA" // Recommended Dietary Allowance (meets needs of 97-98% individuals)
	TargetTypeAI  TargetType = "AI"  // Adequate Intake (established when evidence is insufficient for RDA)
	TargetTypeEAR TargetType = "EAR" // Estimated Average Requirement (meets needs of 50% individuals)
	TargetTypeUL  TargetType = "UL"  // Tolerable Upper Intake Level (maximum safe daily intake)
)

// ProfileInput contains user dimensions and characteristics for deterministic target computation.
type ProfileInput struct {
	Age                 int     `json:"age"`                 // Age in whole years
	DateOfBirth         string  `json:"dateOfBirth"`         // YYYY-MM-DD (preferred for exact age calculation)
	Gender              string  `json:"gender"`              // male | female
	HeightCm            float64 `json:"heightCm"`
	WeightKg            float64 `json:"weightKg"`
	ActivityLevel       string  `json:"activityLevel"`       // sedentary | lightly_active | moderately_active | very_active | extremely_active
	Goal                string  `json:"goal"`                // maintain_weight | weight_loss | weight_gain | healthy_growth | muscle_gain
	PregnancyStatus     string  `json:"pregnancyStatus"`     // none | pregnant | trimester1 | trimester2 | trimester3
	BreastfeedingStatus string  `json:"breastfeedingStatus"` // none | exclusive | partial
	DietaryPattern      string  `json:"dietaryPattern"`      // omnivore | vegetarian | vegan | keto | low_carb
}

// NutrientAmount represents a single nutrient recommendation with unit and scientific classification.
type NutrientAmount struct {
	Nutrient         string     `json:"nutrient"`
	Amount           float64    `json:"amount"`
	Unit             string     `json:"unit"`
	TargetType       TargetType `json:"targetType"`                 // RDA | AI | EAR | UL
	UpperLimit       float64    `json:"upperLimit,omitempty"`       // 0 if no strict upper limit
	ReferenceID      string     `json:"referenceId,omitempty"`      // Source ID in ReferenceRegistry
	ReferenceVersion string     `json:"referenceVersion,omitempty"`
}

// EnergyTarget breakdown.
type EnergyTarget struct {
	Calories float64 `json:"calories"` // Final daily target in kcal
	BMR      float64 `json:"bmr"`      // Basal Metabolic Rate
	TDEE     float64 `json:"tdee"`     // Total Daily Energy Expenditure
	Method   string  `json:"method"`   // E.g. "Mifflin-St Jeor (1990)" | "Schofield (1985)"
}

// MacroTargets breakdown.
type MacroTargets struct {
	Protein       NutrientAmount `json:"protein"`
	Carbohydrates NutrientAmount `json:"carbohydrates"`
	Fat           NutrientAmount `json:"fat"`
	Fiber         NutrientAmount `json:"fiber"`
}

// HydrationTarget breakdown.
type HydrationTarget struct {
	WaterLiters    float64 `json:"waterLiters"`    // Total recommended fluid intake in Liters
	BaselineLiters float64 `json:"baselineLiters"` // Baseline maintenance fluid requirement
	ActivityLiters float64 `json:"activityLiters"` // Extra fluid needed due to exercise/activity
	Unit           string  `json:"unit"`           // "L"
	Method         string  `json:"method"`         // E.g. "Holliday-Segar Fluid Reference" | "Adult 35ml/kg Standard"
}

// CalculationResult provides summary information about calculation execution.
type CalculationResult struct {
	Status  CalculationStatus `json:"status"`
	Method  string            `json:"method"`
	Track   string            `json:"track"` // "PEDIATRIC" | "ADULT" | "NONE"
	Summary string            `json:"summary"`
}

// SafetyGatingResult details safety flags, disclaimers, and referral notices.
type SafetyGatingResult struct {
	Status                 SafetyStatus `json:"status"`
	IsCalculationSupported bool         `json:"isCalculationSupported"`
	NoticeTitle            string       `json:"noticeTitle,omitempty"`
	NoticeMessage          string       `json:"noticeMessage,omitempty"`
	ClinicalFlags          []string     `json:"clinicalFlags,omitempty"`
	AppliedSafetyFloor     bool         `json:"appliedSafetyFloor"`
	MedicalDisclaimer      string       `json:"medicalDisclaimer"`
}

// CalculationSummary provides transparency into applied adjustments.
type CalculationSummary struct {
	AgeGroup           string   `json:"ageGroup"`           // TODDLER | CHILD | ADOLESCENT | ADULT | OLDER_ADULT
	AgeYears           int      `json:"ageYears"`
	AgeMonths          int      `json:"ageMonths"`
	EngineType         string   `json:"engineType"`         // AdultEngine | PediatricEngine
	Methodology        string   `json:"methodology"`
	AppliedAdjustments []string `json:"appliedAdjustments"` // Documented adjustments
	SafetyNotes        []string `json:"safetyNotes"`        // Safety guidance notes
}

// DailyTargets is the consolidated output of the Nutrition Requirement Engine.
type DailyTargets struct {
	Calculation        CalculationResult         `json:"calculation"`
	Safety             SafetyGatingResult        `json:"safety"`
	Energy             *EnergyTarget             `json:"energy"`
	Macros             *MacroTargets             `json:"macros"`
	Vitamins           map[string]NutrientAmount `json:"vitamins,omitempty"`
	Minerals           map[string]NutrientAmount `json:"minerals,omitempty"`
	Hydration          *HydrationTarget          `json:"hydration"`
	CalculationSummary CalculationSummary        `json:"calculationSummary"`
	CalculationVersion string                    `json:"calculationVersion"`
	ReferenceVersion   string                    `json:"referenceVersion"`
	GeneratedAt        string                    `json:"generatedAt"`
}

const (
	EngineVersionCurrent    = "v2.0.0-deterministic"
	ReferenceVersionCurrent = "DRI-2026-Edition"
	MedicalDisclaimerText   = "Nuto provides nutrition estimates, food-tracking information, and general wellness guidance. It is not a medical device and does not diagnose, treat, cure, or prevent any disease or medical condition. Calculations are estimates and should not replace personalized medical advice from a qualified healthcare professional. Pregnancy is not supported."
)

// NewDailyTargets returns an initialized DailyTargets struct with default maps.
func NewDailyTargets() DailyTargets {
	return DailyTargets{
		CalculationVersion: EngineVersionCurrent,
		ReferenceVersion:   ReferenceVersionCurrent,
		GeneratedAt:        time.Now().UTC().Format(time.RFC3339),
		Vitamins:           make(map[string]NutrientAmount),
		Minerals:           make(map[string]NutrientAmount),
		Safety: SafetyGatingResult{
			MedicalDisclaimer: MedicalDisclaimerText,
		},
	}
}
