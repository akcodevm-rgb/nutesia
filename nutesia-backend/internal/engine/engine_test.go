package engine_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/nuto/backend/internal/engine"
)

type GoldenTestCase struct {
	Description          string                   `json:"description"`
	Input                engine.ProfileInput      `json:"input"`
	ExpectedSafetyStatus engine.SafetyStatus      `json:"expectedSafetyStatus"`
	ExpectedCalcStatus   engine.CalculationStatus `json:"expectedCalcStatus"`
	ShouldHaveTargets    bool                     `json:"shouldHaveTargets"`
	ExpectedMinCalories  float64                  `json:"expectedMinCalories,omitempty"`
	ExpectedMaxCalories  float64                  `json:"expectedMaxCalories,omitempty"`
}

func TestGoldenTestCases(t *testing.T) {
	goldenPath := filepath.Join("testdata", "golden_cases.json")
	data, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("Failed to read golden cases file: %v", err)
	}

	var cases []GoldenTestCase
	if err := json.Unmarshal(data, &cases); err != nil {
		t.Fatalf("Failed to parse golden cases JSON: %v", err)
	}

	for _, tc := range cases {
		t.Run(tc.Description, func(t *testing.T) {
			res := engine.CalculateTargets(tc.Input)

			if res.Safety.Status != tc.ExpectedSafetyStatus {
				t.Errorf("SafetyStatus mismatch: got %s, want %s", res.Safety.Status, tc.ExpectedSafetyStatus)
			}
			if res.Calculation.Status != tc.ExpectedCalcStatus {
				t.Errorf("CalculationStatus mismatch: got %s, want %s", res.Calculation.Status, tc.ExpectedCalcStatus)
			}

			if tc.ShouldHaveTargets {
				if res.Energy == nil {
					t.Fatalf("Expected Energy target to be non-nil")
				}
				if res.Macros == nil {
					t.Fatalf("Expected Macros target to be non-nil")
				}
				if res.Hydration == nil {
					t.Fatalf("Expected Hydration target to be non-nil")
				}

				if tc.ExpectedMinCalories > 0 && res.Energy.Calories < tc.ExpectedMinCalories {
					t.Errorf("Energy.Calories %f is below min %f", res.Energy.Calories, tc.ExpectedMinCalories)
				}
				if tc.ExpectedMaxCalories > 0 && res.Energy.Calories > tc.ExpectedMaxCalories {
					t.Errorf("Energy.Calories %f is above max %f", res.Energy.Calories, tc.ExpectedMaxCalories)
				}

				if res.Macros.Protein.Amount <= 0 {
					t.Errorf("Protein amount should be > 0, got %f", res.Macros.Protein.Amount)
				}
				if res.Macros.Fiber.Amount <= 0 {
					t.Errorf("Fiber amount should be > 0, got %f", res.Macros.Fiber.Amount)
				}
			} else {
				if res.Energy != nil {
					t.Errorf("Expected nil Energy target when calculation is unsupported/review, got %+v", res.Energy)
				}
				if res.Macros != nil {
					t.Errorf("Expected nil Macros target when calculation is unsupported/review, got %+v", res.Macros)
				}
				if res.Hydration != nil {
					t.Errorf("Expected nil Hydration target when calculation is unsupported/review, got %+v", res.Hydration)
				}
			}
		})
	}
}

func TestDeterministicIdempotency(t *testing.T) {
	input := engine.ProfileInput{
		Age:           30,
		Gender:        "male",
		HeightCm:      178.0,
		WeightKg:      75.0,
		ActivityLevel: "moderately_active",
		Goal:          "maintain_weight",
	}

	first := engine.CalculateTargets(input)
	for i := 0; i < 50; i++ {
		repeat := engine.CalculateTargets(input)
		if first.Energy.Calories != repeat.Energy.Calories {
			t.Fatalf("Non-deterministic calories detected on iteration %d: %f vs %f", i, first.Energy.Calories, repeat.Energy.Calories)
		}
		if first.Macros.Protein.Amount != repeat.Macros.Protein.Amount {
			t.Fatalf("Non-deterministic protein detected on iteration %d", i)
		}
		if first.Macros.Carbohydrates.Amount != repeat.Macros.Carbohydrates.Amount {
			t.Fatalf("Non-deterministic carbs detected on iteration %d", i)
		}
		if first.Macros.Fat.Amount != repeat.Macros.Fat.Amount {
			t.Fatalf("Non-deterministic fat detected on iteration %d", i)
		}
		if first.Hydration.WaterLiters != repeat.Hydration.WaterLiters {
			t.Fatalf("Non-deterministic water detected on iteration %d", i)
		}
	}
}

