package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

func GetNotificationsHandler(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var notifications []models.Notification
	
	// Ambil notifikasi milik user, urutkan dari yang terbaru
	database.DB.Where("customer_id = ?", userID).Order("created_at desc").Find(&notifications)

	// Jika notifikasi kosong, buatkan notifikasi sambutan default
	if len(notifications) == 0 {
		welcome := models.Notification{
			CustomerID: userID.(uint),
			Title:      "Selamat Datang!",
			Body:       "Terima kasih telah bergabung dengan Jabat Kopi. Nikmati kopi terbaik kami!",
			Type:       "promo",
		}
		database.DB.Create(&welcome)
		notifications = append(notifications, welcome)
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Success",
		"data":    notifications,
	})
}

func MarkNotificationReadHandler(c *gin.Context) {
	id := c.Param("id")
	database.DB.Model(&models.Notification{}).Where("id = ?", id).Update("is_read", true)
	c.JSON(http.StatusOK, gin.H{"message": "Notification marked as read"})
}

// Helper untuk kirim notifikasi (bisa dipanggil dari handler lain)
func SendNotification(customerID uint, title, body, nType string) {
	notif := models.Notification{
		CustomerID: customerID,
		Title:      title,
		Body:       body,
		Type:       nType,
	}
	database.DB.Create(&notif)
}
