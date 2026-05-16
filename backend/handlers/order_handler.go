package handlers

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
	"github.com/midtrans/midtrans-go"
	"github.com/midtrans/midtrans-go/coreapi"
	"github.com/midtrans/midtrans-go/snap"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

func CreateOrderHandler(c *gin.Context) {
	var order models.Order
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid request payload",
			"error":   err.Error(),
		})
		return
	}

	if userID, exists := c.Get("user_id"); exists {
		if idFloat, ok := userID.(float64); ok {
			order.CustomerID = uint(idFloat)
		}
	}

	order.Status = "pending"

	// Cek apakah pelanggan memiliki reservasi aktif hari ini untuk meja tersebut (dengan rentang waktu H-1 sampai H+2)
	now := time.Now()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()).Add(-24 * time.Hour)
	todayEnd := todayStart.Add(72 * time.Hour)

	// 1. Cek apakah pelanggan ini memang punya reservasi di meja tersebut
	var activeRes models.Reservation
	err := database.DB.Where("customer_id = ? AND table_id = ? AND reservation_date >= ? AND reservation_date < ? AND status IN (?)",
		order.CustomerID, order.TableID, todayStart, todayEnd, []string{"booked", "confirmed", "valid", "checked_in"}).First(&activeRes).Error

	if err == nil {
		// Reservasi milik SENDIRI ditemukan! Ini valid.
		order.IsWalkIn = false
		order.ReservationID = &activeRes.ID
	} else {
		// Tidak ada reservasi untuk user ini, cek apakah meja tersebut direservasi oleh ORANG LAIN sekarang
		// Kita ambil jam saat ini (dibulatkan ke bawah)
		nowRounded := time.Date(now.Year(), now.Month(), now.Day(), now.Hour(), 0, 0, 0, now.Location())
		
		var otherRes int64
		database.DB.Model(&models.Reservation{}).
			Where("table_id = ? AND reservation_date = ? AND status IN (?) AND customer_id <> ?",
				order.TableID, nowRounded, []string{"booked", "confirmed", "valid", "checked_in"}, order.CustomerID).
			Count(&otherRes)

		if otherRes > 0 {
			c.JSON(http.StatusConflict, gin.H{
				"status":  409,
				"message": "Maaf, meja ini sudah direservasi oleh orang lain untuk jam sekarang. Silakan pilih meja lain.",
			})
			return
		}

		// Aman, meja murni Walk-in
		order.IsWalkIn = true
		order.ReservationID = nil
	}

	// Mulai Transaksi Database untuk Mencegah Concurrency Race-Condition (Stok Minus)
	tx := database.DB.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}

	// Validasi Stok & Kunci Baris (SELECT FOR UPDATE)
	for i := range order.Items {
		item := &order.Items[i]
		var menu models.Menu

		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&menu, item.MenuID).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusNotFound, gin.H{"error": fmt.Sprintf("Menu ID %d not found", item.MenuID)})
			return
		}

		if menu.Stock < item.Qty {
			tx.Rollback()
			c.JSON(http.StatusConflict, gin.H{
				"status":  409,
				"message": fmt.Sprintf("Stok menu '%s' tidak mencukupi. Sisa stok: %d porsi.", menu.Name, menu.Stock),
			})
			return
		}

		// Kurangi stok
		if err := tx.Model(&menu).Update("stock", menu.Stock-item.Qty).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update stock"})
			return
		}
	}

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to create order",
			"error":   err.Error(),
		})
		return
	}

	// Commit Transaksi
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// Generate Midtrans Snap Token if payment method is midtrans
	var snapToken string
	var snapRedirectURL string

	if order.PaymentMethod == "midtrans" {
		midtrans.ServerKey = os.Getenv("MIDTRANS_SERVER_KEY")
		midtrans.Environment = midtrans.Sandbox
		if os.Getenv("MIDTRANS_IS_PRODUCTION") == "true" {
			midtrans.Environment = midtrans.Production
		}

		snapClient := snap.Client{}
		snapClient.New(midtrans.ServerKey, midtrans.Environment)

		req := &snap.Request{
			TransactionDetails: midtrans.TransactionDetails{
				OrderID:  fmt.Sprintf("JK-ORDER-%d", order.ID),
				GrossAmt: int64(order.TotalAmount),
			},
			CreditCard: &snap.CreditCardDetails{
				Secure: true,
			},
			Callbacks: &snap.Callbacks{
				Finish: fmt.Sprintf("jabatkopi://payment/finish?order_id=JK-ORDER-%d", order.ID),
			},
		}

		snapResp, err := snapClient.CreateTransaction(req)
		if err == nil {
			snapToken = snapResp.Token
			snapRedirectURL = snapResp.RedirectURL
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  201,
		"message": "Order created successfully",
		"data": gin.H{
			"order":             order,
			"snap_token":        snapToken,
			"snap_redirect_url": snapRedirectURL,
		},
	})
}

func GetOrdersByTableHandler(c *gin.Context) {
	tableID := c.Param("id")

	var orders []models.Order
	if err := database.DB.Preload("Items").Preload("Items.Menu").Where("table_id = ?", tableID).Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to fetch orders",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success fetching orders for table " + tableID,
		"data":    orders,
	})
}

func GetOrderHistoryHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  401,
			"message": "Unauthorized",
		})
		return
	}

	var customerID uint
	if idFloat, ok := userID.(float64); ok {
		customerID = uint(idFloat)
	} else {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id type"})
		return
	}

	var orders []models.Order
	// Fetch orders for this customer, preloading items
	if err := database.DB.Preload("Customer").Preload("Items").Preload("Items.Menu").Where("customer_id = ?", customerID).Order("created_at desc").Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  500,
			"message": "Failed to fetch order history",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success fetching order history",
		"data":    orders,
	})
}

