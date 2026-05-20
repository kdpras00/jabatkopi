package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

// CheckAvailabilityHandler handles GET /api/v1/tables/available
// Mengembalikan daftar meja yang tidak ter-booking pada Tanggal & Waktu spesifik yang diminta
func CheckAvailabilityHandler(c *gin.Context) {
	dateStr := c.Query("date")
	timeStr := c.Query("time")

	if dateStr == "" || timeStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "date and time are required"})
		return
	}

	targetTime, err := time.Parse("2006-01-02 15:04", dateStr+" "+timeStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date/time format. Expected YYYY-MM-DD and HH:MM"})
		return
	}

	// 1. Ambil semua meja yang ada di restoran yang statusnya available
	var allTables []models.Table
	if err := database.DB.Where("status = ?", "available").Find(&allTables).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tables"})
		return
	}

	// 2. Ambil ID meja yang sudah direservasi pada waktu tersebut dengan status aktif
	var reservedTableIDs []uint
	database.DB.Model(&models.Reservation{}).
		Where("reservation_date = ? AND status IN (?)", targetTime, []string{"booked", "confirmed", "valid", "pending", "checked_in"}).
		Pluck("table_id", &reservedTableIDs)

	// Buat map lookup untuk kecepatan
	reservedMap := make(map[uint]bool)
	for _, id := range reservedTableIDs {
		reservedMap[id] = true
	}

	// 3. Saring meja yang bebas bentrok
	var availableTables []models.Table
	for _, table := range allTables {
		if !reservedMap[table.ID] {
			availableTables = append(availableTables, table)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data":    availableTables,
	})
}