func TestUnder2YearsAgeBoundary(t *testing.T) {
	input := engine.ProfileInput{
		Age:           1,
		Gender:        "male",
		HeightCm:      78.0,
		WeightKg:      10.5,
		ActivityLevel: "lightly_active",
		Goal:          "healthy_growth",
	}
	res := engine.CalculateTargets(input)
	if res.Safety.Status != engine.SafetyUnsupported {
		t.Errorf("Expected UNSUPPORTED for age 1, got %s", res.Safety.Status)
	}
	if res.Calculation.Status != engine.CalcNotCalculated {
		t.Errorf("Expected NOT_CALCULATED for age 1, got %s", res.Calculation.Status)
	}
	if res.Energy != nil || res.Macros != nil || res.Hydration != nil {
		t.Errorf("Targets must be nil for unsupported age < 2")
	}
	if res.Safety.NoticeTitle == "" || res.Safety.NoticeMessage == "" {
		t.Errorf("Expected explanatory notice title and message for unsupported infant")
	}
}

func TestPediatricCalorieDeficitRejection(t *testing.T) {
	input := engine.ProfileInput{
		Age:           12,
		Gender:        "female",
		HeightCm:      150.0,
		WeightKg:      55.0,
		ActivityLevel: "lightly_active",
		Goal:          "weight_loss",
	}
	res := engine.CalculateTargets(input)
	if res.Safety.Status != engine.SafetyProfessionalReview {
		t.Errorf("Expected PROFESSIONAL_REVIEW for pediatric weight loss, got %s", res.Safety.Status)
	}
	if res.Calculation.Status != engine.CalcNotCalculated {
		t.Errorf("Expected NOT_CALCULATED for pediatric weight loss, got %s", res.Calculation.Status)
	}
	if res.Energy != nil {
		t.Errorf("Energy target must be nil when pediatric deficit is rejected")
	}
}

func TestPregnancySafetyGate(t *testing.T) {
	input := engine.ProfileInput{
		Age:             28,
		Gender:          "female",
		HeightCm:        165.0,
		WeightKg:        63.0,
		ActivityLevel:   "lightly_active",
		Goal:            "maintain_weight",
		PregnancyStatus: "trimester1",
	}
	res := engine.CalculateTargets(input)
	if res.Safety.Status != engine.SafetyUnsupported {
		t.Errorf("Expected UNSUPPORTED for pregnancy, got %s", res.Safety.Status)
	}
	if res.Calculation.Status != engine.CalcNotCalculated {
		t.Errorf("Expected NOT_CALCULATED for pregnancy, got %s", res.Calculation.Status)
	}
	if res.Energy != nil {
		t.Errorf("Energy target must be nil for pregnancy")
	}
}

func TestLactationSafetyGate(t *testing.T) {
	input := engine.ProfileInput{
		Age:                 30,
		Gender:              "female",
		HeightCm:            162.0,
		WeightKg:            60.0,
		ActivityLevel:       "moderately_active",
		Goal:                "maintain_weight",
		BreastfeedingStatus: "partial",
	}
	res := engine.CalculateTargets(input)
	if res.Safety.Status != engine.SafetyProfessionalReview {
		t.Errorf("Expected PROFESSIONAL_REVIEW for lactation, got %s", res.Safety.Status)
	}
	if res.Calculation.Status != engine.CalcNotCalculated {
		t.Errorf("Expected NOT_CALCULATED for lactation, got %s", res.Calculation.Status)
	}
	if res.Energy != nil {
		t.Errorf("Energy target must be nil for lactation")
	}
}

func TestAdultSafetyFloors(t *testing.T) {
	// Tiny female user with severe deficit request
	femaleInput := engine.ProfileInput{
		Age:           25,
		Gender:        "female",
		HeightCm:      145.0,
		WeightKg:      40.0,
		ActivityLevel: "sedentary",
		Goal:          "weight_loss",
	}
	fRes := engine.CalculateTargets(femaleInput)
	if fRes.Energy == nil {
		t.Fatalf("Expected Energy target")
	}
	if fRes.Energy.Calories < 1200.0 {
		t.Errorf("Female calorie target %f below Nuto adult safety floor 1200 kcal", fRes.Energy.Calories)
	}
	if !fRes.Safety.AppliedSafetyFloor {
		t.Errorf("Expected AppliedSafetyFloor flag to be true")
	}

	// Tiny male user with deficit
	maleInput := engine.ProfileInput{
		Age:           30,
		Gender:        "male",
		HeightCm:      155.0,
		WeightKg:      45.0,
		ActivityLevel: "sedentary",
		Goal:          "weight_loss",
	}
	mRes := engine.CalculateTargets(maleInput)
	if mRes.Energy == nil {
		t.Fatalf("Expected Energy target")
	}
	if mRes.Energy.Calories < 1500.0 {
		t.Errorf("Male calorie target %f below Nuto adult safety floor 1500 kcal", mRes.Energy.Calories)
	}
	if !mRes.Safety.AppliedSafetyFloor {
		t.Errorf("Expected AppliedSafetyFloor flag to be true")
	}
}

