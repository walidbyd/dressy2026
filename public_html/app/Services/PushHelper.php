<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Authorization\PushNotificationToken;
use Modules\Core\Http\Services\Notification\FirebaseCloudMessagingService;

class PushHelper
{
    public static function sendToUser(int $userId, string $message, string $flag = Constants::approvalNotiFlag, array $extraData = []): void
    {
        try {
            if ($userId <= 0 || trim($message) === '') {
                return;
            }

            $tokens = PushNotificationToken::where('user_id', $userId)->get();
            if ($tokens->isEmpty()) {
                return;
            }

            $deviceIds = [];
            $platformNames = [];
            foreach ($tokens as $token) {
                if (!empty($token->device_token) && $token->device_token !== 'errorToken') {
                    $deviceIds[] = $token->device_token;
                    $platformNames[] = $token->platform_name ?? 'android';
                }
            }

            if (empty($deviceIds)) {
                return;
            }

            $fcmService = app(FirebaseCloudMessagingService::class);
            $payload = array_merge($extraData, [
                'message' => $message,
                'flag' => $flag,
            ]);

            foreach ($deviceIds as $deviceId) {
                $fcmService->sendAndroidFcm($deviceId, $payload, $platformNames);
            }
        } catch (\Throwable $e) {
            Log::warning("PushHelper failed for user {$userId}: " . $e->getMessage());
        }
    }
}
