# Dokumentasi API Jabat Kopi ☕️

**Base URL:**
- Local: `http://localhost:8000/api`
- Production: `https://jabatkopi.my.id/api`

**Format Response Global:**
```json
{
  "status": 200,
  "message": "Success message here",
  "data": { ... }
}
```

**Header Autentikasi (untuk endpoint yang membutuhkan login):**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

---

## 🔐 1. Authentication

### POST `/auth/login`
Login user dan dapatkan token.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": 200,
  "message": "Login successful",
  "data": {
    "token": "1|abc123...",
    "user": {
      "id": 1,
      "name": "Nama User",
      "email": "user@example.com",
      "role": "customer"
    }
  }
}
```

---

### POST `/auth/register`
Registrasi akun baru.

**Body:**
```json
{
  "name": "Nama User",
  "username": "namauser",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

---

### GET `/profile` *(Auth Required)*
Ambil data profil user yang sedang login.

### PUT `/profile` *(Auth Required)*
Update profil user.

**Body:**
```json
{
  "name": "Nama Baru",
  "username": "username_baru",
  "email": "email@baru.com",
  "image_url": "data:image/jpeg;base64,/9j/..."
}
```

### PUT `/profile/password` *(Auth Required)*
Ganti password.

**Body:**
```json
{
  "current_password": "passwordlama",
  "password": "passwordbaru",
  "password_confirmation": "passwordbaru"
}
```

---

## 🍽 2. Menus

### GET `/menus`
Ambil semua menu yang tersedia. **Tidak perlu login.**

**Response:**
```json
{
  "status": 200,
  "data": [
    {
      "id": 1,
      "name": "Es Kopi Susu",
      "description": "Kopi susu segar",
      "price": 22000,
      "stock": 50,
      "category": "drinks",
      "image_url": "https://jabatkopi.my.id/api/images/menus/kopi.jpg"
    }
  ]
}
```

---

## 🪑 3. Tables (Meja)

### GET `/tables`
Ambil semua meja. **Tidak perlu login.**

### GET `/tables/with-reservations`
Ambil semua meja beserta data reservasi aktif. **Tidak perlu login.**

### GET `/tables/available` *(Auth Required)*
Ambil meja yang tersedia (belum direservasi hari ini).

---

## 📅 4. Reservations *(Auth Required)*

### POST `/reservations`
Buat reservasi meja baru.

**Body:**
```json
{
  "table_id": 3,
  "reservation_date": "2026-07-20",
  "time_slot": "13:00",
  "pax": 2,
  "notes": "Butuh kursi tinggi untuk anak"
}
```

### GET `/reservations` atau `/reservations/history`
Ambil riwayat semua reservasi milik user yang login.

### GET `/reservations/active`
Ambil reservasi aktif hari ini (status: `checked_in`). Digunakan untuk deteksi meja saat checkout.

**Response:**
```json
{
  "status": 200,
  "data": {
    "reservation_id": 12,
    "table_id": 3,
    "table_ref": "Meja 3",
    "status": "checked_in"
  }
}
```

### PUT `/reservations/{id}/cancel`
Batalkan reservasi.

---

## 🛒 5. Orders & Pembayaran *(Auth Required)*

### POST `/orders`
Buat pesanan baru terintegrasi dengan **Midtrans Payment Gateway**.

**Body:**
```json
{
  "table_id": 3,
  "payment_method": "bank_transfer_bca",
  "items": [
    { "menu_id": 1, "qty": 2 },
    { "menu_id": 5, "qty": 1 }
  ]
}
```

**Daftar `payment_method` yang valid:**

| Nilai | Keterangan |
|-------|-----------|
| `cash` | Bayar tunai (tidak via Midtrans) |
| `bank_transfer_bca` | Virtual Account BCA |
| `bank_transfer_bni` | Virtual Account BNI |
| `bank_transfer_bri` | Virtual Account BRI |
| `bank_transfer_mandiri` | Mandiri Bill (echannel) |
| `bank_transfer_permata` | Virtual Account Permata |
| `cstore_alfamart` | Gerai Alfamart |
| `cstore_indomaret` | Gerai Indomaret |
| `gopay` | GoPay (deeplink) |
| `shopeepay` | ShopeePay (deeplink) |
| `qris` | QRIS (scan QR) |

**Response (contoh Virtual Account BCA):**
```json
{
  "status": 201,
  "message": "Order created successfully",
  "data": {
    "order": {
      "id": 42,
      "status": "pending"
    },
    "payment_details": {
      "va_number": "15836253539889052277409",
      "bank": "bca"
    },
    "snap_token": "",
    "snap_redirect_url": ""
  }
}
```

**Response (contoh Mandiri Bill):**
```json
{
  "payment_details": {
    "biller_code": "70012",
    "bill_key": "990000000260"
  }
}
```

**Response (contoh Alfamart/Indomaret):**
```json
{
  "payment_details": {
    "payment_code": "ALFACODE123"
  }
}
```

**Response (contoh GoPay/ShopeePay):**
```json
{
  "payment_details": {
    "deeplink_url": "gojek://gopay/...",
    "qr_url": "https://api.midtrans.com/v2/qr-code/..."
  }
}
```

---

### GET `/orders/history`
Ambil riwayat semua pesanan milik user yang login, beserta detail item.

**Response:**
```json
{
  "status": 200,
  "data": [
    {
      "id": 42,
      "status": "pending",
      "total_amount": 44000,
      "payment_method": "bank_transfer_bca",
      "payment_details": {
        "va_number": "15836253539889052277409",
        "bank": "bca"
      },
      "created_at": "2026-07-15 10:00:00",
      "items": [
        {
          "id": 1,
          "menu_id": 1,
          "qty": 2,
          "subtotal": 44000,
          "menu_name": "Es Kopi Susu",
          "image_url": "https://jabatkopi.my.id/api/images/menus/kopi.jpg"
        }
      ]
    }
  ]
}
```

---

### GET `/orders/active`
Ambil pesanan dengan status `pending`, `processing`, atau `ready` milik user.

### GET `/orders/table/{tableId}`
Ambil pesanan aktif (`pending`, `processing`) pada meja tertentu.

### GET `/orders/{id}/details`
Ambil detail pesanan + sync status pembayaran terbaru dari Midtrans secara otomatis.

### PUT `/orders/{id}/status`
Update status pesanan (biasanya digunakan oleh admin/staff).

**Body:**
```json
{ "status": "completed" }
```

**Status yang valid:** `pending` → `processing` → `preparing` → `ready` → `completed` | `cancelled`

### PUT `/orders/{id}/cancel`
Batalkan pesanan.

---

## 🛡 6. Admin Endpoints *(Auth Required + Role: admin)*

### Menus
- `POST /admin/menus` — Tambah menu baru
- `PUT /admin/menus/{id}` — Edit menu
- `DELETE /admin/menus/{id}` — Hapus menu

### Tables
- `GET /admin/tables` — Semua meja
- `POST /admin/tables` — Tambah meja
- `PUT /admin/tables/{id}` — Edit meja
- `DELETE /admin/tables/{id}` — Hapus meja
- `PUT /admin/tables/{id}/status` — Ubah status meja (`available`, `occupied`, `reserved`)

### Reservations
- `GET /admin/reservations` — Semua reservasi
- `PUT /admin/reservations/{id}/status` — Update status reservasi
- `PUT /admin/reservations/{id}/arrive` — Tandai pelanggan tiba (`checked_in`)
- `PUT /admin/reservations/{id}/complete` — Tandai reservasi selesai (`completed`)

### Users
- `GET /admin/users` — Semua user terdaftar
- `POST /admin/users` — Tambah user
- `PUT /admin/users/{id}` — Edit user
- `DELETE /admin/users/{id}` — Hapus user

### Analytics
- `GET /admin/analytics` — Statistik ringkas

**Response:**
```json
{
  "status": 200,
  "data": {
    "revenue": 1250000,
    "orders": 57,
    "reservations": 24
  }
}
```

---

## 🖼 7. Image Proxy

Untuk menghindari error CORS pada Flutter Web, semua URL gambar menu diakses melalui proxy bawaan API.

### GET `/images/menus/{filename}`
Ambil file gambar menu dengan CORS headers yang benar.

- **Contoh:** `https://jabatkopi.my.id/api/images/menus/kopi.jpg`
- Jika gambar tidak ditemukan, mengembalikan pixel transparan 1x1 (agar Flutter tidak crash).
- Di environment `local`, otomatis memproxy dari production server.

---

## ⚠️ Error Codes

| HTTP Code | Keterangan |
|-----------|-----------|
| `200` | Berhasil |
| `201` | Data berhasil dibuat |
| `401` | Unauthorized (token tidak ada/expired) |
| `403` | Forbidden (role tidak cukup) |
| `404` | Data tidak ditemukan |
| `422` | Validasi gagal |
| `500` | Server error |
