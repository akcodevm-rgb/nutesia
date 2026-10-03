package engine

import (
	"strings"
	"time"
)

// CalculateTargets is the deterministic main entrypoint for the Nuto Nutrition Requirement Engine.
func CalculateTargets(input ProfileInput) DailyTargets {
	targets := NewDailyTargets()

	// 1. Sanitize & Normalize Inputs
	input.Gender = strings.ToLower(strings.TrimSpace(input.Gender))
	if input.Gender != "male" && input.Gender != "female" {
		input.Gender = "female"
	}
	input.ActivityLevel = strings.ToLower(strings.TrimSpace(input.ActivityLevel))
	if input.ActivityLevel == "" {
		input.ActivityLevel = "lightly_active"
	}
	input.Goal = strings.ToLower(strings.TrimSpace(input.Goal))
	if input.Goal == "" {
		input.Goal = "maintain_weight"
	}
	input.PregnancyStatus = strings.ToLower(strings.TrimSpace(input.PregnancyStatus))
	input.BreastfeedingStatus = strings.ToLower(strings.TrimSpace(input.BreastfeedingStatus))

	// 2. Compute Precise Age (Years & Months)
	years := input.Age
	months := 0
	if input.DateOfBirth != "" {
		y, m := parseDOBAge(input.DateOfBirth)
		if y > 0 || m > 0 {
			years = y
			months = m
		}
	}

	// Demographic Stage & Group Name
	stage, groupName := DetermineLifeStage(years, months, input.Gender)

	// 3. Safety Gate 1: Age Minimum (Age < 2 is Unsupported)
	if years < 2 {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "PEDIATRIC",
			Summary: "Calculation unsupported for infants and children under 2 years of age.",
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

	// 4. Safety Gate 2: Pregnancy (Explicitly Unsupported)
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

	// 5. Safety Gate 3: Lactation (Requires Professional Review)
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

	// 6. Safety Gate 4: Pediatric Calorie Deficit Prohibition
	if years < 18 && (input.Goal == "weight_loss" || input.Goal == "lose") {
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

	// 7. Safety Gate 5: Anthropometric Completeness
	if input.HeightCm <= 0 || input.WeightKg <= 0 {
		targets.Calculation = CalculationResult{
			Status:  CalcNotCalculated,
			Method:  "None",
			Track:   "NONE",
			Summary: "Valid height and weight are required for nutrition calculations.",
		}
		targets.Safety = SafetyGatingResult{
			Status:                 SafetyInvalidInput,
			IsCalculationSupported: false,
			NoticeTitle:            "Missing Body Measurements",
			NoticeMessage:          "Please enter a valid height and weight to generate personalized nutritional targets.",
			ClinicalFlags:          []string{"INVALID_ANTHROPOMETRICS"},
			MedicalDisclaimer:      MedicalDisclaimerText,
		}
		targets.CalculationSummary = CalculationSummary{
			AgeGroup:    groupName,
			AgeYears:    years,
			AgeMonths:   months,
			EngineType:  "None",
			SafetyNotes: []string{"Calculations require positive height and weight values."},
		}
		return targets
	}

	// 8. Route to Calculation Pipeline (Pediatric vs Adult)
	if years < 18 {
		return CalculatePediatricTargets(input, years, months, stage, groupName)
	}
	return CalculateAdultTargets(input, years, months, stage, groupName)
}

// parseDOBAge calculates age in years and remaining months from YYYY-MM-DD DOB string.
func parseDOBAge(dobStr string) (int, int) {
	if dobStr == "" {
		return 0, 0
	}
	dob, err := time.Parse("2006-01-02", strings.TrimSpace(dobStr))
	if err != nil {
		return 0, 0
	}

	now := time.Now().UTC()
	if dob.After(now) {
		return 0, 0
	}

	years := now.Year() - dob.Year()
	months := int(now.Month()) - int(dob.Month())

	if now.Day() < dob.Day() {
		months--
	}
	if months < 0 {
		years--
		months += 12
	}

	if years < 0 {
		years = 0
	}
	if months < 0 {
		months = 0
	}

	return years, months
}


