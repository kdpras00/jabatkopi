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
	var totalOrders int64
	var totalRevenue float64

	if database.DB == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "DB connection lost"})
		return
	}

	database.DB.Model(&models.Order{}).Count(&totalOrders)
	database.DB.Model(&models.Order{}).Select("COALESCE(sum(total_amount), 0)").Scan(&totalRevenue)

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
