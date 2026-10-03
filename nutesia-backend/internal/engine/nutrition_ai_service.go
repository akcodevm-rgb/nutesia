package engine

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"time"
)

const NutritionAIVersion = "ai-nutrition-v1.0-DRI2026"

// BuildNutritionPrompt constructs the strict system prompt containing all DRI 2026 reference tables,
// mathematical formulas, safety rules, and required JSON schema.
func BuildNutritionPrompt(input ProfileInput) string {
	years, months := parseDOBAge(input.DateOfBirth)
	stage, groupName := DetermineLifeStage(years, months, input.Gender)

	return fmt.Sprintf(`You are Nuto Nutrition Requirement Engine (Version: %s).
Your task is to calculate daily nutritional requirements for exactly ONE individual profile based on clinical guidelines (DRI 2026, WHO, Schofield, and Mifflin-St Jeor).
You MUST follow the rules, formulas, reference tables, and JSON schema provided below. Do not invent formulas. Do not invent nutrient reference values. Do not provide medical diagnosis.

PROFILE INPUT:
- Date of Birth: %s (Calculated Age: %d years, %d months)
- Life Stage: %s (%s)
- Sex / Gender: %s
- Height: %.1f cm
- Weight: %.1f kg
- Activity Level: %s
- Goal: %s
- Pregnancy Status: %s
- Breastfeeding Status: %s
- Dietary Pattern: %s

RULES & METHODOLOGY:
1. ADULT ENERGY FORMULA (Age >= 18):
   - BMR (Mifflin-St Jeor):
     Male: (10 * WeightKg) + (6.25 * HeightCm) - (5 * AgeYears) + 5
     Female: (10 * WeightKg) + (6.25 * HeightCm) - (5 * AgeYears) - 161
   - PAL Activity Multipliers:
     sedentary: 1.20 | lightly_active: 1.375 | moderately_active: 1.55 | very_active: 1.725 | extremely_active: 1.90
   - TDEE = BMR * PAL
   - Goal Adjustments:
     weight_loss: TDEE - 500 kcal (Floor: 1500 kcal male / 1200 kcal female)
     weight_gain: TDEE + 400 kcal
     muscle_gain: TDEE + 300 kcal
     maintain_weight: TDEE
   - Pregnancy / Lactation Additions:
     trimester2: +340 kcal | trimester3: +450 kcal | exclusive breastfeeding: +500 kcal | partial: +300 kcal

2. PEDIATRIC ENERGY FORMULA (Age < 18):
   - Schofield Pediatric BMR:
     0-3y Male: 60.9 * W - 54 | Female: 61.0 * W - 51
     3-10y Male: 22.7 * W + 495 | Female: 22.5 * W + 499
     10-18y Male: 17.5 * W + 651 | Female: 12.2 * W + 746
   - Pediatric PAL Multipliers:
     sedentary: 1.25 | lightly_active: 1.40 | moderately_active: 1.55 | very_active: 1.75
   - DRI Growth Energy Allowance:
     1-9y: +30 kcal/day | 10-13y: +60 kcal/day | 14-18y: +100 kcal/day
   - TDEE = (Schofield BMR * Pediatric PAL) + Growth Allowance
   - CRITICAL PEDIATRIC SAFETY:
     For children (age < 18), intentional calorie deficit dieting is PROHIBITED. If goal is weight_loss, target calories MUST equal TDEE (Growth baseline).
     Pediatric Growth Floors: 1100 kcal (<10y), 1400 kcal (10-13y), 1700 kcal (14-18y).

3. MACRONUTRIENT RULES:
   - Protein:
     Adults: 1.4 g/kg (sedentary) to 2.0 g/kg (active/muscle gain) (minimum 50g)
     Pediatric: 1.1 g/kg (toddler) to 1.4 g/kg (adolescent) (minimum 20g)
   - Fat:
     Adults: 25-30%% of calories (0.28 * Calories / 9)
     Toddlers (1-3y): 30-35%% of calories
   - Carbohydrates:
     Remainder of calories = (Calories - (Protein*4 + Fat*9)) / 4
     Floor: 130g (Adults for brain glucose) | 100g (Pediatric)
   - Fiber:
     Adults: 28g female / 34g male (21g F / 30g M for age 51+)
     Pediatric: AgeYears + 5g (minimum 14g)

4. HYDRATION RULES:
   - Adults: Baseline = WeightKg * 0.035 Liters + PAL bonus (0.4L moderate, 0.7L active, 1.0L extreme) + 0.7L if lactating
   - Pediatric (Holliday-Segar): <=10kg: 100ml/kg; 10-20kg: 1000ml + 50ml/kg over 10kg; >20kg: 1500ml + 20ml/kg over 20kg.

5. OUTPUT FORMAT:
   Return ONLY a valid JSON object matching this schema exactly (no markdown formatting, no code blocks):
{
  "version": "%s",
  "calculatedAt": "%s",
  "energy": {
    "calories": 2150.0,
    "bmr": 1540.0,
    "tdee": 2150.0
  },
  "macros": {
    "protein": { "amount": 85.0, "unit": "g" },
    "carbohydrates": { "amount": 280.0, "unit": "g" },
    "fat": { "amount": 65.0, "unit": "g" },
    "fiber": { "amount": 34.0, "unit": "g" }
  },
  "vitamins": {
    "vitaminA": { "amount": 900.0, "unit": "mcg", "upperLimit": 3000.0 },
    "vitaminC": { "amount": 90.0, "unit": "mg", "upperLimit": 2000.0 },
    "vitaminD": { "amount": 15.0, "unit": "mcg", "upperLimit": 100.0 },
    "vitaminE": { "amount": 15.0, "unit": "mg", "upperLimit": 1000.0 },
    "vitaminK": { "amount": 120.0, "unit": "mcg" },
    "vitaminB1": { "amount": 1.2, "unit": "mg" },
    "vitaminB2": { "amount": 1.3, "unit": "mg" },
    "vitaminB3": { "amount": 16.0, "unit": "mg", "upperLimit": 35.0 },
    "vitaminB5": { "amount": 5.0, "unit": "mg" },
    "vitaminB6": { "amount": 1.7, "unit": "mg", "upperLimit": 100.0 },
    "vitaminB7": { "amount": 30.0, "unit": "mcg" },
    "vitaminB9": { "amount": 400.0, "unit": "mcg", "upperLimit": 1000.0 },
    "vitaminB12": { "amount": 2.4, "unit": "mcg" }
  },
  "minerals": {
    "calcium": { "amount": 1000.0, "unit": "mg", "upperLimit": 2500.0 },
    "iron": { "amount": 8.0, "unit": "mg", "upperLimit": 45.0 },
    "magnesium": { "amount": 420.0, "unit": "mg", "upperLimit": 350.0 },
    "phosphorus": { "amount": 700.0, "unit": "mg", "upperLimit": 4000.0 },
    "potassium": { "amount": 3400.0, "unit": "mg" },
    "sodium": { "amount": 1500.0, "unit": "mg", "upperLimit": 2300.0 },
    "zinc": { "amount": 11.0, "unit": "mg", "upperLimit": 40.0 },
    "copper": { "amount": 900.0, "unit": "mcg", "upperLimit": 10000.0 },
    "selenium": { "amount": 55.0, "unit": "mcg", "upperLimit": 400.0 },
    "iodine": { "amount": 150.0, "unit": "mcg", "upperLimit": 1100.0 }
  },
  "hydration": {
    "waterLiters": 2.8,
    "baselineLiters": 2.1,
    "activityLiters": 0.7,
    "unit": "L"
  },
  "calculationSummary": {
    "ageGroup": "%s",
    "ageYears": %d,
    "ageMonths": %d,
    "engineType": "AIEngine",
    "methodology": "AI Reasoning + DRI 2026 / Mifflin-St Jeor / Schofield",
    "appliedAdjustments": ["string"],
    "safetyNotes": ["string"]
  }
}`,
		NutritionAIVersion,
		input.DateOfBirth, years, months,
		stage, groupName,
		input.Gender,
		input.HeightCm,
		input.WeightKg,
		input.ActivityLevel,
		input.Goal,
		input.PregnancyStatus,
		input.BreastfeedingStatus,
		input.DietaryPattern,
		NutritionAIVersion,
		time.Now().UTC().Format(time.RFC3339),
		groupName, years, months,
	)
}

