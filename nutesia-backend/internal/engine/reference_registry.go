package engine

// ReferenceMetadata describes authoritative scientific sources referenced by the Nuto engine.
type ReferenceMetadata struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Organization string `json:"organization"`
	Version      string `json:"version"`
	URL          string `json:"url,omitempty"`
	LastReviewed string `json:"lastReviewed"`
}

// Registry of documented calculation references and intake standards.
var ReferenceRegistry = map[string]ReferenceMetadata{
	"ref_energy_adult_mifflin": {
		ID:           "ref_energy_adult_mifflin",
		Name:         "Mifflin-St Jeor Predictive Energy Equation",
		Organization: "American Journal of Clinical Nutrition",
		Version:      "1990",
		URL:          "https://pubmed.ncbi.nlm.nih.gov/2305711/",
		LastReviewed: "2026-01-01",
	},
	"ref_energy_peds_schofield": {
		ID:           "ref_energy_peds_schofield",
		Name:         "Schofield Basal Metabolic Rate Equations",
		Organization: "Human Nutrition: Clinical Nutrition",
		Version:      "1985",
		URL:          "https://pubmed.ncbi.nlm.nih.gov/4044297/",
		LastReviewed: "2026-01-01",
	},
	"ref_dri_macros_micros": {
		ID:           "ref_dri_macros_micros",
		Name:         "Dietary Reference Intakes (DRI) Nutrient Recommendations",
		Organization: "National Academies of Sciences, Engineering, and Medicine",
		Version:      "DRI-2026-Edition",
		URL:          "https://www.nationalacademies.org/our-work/dietary-reference-intakes",
		LastReviewed: "2026-01-01",
	},
	"ref_who_fiber": {
		ID:           "ref_who_fiber",
		Name:         "WHO Dietary Carbohydrate and Fiber Guidance for Children and Adults",
		Organization: "World Health Organization",
		Version:      "2023",
		URL:          "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
		LastReviewed: "2026-01-01",
	},
	"ref_hydration_fluid": {
		ID:           "ref_hydration_fluid",
		Name:         "Holliday-Segar Fluid Estimation & Adult Daily Water References",
		Organization: "Pediatrics & Institute of Medicine",
		Version:      "Clinical-Fluid-Std",
		LastReviewed: "2026-01-01",
	},
}

// GetReference returns metadata for a given reference ID if registered.
func GetReference(id string) (ReferenceMetadata, bool) {
	ref, exists := ReferenceRegistry[id]
	return ref, exists
}
