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
	Username     string         `gorm:"uniqueIndex;not null" json:"username"`
	Email        string         `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string         `json:"-"`
	Role         string         `gorm:"default:'customer'" json:"role"` // admin, pegawai, customer
}

type Menu struct {
	ID          uint           `gorm:"primarykey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Name        string         `json:"name"`
	Category    string         `json:"category"`
	Price       float64        `json:"price"`
	ImageURL    string         `json:"image_url"`
	IsAvailable bool           `gorm:"default:true" json:"is_available"`
}

type Table struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
	QRCodeRef  string         `gorm:"uniqueIndex" json:"qr_code_ref"`
	Status     string         `gorm:"default:'available'" json:"status"` // available, occupied
}

type Reservation struct {
	ID              uint           `gorm:"primarykey" json:"id"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
	CustomerID      uint           `json:"customer_id"`
	Customer        User           `gorm:"foreignKey:CustomerID" json:"-"`
	TableID         uint           `json:"table_id"`
	Table           Table          `gorm:"foreignKey:TableID" json:"-"`
	ReservationDate time.Time      `json:"reservation_date"`
	Pax             int            `json:"pax"`
	Status          string         `gorm:"default:'pending'" json:"status"` // pending, valid, checked_in
}

type Order struct {
	ID            uint           `gorm:"primarykey" json:"id"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`
	CustomerID    uint           `json:"customer_id"`
	Customer      User           `gorm:"foreignKey:CustomerID" json:"-"`
	TableID       uint           `json:"table_id"`
	Table         Table          `gorm:"foreignKey:TableID" json:"-"`
	TotalAmount   float64        `json:"total_amount"`
	Status        string         `gorm:"default:'pending'" json:"status"` // pending, processing, completed
	PaymentMethod string         `json:"payment_method"` // cash, qris
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
