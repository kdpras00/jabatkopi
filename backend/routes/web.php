<?php

use Illuminate\Support\Facades\Route;

// --- API Documentation ---
Route::get('/api-docs', function () {
    return view('api-docs');
});

Route::get('/api-docs-raw', function () {
    $path = base_path('api-docs.md');
    if (!file_exists($path)) {
        abort(404, 'api-docs.md not found');
    }
    return response(file_get_contents($path), 200, [
        'Content-Type' => 'text/plain; charset=UTF-8',
    ]);
});


Route::redirect('/', '/login');

Route::livewire('/login', 'pages::auth.login')
    ->name('login')
    ->middleware('guest');

Route::post('/payment/notification', [\App\Http\Controllers\PaymentController::class, 'handleNotification']);

Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::livewire('/admin/dashboard', 'pages::admin.dashboard')
        ->name('admin.dashboard');
});

Route::middleware(['auth', 'role:pegawai'])->group(function () {
    Route::livewire('/pegawai/dashboard', 'pages::pegawai.dashboard')
        ->name('pegawai.dashboard');
});

Route::post('/api/notify-order', function () {
    event(new \App\Events\OrderCreated());
    return response()->json(['success' => true]);
});

Route::post('/api/notify-reservation', function () {
    event(new \App\Events\ReservationCreated());
    return response()->json(['success' => true]);
});
