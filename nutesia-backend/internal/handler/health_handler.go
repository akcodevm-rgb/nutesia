package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type HealthHandler struct{}

func NewHealthHandler() *HealthHandler { return &HealthHandler{} }

func (h *HealthHandler) Check(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"statusCode": http.StatusOK,
		"message":    "Nuto API is healthy",
		"data":       gin.H{"service": "nuto-api"},
		"error":      nil,
		"timestamp":  time.Now().UTC(),
	})
}
