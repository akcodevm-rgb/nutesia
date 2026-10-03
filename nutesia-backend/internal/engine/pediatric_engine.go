package engine

import (
	"fmt"
	"math"
)

// CalculatePediatricTargets computes deterministic nutrition requirements for children & adolescents (age 2-17).
func CalculatePediatricTargets(input ProfileInput, years int, months int, stage LifeStage, groupName string) DailyTargets {
	targets := NewDailyTargets()

	// Strict Age Boundary Check
	if years < 2 {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "PEDIATRIC",
			Summary: "Calculation unsupported for children under 2 years of age.",
		}
		targets.Safety = SafetyGatingResult{
			Status:                 SafetyUnsupported,
			IsCalculationSupported: false,
			NoticeTitle:            "Infant Nutrition Guidance",
			NoticeMessage:          "Nuto supports children aged 2 years and older. Infant feeding requires specialized pediatric clinical guidance. Please consult your pediatrician.",
			ClinicalFlags:          []string{"AGE_UNDER_2_UNSUPPORTED"},
			MedicalDisclaimer:      MedicalDisclaimerText,
		}
		targets.CalculationSummary = CalculationSummary{
			AgeGroup:    groupName,
			AgeYears:    years,
			AgeMonths:   months,
			EngineType:  "PediatricEngine",
			Methodology: "Schofield (1985) Pediatric BMR + National Academies DRI Reference Intakes",
			SafetyNotes: []string{"Children under 2 years require specialized pediatric feeding oversight."},
		}
		return targets
	}

	// Reject pediatric calorie deficit goals
	if input.Goal == "weight_loss" || input.Goal == "lose" {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "PEDIATRIC",
			Summary: "Calorie deficits are not supported for individuals under 18 years of age.",
		}
		targets.Safety = SafetyGatingResult{
			Status:                 SafetyProfessionalReview,
			IsCalculationSupported: false,
			NoticeTitle:            "Pediatric Calorie Deficit Not Supported",
			NoticeMessage:          "Calorie deficits are not supported for individuals under 18 years of age. Pediatric growth and development require adequate energy and nutrient intake. Please consult a pediatrician or pediatric dietitian for weight management guidance.",
			ClinicalFlags:          []string{"PEDIATRIC_CALORIE_DEFICIT_PROHIBITED"},
			MedicalDisclaimer:      MedicalDisclaimerText,
		}
		targets.CalculationSummary = CalculationSummary{
			AgeGroup:    groupName,
			AgeYears:    years,
			AgeMonths:   months,
			EngineType:  "PediatricEngine",
			Methodology: "Schofield (1985) Pediatric BMR + National Academies DRI Reference Intakes",
			SafetyNotes: []string{"Intentional calorie restriction in growing children is clinically unsafe without direct pediatric supervision."},
		}
		return targets
	}

	safetyNotes := []string{}
	appliedAdjustments := []string{}
	appliedSafetyFloor := false

	w := input.WeightKg
	isMale := input.Gender == "male"

	// 1. Schofield Pediatric BMR Formula (1985)
	var bmr float64
	if years < 3 {
		if isMale {
			bmr = 60.9*w - 54.0
		} else {
			bmr = 61.0*w - 51.0
		}
		appliedAdjustments = append(appliedAdjustments, "BMR: Schofield Infant/Toddler (0-3y) formula")
	} else if years < 10 {
		if isMale {
			bmr = 22.7*w + 495.0
		} else {
			bmr = 22.5*w + 499.0
		}
		appliedAdjustments = append(appliedAdjustments, "BMR: Schofield Child (3-10y) formula")
	} else {
		if isMale {
			bmr = 17.5*w + 651.0
		} else {
			bmr = 12.2*w + 746.0
		}
		appliedAdjustments = append(appliedAdjustments, "BMR: Schofield Adolescent (10-18y) formula")
	}

	// 2. Pediatric Physical Activity Level (PAL) Multiplier
	var actMultiplier float64
	switch input.ActivityLevel {
	case "sedentary":
		actMultiplier = 1.25
		appliedAdjustments = append(appliedAdjustments, "Pediatric PAL: Sedentary (1.25x)")
	case "lightly_active", "light":
		actMultiplier = 1.40
		appliedAdjustments = append(appliedAdjustments, "Pediatric PAL: Lightly Active (1.40x)")
	case "moderately_active", "moderate":
		actMultiplier = 1.55
		appliedAdjustments = append(appliedAdjustments, "Pediatric PAL: Moderately Active (1.55x)")
	case "very_active", "active", "extremely_active", "extreme":
		actMultiplier = 1.75
		appliedAdjustments = append(appliedAdjustments, "Pediatric PAL: Very Active (1.75x)")
	default:
		actMultiplier = 1.40
		appliedAdjustments = append(appliedAdjustments, "Pediatric PAL: Default Lightly Active (1.40x)")
	}

	// 3. Growth Energy Allowance (DRI Growth Addition for Tissue Synthesis)
	growthAllowance := 30.0
	if years >= 10 && years < 14 {
		growthAllowance = 60.0
	} else if years >= 14 {
		growthAllowance = 100.0
	}
	appliedAdjustments = append(appliedAdjustments, fmt.Sprintf("DRI Growth Allowance: +%0.0f kcal/day for tissue synthesis", growthAllowance))

	tdee := (bmr * actMultiplier) + growthAllowance

	// 4. Safe Pediatric Goal Handling
	var targetCalories float64
	if input.Goal == "weight_gain" || input.Goal == "gain" {
		targetCalories = tdee + 250.0
		appliedAdjustments = append(appliedAdjustments, "Pediatric healthy growth surplus: +250 kcal/day")
	} else {
		targetCalories = tdee
		appliedAdjustments = append(appliedAdjustments, "Pediatric healthy growth baseline (TDEE + Growth Allowance)")
	}

	// Pediatric safe growth floors
	minChildFloor := 1100.0
	if years >= 10 && years < 14 {
		minChildFloor = 1400.0
	} else if years >= 14 {
		minChildFloor = 1700.0
	}

	if targetCalories < minChildFloor {
		targetCalories = minChildFloor
		appliedSafetyFloor = true
		safetyNotes = append(safetyNotes, fmt.Sprintf("Energy target adjusted to pediatric growth floor (%0.0f kcal).", minChildFloor))
	}

	targetCalories = math.Round(targetCalories)

	// 5. Pediatric Macro Distribution
	proteinPerKg := 1.2
	if years <= 3 {
		proteinPerKg = 1.1
	} else if years >= 14 {
		proteinPerKg = 1.4
	}

	proteinGrams := math.Round(w * proteinPerKg)
	if proteinGrams < 20 {
		proteinGrams = 20
	}

	fatRatio := 0.30
	if years <= 3 {
		fatRatio = 0.35
	}
	fatGrams := math.Round((targetCalories * fatRatio) / 9.0)

	proteinCalories := proteinGrams * 4.0
	fatCalories := fatGrams * 9.0
	carbsCalories := targetCalories - proteinCalories - fatCalories
	carbsGrams := math.Round(carbsCalories / 4.0)
	if carbsGrams < 100 {
		carbsGrams = 100
	}

	fiberTarget := GetFiberReference(years, input.Gender)

	// 6. Pediatric Hydration (Holliday-Segar Fluid Requirement Method)
	var baselineMl float64
	if w <= 10 {
		baselineMl = w * 100.0
	} else if w <= 20 {
		baselineMl = 1000.0 + ((w - 10.0) * 50.0)
	} else {
		baselineMl = 1500.0 + ((w - 20.0) * 20.0)
	}

	baselineLiters := math.Round((baselineMl/1000.0)*10) / 10.0
	activityBonus := 0.3
	if actMultiplier >= 1.55 {
		activityBonus = 0.5
	}

	// 7. Assemble Targets
	targets.Calculation = CalculationResult{
		Status:  CalcCalculated,
		Method:  "Schofield (1985) + DRI Growth Allowance",
		Track:   "PEDIATRIC",
		Summary: fmt.Sprintf("Calculated %0.0f kcal/day for %d-year-old child/adolescent.", targetCalories, years),
	}

	targets.Safety = SafetyGatingResult{
		Status:                 SafetySafe,
		IsCalculationSupported: true,
		AppliedSafetyFloor:     appliedSafetyFloor,
		MedicalDisclaimer:      MedicalDisclaimerText,
	}

	targets.Energy = &EnergyTarget{
		Calories: targetCalories,
		BMR:      math.Round(bmr),
		TDEE:     math.Round(tdee),
		Method:   "Schofield (1985)",
	}

	targets.Macros = &MacroTargets{
		Protein: NutrientAmount{
			Nutrient:    "protein",
			Amount:      proteinGrams,
			Unit:        "g",
			TargetType:  TargetTypeRDA,
			ReferenceID: "ref_dri_macros_micros",
		},
		Carbohydrates: NutrientAmount{
			Nutrient:    "carbohydrates",
			Amount:      carbsGrams,
			Unit:        "g",
			TargetType:  TargetTypeRDA,
			ReferenceID: "ref_dri_macros_micros",
		},
		Fat: NutrientAmount{
			Nutrient:    "fat",
			Amount:      fatGrams,
			Unit:        "g",
			TargetType:  TargetTypeAI,
			ReferenceID: "ref_dri_macros_micros",
		},
		Fiber: fiberTarget,
	}

	targets.Vitamins = GetVitaminsReference(stage)
	targets.Minerals = GetMineralsReference(stage)

	targets.Hydration = &HydrationTarget{
		WaterLiters:    math.Round((baselineLiters+activityBonus)*10) / 10.0,
		BaselineLiters: baselineLiters,
		ActivityLiters: activityBonus,
		Unit:           "L",
		Method:         "Holliday-Segar Fluid Reference",
	}

	targets.CalculationSummary = CalculationSummary{
		AgeGroup:           groupName,
		AgeYears:           years,
		AgeMonths:          months,
		EngineType:         "PediatricEngine",
		Methodology:        "Schofield (1985) Pediatric BMR + DRI Growth Allowance + National Academies DRI Reference Intakes",
		AppliedAdjustments: appliedAdjustments,
		SafetyNotes:        safetyNotes,
	}

	return targets
}

