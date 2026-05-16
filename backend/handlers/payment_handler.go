package handlers

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/models"
)

func MidtransWebhookHandler(c *gin.Context) {
	var payload map[string]interface{}

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  400,
			"message": "Invalid webhook payload",
		})
		return
	}

	if transactionStatus, ok := payload["transaction_status"].(string); ok {
		if orderIDStr, ok := payload["order_id"].(string); ok {
			parts := strings.Split(orderIDStr, "-")
			if len(parts) == 3 {
				dbOrderID := parts[2]

				var order models.Order
				if err := database.DB.First(&order, dbOrderID).Error; err == nil {
					// Update specific payment method if found in payload
					if payType, ok := payload["payment_type"].(string); ok {
						paymentDesc := payType
						if payType == "bank_transfer" {
							if vaNumbers, ok := payload["va_numbers"].([]interface{}); ok && len(vaNumbers) > 0 {
								if firstVA, ok := vaNumbers[0].(map[string]interface{}); ok {
									if bank, ok := firstVA["bank"].(string); ok {
										paymentDesc = fmt.Sprintf("%s (%s)", payType, strings.ToUpper(bank))
									}
								}
							}
						}
						order.PaymentMethod = strings.ReplaceAll(paymentDesc, "_", " ")
					}

					if transactionStatus == "settlement" || transactionStatus == "capture" {
						order.Status = "processing"
						database.DB.Save(&order)
					} else if transactionStatus == "cancel" || transactionStatus == "deny" || transactionStatus == "expire" {
						order.Status = "cancelled"
						database.DB.Save(&order)
					}
				} else {
					fmt.Println("Webhook: Order not found:", dbOrderID)
				}
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"status":  200,
			"message": "Webhook processed successfully",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "Webhook received, but status is not settlement",
	})
}