// CreateReservationHandler handles POST /api/v1/reservations
func CreateReservationHandler(c *gin.Context) {
	var req struct {
		Date       string `json:"date"`
		Time       string `json:"time"`
		Guests     int    `json:"guests"`
		CustomerID int    `json:"customer_id"`
		TableID    int    `json:"table_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			req.CustomerID = int(idFloat)
		}
	}

	resTime, _ := time.Parse("2006-01-02 15:04", req.Date+" "+req.Time)
	timeEnd := resTime.Add(1 * time.Hour) // Default durasi 1 jam

	// Validasi 1: Cek Kapasitas Meja
	var table models.Table
	if err := database.DB.First(&table, req.TableID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Meja tidak ditemukan"})
		return
	}
	if req.Guests > table.Capacity {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": fmt.Sprintf("Jumlah tamu (%d) melebihi kapasitas Meja %d (Maksimal %d orang).", req.Guests, table.ID, table.Capacity),
		})
		return
	}

	// Validasi 2: Limit Reservasi Aktif per Akun (Maksimal 2 reservasi aktif dalam satu waktu)
	var activeUserReservations int64
	database.DB.Model(&models.Reservation{}).
		Where("customer_id = ? AND status IN (?)", req.CustomerID, []string{"booked", "confirmed", "valid", "pending"}).
		Count(&activeUserReservations)

	if activeUserReservations >= 2 {
		c.JSON(http.StatusTooManyRequests, gin.H{
			"status":  429,
			"message": "Batas reservasi tercapai. Anda memiliki 2 reservasi aktif saat ini. Selesaikan atau batalkan reservasi sebelumnya terlebih dahulu.",
		})
		return
	}

	// Validasi 3: Validasi Bentrok Slot Waktu Meja (Collision Check)
	var count int64
	database.DB.Model(&models.Reservation{}).
		Where("table_id = ? AND reservation_date = ? AND time_start = ? AND status IN (?)",
			req.TableID, resTime, resTime, []string{"booked", "confirmed", "valid", "pending", "checked_in"}).
		Count(&count)

	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{
			"status":  409,
			"message": "Meja tersebut sudah direservasi pada slot waktu yang dipilih. Silakan pilih waktu atau meja lain.",
		})
		return
	}

	barcodeStr := fmt.Sprintf("QR_CODE_%d_%d", req.CustomerID, time.Now().UnixNano())

	reservation := models.Reservation{
		TableID:         uint(req.TableID),
		CustomerID:      uint(req.CustomerID),
		ReservationDate: resTime,
		TimeStart:       resTime,
		TimeEnd:         timeEnd,
		Pax:             req.Guests,
		Barcode:         barcodeStr,
		Status:          "booked",
	}

	if err := database.DB.Create(&reservation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create reservation"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data": gin.H{
			"reservation_id":       reservation.ID,
			"table_id":             reservation.TableID,
			"barcode":              reservation.Barcode, // Barcode asli untuk QR Code
			"qr_code":              reservation.Barcode, // Alias agar kompatibel
			"booking_id":           fmt.Sprintf("JK-RES-%d", reservation.ID),
			"reservation_date":     reservation.ReservationDate,
			"time_start":           reservation.TimeStart,
			"time_end":             reservation.TimeEnd,
			"pax":                  reservation.Pax,
			"status":               reservation.Status,
		},
	})
}

// GetActiveReservationHandler handles GET /api/v1/reservations/active
// Returns the customer's reservation for today (if any)
func GetActiveReservationHandler(c *gin.Context) {
	var customerID int
	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			customerID = int(idFloat)
		}
	}

	// Cari reservasi aktif hari ini (menggunakan filter tanggal yang lebar: H-1 sampai H+2)
	// Hal ini untuk menangani konversi zona waktu UTC di database Supabase vs WIB/GMT+7 di lokal
	now := time.Now()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()).Add(-24 * time.Hour)
	todayEnd := todayStart.Add(72 * time.Hour)

	var reservation models.Reservation
	result := database.DB.Joins("Table").
		Where("customer_id = ? AND reservation_date >= ? AND reservation_date < ? AND status IN (?)",
			customerID, todayStart, todayEnd, []string{"booked", "confirmed", "valid", "checked_in"}).
		Order("CASE status WHEN 'checked_in' THEN 0 ELSE 1 END"). // Prioritaskan yang sudah check-in
		First(&reservation)

	if result.Error != nil {
		// No active reservation found — not an error, just empty
		c.JSON(http.StatusOK, gin.H{
			"status":  200,
			"message": "No active reservation",
			"data":    nil,
		})
		return
	}

	tableRef := fmt.Sprintf("Meja %d", reservation.TableID)
	if reservation.Table.QRCodeRef != "" {
		tableRef = reservation.Table.QRCodeRef
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data": gin.H{
			"reservation_id":   reservation.ID,
			"table_id":         reservation.TableID,
			"table_ref":        tableRef,
			"reservation_date": reservation.ReservationDate,
			"time_start":       reservation.TimeStart,
			"pax":              reservation.Pax,
			"status":           reservation.Status, // booked atau checked_in
			"barcode":          reservation.Barcode,
		},
	})
}

// GetAdminReservationsHandler handles GET /api/v1/admin/reservations
// Lists today's reservations with customer and table details
func GetAdminReservationsHandler(c *gin.Context) {
	var reservations []models.Reservation
	if err := database.DB.Joins("Customer").Joins("Table").
		Order("reservation_date ASC").
		Find(&reservations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reservations"})
		return
	}

	var data []gin.H
	for _, res := range reservations {
		data = append(data, gin.H{
			"id":               res.ID,
			"booking_id":       fmt.Sprintf("JK-RES-%d", res.ID),
			"customer_name":    res.Customer.Name,
			"table_id":         res.TableID,
			"pax":              res.Pax,
			"reservation_date": res.ReservationDate,
			"status":           res.Status,
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Success", "data": data})
}

// VerifyReservationArrivalHandler handles PUT /api/v1/admin/reservations/:id/arrive
// Mark reservation status as checked_in and lock table as occupied
func VerifyReservationArrivalHandler(c *gin.Context) {
	id := c.Param("id")

	var reservation models.Reservation
	if err := database.DB.First(&reservation, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reservation not found"})
		return
	}

	now := time.Now()
	reservation.Status = "checked_in"
	reservation.CheckedInAt = &now
	if err := database.DB.Save(&reservation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update reservation status"})
		return
	}

	// Otomatis kunci meja menjadi "occupied" saat tamu tiba
	if reservation.TableID > 0 {
		var table models.Table
		if err := database.DB.First(&table, reservation.TableID).Error; err == nil {
			table.Status = "occupied"
			database.DB.Save(&table)
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Reservation verified and table locked successfully", "data": reservation})
}

// CompleteReservationByStaffHandler handles PUT /api/v1/admin/reservations/:id/complete
// Stage 8: Staff tandai tamu selesai → reservasi COMPLETED, meja dibebaskan
func CompleteReservationByStaffHandler(c *gin.Context) {
	id := c.Param("id")

	var reservation models.Reservation
	if err := database.DB.First(&reservation, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reservation not found"})
		return
	}

	now := time.Now()
	reservation.Status = "completed"
	reservation.CompletedAt = &now
	if err := database.DB.Save(&reservation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update reservation status"})
		return
	}

	// Bebaskan meja kembali menjadi "available"
	if reservation.TableID > 0 {
		var table models.Table
		if err := database.DB.First(&table, reservation.TableID).Error; err == nil {
			table.Status = "available"
			database.DB.Save(&table)
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Reservasi selesai. Meja kembali tersedia.", "data": reservation})
}

// GetReservationHistoryHandler handles GET /api/v1/reservations/history
// Returns all reservations for the logged-in customer
func GetReservationHistoryHandler(c *gin.Context) {
	var customerID int
	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			customerID = int(idFloat)
		}
	}

	var reservations []models.Reservation
	if err := database.DB.Where("customer_id = ?", customerID).Order("reservation_date DESC").Find(&reservations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reservation history"})
		return
	}

	var data []gin.H
	for _, res := range reservations {
		data = append(data, gin.H{
			"id":               res.ID,
			"booking_id":       fmt.Sprintf("JK-RES-%d", res.ID),
			"table_id":         res.TableID,
			"pax":              res.Pax,
			"reservation_date": res.ReservationDate,
			"status":           res.Status,
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Success", "data": data})
}

// CancelReservationHandler handles PUT /api/v1/reservations/:id/cancel
func CancelReservationHandler(c *gin.Context) {
	resID := c.Param("id")
	var customerID int
	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			customerID = int(idFloat)
		}
	}

	var reservation models.Reservation
	if err := database.DB.Where("id = ? AND customer_id = ?", resID, customerID).First(&reservation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reservasi tidak ditemukan atau bukan milik Anda"})
		return
	}

	if reservation.Status != "confirmed" && reservation.Status != "valid" && reservation.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Reservasi tidak dapat dibatalkan karena status saat ini: " + reservation.Status})
		return
	}

	reservation.Status = "cancelled"
	if err := database.DB.Save(&reservation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membatalkan reservasi"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Reservasi berhasil dibatalkan",
		"data":    reservation,
	})
}


