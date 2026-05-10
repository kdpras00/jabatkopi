package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/handlers"
	"github.com/jabatkopi/backend/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 1. Initialize Database (Mock DSN)
	dsn := "host=localhost user=postgres password=postgres dbname=jabatkopi port=5432 sslmode=disable"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Println("Failed to connect to database, but continuing for skeleton/mocking purposes")
	} else {
		// 2. Auto Migrate Schema
		db.AutoMigrate(
			&models.User{},
			&models.Menu{},
			&models.Table{},
			&models.Reservation{},
			&models.Order{},
			&models.Payment{},
		)
	}

	// 3. Setup Gin Router
	r := gin.Default()

	// 4. Setup Routes
	v1 := r.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/login", handlers.LoginHandler)
			// auth.POST("/register", handlers.RegisterHandler)
		}
	}

	// 5. Run Server
	r.Run(":8080")
}
