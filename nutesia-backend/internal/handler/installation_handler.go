package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/model"
	"github.com/nuto/backend/internal/service"
)

type InstallationHandler struct {
	service *service.AntiAbuseService
}

func NewInstallationHandler(service *service.AntiAbuseService) *InstallationHandler {
	return &InstallationHandler{service: service}
}

// Track registers or refreshes installation identity and evaluates promotional eligibility/risk.
func (h *InstallationHandler) Track(c *gin.Context) {
	var inst model.Installation
	if err := c.ShouldBindJSON(&inst); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid installation payload"})
		return
	}

	userID := c.GetString("uid")
	result, err := h.service.TrackInstallation(inst, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process installation"})
		return
	}

	c.JSON(http.StatusOK, result)
}
