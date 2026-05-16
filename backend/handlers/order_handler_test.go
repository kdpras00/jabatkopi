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

func TestOrderHandler_Create(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.POST("/api/v1/orders", CreateOrderHandler)

	body := map[string]interface{}{
		"table_id":       4,
		"customer_id":    1,
		"total_amount":   30000,
		"payment_method": "qris",
		"items": []map[string]interface{}{
			{
				"menu_id":  1,
				"qty":      2,
				"subtotal": 30000,
			},
		},
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/orders", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
}

func TestOrderHandler_GetByTable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.GET("/api/v1/orders/table/:id", GetOrdersByTableHandler)

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/orders/table/4", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestOrderHandler_GetDetails(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.GET("/api/v1/orders/:id/details", GetOrderDetailsHandler)

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/orders/101/details", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}
