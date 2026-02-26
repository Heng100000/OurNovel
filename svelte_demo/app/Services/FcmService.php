<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * Send a push notification to a specific user.
     */
    public function sendToUser(User $user, string $title, string $body, array $data = []): void
    {
        $tokens = $user->devices()->pluck('fcm_token')->toArray();

        foreach ($tokens as $token) {
            $this->sendNotification($token, $title, $body, $data);
        }
    }

    /**
     * Send a data-only push notification to an FCM topic.
     */
    public function sendToTopic(string $topic, array $data = []): void
    {
        $projectId = config('services.fcm.project_id');
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $accessToken = $this->getAccessToken();

        if (!$accessToken) {
            Log::error('FCM: Failed to get access token for topic payload.');
            return;
        }

        $response = Http::withoutVerifying()->withToken($accessToken)->post($url, [
            'message' => [
                'topic' => $topic,
                'data' => empty($data) ? (object)[] : array_map('strval', $data),
            ],
        ]);

        if ($response->failed()) {
            Log::error('FCM Topic Error: ' . $response->body());
        }
    }

    /**
     * Send notification via FCM v1 API.
     * Note: Requires a Google Service Account JSON file.
     */
    protected function sendNotification(string $deviceToken, string $title, string $body, array $data = []): void
    {
        $projectId = config('services.fcm.project_id');
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $accessToken = $this->getAccessToken();

        if (!$accessToken) {
            Log::error('FCM: Failed to get access token.');
            return;
        }

        $response = Http::withoutVerifying()->withToken($accessToken)->post($url, [
            'message' => [
                'token' => $deviceToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => empty($data) ? (object)[] : array_map('strval', $data),
            ],
        ]);

        if ($response->failed()) {
            Log::error('FCM Error: ' . $response->body());
        }
    }

    /**
     * Get OAuth2 access token for FCM.
     */
    protected function getAccessToken(): ?string
    {
        $path = base_path(config('services.fcm.service_account_path'));

        if (!file_exists($path)) {
            Log::error("FCM: Service account file not found at {$path}");
            return null;
        }

        try {
            $serviceAccount = json_decode(file_get_contents($path), true);
            
            $now = time();
            $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
            $payload = json_encode([
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/cloud-platform',
                'aud' => 'https://oauth2.googleapis.com/token',
                'exp' => $now + 3600,
                'iat' => $now,
            ]);

            $base64UrlHeader = $this->base64UrlEncode($header);
            $base64UrlPayload = $this->base64UrlEncode($payload);

            $signature = '';
            openssl_sign(
                $base64UrlHeader . "." . $base64UrlPayload,
                $signature,
                $serviceAccount['private_key'],
                'SHA256'
            );
            $base64UrlSignature = $this->base64UrlEncode($signature);

            $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

            $response = Http::withoutVerifying()->asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if ($response->failed()) {
                Log::error('FCM Token Error: ' . $response->body());
                return null;
            }

            return $response->json('access_token');
        } catch (\Exception $e) {
            Log::error('FCM Access Token Exception: ' . $e->getMessage());
            return null;
        }
    }

    protected function base64UrlEncode(string $data): string
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }
}
