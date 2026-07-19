<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\ReservationController;
use App\Http\Controllers\Api\WaitingListController;

// Rate-limited: max 10 requests per menit per IP untuk mencegah brute-force & spam
Route::middleware(['throttle:10,1'])->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/register', [AuthController::class, 'register']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::put('/profile/password', [AuthController::class, 'updatePassword']);
    // Endpoint untuk update FCM token dari Flutter (dipanggil setiap login)
    Route::put('/profile/fcm-token', [AuthController::class, 'updateFcmToken']);
});

// --- WAITING LIST (Customer) ---
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/waiting-list', [WaitingListController::class, 'join']);
    Route::get('/waiting-list/my', [WaitingListController::class, 'myStatus']);
    Route::put('/waiting-list/{id}/cancel', [WaitingListController::class, 'cancelMy']);
});

Route::get('/menus', [MenuController::class, 'index']);

Route::get('/tables', [TableController::class, 'index']);

Route::get('/tables/with-reservations', [TableController::class, 'getWithReservations']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/reservations', [ReservationController::class, 'index']);
    Route::get('/reservations/history', [ReservationController::class, 'index']); // endpoint mapping for Flutter
    Route::post('/reservations', [ReservationController::class, 'store']);
    Route::put('/reservations/{id}/cancel', [ReservationController::class, 'cancel']);
    
    Route::post('/orders', [OrderController::class, 'create']);
    Route::get('/orders/history', [OrderController::class, 'history']);
    Route::get('/orders/active', [OrderController::class, 'active']);
    Route::get('/reservations/active', [ReservationController::class, 'active']);
});


// --- ORDER ENDPOINTS (Auth Protected) ---
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/orders/table/{tableId}', [OrderController::class, 'byTable']);
    Route::get('/orders/{id}/details', [OrderController::class, 'details']);
    Route::put('/orders/{id}/status', [OrderController::class, 'updateStatus']);
    Route::put('/orders/{id}/cancel', [OrderController::class, 'cancel']);
});

// Tables (public read)
Route::get('/tables/available', [TableController::class, 'available']);

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    // Menus
    Route::post('/admin/menus', [MenuController::class, 'store']);
    Route::put('/admin/menus/{id}', [MenuController::class, 'update']);
    Route::delete('/admin/menus/{id}', [MenuController::class, 'destroy']);
    
    // Tables
    Route::post('/admin/tables', [TableController::class, 'store']);
    Route::put('/admin/tables/{id}', [TableController::class, 'update']);
    Route::delete('/admin/tables/{id}', [TableController::class, 'destroy']);
    Route::get('/admin/tables/with-reservations', [TableController::class, 'getWithReservations']);
    Route::get('/admin/tables', [TableController::class, 'index']);
    Route::put('/admin/tables/{id}/status', [TableController::class, 'updateStatus']);

    // Waiting List (Admin)
    Route::get('/admin/waiting-list', [WaitingListController::class, 'adminIndex']);
    Route::put('/admin/waiting-list/{id}/notify', [WaitingListController::class, 'notify']);
    Route::put('/admin/waiting-list/{id}/seat', [WaitingListController::class, 'seat']);
    Route::put('/admin/waiting-list/{id}/expire', [WaitingListController::class, 'expire']);
    
    // Reservations
    Route::get('/admin/reservations', [ReservationController::class, 'adminIndex']);
    Route::put('/admin/reservations/{id}/status', [ReservationController::class, 'updateStatus']);
    Route::put('/admin/reservations/{id}/arrive', function($id) {
        DB::table('reservations')->where('id', $id)->update(['status' => 'checked_in']);
        event(new \App\Events\ReservationCreated());
        return response()->json(['status' => 200]);
    });
    Route::put('/admin/reservations/{id}/complete', function($id) {
        DB::table('reservations')->where('id', $id)->update(['status' => 'completed']);
        event(new \App\Events\ReservationCreated());
        return response()->json(['status' => 200]);
    });
    
    // Users & Analytics (Mocks)
    Route::get('/admin/users', function() {
        return response()->json(['status' => 200, 'data' => DB::table('users')->get()]);
    });
    Route::post('/admin/users', function(\Illuminate\Http\Request $request) {
        return response()->json(['status' => 201]);
    });
    Route::put('/admin/users/{id}', function(\Illuminate\Http\Request $request, $id) {
        return response()->json(['status' => 200]);
    });
    Route::delete('/admin/users/{id}', function($id) {
        return response()->json(['status' => 200]);
    });
    Route::get('/admin/analytics', function() {
        return response()->json(['status' => 200, 'data' => [
            'revenue' => DB::table('orders')->sum('total_amount') ?? 0,
            'orders' => DB::table('orders')->count(),
            'reservations' => DB::table('reservations')->count()
        ]]);
    });
});

// --- PONYTAIL: CORS IMAGE PROXY ---
// Serve images with CORS headers to satisfy CanvasKit renderer without needing --web-renderer html
// If image is missing, serve a transparent 1x1 pixel so CanvasKit doesn't crash trying to decode a 404 HTML page!
Route::get('/images/menus/{filename}', function($filename) {
    if ($filename === 'default-menu.png') {
        $path = storage_path('app/public/images/' . $filename);
    } else {
        $path = storage_path('app/public/menus/' . $filename);
    }
    
    if (!file_exists($path)) {
        // Proxy dari production supaya tidak ada cross-origin redirect
        if (config('app.env') === 'local') {
            $url = 'https://jabatkopi.my.id/storage/menus/' . $filename;
            $imageData = @file_get_contents($url);
            if ($imageData !== false) {
                $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
                $mime = in_array($ext, ['png']) ? 'image/png' : 'image/jpeg';
                return response($imageData, 200, [
                    'Content-Type' => $mime,
                    'Access-Control-Allow-Origin' => '*',
                    'Access-Control-Allow-Methods' => 'GET, OPTIONS',
                ]);
            }
        }

        $pixel = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
        return response($pixel, 200, [
            'Content-Type' => 'image/png',
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        ]);
    }
    return response()->file($path, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
    ]);
});
