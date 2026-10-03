package engine_test

import (
	"testing"
	"time"

	"github.com/nuto/backend/internal/engine"
)

func TestNutritionPromptBuilder(t *testing.T) {
	input := engine.ProfileInput{
		DateOfBirth:   "1995-06-15",
		Gender:        "female",
		HeightCm:      165,
		WeightKg:      60,
		ActivityLevel: "moderately_active",
		Goal:          "maintain_weight",
	}

	prompt := engine.BuildNutritionPrompt(input)
	if len(prompt) < 200 {
		t.Errorf("Expected comprehensive prompt, got %d chars", len(prompt))
	}
}

func TestAITargetValidation_ValidAdult(t *testing.T) {
	dob := time.Now().AddDate(-28, 0, 0).Format("2006-01-02")
	input := engine.ProfileInput{
		DateOfBirth:   dob,
		Gender:        "female",
		HeightCm:      165,
		WeightKg:      60,
		ActivityLevel: "moderately_active",
		Goal:          "maintain_weight",
	}

	targets := engine.CalculateTargets(input)
	err := engine.ValidateAITargets(input, targets)
	if err != nil {
		t.Errorf("Expected valid targets to pass validation, got: %v", err)
	}
}

func TestAITargetValidation_DangerousAdultDeficit(t *testing.T) {
	dob := time.Now().AddDate(-28, 0, 0).Format("2006-01-02")
	input := engine.ProfileInput{
		DateOfBirth:   dob,
		Gender:        "male",
		HeightCm:      180,
		WeightKg:      85,
		ActivityLevel: "sedentary",
		Goal:          "weight_loss",
	}

	targets := engine.CalculateTargets(input)
	// Artificially simulate an unsafe AI output of 900 kcal
	targets.Energy.Calories = 900.0

	err := engine.ValidateAITargets(input, targets)
	if err == nil {
		t.Errorf("Expected validation error for dangerous 900 kcal adult target, but got nil")
	}
}

func TestAITargetValidation_PediatricDeficitViolation(t *testing.T) {
	dob := time.Now().AddDate(-8, 0, 0).Format("2006-01-02")
	input := engine.ProfileInput{
		DateOfBirth:   dob,
		Gender:        "female",
		HeightCm:      125,
		WeightKg:      25,
		ActivityLevel: "moderately_active",
		Goal:          "healthy_growth",
	}

	targets := engine.CalculateTargets(input)
	if targets.Energy == nil {
		t.Fatalf("Expected valid pediatric baseline targets")
	}
	// Artificially simulate an unsafe AI output below child growth floor
	targets.Energy.Calories = 700.0

	err := engine.ValidateAITargets(input, targets)
	if err == nil {
		t.Errorf("Expected validation error for child target below growth floor, but got nil")
	}
}
