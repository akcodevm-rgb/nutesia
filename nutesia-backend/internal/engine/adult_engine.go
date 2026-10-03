package engine

import (
	"fmt"
	"math"
)

// CalculateAdultTargets computes deterministic nutrition requirements for adult users (age >= 18).
func CalculateAdultTargets(input ProfileInput, years int, months int, stage LifeStage, groupName string) DailyTargets {
	targets := NewDailyTargets()

	// Safety Check: Pregnancy is explicitly unsupported
	if input.PregnancyStatus != "" && input.PregnancyStatus != "none" {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "ADULT",
			Summary: "Personalized nutrition calculations are not supported during pregnancy.",
		}
		targets.Safety = SafetyGatingResult{
			Status:                 SafetyUnsupported,
			IsCalculationSupported: false,
			NoticeTitle:            "Pregnancy Nutrition Notice",
			NoticeMessage:          "Nuto does not calculate personalized nutrition targets during pregnancy. Nutritional needs change dynamically across trimesters. Please consult an obstetrician or registered dietitian for clinical dietary counseling.",
			ClinicalFlags:          []string{"PREGNANCY_UNSUPPORTED"},
			MedicalDisclaimer:      MedicalDisclaimerText,
		}
		targets.CalculationSummary = CalculationSummary{
			AgeGroup:    groupName,
			AgeYears:    years,
			AgeMonths:   months,
			EngineType:  "AdultEngine",
			Methodology: "Mifflin-St Jeor (1990) Adult BMR + National Academies DRI Reference Intakes",
			SafetyNotes: []string{"Pregnancy-specific targets require individualized clinical obstetric care."},
		}
		return targets
	}

	// Safety Check: Breastfeeding requires professional review
	if input.BreastfeedingStatus != "" && input.BreastfeedingStatus != "none" {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "ADULT",
			Summary: "Lactation requires individualized nutrient and fluid assessment.",
		}
		targets.Safety = SafetyGatingResult{
			Status:                 SafetyProfessionalReview,
			IsCalculationSupported: false,
			NoticeTitle:            "Lactation Review Notice",
			NoticeMessage:          "Lactation requires individualized nutrient and fluid assessment. Please review targets with a healthcare provider.",
			ClinicalFlags:          []string{"LACTATION_REQUIRES_PROFESSIONAL_REVIEW"},
			MedicalDisclaimer:      MedicalDisclaimerText,
		}
		targets.CalculationSummary = CalculationSummary{
			AgeGroup:    groupName,
			AgeYears:    years,
			AgeMonths:   months,
			EngineType:  "AdultEngine",
			Methodology: "Mifflin-St Jeor (1990) Adult BMR + National Academies DRI Reference Intakes",
			SafetyNotes: []string{"Lactation energy and fluid demands vary with feeding frequency and require clinical review."},
		}
		return targets
	}

	safetyNotes := []string{}
	appliedAdjustments := []string{}
	appliedSafetyFloor := false

	// 1. Basal Metabolic Rate (BMR) - Mifflin-St Jeor Equation (1990)
	var bmr float64
	if input.Gender == "male" {
		bmr = (10.0 * input.WeightKg) + (6.25 * input.HeightCm) - (5.0 * float64(years)) + 5.0
	} else {
		bmr = (10.0 * input.WeightKg) + (6.25 * input.HeightCm) - (5.0 * float64(years)) - 161.0
	}

	// 2. Physical Activity Level (PAL) Multiplier
	var actMultiplier float64
	switch input.ActivityLevel {
	case "sedentary":
		actMultiplier = 1.20
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Sedentary (1.20x)")
	case "lightly_active", "light":
		actMultiplier = 1.375
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Lightly Active (1.375x)")
	case "moderately_active", "moderate":
		actMultiplier = 1.55
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Moderately Active (1.55x)")
	case "very_active", "active":
		actMultiplier = 1.725
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Very Active (1.725x)")
	case "extremely_active", "extreme":
		actMultiplier = 1.90
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Extremely Active (1.90x)")
	default:
		actMultiplier = 1.375
		appliedAdjustments = append(appliedAdjustments, "Physical Activity Level: Default Lightly Active (1.375x)")
	}

	tdee := bmr * actMultiplier

	// 3. Goal Adjustment
	var targetCalories float64
	switch input.Goal {
	case "weight_loss", "lose":
		targetCalories = tdee - 500.0
		appliedAdjustments = append(appliedAdjustments, "Goal: Weight loss deficit (-500 kcal/day)")
	case "weight_gain", "gain":
		targetCalories = tdee + 400.0
		appliedAdjustments = append(appliedAdjustments, "Goal: Weight gain surplus (+400 kcal/day)")
	case "muscle_gain":
		targetCalories = tdee + 300.0
		appliedAdjustments = append(appliedAdjustments, "Goal: Muscle gain surplus (+300 kcal/day)")
	default: // maintain_weight, healthy_growth
		targetCalories = tdee
		appliedAdjustments = append(appliedAdjustments, "Goal: Maintenance (TDEE baseline)")
	}

	// 4. Nuto Adult Application Safety Floors (1500 kcal male / 1200 kcal female)
	minSafe := 1200.0
	if input.Gender == "male" {
		minSafe = 1500.0
	}
	if targetCalories < minSafe {
		targetCalories = minSafe
		appliedSafetyFloor = true
		safetyNotes = append(safetyNotes, fmt.Sprintf("Energy target adjusted to Nuto Adult Application Safety Floor (%0.0f kcal) to prevent metabolic slowing and nutrient deficiency.", minSafe))
	}

	targetCalories = math.Round(targetCalories)

	// 5. Macro Calculation
	// Protein: 1.4 g/kg baseline up to 2.0 g/kg (muscle gain / very active)
	proteinPerKg := 1.4
	if input.Goal == "muscle_gain" || input.ActivityLevel == "very_active" || input.ActivityLevel == "extremely_active" {
		proteinPerKg = 2.0
	} else if input.ActivityLevel == "moderately_active" {
		proteinPerKg = 1.6
	}

	proteinGrams := math.Round(input.WeightKg * proteinPerKg)
	if proteinGrams < 50 {
		proteinGrams = 50
	}

	// Fat: 28% of total calories (9 kcal/g)
	fatRatio := 0.28
	fatGrams := math.Round((targetCalories * fatRatio) / 9.0)

	// Carbs: Remainder of calories (4 kcal/g)
	proteinCalories := proteinGrams * 4.0
	fatCalories := fatGrams * 9.0
	carbsCalories := targetCalories - proteinCalories - fatCalories
	carbsGrams := math.Round(carbsCalories / 4.0)
	if carbsGrams < 130 { // Minimum RDA for brain glucose utilization
		carbsGrams = 130
		safetyNotes = append(safetyNotes, "Carbohydrates set to DRI minimum recommended 130g/day for cognitive glucose needs.")
	}

	// Fiber: DRI / WHO standard
	fiberTarget := GetFiberReference(years, input.Gender)

	// 6. Hydration Calculation (Adult 35ml/kg Standard + PAL Bonus)
	baselineWater := math.Round((input.WeightKg*0.035)*10) / 10.0 // 35 ml/kg
	activityBonus := 0.4
	if actMultiplier >= 1.725 {
		activityBonus = 1.0
	} else if actMultiplier >= 1.55 {
		activityBonus = 0.7
	}

	safetyStatus := SafetySafe
	if appliedSafetyFloor {
		safetyStatus = SafetyWarning
	}

	// 7. Assemble Targets
	targets.Calculation = CalculationResult{
		Status:  CalcCalculated,
		Method:  "Mifflin-St Jeor (1990) + DRI Reference Intakes",
		Track:   "ADULT",
		Summary: fmt.Sprintf("Calculated %0.0f kcal/day for %d-year-old adult.", targetCalories, years),
	}

	targets.Safety = SafetyGatingResult{
		Status:                 safetyStatus,
		IsCalculationSupported: true,
		AppliedSafetyFloor:     appliedSafetyFloor,
		MedicalDisclaimer:      MedicalDisclaimerText,
	}

	targets.Energy = &EnergyTarget{
		Calories: targetCalories,
		BMR:      math.Round(bmr),
		TDEE:     math.Round(tdee),
		Method:   "Mifflin-St Jeor (1990)",
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
		WaterLiters:    math.Round((baselineWater+activityBonus)*10) / 10.0,
		BaselineLiters: baselineWater,
		ActivityLiters: activityBonus,
		Unit:           "L",
		Method:         "Adult 35ml/kg Standard + PAL Hydration Adjustment",
	}

	targets.CalculationSummary = CalculationSummary{
		AgeGroup:           groupName,
		AgeYears:           years,
		AgeMonths:          months,
		EngineType:         "AdultEngine",
		Methodology:        "Mifflin-St Jeor (1990) Adult BMR + National Academies DRI Reference Intakes",
		AppliedAdjustments: appliedAdjustments,
		SafetyNotes:        safetyNotes,
	}

	return targets
}

