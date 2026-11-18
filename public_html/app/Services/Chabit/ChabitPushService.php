<?php

namespace App\Services\Chabit;

use App\Config\ps_constant;
use Google\Auth\OAuth2;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Modules\Core\Entities\Authorization\PushNotificationToken;

class ChabitPushService
{
    /**
     * Send an FCM push notification to all registered devices for a user.
     * Supports deep-linking into ChabitChatScreen via type='chabit_chat' & thread_id.
     */
    public function sendToUser(
        int|string $userId,
        string $title,
        string $body,
        ?int $threadId = null,
        array $extraData = []
    ): bool {
        try {
            $tokens = PushNotificationToken::where('user_id', $userId)
                ->whereNotNull('device_token')
                ->where('device_token', '!=', '')
                ->pluck('device_token')
                ->unique()
                ->values()
                ->all();

            if (empty($tokens)) {
                return false;
            }

            $keyData = $this->loadFirebaseCredentials();
            if (! $keyData || empty($keyData['project_id'])) {
                return false;
            }

            $accessToken = $this->fetchAccessToken($keyData);
            if (! $accessToken) {
                return false;
            }

            $url = sprintf('https://fcm.googleapis.com/v1/projects/%s/messages:send', $keyData['project_id']);

            $dataPayload = array_merge([
                'type' => 'chabit_chat',
                'flag' => 'chabit_chat',
                'thread_id' => $threadId ? (string) $threadId : '',
                'message' => mb_substr($body, 0, 240),
                'title' => $title,
                'click_action' => ps_constant::flutterNotificationClick,
            ], array_map('strval', $extraData));

            $sentAny = false;
            foreach ($tokens as $token) {
                $payload = [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $title,
                            'body' => mb_substr($body, 0, 240),
                        ],
                        'data' => $dataPayload,
                        'android' => [
                            'priority' => 'high',
                            'notification' => [
                                'sound' => 'default',
                                'click_action' => ps_constant::flutterNotificationClick,
                            ],
                        ],
                        'apns' => [
                            'payload' => [
                                'aps' => [
                                    'sound' => 'default',
                                ],
                            ],
                        ],
                    ],
                ];

                $response = Http::timeout(10)
                    ->withToken($accessToken)
                    ->acceptJson()
                    ->post($url, $payload);

                if ($response->successful()) {
                    $sentAny = true;
                } else {
                    Log::warning('ChabitPushService FCM send failed: '.$response->status().' '.$response->body());
                }
            }

            return $sentAny;
        } catch (\Throwable $e) {
            Log::warning('ChabitPushService exception: '.$e->getMessage());

            return false;
        }
    }

    protected function loadFirebaseCredentials(): ?array
    {
        $fileName = ps_constant::privateKeyFileNameForFCM;
        $paths = [
            base_path('storage/firebase/'.$fileName),
            base_path('storage/firebase/firebase-private-key.json'),
        ];

        foreach ($paths as $path) {
            if (is_file($path)) {
                $decoded = json_decode(file_get_contents($path), true);
                if (is_array($decoded) && ! empty($decoded['private_key'])) {
                    return $decoded;
                }
            }
        }

        return null;
    }

    protected function fetchAccessToken(array $keyData): ?string
    {
        $oauth2 = new OAuth2([
            'audience' => 'https://oauth2.googleapis.com/token',
            'issuer' => $keyData['client_email'],
            'signingAlgorithm' => 'RS256',
            'signingKey' => $keyData['private_key'],
            'tokenCredentialUri' => 'https://oauth2.googleapis.com/token',
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        ]);

        $token = $oauth2->fetchAuthToken();

        return $token['access_token'] ?? null;
    }
}