// ValidateAITargets performs strict deterministic clinical guardrail checks on AI-generated targets.
// If the AI output violates any physiological boundaries or safety rules, an error is returned.
func ValidateAITargets(input ProfileInput, targets DailyTargets) error {
	years, months := parseDOBAge(input.DateOfBirth)
	if years <= 0 {
		years = input.Age
	}

	if targets.Energy == nil || targets.Macros == nil || targets.Hydration == nil {
		return fmt.Errorf("targets are incomplete or nil")
	}

	// 1. Basic Positivity & Range Checks
	if targets.Energy.Calories < 800 || targets.Energy.Calories > 6000 {
		return fmt.Errorf("calories out of safe clinical bounds: %.1f kcal", targets.Energy.Calories)
	}
	if targets.Macros.Protein.Amount < 15 || targets.Macros.Protein.Amount > 350 {
		return fmt.Errorf("protein out of physiological bounds: %.1f g", targets.Macros.Protein.Amount)
	}
	if targets.Macros.Carbohydrates.Amount < 80 || targets.Macros.Carbohydrates.Amount > 800 {
		return fmt.Errorf("carbohydrates out of safe bounds: %.1f g", targets.Macros.Carbohydrates.Amount)
	}
	if targets.Macros.Fat.Amount < 15 || targets.Macros.Fat.Amount > 250 {
		return fmt.Errorf("fat out of physiological bounds: %.1f g", targets.Macros.Fat.Amount)
	}
	if targets.Hydration.WaterLiters < 0.5 || targets.Hydration.WaterLiters > 8.0 {
		return fmt.Errorf("hydration out of safe volume: %.1f L", targets.Hydration.WaterLiters)
	}

	// 2. Adult Metabolic Floor Check
	if years >= 18 {
		minSafe := 1200.0
		if input.Gender == "male" {
			minSafe = 1500.0
		}
		if targets.Energy.Calories < minSafe-10.0 { // 10 kcal tolerance
			return fmt.Errorf("adult calories (%.1f) below metabolic safety floor (%.0f kcal)", targets.Energy.Calories, minSafe)
		}
		if targets.Macros.Carbohydrates.Amount < 125.0 {
			return fmt.Errorf("adult carbohydrate target (%.1f g) below minimum cognitive RDA (130g)", targets.Macros.Carbohydrates.Amount)
		}
	}

	// 3. Pediatric Deficit Immunity Guardrail
	if years < 18 {
		minChildFloor := 1100.0
		if years >= 10 {
			minChildFloor = 1400.0
		}
		if years >= 14 {
			minChildFloor = 1700.0
		}
		if targets.Energy.Calories < minChildFloor-10.0 {
			return fmt.Errorf("pediatric calories (%.1f) below developmental growth floor (%.0f kcal)", targets.Energy.Calories, minChildFloor)
		}
	}

	// 4. Critical Micronutrients Existence
	requiredVits := []string{"vitaminA", "vitaminC", "vitaminD", "vitaminB12"}
	for _, v := range requiredVits {
		if val, ok := targets.Vitamins[v]; !ok || val.Amount <= 0 {
			return fmt.Errorf("missing required vitamin: %s", v)
		}
	}
	requiredMins := []string{"calcium", "iron", "zinc", "potassium", "sodium"}
	for _, m := range requiredMins {
		if val, ok := targets.Minerals[m]; !ok || val.Amount <= 0 {
			return fmt.Errorf("missing required mineral: %s", m)
		}
	}

	_ = months
	return nil
}

