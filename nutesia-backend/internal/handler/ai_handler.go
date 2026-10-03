package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/repository"
	"github.com/nuto/backend/internal/service"
)

const groqEndpoint = "https://api.groq.com/openai/v1/chat/completions"

const foodParsePrompt = `You are NutoAI, a precise nutrition analysis assistant. Parse the user's food description into foods and nutritional estimates. All nutritional values and calculations must represent the consumption for only a single person (a single serving/portion sized for one individual). Return only a valid JSON object with: foods (name, quantity, unit, calories, protein, carbs, fat, vitamins with vitaminA/vitaminB1/vitaminB2/vitaminB6/vitaminB12/vitaminC/vitaminD/vitaminE/vitaminK/folate, minerals with calcium/iron/zinc/magnesium/potassium/sodium/phosphorus), explanation, and error. All numeric values must be doubles. Calories must equal protein*4 + carbs*4 + fat*9. For invalid food input return an empty foods array and a non-empty error.`

const deficiencyPrompt = `You are NutoAI, a clinical nutrition specialist. Given a user's profile and average daily nutrient intake compared with targets, return only valid JSON with riskLevel, summary, deficiencies (nutrient, probability, symptoms, explanation), and recommendations (food, reason, tips). List only materially deficient nutrients and offer practical food recommendations, not supplement brands.`

type AIHandler struct {
	apiKey string
	client *http.Client
	repo   repository.Repository
	wallet *WalletHandler
}

func NewAIHandler(apiKey string, repo repository.Repository, wallet *WalletHandler) *AIHandler {
	return &AIHandler{apiKey: apiKey, client: &http.Client{Timeout: 35 * time.Second}, repo: repo, wallet: wallet}
}

// ParseFood parses natural language food logs into macros and charges the shared space wallet.
func (h *AIHandler) ParseFood(c *gin.Context) {
	spaceID, ok := validDeviceID(c)
	if !ok {
		return
	}
	memberID := c.Query("memberId")

	var request struct {
		Input string `json:"input"`
	}
	if err := c.ShouldBindJSON(&request); err != nil || strings.TrimSpace(request.Input) == "" || len(request.Input) > 4000 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "A food description up to 4000 characters is required"})
		return
	}

	analysisRef := fmt.Sprintf("analysis_%d", time.Now().UnixNano())
	idempotencyKey := c.GetHeader("X-Idempotency-Key")

	// Atomic deduction from shared wallet (Daily balance first, then Ad balance)
	_, _, err := h.wallet.Deduct(spaceID, memberID, 2, model.TxTypeMealAnalysis, analysisRef, idempotencyKey)
	if err != nil {
		h.writeCreditError(c, err)
		return
	}

	content, err := h.complete("food_parse", request.Input)
	if err != nil {
		_, _ = h.wallet.Refund(spaceID, memberID, 2, analysisRef)
		c.JSON(http.StatusBadGateway, gin.H{"error": "AI provider request failed"})
		return
	}

	var resultObj struct {
		Foods []any  `json:"foods"`
		Error string `json:"error"`
	}
	if err := json.Unmarshal([]byte(content), &resultObj); err == nil {
		if resultObj.Error != "" || len(resultObj.Foods) == 0 {
			_, _ = h.wallet.Refund(spaceID, memberID, 2, analysisRef)
			errMsg := resultObj.Error
			if errMsg == "" {
				errMsg = "Invalid food input. Please describe a food item."
			}
			c.JSON(http.StatusBadRequest, gin.H{"error": errMsg})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"content": content})
}

// AnalyzeDeficiencies analyzes nutritional deficiencies across daily logs.
func (h *AIHandler) AnalyzeDeficiencies(c *gin.Context) {
	spaceID, ok := validDeviceID(c)
	if !ok {
		return
	}
	memberID := c.Query("memberId")

	var request struct {
		StartDate string `json:"startDate"`
		EndDate   string `json:"endDate"`
	}
	if err := c.ShouldBindJSON(&request); err != nil || !datePattern.MatchString(request.StartDate) || !datePattern.MatchString(request.EndDate) || request.StartDate > request.EndDate {
		c.JSON(http.StatusBadRequest, gin.H{"error": "A valid startDate and endDate are required"})
		return
	}

	profile, found, err := h.repo.Get("users", spaceID)
	if err != nil || !found {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nutrition space not found"})
		return
	}

	logs, err := h.repo.List("days/" + spaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load food logs"})
		return
	}

	var days []json.RawMessage
	for _, raw := range logs {
		var day struct {
			Date     string `json:"date"`
			MemberID string `json:"memberId"`
		}
		if json.Unmarshal(raw, &day) == nil && day.Date >= request.StartDate && day.Date <= request.EndDate {
			if memberID != "" && day.MemberID != "" && day.MemberID != memberID {
				continue
			}
			days = append(days, raw)
		}
	}

	analysisRef := fmt.Sprintf("deficiency_%d", time.Now().UnixNano())
	idempotencyKey := c.GetHeader("X-Idempotency-Key")

	if _, _, err := h.wallet.Deduct(spaceID, memberID, 3, model.TxTypeMealAnalysis, analysisRef, idempotencyKey); err != nil {
		h.writeCreditError(c, err)
		return
	}

	input, _ := json.Marshal(gin.H{"profile": json.RawMessage(profile), "startDate": request.StartDate, "endDate": request.EndDate, "dailyLogs": days})
	content, err := h.complete("deficiency_analysis", string(input))
	if err != nil {
		_, _ = h.wallet.Refund(spaceID, memberID, 3, analysisRef)
		c.JSON(http.StatusBadGateway, gin.H{"error": "AI provider request failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"content": content})
}

func (h *AIHandler) writeCreditError(c *gin.Context, err error) {
	if errors.Is(err, service.ErrInsufficientCredits) {
		WriteJSONError(c, http.StatusPaymentRequired, "INSUFFICIENT_CREDITS", "Not enough credits for AI analysis. Watch an ad to earn free credits.", nil, false)
		return
	}
	WriteJSONError(c, http.StatusInternalServerError, "WALLET_ERROR", "Unable to process credit deduction", nil, true)
}

func (h *AIHandler) complete(operation, input string) (string, error) {
	if h.apiKey == "" {
		return "", errors.New("AI service is not configured")
	}
	prompt := foodParsePrompt
	if operation == "deficiency_analysis" {
		prompt = deficiencyPrompt
	}
	body, _ := json.Marshal(gin.H{"model": "llama-3.3-70b-versatile", "temperature": 0.3, "max_tokens": 1024, "response_format": gin.H{"type": "json_object"}, "messages": []gin.H{{"role": "system", "content": prompt}, {"role": "user", "content": input}}})
	req, _ := http.NewRequest(http.MethodPost, groqEndpoint, bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+h.apiKey)
	req.Header.Set("Content-Type", "application/json")
	response, err := h.client.Do(req)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	result, _ := io.ReadAll(io.LimitReader(response.Body, 2<<20))
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return "", errors.New("provider error")
	}
	var payload struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if json.Unmarshal(result, &payload) != nil || len(payload.Choices) == 0 {
		return "", errors.New("invalid provider response")
	}
	return payload.Choices[0].Message.Content, nil
}
