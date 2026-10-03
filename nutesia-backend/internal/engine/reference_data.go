package engine

// LifeStage represents DRI demographic classifications.
type LifeStage string

const (
	StageUnsupportedInfant LifeStage = "UNSUPPORTED_INFANT"
	StageToddler2To3y      LifeStage = "TODDLER_2_3Y"
	StageChild4To8y        LifeStage = "CHILD_4_8Y"
	StageChild9To13yM      LifeStage = "CHILD_9_13Y_M"
	StageChild9To13yF      LifeStage = "CHILD_9_13Y_F"
	StageAdol14To18yM      LifeStage = "ADOL_14_18Y_M"
	StageAdol14To18yF      LifeStage = "ADOL_14_18Y_F"
	StageAdult19To30yM     LifeStage = "ADULT_19_30Y_M"
	StageAdult19To30yF     LifeStage = "ADULT_19_30Y_F"
	StageAdult31To50yM     LifeStage = "ADULT_31_50Y_M"
	StageAdult31To50yF     LifeStage = "ADULT_31_50Y_F"
	StageAdult51To70yM     LifeStage = "ADULT_51_70Y_M"
	StageAdult51To70yF     LifeStage = "ADULT_51_70Y_F"
	StageOlder71yM         LifeStage = "OLDER_71Y_M"
	StageOlder71yF         LifeStage = "OLDER_71Y_F"
)

// DetermineLifeStage resolves exact DRI life stage given age in years, months, and sex.
func DetermineLifeStage(years int, months int, gender string) (LifeStage, string) {
	isMale := gender == "male"

	if years < 2 {
		return StageUnsupportedInfant, "INFANT"
	}
	if years <= 3 {
		return StageToddler2To3y, "TODDLER"
	}
	if years <= 8 {
		return StageChild4To8y, "CHILD"
	}
	if years <= 13 {
		if isMale {
			return StageChild9To13yM, "CHILD"
		}
		return StageChild9To13yF, "CHILD"
	}
	if years < 18 {
		if isMale {
			return StageAdol14To18yM, "ADOLESCENT"
		}
		return StageAdol14To18yF, "ADOLESCENT"
	}
	if years <= 30 {
		if isMale {
			return StageAdult19To30yM, "ADULT"
		}
		return StageAdult19To30yF, "ADULT"
	}
	if years <= 50 {
		if isMale {
			return StageAdult31To50yM, "ADULT"
		}
		return StageAdult31To50yF, "ADULT"
	}
	if years <= 70 {
		if isMale {
			return StageAdult51To70yM, "ADULT"
		}
		return StageAdult51To70yF, "ADULT"
	}
	if isMale {
		return StageOlder71yM, "OLDER_ADULT"
	}
	return StageOlder71yF, "OLDER_ADULT"
}

// GetFiberReference returns the recommended dietary fiber target according to WHO and DRI guidelines.
func GetFiberReference(years int, gender string) NutrientAmount {
	if years < 2 {
		return NutrientAmount{
			Nutrient:    "fiber",
			Amount:      0,
			Unit:        "g",
			TargetType:  TargetTypeAI,
			ReferenceID: "ref_who_fiber",
		}
	}
	if years < 18 {
		// WHO / DRI pediatric rule: Age + 5g (minimum 14g)
		fiber := float64(years) + 5.0
		if fiber < 14.0 {
			fiber = 14.0
		}
		return NutrientAmount{
			Nutrient:    "fiber",
			Amount:      fiber,
			Unit:        "g",
			TargetType:  TargetTypeAI,
			ReferenceID: "ref_who_fiber",
		}
	}
	// Adult standards
	isMale := gender == "male"
	if years >= 51 {
		if isMale {
			return NutrientAmount{
				Nutrient:    "fiber",
				Amount:      30.0,
				Unit:        "g",
				TargetType:  TargetTypeAI,
				ReferenceID: "ref_who_fiber",
			}
		}
		return NutrientAmount{
			Nutrient:    "fiber",
			Amount:      21.0,
			Unit:        "g",
			TargetType:  TargetTypeAI,
			ReferenceID: "ref_who_fiber",
		}
	}
	if isMale {
		return NutrientAmount{
			Nutrient:    "fiber",
			Amount:      34.0,
			Unit:        "g",
			TargetType:  TargetTypeAI,
			ReferenceID: "ref_who_fiber",
		}
	}
	return NutrientAmount{
		Nutrient:    "fiber",
		Amount:      28.0,
		Unit:        "g",
		TargetType:  TargetTypeAI,
		ReferenceID: "ref_who_fiber",
	}
}