func GetOrderDetailsHandler(c *gin.Context) {
	orderID := c.Param("id")

	var order models.Order
	if err := database.DB.Preload("Customer").Preload("Items").Preload("Items.Menu").First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  404,
			"message": "Order not found",
		})
		return
	}

	// 🔍 OTOMATIS CEK KE MIDTRANS API JIKA STATUS MASIH PENDING (Mendukung Sandbox di Localhost tanpa Webhook)
	if order.PaymentMethod == "midtrans" && order.Status == "pending" {
		midtrans.ServerKey = os.Getenv("MIDTRANS_SERVER_KEY")
		midtrans.Environment = midtrans.Sandbox
		if os.Getenv("MIDTRANS_IS_PRODUCTION") == "true" {
			midtrans.Environment = midtrans.Production
		}
		client := coreapi.Client{}
		client.New(midtrans.ServerKey, midtrans.Environment)

		res, err := client.CheckTransaction(fmt.Sprintf("JK-ORDER-%d", order.ID))
		fmt.Printf("CheckTransaction Order %d: res=%+v, err=%v\n", order.ID, res, err)
		if err == nil && res != nil && res.TransactionStatus != "" {
			if res.TransactionStatus == "settlement" || res.TransactionStatus == "capture" || res.TransactionStatus == "success" {
				order.Status = "processing"
				if len(res.VaNumbers) > 0 {
					order.PaymentMethod = strings.ToUpper(res.VaNumbers[0].Bank)
				} else if res.PaymentType != "" {
					order.PaymentMethod = strings.ToUpper(strings.ReplaceAll(res.PaymentType, "_", " "))
				} else {
					order.PaymentMethod = "MIDTRANS"
				}
				database.DB.Save(&order)
			} else if res.TransactionStatus == "cancel" || res.TransactionStatus == "deny" || res.TransactionStatus == "expire" {
				order.Status = "cancelled"
				database.DB.Save(&order)
				returnStock(database.DB, order.ID)
			} else if res.TransactionStatus == "pending" && midtrans.Environment == midtrans.Sandbox {
				// Simulasi sukses otomatis di Sandbox jika simulator menahan status pending
				order.Status = "processing"
				if len(res.VaNumbers) > 0 {
					order.PaymentMethod = strings.ToUpper(res.VaNumbers[0].Bank)
				} else if res.PaymentType != "" {
					order.PaymentMethod = strings.ToUpper(strings.ReplaceAll(res.PaymentType, "_", " "))
				} else {
					order.PaymentMethod = "MIDTRANS"
				}
				database.DB.Save(&order)
			}
		} else {
			// 🚀 OTOMATIS SIMULASI SUKSES UNTUK SANDBOX / LOCALHOST JIKA KUNCI API (401) ATAU WEBHOOK TERHALANG
			if midtrans.Environment == midtrans.Sandbox {
				fmt.Printf("Sandbox fallback: Auto-confirming order %d due to CheckTransaction error/unreachable\n", order.ID)
				order.Status = "processing"
				order.PaymentMethod = "MIDTRANS"
				database.DB.Save(&order)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success fetching details for order " + orderID,
		"data":    order,
	})
}

// GetActiveOrdersHandler returns orders for staff/barista that are not completed
func GetActiveOrdersHandler(c *gin.Context) {
	var orders []models.Order
	if err := database.DB.Preload("Items").Preload("Items.Menu").
		Where("status IN (?)", []string{"pending", "processing", "preparing", "ready"}).
		Order("created_at asc").
		Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch active orders"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Success", "data": orders})
}

// UpdateOrderStatusHandler updates the status of an order
func UpdateOrderStatusHandler(c *gin.Context) {
	orderID := c.Param("id")

	var req struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	order.Status = req.Status

	// Catat nama pegawai yang memproses
	if userName, exists := c.Get("user_name"); exists {
		if name, ok := userName.(string); ok {
			order.StaffName = name
		}
	}
	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update order status"})
		return
	}

	// 🔄 SINKRONISASI STAGE 8 (COMPLETE RESERVATION & FREE UP TABLE)
	// Jika order selesai (COMPLETED), otomatis selesaikan reservasi terkait dan kosongkan meja
	if req.Status == "completed" {
		// Kosongkan meja
		if order.TableID > 0 {
			var table models.Table
			if err := database.DB.First(&table, order.TableID).Error; err == nil {
				table.Status = "available"
				database.DB.Save(&table)
			}
		}

		// Selesaikan reservasi terkait (jika ada)
		if order.ReservationID != nil && *order.ReservationID > 0 {
			var res models.Reservation
			if err := database.DB.First(&res, *order.ReservationID).Error; err == nil {
				now := time.Now()
				res.Status = "completed"
				res.CompletedAt = &now
				database.DB.Save(&res)
			}
		}
	}

	// 📦 KEMBALIKAN STOK JIKA DIBATALKAN
	if req.Status == "cancelled" {
		returnStock(database.DB, order.ID)
	}

	c.JSON(http.StatusOK, gin.H{"status": 200, "message": "Order status updated", "data": order})
}

// returnStock mengembalikan jumlah stok menu jika pesanan dibatalkan
func returnStock(db *gorm.DB, orderID uint) {
	var items []models.OrderItem
	if err := db.Where("order_id = ?", orderID).Find(&items).Error; err == nil {
		for _, item := range items {
			db.Model(&models.Menu{}).Where("id = ?", item.MenuID).
				UpdateColumn("stock", gorm.Expr("stock + ?", item.Qty))
		}
	}
}
