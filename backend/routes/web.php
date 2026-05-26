<?php

use Illuminate\Support\Facades\Route;

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