// GetVitaminsReference returns the DRI vitamin targets for a given life stage.
func GetVitaminsReference(stage LifeStage) map[string]NutrientAmount {
	refID := "ref_dri_macros_micros"
	switch stage {
	case StageToddler2To3y:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 300, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 600, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 63, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 6, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 200, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 0.5, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 0.5, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 6, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 10, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 2.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 0.5, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 30, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 8, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 300, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 0.9, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageChild4To8y:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 900, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 25, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 650, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 75, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 7, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 300, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 55, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 0.6, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 0.6, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 8, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 15, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 3.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 0.6, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 12, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 200, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 1.2, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageChild9To13yM, StageChild9To13yF:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 600, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1700, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 45, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1200, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 11, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 600, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 60, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 0.9, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 0.9, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 12, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 20, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 4.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 60, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 20, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 300, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 600, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 1.8, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageAdol14To18yM:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 2800, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 75, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1800, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 800, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 75, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.2, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.3, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 16, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 30, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.3, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 80, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 25, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 800, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageAdol14To18yF:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 700, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 2800, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 65, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1800, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 800, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 75, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.0, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.0, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 14, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 30, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.2, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 80, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 25, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 800, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageAdult19To30yF, StageAdult31To50yF:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 700, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 75, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 90, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 14, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 35, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.3, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageAdult51To70yF:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 700, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 75, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 90, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 14, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 35, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.5, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageOlder71yF:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 700, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 75, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 20, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 90, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.1, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 14, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 35, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.5, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	case StageOlder71yM:
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 90, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 20, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 120, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.2, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.3, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 16, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 35, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.7, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	default: // Adult Male defaults (19-70y M)
		return map[string]NutrientAmount{
			"vitaminA":   {Nutrient: "vitaminA", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"vitaminC":   {Nutrient: "vitaminC", Amount: 90, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"vitaminD":   {Nutrient: "vitaminD", Amount: 15, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminE":   {Nutrient: "vitaminE", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminK":   {Nutrient: "vitaminK", Amount: 120, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB1":  {Nutrient: "vitaminB1", Amount: 1.2, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB2":  {Nutrient: "vitaminB2", Amount: 1.3, Unit: "mg", TargetType: TargetTypeRDA, ReferenceID: refID},
			"vitaminB3":  {Nutrient: "vitaminB3", Amount: 16, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 35, ReferenceID: refID},
			"vitaminB5":  {Nutrient: "vitaminB5", Amount: 5.0, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB6":  {Nutrient: "vitaminB6", Amount: 1.7, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 100, ReferenceID: refID},
			"vitaminB7":  {Nutrient: "vitaminB7", Amount: 30, Unit: "mcg", TargetType: TargetTypeAI, ReferenceID: refID},
			"vitaminB9":  {Nutrient: "vitaminB9", Amount: 400, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"vitaminB12": {Nutrient: "vitaminB12", Amount: 2.4, Unit: "mcg", TargetType: TargetTypeRDA, ReferenceID: refID},
		}
	}
}

// GetMineralsReference returns the DRI mineral targets for a given life stage.
func GetMineralsReference(stage LifeStage) map[string]NutrientAmount {
	refID := "ref_dri_macros_micros"
	switch stage {
	case StageToddler2To3y:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 700, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2500, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 7, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 80, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 65, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 460, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2000, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 800, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 1200, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 3.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 7, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 340, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 20, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 90, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 90, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 200, ReferenceID: refID},
		}
	case StageChild4To8y:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1000, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2500, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 10, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 130, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 110, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 500, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2300, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1000, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 1500, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 5.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 12, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 440, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 30, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 150, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 90, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 300, ReferenceID: refID},
		}
	case StageChild9To13yM, StageChild9To13yF:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1300, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 8, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 240, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 1250, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2500, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1200, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 1800, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 8.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 23, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 700, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 5000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 40, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 280, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 120, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 600, ReferenceID: refID},
		}
	case StageAdol14To18yM:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1300, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 11, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 410, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 1250, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 3000, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 11.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 34, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 890, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 8000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 900, ReferenceID: refID},
		}
	case StageAdol14To18yF:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1300, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 3000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 15, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 360, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 1250, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2300, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 9.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 34, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 890, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 8000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 900, ReferenceID: refID},
		}
	case StageAdult19To30yF, StageAdult31To50yF:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1000, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2500, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 18, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 320, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 700, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2600, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 8.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 10000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1100, ReferenceID: refID},
		}
	case StageAdult51To70yF, StageOlder71yF:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1200, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 8, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 320, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 700, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 2600, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 8.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 10000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1100, ReferenceID: refID},
		}
	case StageOlder71yM:
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1200, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 8, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 420, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 700, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 3400, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 11.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 10000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1100, ReferenceID: refID},
		}
	default: // Adult Male defaults (19-70y M)
		return map[string]NutrientAmount{
			"calcium":    {Nutrient: "calcium", Amount: 1000, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 2000, ReferenceID: refID},
			"iron":       {Nutrient: "iron", Amount: 8, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 45, ReferenceID: refID},
			"magnesium":  {Nutrient: "magnesium", Amount: 420, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 350, ReferenceID: refID},
			"phosphorus": {Nutrient: "phosphorus", Amount: 700, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 4000, ReferenceID: refID},
			"potassium":  {Nutrient: "potassium", Amount: 3400, Unit: "mg", TargetType: TargetTypeAI, ReferenceID: refID},
			"sodium":     {Nutrient: "sodium", Amount: 1500, Unit: "mg", TargetType: TargetTypeAI, UpperLimit: 2300, ReferenceID: refID},
			"zinc":       {Nutrient: "zinc", Amount: 11.0, Unit: "mg", TargetType: TargetTypeRDA, UpperLimit: 40, ReferenceID: refID},
			"copper":     {Nutrient: "copper", Amount: 900, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 10000, ReferenceID: refID},
			"selenium":   {Nutrient: "selenium", Amount: 55, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 400, ReferenceID: refID},
			"iodine":     {Nutrient: "iodine", Amount: 150, Unit: "mcg", TargetType: TargetTypeRDA, UpperLimit: 1100, ReferenceID: refID},
		}
	}
}
