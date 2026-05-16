package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
	"golang.org/x/crypto/bcrypt"
)

func GetUsersHandler(c *gin.Context) {
	var users []models.User
	if err := database.DB.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to fetch users",
		})
		return
	}

	fmt.Printf("[DEBUG] Users found in DB: %d\n", len(users))

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data":    users,
	})
}

func CreateUserHandler(c *gin.Context) {
	var req struct {
		Name     string `json:"name" binding:"required"`
		Username string `json:"username" binding:"required"`
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
		Role     string `json:"role" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid request payload",
		})
		return
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)

	user := models.User{
		Name:         req.Name,
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		Role:         req.Role,
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to create user",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  201,
		"message": "User created successfully",
	})
}

func UpdateUserHandler(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "User not found"})
		return
	}

	var req struct {
		Name     string `json:"name"`
		Username string `json:"username"`
		Email    string `json:"email"`
		Role     string `json:"role"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "Invalid payload"})
		return
	}

	user.Name = req.Name
	user.Username = req.Username
	user.Email = req.Email
	user.Role = req.Role

	database.DB.Save(&user)
	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "User updated successfully"})
}

func DeleteUserHandler(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Unscoped().Delete(&models.User{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to delete user",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "User deleted successfully",
	})
}

func GetProfileHandler(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "data": user})
}

func UpdateProfileHandler(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var req struct {
		Name     string `json:"name"`
		Username string `json:"username"`
		Email    string `json:"email"`
		ImageURL string `json:"image_url"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		user.Name = req.Name
	}
	if req.Username != "" {
		user.Username = req.Username
	}
	if req.Email != "" {
		user.Email = req.Email
	}
	if req.ImageURL != "" {
		user.ImageURL = req.ImageURL
	}

	database.DB.Save(&user)
	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Profile updated successfully", "data": user})
}
