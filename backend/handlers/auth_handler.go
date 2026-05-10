package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

var jwtSecret = []byte("super-secret-key-for-jabatkopi")

func LoginHandler(c *gin.Context) {
	var req LoginRequest

	// Validate payload
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid request payload",
			"error":   err.Error(),
		})
		return
	}

	// Mock DB check
	if req.Username != "johndoe" || req.Password != "password123" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  401,
			"message": "Invalid username or password",
		})
		return
	}

	// Generate JWT Token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": req.Username,
		"role":     "customer",
		"exp":      time.Now().Add(time.Hour * 72).Unix(),
	})

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to generate token",
		})
		return
	}

	// Success response matching API Contract
	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data": gin.H{
			"token": tokenString,
			"role":  "customer",
		},
	})
}
