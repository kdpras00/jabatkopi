package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID           uint           `gorm:"primarykey" json:"id"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
	Name         string         `json:"name"`
	Username     string         `gorm:"uniqueIndex;index:idx_user_username;not null" json:"username"` 
	Email        string         `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string         `json:"-"`
	ImageURL     string         `json:"image_url"`
	Role         string         `gorm:"default:'customer'" json:"role"`
}

type Notification struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	CreatedAt  time.Time      `json:"created_at"`
	CustomerID uint           `gorm:"index" json:"customer_id"`
	Title      string         `json:"title"`
	Body       string         `json:"body"`
	Type       string         `json:"type"` // promo, order, reservation
	IsRead     bool           `gorm:"default:false" json:"is_read"`
}

type Menu struct {
	ID          uint           `gorm:"primarykey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Name        string         `json:"name"`
	Category    string         `gorm:"index:idx_menu_category" json:"category"` // Indeks kategori untuk filter menu
	Price       float64        `json:"price"`
	ImageURL    string         `json:"image_url"`
	IsAvailable bool           `gorm:"index:idx_menu_avail;default:true" json:"is_available"` // Indeks ketersediaan
	Stock       int            `gorm:"default:50" json:"stock"` // Default 50 porsi untuk pencegahan stok minus
}

type Table struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
	QRCodeRef  string         `gorm:"uniqueIndex" json:"qr_code_ref"`
	Capacity   int            `gorm:"default:4" json:"capacity"` // Kapasitas meja (misal 2, 4, 6 orang)
	Status     string         `gorm:"default:'available'" json:"status"` // available, occupied
}

type Reservation struct {
	ID              uint           `gorm:"primarykey" json:"id"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
	CustomerID      uint           `gorm:"index" json:"customer_id"`
	Customer        User           `gorm:"foreignKey:CustomerID" json:"-"`
	TableID         uint           `gorm:"index" json:"table_id"`
	Table           Table          `gorm:"foreignKey:TableID" json:"-"`
	ReservationDate time.Time      `gorm:"index:idx_res_date_status" json:"reservation_date"` // Composite index untuk cron job cepat
	TimeStart       time.Time      `json:"time_start"` // e.g. 12:00
	TimeEnd         time.Time      `json:"time_end"`   // e.g. 13:00
	Pax             int            `json:"pax"`        // Jumlah tamu
	Barcode         string         `gorm:"uniqueIndex" json:"barcode"` // QR code untuk check-in
	Status          string         `gorm:"index:idx_res_date_status;default:'booked'" json:"status"` // booked, checked_in, completed, cancelled, no_show
	CheckedInAt     *time.Time     `json:"checked_in_at"` // Waktu actual check-in
	CompletedAt     *time.Time     `json:"completed_at"`  // Waktu selesai
}

type Order struct {
	ID            uint           `gorm:"primarykey" json:"id"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`
	CustomerID    uint           `gorm:"index" json:"customer_id"`
	Customer      User           `gorm:"foreignKey:CustomerID" json:"-"`
	TableID       uint           `json:"table_id"`
	Table         Table          `gorm:"foreignKey:TableID" json:"-"`
	IsWalkIn      bool           `gorm:"default:true" json:"is_walk_in"`
	ReservationID *uint          `json:"reservation_id"`
	Reservation   *Reservation   `gorm:"foreignKey:ReservationID" json:"-"`
	TotalAmount   float64        `json:"total_amount"`
	Status        string         `gorm:"default:'pending'" json:"status"` // pending, processing, paid, completed
	PaymentMethod string         `json:"payment_method"` // cash, qris, midtrans
	StaffName     string         `json:"staff_name"`     // Nama pegawai yang memproses
	Items         []OrderItem    `gorm:"foreignKey:OrderID" json:"items"`
}

type OrderItem struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	OrderID   uint           `json:"order_id"`
	Order     Order          `gorm:"foreignKey:OrderID" json:"-"`
	MenuID    uint           `json:"menu_id"`
	Menu      Menu           `gorm:"foreignKey:MenuID" json:"menu"`
	Qty       int            `json:"qty"`
	Subtotal  float64        `json:"subtotal"`
}

type Payment struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	OrderID   uint           `json:"order_id"`
	Order     Order          `gorm:"foreignKey:OrderID" json:"-"`
	Provider  string         `json:"provider"` // midtrans, cash
	Status    string         `gorm:"default:'pending'" json:"status"` // pending, success, failed
}
