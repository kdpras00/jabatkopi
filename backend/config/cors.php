<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Allowed origins are read from CORS_ALLOWED_ORIGINS in .env so that
    | local and production environments can differ without touching this file.
    |
    | Local .env  : CORS_ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
    | Prod  .env  : CORS_ALLOWED_ORIGINS=https://jabatkopi.my.id
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => array_filter(
        array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost,http://127.0.0.1')))
    ),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['Content-Type', 'Accept', 'Authorization', 'X-Requested-With'],

    'exposed_headers' => [],

    'max_age' => 86400, // 24 jam preflight cache

    'supports_credentials' => false,
];
