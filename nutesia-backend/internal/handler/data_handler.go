package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/engine"
	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

type DataHandler struct {
	repo repository.Repository
}

var (
	idPattern   = regexp.MustCompile(`^[A-Za-z0-9_-]{1,128}$`)
	datePattern = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)
)

func NewDataHandler(repo repository.Repository) *DataHandler {
	return &DataHandler{repo: repo}
}

// NutritionSpaceResponse bundles the space and its enriched member profiles.
type NutritionSpaceResponse struct {
	model.NutritionSpace
	Profiles []model.MemberEnrichedProfile `json:"profiles"`
}

// GetUserSpace loads the user's NutritionSpace along with its enriched member profiles.
func (h *DataHandler) GetUser(c *gin.Context) {
	spaceID := c.Param("deviceId")
	if !idPattern.MatchString(spaceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid space/deviceId"})
		return
	}

	space, members, err := h.loadOrCreateSpace(spaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load nutrition space"})
		return
	}

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// SaveUser saves or updates the NutritionSpace and the primary member profile.
func (h *DataHandler) SaveUser(c *gin.Context) {
	spaceID := c.Param("deviceId")
	if !idPattern.MatchString(spaceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid space/deviceId"})
		return
	}

	var raw map[string]any
	if err := c.ShouldBindJSON(&raw); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "A valid payload is required"})
		return
	}

	space, members, _ := h.loadOrCreateSpace(spaceID)

	// If payload contains profiles list, sync them
	if profsRaw, ok := raw["profiles"].([]any); ok && len(profsRaw) > 0 {
		newMembers := make([]model.Member, 0, len(profsRaw))
		for _, pRaw := range profsRaw {
			if pMap, ok := pRaw.(map[string]any); ok {
				var m model.Member
				b, _ := json.Marshal(pMap)
				_ = json.Unmarshal(b, &m)
				m.SpaceID = spaceID
				if m.ID == "" {
					m.ID = fmt.Sprintf("mem_%d", time.Now().UnixNano())
				}
				if m.CreatedAt == "" {
					m.CreatedAt = time.Now().UTC().Format(time.RFC3339)
				}
				m.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
				newMembers = append(newMembers, m)
			}
		}
		if len(newMembers) > 3 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Member limit exceeded. Maximum 3 members allowed per space."})
			return
		}
		members = newMembers
	} else {
		// Single profile payload sync for primary owner
		if len(members) > 0 {
			updateMemberFromMap(&members[0], raw)
			members[0].UpdatedAt = time.Now().UTC().Format(time.RFC3339)
		}
	}

	// Mode handling
	if modeStr, ok := raw["mode"].(string); ok && modeStr != "" {
		m := model.SpaceMode(strings.ToUpper(strings.TrimSpace(modeStr)))
		if m == model.ModeFamily || m == model.ModePersonal {
			space.Mode = m
		}
	}
	if len(members) > 1 {
		space.Mode = model.ModeFamily
	}

	if activeID, ok := raw["activeProfileId"].(string); ok && activeID != "" {
		space.ActiveMemberID = activeID
	}
	if space.ActiveMemberID == "" && len(members) > 0 {
		space.ActiveMemberID = members[0].ID
	}

	space.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	// Persist space and members
	_ = h.persistSpaceAndMembers(space, members)

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// UpdateSpaceMode explicitly updates the mode of the space (e.g. PERSONAL -> FAMILY).
func (h *DataHandler) UpdateSpaceMode(c *gin.Context) {
	spaceID := c.Param("deviceId")
	if !idPattern.MatchString(spaceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid space/deviceId"})
		return
	}

	var req struct {
		Mode string `json:"mode"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Mode is required in body"})
		return
	}

	mode := model.SpaceMode(strings.ToUpper(strings.TrimSpace(req.Mode)))
	if mode != model.ModePersonal && mode != model.ModeFamily {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Mode must be PERSONAL or FAMILY"})
		return
	}

	space, members, err := h.loadOrCreateSpace(spaceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nutrition space not found"})
		return
	}

	// Architectural Rule: Family -> Personal cannot be done automatically if multiple members exist
	if mode == model.ModePersonal && len(members) > 1 {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot revert to PERSONAL mode while multiple family members exist. Remove additional members first."})
		return
	}

	space.Mode = mode
	space.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
	_ = h.persistSpaceAndMembers(space, members)

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// AddMember adds a new profile to the space, auto-upgrading to FAMILY mode.
func (h *DataHandler) AddMember(c *gin.Context) {
	spaceID := c.Param("deviceId")
	if !idPattern.MatchString(spaceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid space/deviceId"})
		return
	}

	var newMember model.Member
	if err := c.ShouldBindJSON(&newMember); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid member payload"})
		return
	}

	space, members, err := h.loadOrCreateSpace(spaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load space"})
		return
	}

	// Rule: Maximum 3 member profiles per space
	if len(members) >= 3 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Member limit reached. Maximum 3 members allowed per nutrition space."})
		return
	}

	newMember.ID = fmt.Sprintf("mem_%d", time.Now().UnixNano())
	newMember.SpaceID = spaceID
	if newMember.Relationship == "" {
		newMember.Relationship = "family"
	}
	now := time.Now().UTC().Format(time.RFC3339)
	newMember.CreatedAt = now
	newMember.UpdatedAt = now

	members = append(members, newMember)
	// Adding member automatically transitions space mode to FAMILY
	space.Mode = model.ModeFamily
	space.UpdatedAt = now

	_ = h.persistSpaceAndMembers(space, members)

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// UpdateMember updates an existing member's inputs (DOB, height, weight, goals).
func (h *DataHandler) UpdateMember(c *gin.Context) {
	spaceID := c.Param("deviceId")
	memberID := c.Param("memberId")
	if !idPattern.MatchString(spaceID) || !idPattern.MatchString(memberID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid spaceId or memberId"})
		return
	}

	var updatePayload model.Member
	if err := c.ShouldBindJSON(&updatePayload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid update payload"})
		return
	}

	space, members, err := h.loadOrCreateSpace(spaceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nutrition space not found"})
		return
	}

	foundIdx := -1
	for i, m := range members {
		if m.ID == memberID {
			// Rule: Strict space isolation check
			if m.SpaceID != spaceID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: member does not belong to this space"})
				return
			}
			foundIdx = i
			break
		}
	}

	if foundIdx == -1 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Member not found"})
		return
	}

	// Apply updates
	target := &members[foundIdx]
	if updatePayload.Name != "" {
		target.Name = updatePayload.Name
	}
	if updatePayload.DateOfBirth != "" {
		target.DateOfBirth = updatePayload.DateOfBirth
	}
	if updatePayload.Gender != "" {
		target.Gender = updatePayload.Gender
	}
	if updatePayload.HeightCm > 0 {
		target.HeightCm = updatePayload.HeightCm
	}
	if updatePayload.WeightKg > 0 {
		target.WeightKg = updatePayload.WeightKg
	}
	if updatePayload.Goal != "" {
		target.Goal = updatePayload.Goal
	}
	if updatePayload.ActivityLevel != "" {
		target.ActivityLevel = updatePayload.ActivityLevel
	}
	if updatePayload.ProfileImage != "" {
		target.ProfileImage = updatePayload.ProfileImage
	}
	if updatePayload.Relationship != "" {
		target.Relationship = updatePayload.Relationship
	}
	target.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
	space.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	_ = h.persistSpaceAndMembers(space, members)

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// DeleteMember removes a member profile from the space (owner profile protected).
func (h *DataHandler) DeleteMember(c *gin.Context) {
	spaceID := c.Param("deviceId")
	memberID := c.Param("memberId")
	if !idPattern.MatchString(spaceID) || !idPattern.MatchString(memberID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid spaceId or memberId"})
		return
	}

	space, members, err := h.loadOrCreateSpace(spaceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nutrition space not found"})
		return
	}

	newMembers := make([]model.Member, 0, len(members))
	found := false
	for _, m := range members {
		if m.ID == memberID {
			if m.Relationship == "owner" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete primary owner profile"})
				return
			}
			found = true
			continue
		}
		newMembers = append(newMembers, m)
	}

	if !found {
		c.JSON(http.StatusNotFound, gin.H{"error": "Member not found"})
		return
	}

	members = newMembers
	if space.ActiveMemberID == memberID && len(members) > 0 {
		space.ActiveMemberID = members[0].ID
	}
	space.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	_ = h.persistSpaceAndMembers(space, members)

	enrichedProfiles := make([]model.MemberEnrichedProfile, 0, len(members))
	for _, m := range members {
		enrichedProfiles = append(enrichedProfiles, enrichMemberProfile(m))
	}

	c.JSON(http.StatusOK, NutritionSpaceResponse{
		NutritionSpace: space,
		Profiles:       enrichedProfiles,
	})
}

// SaveDay saves a daily nutrition log scoped to a space and member with point-in-time TargetSnapshot.
func (h *DataHandler) SaveDay(c *gin.Context) {
	spaceID := c.Param("deviceId")
	date := c.Param("date")
	memberID := c.Query("memberId")

	if !idPattern.MatchString(spaceID) || !datePattern.MatchString(date) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid spaceId or date"})
		return
	}

	var raw map[string]any
	if err := c.ShouldBindJSON(&raw); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Valid daily log payload required"})
		return
	}

	_, members, _ := h.loadOrCreateSpace(spaceID)
	var activeMember *model.Member
	if memberID != "" {
		for i := range members {
			if members[i].ID == memberID {
				activeMember = &members[i]
				break
			}
		}
	} else if len(members) > 0 {
		activeMember = &members[0]
		memberID = activeMember.ID
	}

	// Generate point-in-time TargetSnapshot
	var snapshot *model.TargetSnapshot
	if activeMember != nil && activeMember.HeightCm > 0 && activeMember.WeightKg > 0 {
		input := modelToProfileInput(*activeMember)
		dt := engine.CalculateTargets(input)
		if dt.Energy != nil && dt.Macros != nil && dt.Hydration != nil {
			snapshot = &model.TargetSnapshot{
				Calories:           dt.Energy.Calories,
				Protein:            dt.Macros.Protein.Amount,
				Carbs:              dt.Macros.Carbohydrates.Amount,
				Fat:                dt.Macros.Fat.Amount,
				Fiber:              dt.Macros.Fiber.Amount,
				HydrationLiters:    dt.Hydration.WaterLiters,
				CalculationVersion: "v3.0.0-DRI2026",
				CalculatedAt:       time.Now().UTC().Format(time.RFC3339),
			}
		}
	}

	raw["date"] = date
	raw["spaceId"] = spaceID
	if memberID != "" {
		raw["memberId"] = memberID
	}
	if snapshot != nil {
		raw["targetSnapshot"] = snapshot
	}

	key := date
	if memberID != "" {
		key = memberID + "__" + date
	}

	path := "days/" + spaceID
	if err := h.repo.Put(path, key, raw); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to save daily log"})
		return
	}

	c.JSON(http.StatusOK, raw)
}

// GetDay retrieves a daily log scoped to a space and member.
func (h *DataHandler) GetDay(c *gin.Context) {
	spaceID := c.Param("deviceId")
	date := c.Param("date")
	memberID := c.Query("memberId")

	if !idPattern.MatchString(spaceID) || !datePattern.MatchString(date) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid spaceId or date"})
		return
	}

	path := "days/" + spaceID
	key := date
	if memberID != "" {
		key = memberID + "__" + date
	}

	data, found, err := h.repo.Get(path, key)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load data"})
		return
	}
	if !found && memberID != "" {
		// Fallback for root date key
		data, found, _ = h.repo.Get(path, date)
	}

	if !found {
		c.Status(http.StatusNotFound)
		return
	}
	c.Data(http.StatusOK, "application/json", data)
}

// ListDays lists daily logs filtered by date range and memberId.
func (h *DataHandler) ListDays(c *gin.Context) {
	spaceID := c.Param("deviceId")
	memberID := c.Query("memberId")

	if !idPattern.MatchString(spaceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid spaceId"})
		return
	}

	items, err := h.repo.List("days/" + spaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to list logs"})
		return
	}

	start, end := c.Query("start"), c.Query("end")
	if (start != "" && !datePattern.MatchString(start)) || (end != "" && !datePattern.MatchString(end)) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dates must use YYYY-MM-DD"})
		return
	}

	logs := make([]map[string]any, 0, len(items))
	for _, item := range items {
		var day map[string]any
		if json.Unmarshal(item, &day) != nil {
			continue
		}
		date, _ := day["date"].(string)
		mID, _ := day["memberId"].(string)

		if memberID != "" {
			if mID != "" && mID != memberID {
				continue
			}
		}

		if (start == "" || date >= start) && (end == "" || date <= end) {
			logs = append(logs, day)
		}
	}

	sort.Slice(logs, func(i, j int) bool {
		d1, _ := logs[i]["date"].(string)
		d2, _ := logs[j]["date"].(string)
		return d1 < d2
	})

	c.JSON(http.StatusOK, logs)
}

// Internal Helpers

func (h *DataHandler) loadOrCreateSpace(spaceID string) (model.NutritionSpace, []model.Member, error) {
	data, found, err := h.repo.Get("users", spaceID)
	if err != nil {
		return model.NutritionSpace{}, nil, err
	}

	var raw map[string]any
	if found {
		_ = json.Unmarshal(data, &raw)
	} else {
		raw = make(map[string]any)
	}

	space := model.NewNutritionSpace(spaceID)
	if mStr, ok := raw["mode"].(string); ok && mStr != "" {
		space.Mode = model.SpaceMode(strings.ToUpper(mStr))
	}
	if activeID, ok := raw["activeProfileId"].(string); ok {
		space.ActiveMemberID = activeID
	}

	members := make([]model.Member, 0)
	if profsRaw, ok := raw["profiles"].([]any); ok && len(profsRaw) > 0 {
		for _, pRaw := range profsRaw {
			if pMap, ok := pRaw.(map[string]any); ok {
				var m model.Member
				b, _ := json.Marshal(pMap)
				_ = json.Unmarshal(b, &m)
				m.SpaceID = spaceID
				members = append(members, m)
			}
		}
	}

	// Legacy migration fallback
	if len(members) == 0 {
		primary := model.Member{
			ID:            "mem_primary",
			SpaceID:       spaceID,
			Name:          "",
			Relationship:  "owner",
			Age:           25,
			Gender:        "female",
			HeightCm:      0,
			WeightKg:      0,
			HeightUnit:    "cm",
			WeightUnit:    "kg",
			Goal:          "maintain_weight",
			ActivityLevel: "lightly_active",
			CreatedAt:     space.CreatedAt,
			UpdatedAt:     space.UpdatedAt,
		}
		updateMemberFromMap(&primary, raw)
		members = append(members, primary)
		space.ActiveMemberID = primary.ID
		_ = h.persistSpaceAndMembers(space, members)
	}

	if space.ActiveMemberID == "" && len(members) > 0 {
		space.ActiveMemberID = members[0].ID
	}

	return space, members, nil
}

func (h *DataHandler) persistSpaceAndMembers(space model.NutritionSpace, members []model.Member) error {
	payload := map[string]any{
		"id":              space.ID,
		"deviceId":        space.ID,
		"ownerUserId":     space.OwnerUserID,
		"mode":            space.Mode,
		"activeProfileId": space.ActiveMemberID,
		"maxMembers":      space.MaxMembers,
		"profiles":        members,
		"createdAt":       space.CreatedAt,
		"updatedAt":       space.UpdatedAt,
	}
	return h.repo.Put("users", space.ID, payload)
}

// Helper: enrichMemberProfile attaches dynamic BMI category and deterministic Daily Targets
func enrichMemberProfile(m model.Member) model.MemberEnrichedProfile {
	age := m.Age
	if m.DateOfBirth != "" {
		dobAge := calculateAge(m.DateOfBirth)
		if dobAge > 0 {
			age = dobAge
		}
	}

	enriched := model.MemberEnrichedProfile{
		Member:        m,
		Age:           age,
		ProfileStatus: "profile_complete",
	}

	// Dynamic BMI Assessment (CDC/WHO percentile for pediatric, adult categories for adults)
	bmiAssessment := engine.AssessBMIWithAge(m.HeightCm, m.WeightKg, age, m.DateOfBirth, m.Gender)
	enriched.BMIAssessment = bmiAssessment
	enriched.BMI = bmiAssessment.BMI
	enriched.BMICategory = bmiAssessment.Category

	if m.HeightCm <= 0 || m.WeightKg <= 0 || m.Name == "" || m.Name == "Primary Member" {
		enriched.ProfileStatus = "profile_incomplete"
		enriched.Calculation = map[string]any{
			"status":      "not_calculated",
			"safetyState": "insufficient_data",
		}
		return enriched
	}

	// Deterministic Daily Targets Calculation
	input := modelToProfileInput(m)
	dt := engine.CalculateTargets(input)
	if dt.CalculationSummary.AgeYears > 0 {
		enriched.Age = dt.CalculationSummary.AgeYears
	}

	if dt.Energy != nil && dt.Macros != nil && dt.Hydration != nil {
		enriched.DailyTargets = map[string]any{
			"calories":  dt.Energy.Calories,
			"protein":   dt.Macros.Protein.Amount,
			"carbs":     dt.Macros.Carbohydrates.Amount,
			"fat":       dt.Macros.Fat.Amount,
			"fiber":     dt.Macros.Fiber.Amount,
			"vitamins":  dt.Vitamins,
			"minerals":  dt.Minerals,
			"hydration": dt.Hydration,
		}
	}

	enriched.Calculation = map[string]any{
		"status":             dt.Calculation.Status,
		"method":             dt.Calculation.Method,
		"track":              dt.Calculation.Track,
		"summary":            dt.Calculation.Summary,
		"calculatedAt":       dt.GeneratedAt,
		"algorithmVersion":   dt.CalculationVersion,
		"referenceVersion":   dt.ReferenceVersion,
		"calculatedAge":      enriched.Age,
		"safety":             dt.Safety,
		"calculationSummary": dt.CalculationSummary,
	}

	return enriched
}

func modelToProfileInput(m model.Member) engine.ProfileInput {
	return engine.ProfileInput{
		Age:                 m.Age,
		DateOfBirth:         m.DateOfBirth,
		Gender:              m.Gender,
		HeightCm:            m.HeightCm,
		WeightKg:            m.WeightKg,
		ActivityLevel:       m.ActivityLevel,
		Goal:                m.Goal,
		PregnancyStatus:     m.PregnancyStatus,
		BreastfeedingStatus: m.BreastfeedingStatus,
		DietaryPattern:      m.DietaryPattern,
	}
}

func updateMemberFromMap(m *model.Member, raw map[string]any) {
	if n, ok := raw["name"].(string); ok && n != "" {
		m.Name = n
	}
	if a, ok := raw["age"]; ok {
		m.Age = int(toFloat(a))
	}
	if dob, ok := raw["dateOfBirth"].(string); ok && dob != "" {
		m.DateOfBirth = dob
	}
	if g, ok := raw["gender"].(string); ok && g != "" {
		m.Gender = g
	}
	if h, ok := raw["heightCm"]; ok {
		m.HeightCm = toFloat(h)
	}
	if w, ok := raw["weightKg"]; ok {
		m.WeightKg = toFloat(w)
	}
	if gl, ok := raw["goal"].(string); ok && gl != "" {
		m.Goal = gl
	}
	if al, ok := raw["activityLevel"].(string); ok && al != "" {
		m.ActivityLevel = al
	}
	if ps, ok := raw["pregnancyStatus"].(string); ok {
		m.PregnancyStatus = ps
	}
	if bs, ok := raw["breastfeedingStatus"].(string); ok {
		m.BreastfeedingStatus = bs
	}
	if dp, ok := raw["dietaryPattern"].(string); ok {
		m.DietaryPattern = dp
	}
}

func calculateAge(dobStr string) int {
	if dobStr == "" || !datePattern.MatchString(dobStr) {
		return 0
	}
	t, err := time.Parse("2006-01-02", dobStr)
	if err != nil {
		return 0
	}
	now := time.Now().UTC()
	years := now.Year() - t.Year()
	if now.YearDay() < t.YearDay() {
		years--
	}
	if years < 0 {
		return 0
	}
	return years
}

func toFloat(v any) float64 {
	switch val := v.(type) {
	case float64:
		return val
	case float32:
		return float64(val)
	case int:
		return float64(val)
	case int64:
		return float64(val)
	}
	return 0.0
}
