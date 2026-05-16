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

func TestLoginHandler_Success(t *testing.T) {
	// Setup Router
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.POST("/api/v1/auth/login", LoginHandler)

	// Mock Body
	body := map[string]string{
		"username": "johndoe",
		"password": "password123",
	}
	jsonBody, _ := json.Marshal(body)

	// Perform Request
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// Assertions
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, float64(200), response["status"])
	assert.Equal(t, "Success", response["message"])

	data := response["data"].(map[string]interface{})
	assert.NotEmpty(t, data["token"])
	assert.Equal(t, "customer", data["role"])
}

func TestLoginHandler_Fail_InvalidPayload(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.POST("/api/v1/auth/login", LoginHandler)

	// Missing password
	body := map[string]string{
		"username": "johndoe",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}
