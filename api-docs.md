# Dokumentasi API Jabat Kopi ☕️

Base URL: `http://localhost:8000/api` atau `https://jabatkopi.my.id/api` (sesuaikan dengan environment)

Format Response Global:
```json
{
  "status": 200,
  "message": "Success message here",
  "data": { ... } 
}
```

Semua API yang membutuhkan autentikasi harus mengirimkan header:
`Authorization: Bearer {token}`

---

## 🔐 1. Authentication

### Login
- **URL**: `/auth/login`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**: Mengembalikan data user beserta `access_token`.

### Register
- **URL**: `/auth/register`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "name": "Nama User",
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
  ```

### Profile (Auth Required)
- **Get Profile**: `GET /profile`
- **Update Profile**: `PUT /profile`
- **Update Password**: `PUT /profile/password`

---

## 🍽 2. Menus (Menu Kopi/Makanan)

### Get All Menus
- **URL**: `/menus`
- **Method**: `GET`
- **Response**: Menampilkan semua menu yang tersedia.

---

## 🪑 3. Tables (Meja)

### Get All Tables
- **URL**: `/tables`
- **Method**: `GET`

### Get Tables with active reservations
- **URL**: `/tables/with-reservations`
- **Method**: `GET`

### Get Available Tables (Auth Required)
- **URL**: `/tables/available`
- **Method**: `GET`

---

## 📅 4. Reservations (Reservasi Meja) - Auth Required

### Create Reservation
- **URL**: `/reservations`
- **Method**: `POST`
- **Body**: Parameter reservasi seperti `table_id`, `reservation_date`, `pax`, dll.

### Reservation History
- **URL**: `/reservations/history` ATAU `/reservations`
- **Method**: `GET`

### Active Reservations
- **URL**: `/reservations/active`
- **Method**: `GET`

### Cancel Reservation
- **URL**: `/reservations/{id}/cancel`
- **Method**: `PUT`

---

## 🛒 5. Orders (Pemesanan) - Auth Required

### Create Order & Payment
Endpoint ini terintegrasi dengan Midtrans untuk pembuatan pembayaran (Bank Transfer, QRIS, e-Wallet).
- **URL**: `/orders`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "table_id": 1,
    "payment_method": "qris", // atau: bank_transfer_bca, gopay, shopeepay, dll
    "items": [
      {
        "menu_id": 2,
        "qty": 2
      }
    ]
  }
  ```
- **Response**: Mengembalikan order id dan url pembayaran Midtrans atau QRIS.

### Order History
- **URL**: `/orders/history`
- **Method**: `GET`
- **Response**: List semua pesanan dari user tersebut beserta item pesanan.

### Active Orders
- **URL**: `/orders/active`
- **Method**: `GET`

### Order Details & Sync Status
Endpoint ini juga akan mengecek status pembayaran terbaru ke Midtrans dan mengupdate ke sistem.
- **URL**: `/orders/{id}/details`
- **Method**: `GET`

### Update Order Status
- **URL**: `/orders/{id}/status`
- **Method**: `PUT`
- **Body**:
  ```json
  {
    "status": "completed"
  }
  ```

### Cancel Order
- **URL**: `/orders/{id}/cancel`
- **Method**: `PUT`

---

## 🛡 6. Admin Endpoints (Auth + Role Admin Required)

Endpoint khusus untuk panel Admin:

**Menus CRUD:**
- `POST /admin/menus` (Create menu)
- `PUT /admin/menus/{id}` (Update menu)
- `DELETE /admin/menus/{id}` (Hapus menu)

**Tables CRUD:**
- `GET /admin/tables`
- `POST /admin/tables`
- `PUT /admin/tables/{id}`
- `DELETE /admin/tables/{id}`
- `PUT /admin/tables/{id}/status` (Ubah status meja)

**Reservations Management:**
- `GET /admin/reservations`
- `PUT /admin/reservations/{id}/status`
- `PUT /admin/reservations/{id}/arrive` (Tandai pelanggan tiba)
- `PUT /admin/reservations/{id}/complete` (Selesaikan reservasi)

**Analytics:**
- `GET /admin/analytics` (Mockup dashboard statistik pendapatan)

---

## 🖼 7. Images Proxy

Karena issue terkait CanvasKit pada Flutter Web saat mengakses gambar beda origin (CORS), tersedia proxy image bawaan dari API.
- **URL**: `/images/menus/{filename}`
- **Method**: `GET`
- **Catatan**: Gunakan endpoint ini di aplikasi Flutter untuk meload `image_url` dari menu agar tidak terkena _CORS Error_. Jika berjalan di local, API secara otomatis akan memproxy gambar dari production server (`jabatkopi.my.id`).
