package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestPaymentWebhookHandler_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.POST("/api/v1/payments/webhook/midtrans", MidtransWebhookHandler)

	body := map[string]interface{}{
		"transaction_time":   "2023-01-01 10:00:00",
		"transaction_status": "settlement",
		"transaction_id":     "57d5293c-e65f-4a29-9ce4-d222aa410d9e",
		"status_message":     "midtrans payment notification",
		"status_code":        "200",
		"signature_key":      "mock_signature",
		"payment_type":       "qris",
		"order_id":           "101",
		"merchant_id":        "G123456",
		"gross_amount":       "30000.00",
		"fraud_status":       "accept",
		"currency":           "IDR",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/payments/webhook/midtrans", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}
