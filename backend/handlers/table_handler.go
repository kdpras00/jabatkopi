package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

// GetTablesHandler handles GET /api/v1/tables
func GetTablesHandler(c *gin.Context) {
	var tables []models.Table
	if err := database.DB.Find(&tables).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tables"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Success", "data": tables})
}

// GetTablesWithStatusHandler handles GET /api/v1/tables/status?date=...&time=...&customer_id=...
func GetTablesWithStatusHandler(c *gin.Context) {
	dateStr := c.Query("date")
	timeStr := c.Query("time")
	
	// Coba ambil customerID dari context (JWT)
	customerIDStr := c.Query("customer_id")
	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			customerIDStr = fmt.Sprintf("%d", int(idFloat))
		}
	}

	var tables []models.Table
	database.DB.Find(&tables)

	// Jika tidak ada parameter waktu, kembalikan status fisik saja
	if dateStr == "" || timeStr == "" {
		var data []gin.H
		for _, t := range tables {
			data = append(data, gin.H{
				"id":           t.ID,
				"qr_code_ref":  t.QRCodeRef,
				"capacity":     t.Capacity,
				"status":       t.Status,
				"display_status": t.Status,
			})
		}
		c.JSON(http.StatusOK, gin.H{"status": 200, "data": data})
		return
	}

	targetTime, _ := time.Parse("2006-01-02 15:04", dateStr+" "+timeStr)

	// Ambil semua reservasi pada waktu tersebut
	var reservations []models.Reservation
	database.DB.Where("reservation_date = ? AND status IN (?)", targetTime, []string{"booked", "confirmed", "valid", "pending", "checked_in"}).
		Find(&reservations)

	reservedMap := make(map[uint]uint) // TableID -> CustomerID
	for _, res := range reservations {
		reservedMap[res.TableID] = res.CustomerID
	}

	var data []gin.H
	for _, t := range tables {
		resCustomerID, isReserved := reservedMap[t.ID]
		displayStatus := "available"
		isMine := false

		if t.Status == "occupied" {
			displayStatus = "occupied"
		} else if isReserved {
			if customerIDStr != "" && fmt.Sprintf("%d", resCustomerID) == customerIDStr {
				displayStatus = "available" // Bisa saya pilih
				isMine = true
			} else {
				displayStatus = "reserved" // Punya orang lain
			}
		}

		data = append(data, gin.H{
			"id":             t.ID,
			"qr_code_ref":    t.QRCodeRef,
			"capacity":       t.Capacity,
			"status":         t.Status,
			"display_status": displayStatus,
			"is_mine":        isMine,
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Success", "data": data})
}

// CreateTableHandler handles POST /api/v1/admin/tables
func CreateTableHandler(c *gin.Context) {
	var req struct {
		QRCodeRef string `json:"qr_code_ref"`
		Capacity  int    `json:"capacity"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.QRCodeRef == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "qr_code_ref is required"})
		return
	}

	capacity := req.Capacity
	if capacity <= 0 {
		capacity = 4 // Default 4 orang
	}

	table := models.Table{
		QRCodeRef: req.QRCodeRef,
		Capacity:  capacity,
		Status:    "available",
	}
	if err := database.DB.Create(&table).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create table"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"status": 201, "message": "Table created", "data": table})
}

// SeedTablesHandler handles POST /api/v1/admin/tables/seed — seed default tables
func SeedTablesHandler(c *gin.Context) {
	defaultTables := []models.Table{
		{QRCodeRef: "JK-TABLE-1", Capacity: 2, Status: "available"},
		{QRCodeRef: "JK-TABLE-2", Capacity: 4, Status: "available"},
		{QRCodeRef: "JK-TABLE-3", Capacity: 4, Status: "available"},
		{QRCodeRef: "JK-TABLE-4", Capacity: 6, Status: "available"},
		{QRCodeRef: "JK-TABLE-5", Capacity: 2, Status: "available"},
		{QRCodeRef: "JK-TABLE-6", Capacity: 8, Status: "available"},
	}

	var created []models.Table
	for _, t := range defaultTables {
		var existing models.Table
		if err := database.DB.Where("qr_code_ref = ?", t.QRCodeRef).First(&existing).Error; err != nil {
			// Not found, create it
			if err2 := database.DB.Create(&t).Error; err2 == nil {
				created = append(created, t)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Tables seeded successfully",
		"data":    created,
	})
}

// UpdateTableStatusHandler handles PUT /api/v1/admin/tables/:id/status
func UpdateTableStatusHandler(c *gin.Context) {
	tableID := c.Param("id")
	var req struct {
		Status string `json:"status"` // available, occupied
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var table models.Table
	if err := database.DB.First(&table, tableID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Table not found"})
		return
	}

	table.Status = req.Status
	database.DB.Save(&table)

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Table status updated", "data": table})
}
