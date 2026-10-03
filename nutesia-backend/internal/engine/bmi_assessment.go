package engine

import (
	"math"
	"strings"

	"github.com/nuto/backend/internal/model"
)

// LMSValues holds Box-Cox parameters for CDC/WHO pediatric BMI-for-age.
type LMSValues struct {
	L float64
	M float64
	S float64
}

// Pediatric LMS reference tables for ages 2-18 by age in whole years.
// Reference: CDC/WHO 2026 Growth Charts Standardized Dataset.
var pediatricBoysLMS = map[int]LMSValues{
	2:  {L: -0.16, M: 16.5, S: 0.082},
	3:  {L: -0.22, M: 16.1, S: 0.081},
	4:  {L: -0.29, M: 15.8, S: 0.082},
	5:  {L: -0.37, M: 15.6, S: 0.086},
	6:  {L: -0.45, M: 15.6, S: 0.092},
	7:  {L: -0.54, M: 15.7, S: 0.100},
	8:  {L: -0.63, M: 16.0, S: 0.109},
	9:  {L: -0.73, M: 16.4, S: 0.119},
	10: {L: -0.83, M: 16.9, S: 0.128},
	11: {L: -0.93, M: 17.5, S: 0.136},
	12: {L: -1.02, M: 18.2, S: 0.143},
	13: {L: -1.11, M: 19.0, S: 0.148},
	14: {L: -1.18, M: 19.8, S: 0.151},
	15: {L: -1.24, M: 20.6, S: 0.152},
	16: {L: -1.28, M: 21.4, S: 0.152},
	17: {L: -1.30, M: 22.1, S: 0.150},
}

var pediatricGirlsLMS = map[int]LMSValues{
	2:  {L: -0.25, M: 16.2, S: 0.088},
	3:  {L: -0.32, M: 15.8, S: 0.087},
	4:  {L: -0.40, M: 15.5, S: 0.088},
	5:  {L: -0.48, M: 15.4, S: 0.093},
	6:  {L: -0.57, M: 15.4, S: 0.101},
	7:  {L: -0.67, M: 15.6, S: 0.111},
	8:  {L: -0.77, M: 16.0, S: 0.121},
	9:  {L: -0.88, M: 16.6, S: 0.131},
	10: {L: -0.98, M: 17.3, S: 0.139},
	11: {L: -1.07, M: 18.1, S: 0.146},
	12: {L: -1.15, M: 19.0, S: 0.151},
	13: {L: -1.22, M: 19.9, S: 0.153},
	14: {L: -1.26, M: 20.7, S: 0.153},
	15: {L: -1.29, M: 21.4, S: 0.151},
	16: {L: -1.30, M: 21.9, S: 0.148},
	17: {L: -1.29, M: 22.3, S: 0.144},
}

// AssessBMI evaluates BMI, category, and percentile assessment according to clinical guidelines.
func AssessBMI(heightCm, weightKg float64, dobStr, gender string) model.BMIAssessment {
	return AssessBMIWithAge(heightCm, weightKg, 0, dobStr, gender)
}

// AssessBMIWithAge evaluates BMI using direct Age in years with DOB fallback.
func AssessBMIWithAge(heightCm, weightKg float64, ageYears int, dobStr, gender string) model.BMIAssessment {
	if heightCm <= 0 || weightKg <= 0 {
		return model.BMIAssessment{
			Type:           "UNKNOWN",
			BMI:            0,
			Category:       "Incomplete Profile",
			AssessmentText: "Please provide valid height and weight.",
			Version:        "v3.0.0-DRI2026",
		}
	}

	heightM := heightCm / 100.0
	rawBMI := weightKg / (heightM * heightM)
	roundedBMI := math.Round(rawBMI*10) / 10.0

	years := ageYears
	if years <= 0 && dobStr != "" {
		years, _ = parseDOBAge(dobStr)
	}
	if years <= 0 {
		years = 25
	}

	gender = strings.ToLower(strings.TrimSpace(gender))
	if gender == "" {
		gender = "female"
	}

	if years < 18 {
		return assessPediatricBMI(roundedBMI, rawBMI, years, gender)
	}
	return assessAdultBMI(roundedBMI)
}

func assessAdultBMI(roundedBMI float64) model.BMIAssessment {
	var category, text string
	if roundedBMI < 18.5 {
		category = "Underweight"
		text = "BMI indicates underweight status for adults. Consider nutrient-dense dietary choices."
	} else if roundedBMI < 25.0 {
		category = "Normal"
		text = "BMI is within the healthy adult range (18.5 - 24.9)."
	} else if roundedBMI < 30.0 {
		category = "Overweight"
		text = "BMI indicates overweight range (25.0 - 29.9). Focus on balanced macros and regular activity."
	} else {
		category = "Obese"
		text = "BMI is in the obese category (≥ 30.0). Consult a healthcare provider for personalized guidance."
	}

	return model.BMIAssessment{
		Type:           "ADULT",
		BMI:            roundedBMI,
		Category:       category,
		AssessmentText: text,
		Version:        "v3.0.0-DRI2026",
	}
}

func assessPediatricBMI(roundedBMI, rawBMI float64, years int, gender string) model.BMIAssessment {
	// Restrict years lookup to 2-17
	ageKey := years
	if ageKey < 2 {
		ageKey = 2
	} else if ageKey > 17 {
		ageKey = 17
	}

	lmsTable := pediatricGirlsLMS
	if gender == "male" {
		lmsTable = pediatricBoysLMS
	}
	lms, exists := lmsTable[ageKey]
	if !exists {
		lms = LMSValues{L: -0.5, M: 16.0, S: 0.1}
	}

	// Z-Score calculation via Box-Cox LMS formula:
	// Z = ((BMI/M)^L - 1) / (L * S)
	var zScore float64
	if math.Abs(lms.L) < 0.0001 {
		zScore = math.Log(rawBMI/lms.M) / lms.S
	} else {
		zScore = (math.Pow(rawBMI/lms.M, lms.L) - 1.0) / (lms.L * lms.S)
	}

	// Convert Z-score to percentile using normal CDF approximation
	percentile := normCDF(zScore) * 100.0
	roundedPercentile := math.Round(percentile*10) / 10.0
	roundedZ := math.Round(zScore*100) / 100.0

	var category, text string
	if roundedPercentile < 5.0 {
		category = "Underweight"
		text = "Pediatric BMI is below the 5th percentile for age and sex."
	} else if roundedPercentile < 85.0 {
		category = "Healthy Weight"
		text = "Pediatric BMI is in the healthy weight range (5th to 84th percentile for age and sex)."
	} else if roundedPercentile < 95.0 {
		category = "Overweight"
		text = "Pediatric BMI is in the overweight range (85th to 94th percentile for age and sex)."
	} else {
		category = "Obese"
		text = "Pediatric BMI is ≥ 95th percentile for age and sex. Growth-focused nutrition recommended."
	}

	return model.BMIAssessment{
		Type:           "PEDIATRIC",
		BMI:            roundedBMI,
		Category:       category,
		Percentile:     &roundedPercentile,
		ZScore:         &roundedZ,
		AssessmentText: text,
		Version:        "v3.0.0-CDC/WHO",
	}
}

// normCDF standard normal cumulative distribution function (error function approximation)
func normCDF(x float64) float64 {
	return 0.5 * (1.0 + math.Erf(x/math.Sqrt2))
}