func TestLifeStageResolution(t *testing.T) {
	stages := []struct {
		years    int
		months   int
		gender   string
		expected engine.LifeStage
		group    string
	}{
		{0, 4, "male", engine.StageUnsupportedInfant, "INFANT"},
		{1, 6, "female", engine.StageUnsupportedInfant, "INFANT"},
		{2, 0, "male", engine.StageToddler2To3y, "TODDLER"},
		{6, 0, "female", engine.StageChild4To8y, "CHILD"},
		{11, 0, "male", engine.StageChild9To13yM, "CHILD"},
		{11, 0, "female", engine.StageChild9To13yF, "CHILD"},
		{16, 0, "male", engine.StageAdol14To18yM, "ADOLESCENT"},
		{16, 0, "female", engine.StageAdol14To18yF, "ADOLESCENT"},
		{25, 0, "male", engine.StageAdult19To30yM, "ADULT"},
		{40, 0, "female", engine.StageAdult31To50yF, "ADULT"},
		{60, 0, "male", engine.StageAdult51To70yM, "ADULT"},
		{60, 0, "female", engine.StageAdult51To70yF, "ADULT"},
		{75, 0, "male", engine.StageOlder71yM, "OLDER_ADULT"},
		{75, 0, "female", engine.StageOlder71yF, "OLDER_ADULT"},
	}

	for _, s := range stages {
		stage, group := engine.DetermineLifeStage(s.years, s.months, s.gender)
		if stage != s.expected {
			t.Errorf("For age %d y %d m %s, expected stage %s, got %s", s.years, s.months, s.gender, s.expected, stage)
		}
		if group != s.group {
			t.Errorf("For age %d y %d m %s, expected group %s, got %s", s.years, s.months, s.gender, s.group, group)
		}
	}
}

func TestMicronutrientMatrixCompleteness(t *testing.T) {
	allStages := []engine.LifeStage{
		engine.StageToddler2To3y,
		engine.StageChild4To8y,
		engine.StageChild9To13yM,
		engine.StageChild9To13yF,
		engine.StageAdol14To18yM,
		engine.StageAdol14To18yF,
		engine.StageAdult19To30yM,
		engine.StageAdult19To30yF,
		engine.StageAdult31To50yM,
		engine.StageAdult31To50yF,
		engine.StageAdult51To70yM,
		engine.StageAdult51To70yF,
		engine.StageOlder71yM,
		engine.StageOlder71yF,
	}

	requiredVitamins := []string{
		"vitaminA", "vitaminC", "vitaminD", "vitaminE", "vitaminK",
		"vitaminB1", "vitaminB2", "vitaminB3", "vitaminB5", "vitaminB6",
		"vitaminB7", "vitaminB9", "vitaminB12",
	}

	requiredMinerals := []string{
		"calcium", "iron", "magnesium", "phosphorus", "potassium",
		"sodium", "zinc", "copper", "selenium", "iodine",
	}

	for _, stage := range allStages {
		vits := engine.GetVitaminsReference(stage)
		for _, v := range requiredVitamins {
			amt, ok := vits[v]
			if !ok || amt.Amount <= 0 {
				t.Errorf("Stage %s missing required vitamin %s", stage, v)
			}
			if amt.TargetType == "" {
				t.Errorf("Stage %s vitamin %s missing TargetType classification", stage, v)
			}
		}

		mins := engine.GetMineralsReference(stage)
		for _, m := range requiredMinerals {
			amt, ok := mins[m]
			if !ok || amt.Amount <= 0 {
				t.Errorf("Stage %s missing required mineral %s", stage, m)
			}
			if amt.TargetType == "" {
				t.Errorf("Stage %s mineral %s missing TargetType classification", stage, m)
			}
		}
	}
}

func TestReferenceRegistryLookup(t *testing.T) {
	refIDs := []string{
		"ref_energy_adult_mifflin",
		"ref_energy_peds_schofield",
		"ref_dri_macros_micros",
		"ref_who_fiber",
		"ref_hydration_fluid",
	}

	for _, id := range refIDs {
		ref, exists := engine.GetReference(id)
		if !exists {
			t.Errorf("Expected registered reference for %s", id)
		}
		if ref.Name == "" || ref.Organization == "" || ref.Version == "" {
			t.Errorf("Reference %s missing required metadata fields: %+v", id, ref)
		}
	}
}

