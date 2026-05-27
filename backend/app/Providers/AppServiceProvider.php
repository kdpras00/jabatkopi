<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Http;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Http::macro('supabase', function (bool $useServiceKey = false) {
            $url = config('services.supabase.url');
            $key = $useServiceKey
                ? config('services.supabase.service_key')
                : config('services.supabase.anon_key');

            return Http::baseUrl($url)
                ->withHeaders([
                    'apikey' => $key,
                    'Authorization' => 'Bearer ' . $key,
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                ]);
        });
    }
}
