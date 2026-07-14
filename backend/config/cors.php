<?php

$allowedOrigins = array_filter(
    array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost,http://127.0.0.1')))
);

// Untuk local: izinkan semua port localhost (Flutter web pakai port random).
// Untuk production: tidak ada pattern — hanya CORS_ALLOWED_ORIGINS yang berlaku.
$allowedPatterns = env('APP_ENV', 'local') === 'local'
    ? ['/^https?:\/\/localhost(:\d+)?$/', '/^https?:\/\/127\.0\.0\.1(:\d+)?$/']
    : [];

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => $allowedOrigins,

    // Pattern match semua port localhost di local dev, kosong di production
    'allowed_origins_patterns' => $allowedPatterns,

    'allowed_headers' => ['Content-Type', 'Accept', 'Authorization', 'X-Requested-With'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => false,
];
