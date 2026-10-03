package engine

import (
	"testing"
)

func TestBMIAssessment(t *testing.T) {
	// 1. Adult BMI Assessment
	adultAssessment := AssessBMI(175.0, 70.0, "1995-05-10", "male")
	if adultAssessment.Type != "ADULT" {
		t.Errorf("Expected ADULT assessment, got %s", adultAssessment.Type)
	}
	if adultAssessment.Category != "Normal" {
		t.Errorf("Expected Normal category, got %s", adultAssessment.Category)
	}
	if adultAssessment.Percentile != nil {
		t.Errorf("Expected nil percentile for adult")
	}

	// 2. Pediatric BMI Assessment (10-year-old boy: 138cm, 32kg -> BMI ~16.8, healthy weight)
	childAssessment := AssessBMI(138.0, 32.0, "2016-01-01", "male")
	if childAssessment.Type != "PEDIATRIC" {
		t.Errorf("Expected PEDIATRIC assessment, got %s", childAssessment.Type)
	}
	if childAssessment.Percentile == nil {
		t.Fatalf("Expected non-nil percentile for pediatric assessment")
	}
	if *childAssessment.Percentile < 10.0 || *childAssessment.Percentile > 90.0 {
		t.Errorf("Expected healthy percentile around 50th, got %f", *childAssessment.Percentile)
	}
	if childAssessment.Category != "Healthy Weight" {
		t.Errorf("Expected Healthy Weight, got %s", childAssessment.Category)
	}
}
