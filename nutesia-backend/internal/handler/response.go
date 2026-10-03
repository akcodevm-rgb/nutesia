package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// APIError represents the standardized error envelope for Nuto backend APIs.
type APIError struct {
	Code      string         `json:"code"`
	Message   string         `json:"message"`
	Details   map[string]any `json:"details,omitempty"`
	Retryable bool           `json:"retryable"`
}

// APIResponse represents the top-level standard JSON response format.
type APIResponse struct {
	Success    bool      `json:"success"`
	StatusCode int       `json:"statusCode"`
	Data       any       `json:"data,omitempty"`
	Error      *APIError `json:"error,omitempty"`
}

// WriteJSONError sends a structured error response matching the client error parser format.
func WriteJSONError(c *gin.Context, statusCode int, code, message string, details map[string]any, retryable bool) {
	c.JSON(statusCode, APIResponse{
		Success:    false,
		StatusCode: statusCode,
		Error: &APIError{
			Code:      code,
			Message:   message,
			Details:   details,
			Retryable: retryable,
		},
	})
}

// WriteJSONSuccess sends a structured success response.
func WriteJSONSuccess(c *gin.Context, statusCode int, data any) {
	c.JSON(statusCode, APIResponse{
		Success:    true,
		StatusCode: statusCode,
		Data:       data,
	})
}

// Helper shorthand methods for common errors
func BadRequestError(c *gin.Context, code, message string, details map[string]any) {
	if code == "" {
		code = "BAD_REQUEST"
	}
	WriteJSONError(c, http.StatusBadRequest, code, message, details, false)
}

func ValidationError(c *gin.Context, message string, fieldErrors map[string]any) {
	WriteJSONError(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", message, fieldErrors, false)
}

func UnauthorizedError(c *gin.Context, message string) {
	if message == "" {
		message = "Session expired or authentication required"
	}
	WriteJSONError(c, http.StatusUnauthorized, "SESSION_EXPIRED", message, nil, false)
}

func ForbiddenError(c *gin.Context, message string) {
	if message == "" {
		message = "You do not have permission to perform this action"
	}
	WriteJSONError(c, http.StatusForbidden, "FORBIDDEN", message, nil, false)
}

func NotFoundError(c *gin.Context, message string) {
	if message == "" {
		message = "Requested resource was not found"
	}
	WriteJSONError(c, http.StatusNotFound, "NOT_FOUND", message, nil, false)
}

func RateLimitedError(c *gin.Context, message string) {
	if message == "" {
		message = "Too many requests. Please wait a moment before trying again."
	}
	WriteJSONError(c, http.StatusTooManyRequests, "RATE_LIMITED", message, nil, true)
}

func ServerError(c *gin.Context, message string) {
	if message == "" {
		message = "An unexpected server error occurred. Please try again."
	}
	WriteJSONError(c, http.StatusInternalServerError, "SERVER_ERROR", message, nil, true)
}
