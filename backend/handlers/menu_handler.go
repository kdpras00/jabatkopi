package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

func GetMenusHandler(c *gin.Context) {
	var menus []models.Menu
	if err := database.DB.Find(&menus).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to fetch menus",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data":    menus,
	})
}

func CreateMenuHandler(c *gin.Context) {
	var menu models.Menu
	if err := c.ShouldBindJSON(&menu); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid request payload",
		})
		return
	}

	if err := database.DB.Create(&menu).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to create menu",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  201,
		"message": "Menu created successfully",
		"data":    menu,
	})
}

func UpdateMenuHandler(c *gin.Context) {
	id := c.Param("id")
	var menu models.Menu
	if err := database.DB.First(&menu, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  404,
			"message": "Menu not found",
		})
		return
	}

	if err := c.ShouldBindJSON(&menu); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid request payload",
		})
		return
	}

	database.DB.Save(&menu)
	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Menu updated successfully",
		"data":    menu,
	})
}

func DeleteMenuHandler(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Unscoped().Delete(&models.Menu{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to delete menu",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Menu deleted successfully",
	})
}
