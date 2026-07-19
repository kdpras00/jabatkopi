<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Firebase\JWT\JWT;

class FcmService
{
    /**
     * Kirim FCM push notification via Firebase HTTP v1 API menggunakan service account.
     */
    public function sendNotification(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        try {
            // Baca service account credentials
            $credentialsPath = storage_path('app/' . config('services.firebase.credentials', 'firebase-auth.json'));
            if (!file_exists($credentialsPath)) {
                Log::warning('[FCM] firebase-auth.json tidak ditemukan di: ' . $credentialsPath);
                return false;
            }

            $credentials = json_decode(file_get_contents($credentialsPath), true);
            $projectId = $credentials['project_id'] ?? null;

            if (!$projectId) {
                Log::warning('[FCM] project_id tidak ada di firebase-auth.json');
                return false;
            }

            // Dapatkan access token via Google OAuth2 (JWT)
            $accessToken = $this->getGoogleAccessToken($credentials);
            if (!$accessToken) return false;

            $payload = [
                'message' => [
                    'token'        => $fcmToken,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => $data,
                ],
            ];

            $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ]);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200) {
                Log::error('[FCM] Failed to send notification', [
                    'http_code' => $httpCode,
                    'response'  => $response,
                ]);
                return false;
            }

            return true;
        } catch (\Exception $e) {
            Log::error('[FCM] Exception sending notification: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Generate Google OAuth2 Access Token using Service Account (JWT).
     */
    private function getGoogleAccessToken(array $credentials): ?string
    {
        try {
            $clientEmail = $credentials['client_email'] ?? null;
            $privateKey = $credentials['private_key'] ?? null;

            if (!$clientEmail || !$privateKey) {
                Log::warning('[FCM] client_email atau private_key tidak ada di service account JSON.');
                return null;
            }

            $now = time();
            $payload = [
                'iss'   => $clientEmail,
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud'   => 'https://oauth2.googleapis.com/token',
                'exp'   => $now + 3600,
                'iat'   => $now,
            ];

            $jwt = JWT::encode($payload, $privateKey, 'RS256');

            $ch = curl_init('https://oauth2.googleapis.com/token');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200) {
                Log::error('[FCM] Gagal generate access token: ' . $response);
                return null;
            }

            $data = json_decode($response, true);
            return $data['access_token'] ?? null;
        } catch (\Exception $e) {
            Log::error('[FCM] Exception generating token: ' . $e->getMessage());
            return null;
        }
    }
}