// CalculateHybridTargets calls the LLM with the clinical prompt, validates the output,
// and automatically falls back to the deterministic Go engine if anything fails or violates guardrails.
func CalculateHybridTargets(apiKey string, input ProfileInput) DailyTargets {
	// If no API key is provided, execute deterministic Go engine immediately
	if apiKey == "" {
		return CalculateTargets(input)
	}

	prompt := BuildNutritionPrompt(input)

	// Call LLM Provider (Groq llama-3.3-70b-versatile with JSON response format)
	client := &http.Client{Timeout: 20 * time.Second}
	body, _ := json.Marshal(map[string]any{
		"model":           "llama-3.3-70b-versatile",
		"temperature":     0.2, // Low temperature for deterministic calculation fidelity
		"max_tokens":      1500,
		"response_format": map[string]string{"type": "json_object"},
		"messages": []map[string]string{
			{"role": "system", "content": prompt},
			{"role": "user", "content": "Calculate daily targets for the provided profile according to the strict methodology."},
		},
	})

	req, err := http.NewRequest(http.MethodPost, "https://api.groq.com/openai/v1/chat/completions", bytes.NewReader(body))
	if err != nil {
		return CalculateTargets(input)
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		return CalculateTargets(input)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(io.LimitReader(resp.Body, 2<<20))
	if err != nil {
		return CalculateTargets(input)
	}

	var payload struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(respBytes, &payload); err != nil || len(payload.Choices) == 0 {
		return CalculateTargets(input)
	}

	// Parse JSON into DailyTargets
	var aiTargets DailyTargets
	if err := json.Unmarshal([]byte(payload.Choices[0].Message.Content), &aiTargets); err != nil {
		return CalculateTargets(input)
	}

	// Run Go Backend Guardrail Validation
	if err := ValidateAITargets(input, aiTargets); err != nil {
		// Validation failed! Fall back to deterministic calculation
		fallback := CalculateTargets(input)
		fallback.CalculationSummary.SafetyNotes = append(fallback.CalculationSummary.SafetyNotes,
			fmt.Sprintf("AI Target calculation failed validation (%v); deterministic fallback applied.", err))
		return fallback
	}

	// Ensure all standard DRI vitamins & minerals exist in map (merge if missing any keys)
	years, months := parseDOBAge(input.DateOfBirth)
	stage, _ := DetermineLifeStage(years, months, input.Gender)
	defaultVits := GetVitaminsReference(stage)
	for k, v := range defaultVits {
		if _, exists := aiTargets.Vitamins[k]; !exists {
			aiTargets.Vitamins[k] = v
		}
	}
	defaultMins := GetMineralsReference(stage)
	for k, v := range defaultMins {
		if _, exists := aiTargets.Minerals[k]; !exists {
			aiTargets.Minerals[k] = v
		}
	}

	// Round energy numbers
	aiTargets.Energy.Calories = math.Round(aiTargets.Energy.Calories)
	aiTargets.Energy.BMR = math.Round(aiTargets.Energy.BMR)
	aiTargets.Energy.TDEE = math.Round(aiTargets.Energy.TDEE)

	return aiTargets
}
