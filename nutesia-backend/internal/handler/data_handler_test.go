package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
)

func setupTestRouter(t *testing.T) (*gin.Engine, *DataHandler) {
	gin.SetMode(gin.TestMode)
	tmpDir := t.TempDir()
	repo, err := repository.NewFileRepository(tmpDir)
	if err != nil {
		t.Fatalf("failed to create repo: %v", err)
	}

	h := NewDataHandler(repo)
	r := gin.New()
	v1 := r.Group("/api/v1")
	v1.GET("/users/:deviceId", h.GetUser)
	v1.PUT("/users/:deviceId", h.SaveUser)
	v1.PATCH("/users/:deviceId/mode", h.UpdateSpaceMode)
	v1.POST("/users/:deviceId/members", h.AddMember)
	v1.PUT("/users/:deviceId/members/:memberId", h.UpdateMember)
	v1.DELETE("/users/:deviceId/members/:memberId", h.DeleteMember)
	v1.GET("/users/:deviceId/days", h.ListDays)
	v1.PUT("/users/:deviceId/days/:date", h.SaveDay)

	return r, h
}

func TestUnifiedNutritionSpaceAndMemberLimit(t *testing.T) {
	r, _ := setupTestRouter(t)
	deviceID := "test-family-device-101"

	// 1. GET User space (should auto-create primary owner profile in PERSONAL mode)
	req := httptest.NewRequest("GET", "/api/v1/users/"+deviceID, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for GetUser, got %d", w.Code)
	}

	var spaceResp NutritionSpaceResponse
	_ = json.Unmarshal(w.Body.Bytes(), &spaceResp)

	if len(spaceResp.Profiles) != 1 {
		t.Errorf("Expected 1 initial primary profile, got %d", len(spaceResp.Profiles))
	}
	if spaceResp.Mode != model.ModePersonal {
		t.Errorf("Expected initial mode PERSONAL, got %s", spaceResp.Mode)
	}

	// 2. Add Member 2: Child 1 (Leo, age 12 via DOB)
	child1 := model.Member{
		Name:         "Leo (Son)",
		Relationship: "child",
		DateOfBirth:  "2014-06-15",
		Gender:       "male",
		HeightCm:     145.0,
		WeightKg:     40.0,
	}
	body1, _ := json.Marshal(child1)
	req1 := httptest.NewRequest("POST", "/api/v1/users/"+deviceID+"/members", bytes.NewBuffer(body1))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	if w1.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for AddMember 2, got %d: %s", w1.Code, w1.Body.String())
	}
	_ = json.Unmarshal(w1.Body.Bytes(), &spaceResp)

	if len(spaceResp.Profiles) != 2 {
		t.Errorf("Expected 2 profiles, got %d", len(spaceResp.Profiles))
	}
	if spaceResp.Mode != model.ModeFamily {
		t.Errorf("Expected auto-upgrade to FAMILY mode, got %s", spaceResp.Mode)
	}

	// Verify child 1 dynamic age and pediatric BMI assessment
	addedChild1 := spaceResp.Profiles[1]
	if addedChild1.Age < 11 || addedChild1.Age > 13 {
		t.Errorf("Expected child age ~12, got %d", addedChild1.Age)
	}
	if addedChild1.BMIAssessment.Type != "PEDIATRIC" {
		t.Errorf("Expected PEDIATRIC BMI assessment, got %s", addedChild1.BMIAssessment.Type)
	}
	if addedChild1.BMIAssessment.Percentile == nil {
		t.Errorf("Expected pediatric BMI percentile to be present")
	}

	// 3. Add Member 3: Child 2 (Meera, age 8 via DOB)
	child2 := model.Member{
		Name:         "Meera (Daughter)",
		Relationship: "child",
		DateOfBirth:  "2018-09-20",
		Gender:       "female",
		HeightCm:     125.0,
		WeightKg:     25.0,
	}
	body2, _ := json.Marshal(child2)
	req2 := httptest.NewRequest("POST", "/api/v1/users/"+deviceID+"/members", bytes.NewBuffer(body2))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	if w2.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for AddMember 3, got %d", w2.Code)
	}
	_ = json.Unmarshal(w2.Body.Bytes(), &spaceResp)

	if len(spaceResp.Profiles) != 3 {
		t.Fatalf("Expected 3 profiles, got %d", len(spaceResp.Profiles))
	}

	// 4. Attempt to Add Member 4: MUST FAIL with 400 Bad Request (3-member limit)
	child3 := model.Member{
		Name:         "Extra Child",
		Relationship: "child",
		DateOfBirth:  "2020-01-01",
		Gender:       "male",
		HeightCm:     100.0,
		WeightKg:     16.0,
	}
	body3, _ := json.Marshal(child3)
	req3 := httptest.NewRequest("POST", "/api/v1/users/"+deviceID+"/members", bytes.NewBuffer(body3))
	req3.Header.Set("Content-Type", "application/json")
	w3 := httptest.NewRecorder()
	r.ServeHTTP(w3, req3)

	if w3.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 Bad Request for 4th member, got %d: %s", w3.Code, w3.Body.String())
	}
}

func TestScopedDailyFoodLogs(t *testing.T) {
	r, _ := setupTestRouter(t)
	deviceID := "test-family-device-102"

	// Save log for Primary Member
	log1 := map[string]any{
		"foodName": "Mother's Breakfast Oatmeal",
		"calories": 350,
	}
	b1, _ := json.Marshal(log1)
	req1 := httptest.NewRequest("PUT", "/api/v1/users/"+deviceID+"/days/2026-08-30?memberId=prof_primary", bytes.NewBuffer(b1))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	if w1.Code != http.StatusOK {
		t.Fatalf("Failed to save log for primary: %d", w1.Code)
	}

	// Save log for Child 1
	log2 := map[string]any{
		"foodName": "Leo's Lunch Rice & Chicken",
		"calories": 500,
	}
	b2, _ := json.Marshal(log2)
	req2 := httptest.NewRequest("PUT", "/api/v1/users/"+deviceID+"/days/2026-08-30?memberId=mem_child1", bytes.NewBuffer(b2))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	if w2.Code != http.StatusOK {
		t.Fatalf("Failed to save log for child: %d", w2.Code)
	}

	// List logs scoped to Child 1
	reqList := httptest.NewRequest("GET", "/api/v1/users/"+deviceID+"/days?memberId=mem_child1", nil)
	wList := httptest.NewRecorder()
	r.ServeHTTP(wList, reqList)

	if wList.Code != http.StatusOK {
		t.Fatalf("Failed to list logs: %d", wList.Code)
	}

	var logs []map[string]any
	_ = json.Unmarshal(wList.Body.Bytes(), &logs)

	if len(logs) != 1 {
		t.Fatalf("Expected 1 scoped log for child 1, got %d", len(logs))
	}
	if logs[0]["foodName"] != "Leo's Lunch Rice & Chicken" {
		t.Errorf("Unexpected food name in child log: %v", logs[0]["foodName"])
	}
}
