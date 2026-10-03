package router

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nuto/backend/internal/handler"
	"github.com/nuto/backend/internal/middleware"
)

// New exposes HTTP endpoints while keeping request handling outside main.
func New(
	health *handler.HealthHandler,
	data *handler.DataHandler,
	ai *handler.AIHandler,
	wallet *handler.WalletHandler,
	installation *handler.InstallationHandler,
	allowedOrigin, projectID string,
) *gin.Engine {
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	r.Use(cors(allowedOrigin))

	r.GET("/health", health.Check)

	v1 := r.Group("/api/v1")
	if projectID != "" {
		auth := middleware.NewAuthMiddleware(projectID)
		v1.Use(auth.RequireAuth())
		v1.Use(verifyUserAccess())
	}

	// Installation & Anti-abuse telemetry
	if installation != nil {
		v1.POST("/installations", installation.Track)
	}

	// NutritionSpace & Member Profile Operations
	v1.GET("/users/:deviceId", data.GetUser)
	v1.PUT("/users/:deviceId", data.SaveUser)
	v1.PATCH("/users/:deviceId/mode", data.UpdateSpaceMode)
	v1.POST("/users/:deviceId/members", data.AddMember)
	v1.PUT("/users/:deviceId/members/:memberId", data.UpdateMember)
	v1.DELETE("/users/:deviceId/members/:memberId", data.DeleteMember)

	// Scoped Daily Nutrition Logs (Supports ?memberId=mem_xxx query parameter)
	v1.GET("/users/:deviceId/days", data.ListDays)
	v1.GET("/users/:deviceId/days/:date", data.GetDay)
	v1.PUT("/users/:deviceId/days/:date", data.SaveDay)

	// Shared Credit Wallet & Rewards
	v1.GET("/users/:deviceId/wallet", wallet.Get)
	v1.POST("/users/:deviceId/wallet/rewarded-ad", wallet.RewardAd)

	// AI Nutrition & Vision Endpoints
	v1.POST("/users/:deviceId/ai/food-parse", ai.ParseFood)
	v1.POST("/users/:deviceId/ai/deficiency-analysis", ai.AnalyzeDeficiencies)

	return r
}

func verifyUserAccess() gin.HandlerFunc {
	return func(c *gin.Context) {
		uid, exists := c.Get("uid")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: missing user session"})
			c.Abort()
			return
		}

		deviceID := c.Param("deviceId")
		if deviceID != "" && deviceID != uid.(string) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: access denied to this nutrition space"})
			c.Abort()
			return
		}
		c.Next()
	}
}

func cors(allowedOrigin string) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		if allowedOrigin == "*" && origin != "" {
			c.Header("Access-Control-Allow-Origin", origin)
		} else if allowedOrigin != "" {
			c.Header("Access-Control-Allow-Origin", allowedOrigin)
		} else {
			c.Header("Access-Control-Allow-Origin", "*")
		}

		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Installation-ID, X-Idempotency-Key")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusOK)
			return
		}
		c.Next()
	}
}
