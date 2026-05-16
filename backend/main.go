package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jabatkopi/backend/database"
	"github.com/jabatkopi/backend/handlers"
	"github.com/jabatkopi/backend/middleware"
	"github.com/jabatkopi/backend/models"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func init() {
	godotenv.Load()
}

func main() {
	// 1. Initialize Database from .env
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=require",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Println("[error] failed to initialize database, got error", err)
	} else {
		// Set global DB instance
		database.DB = db

		// 2. Auto Migrate Schema
		db.AutoMigrate(
			&models.User{},
			&models.Menu{},
			&models.Table{},
			&models.Reservation{},
			&models.Order{},
			&models.OrderItem{},
			&models.Payment{},
		)

		// 2b. Jalankan Background Scheduler (Pembersih Reservasi Kadaluarsa)
		go func() {
			ticker := time.NewTicker(1 * time.Minute)
			for range ticker.C {
				var expiredReservations []models.Reservation
				cutoff := time.Now().Add(-45 * time.Minute)
				
				// 1. Cari reservasi yang telat
				database.DB.Where("reservation_date < ? AND status = ?", cutoff, "booked").Find(&expiredReservations)
				
				if len(expiredReservations) > 0 {
					for _, res := range expiredReservations {
						// 2. Batalkan Reservasi
						database.DB.Model(&res).Update("status", "cancelled")
						
						// 3. Bebaskan Meja
						database.DB.Model(&models.Table{}).Where("id = ?", res.TableID).Update("status", "available")
					}
					log.Printf("[scheduler] Berhasil membatalkan %d reservasi kadaluarsa", len(expiredReservations))
				}
			}
		}()
	}

	// 3. Setup Gin Router
	r := gin.Default()

	// 4. Setup CORS Middleware
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// 5. Setup Routes
	v1 := r.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/login", handlers.LoginHandler)
			auth.POST("/register", handlers.RegisterHandler)
		}
		
		menus := v1.Group("/menus")
		{
			menus.GET("", handlers.GetMenusHandler)
		}
		
		orders := v1.Group("/orders")
		orders.Use(middleware.RequireAuth())
		{
			orders.POST("", handlers.CreateOrderHandler)
			orders.GET("/history", handlers.GetOrderHistoryHandler)
			orders.GET("/active", handlers.GetActiveOrdersHandler)
			orders.GET("/table/:id", handlers.GetOrdersByTableHandler)
			orders.GET("/:id/details", handlers.GetOrderDetailsHandler)
			orders.PUT("/:id/status", handlers.UpdateOrderStatusHandler)
		}
		
		tables := v1.Group("/tables")
		{
			tables.GET("", handlers.GetTablesHandler)
			tables.GET("/available", handlers.CheckAvailabilityHandler)
			tables.GET("/status", handlers.GetTablesWithStatusHandler)
		}
		
		reservations := v1.Group("/reservations")
		reservations.Use(middleware.RequireAuth())
		{
			reservations.POST("", handlers.CreateReservationHandler)
			reservations.GET("/active", handlers.GetActiveReservationHandler)
			reservations.GET("/history", handlers.GetReservationHistoryHandler)
			reservations.PUT("/:id/cancel", handlers.CancelReservationHandler)
		}
		
		payments := v1.Group("/payments")
		{
			payments.POST("/webhook/midtrans", handlers.MidtransWebhookHandler)
		}

		profile := v1.Group("/profile")
		profile.Use(middleware.RequireAuth())
		{
			profile.GET("", handlers.GetProfileHandler)
			profile.PUT("", handlers.UpdateProfileHandler)
			profile.PUT("/password", handlers.ChangePasswordHandler)
		}

		v1.GET("/notifications", middleware.RequireAuth(), handlers.GetNotificationsHandler)

		admin := v1.Group("/admin")
		admin.Use(middleware.RequireAuth())
		admin.Use(middleware.RequireRole("admin", "pegawai"))
		{
			admin.GET("/analytics", handlers.GetAdminAnalyticsHandler)
			
			// Menu Management
			admin.POST("/menus", handlers.CreateMenuHandler)
			admin.PUT("/menus/:id", handlers.UpdateMenuHandler)
			admin.DELETE("/menus/:id", handlers.DeleteMenuHandler)

			// User/Account Management
			admin.GET("/users", handlers.GetUsersHandler)
			admin.POST("/users", handlers.CreateUserHandler)
			admin.PUT("/users/:id", handlers.UpdateUserHandler)
			admin.DELETE("/users/:id", handlers.DeleteUserHandler)

			// Table Management
			admin.POST("/tables", handlers.CreateTableHandler)
			admin.POST("/tables/seed", handlers.SeedTablesHandler)
			admin.PUT("/tables/:id/status", handlers.UpdateTableStatusHandler)

			// Reservation Verification
			admin.GET("/reservations", handlers.GetAdminReservationsHandler)
			admin.PUT("/reservations/:id/arrive", handlers.VerifyReservationArrivalHandler)
			admin.PUT("/reservations/:id/complete", handlers.CompleteReservationByStaffHandler)
		}
	}

	// 5. Run Server
	r.Run(":8080")
}
