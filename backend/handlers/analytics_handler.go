package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

func GetAdminAnalyticsHandler(c *gin.Context) {
	var stats struct {
		TotalOrders  int64
		TotalRevenue float64
	}

	if err := database.DB.Model(&models.Order{}).
		Select("COUNT(id) as total_orders, COALESCE(SUM(total_amount), 0) as total_revenue").
		Scan(&stats).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "Failed to calculate analytics"})
		return
	}

	totalOrders := stats.TotalOrders
	totalRevenue := stats.TotalRevenue

	fmt.Printf("[DEBUG] Total Orders: %d, Total Revenue: %f\n", totalOrders, totalRevenue)

	type TopItem struct {
		Name  string `json:"name"`
		Sales int    `json:"sales"`
	}
	var topItems []TopItem
	
	database.DB.Table("order_items").
		Select("menus.name, count(order_items.id) as sales").
		Joins("join menus on menus.id = order_items.menu_id").
		Group("menus.name").
		Order("sales desc").
		Limit(5).
		Scan(&topItems)

	fmt.Printf("[DEBUG] Top Items found: %d\n", len(topItems))

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data": gin.H{
			"total_revenue": totalRevenue,
			"total_orders":  totalOrders,
			"top_items":     topItems,
			"revenue_chart": []gin.H{
				{"date": time.Now().Format("02 Jan"), "amount": totalRevenue},
			},
		},
	})
}
