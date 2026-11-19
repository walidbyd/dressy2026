<?php

namespace App\Services;

use App\Config\ps_constant;
use Carbon\Carbon;
use Google\Auth\OAuth2;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Authorization\PushNotificationToken;
use Modules\Core\Entities\Notification\ChatHistory;
use Modules\Core\Entities\Notification\ChatNoti;
use Modules\Core\Http\Services\Notification\FirebaseCloudMessagingService;
use Modules\StoreFront\VendorPanel\Entities\Order;

class OrderChatNotificationService
{
    protected ?string $cachedOAuthToken = null;
    protected ?int $tokenExpiresAt = null;

    public function __construct(
        protected FirebaseCloudMessagingService $fcmService
    ) {}

    /**
     * Get or refresh Google OAuth2 access token for Firebase RTDB & FCM.
     */
    public function getFirebaseOAuthToken(): ?string
    {
        if ($this->cachedOAuthToken && $this->tokenExpiresAt && time() < $this->tokenExpiresAt - 60) {
            return $this->cachedOAuthToken;
        }

        $filePath = base_path('storage/firebase/' . ps_constant::privateKeyFileNameForFCM);
        if (!file_exists($filePath)) {
            $filePath = base_path('storage/firebase/firebase-private-key.json');
        }
        if (!file_exists($filePath)) {
            Log::warning('Firebase private key file not found for RTDB.');
            return null;
        }

        $jsonKey = json_decode(file_get_contents($filePath), true);
        if (empty($jsonKey)) {
            return null;
        }

        try {
            $oauth2 = new OAuth2([
                'audience' => $jsonKey['token_uri'],
                'issuer' => $jsonKey['client_email'],
                'signingAlgorithm' => 'RS256',
                'signingKey' => $jsonKey['private_key'],
                'scope' => [
                    'https://www.googleapis.com/auth/firebase.database',
                    'https://www.googleapis.com/auth/userinfo.email',
                ],
                'sub' => $jsonKey['client_email'],
                'tokenCredentialUri' => $jsonKey['token_uri'],
            ]);

            $token = $oauth2->fetchAuthToken();
            if (!empty($token['access_token'])) {
                $this->cachedOAuthToken = $token['access_token'];
                $this->tokenExpiresAt = time() + ($token['expires_in'] ?? 3600);
                return $this->cachedOAuthToken;
            }
        } catch (\Throwable $e) {
            Log::warning('Error fetching Firebase OAuth token: ' . $e->getMessage());
        }

        return null;
    }

    /**
     * Write/PUT message object to Firebase Realtime Database.
     */
    public function writeToFirebase(string $sessionId, string $messageKey, array $data): bool
    {
        try {
            $token = $this->getFirebaseOAuthToken();
            if (!$token) {
                Log::warning('Firebase OAuth token unavailable for RTDB write');
                return false;
            }

            $url = "https://dressydz-default-rtdb.firebaseio.com/Message/{$sessionId}/{$messageKey}.json";
            $response = Http::withToken($token)->put($url, $data);
            return $response->successful();
        } catch (\Throwable $e) {
            Log::warning('Firebase RTDB write error: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Update fields of message object in Firebase Realtime Database.
     */
    public function patchFirebaseMessage(string $sessionId, string $messageKey, array $patchData): bool
    {
        try {
            $token = $this->getFirebaseOAuthToken();
            if (!$token) {
                return false;
            }

            $url = "https://dressydz-default-rtdb.firebaseio.com/Message/{$sessionId}/{$messageKey}.json";
            $response = Http::withToken($token)->patch($url, $patchData);
            return $response->successful();
        } catch (\Throwable $e) {
            Log::warning('Firebase RTDB patch error: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Resolve buyer user ID from order.
     */
    public function getBuyerUserId(Order $order): ?int
    {
        return $order->user_id ? (int)$order->user_id : ($order->added_user_id ? (int)$order->added_user_id : null);
    }

    /**
     * Resolve seller user ID from order.
     */
    public function getSellerUserId(Order $order): ?int
    {
        $sellerId = $order->vendor?->owner_user_id;
        if (!$sellerId && $order->vendor_id) {
            $sellerId = \Modules\Core\Entities\Vendor\Vendor::where('id', $order->vendor_id)->value('owner_user_id');
        }
        if (!$sellerId) {
            $firstItem = $order->orderItems()->with('item')->first();
            $sellerId = $firstItem?->item?->added_user_id;
        }
        return $sellerId ? (int)$sellerId : null;
    }

    /**
     * Resolve item ID from order.
     */
    public function getItemId(Order $order): ?int
    {
        $firstItem = $order->orderItems()->first();
        return $firstItem?->item_id ? (int)$firstItem->item_id : null;
    }

    /**
     * Compute sorted session ID as used by Flutter chat: min(id1, id2)_max(id1, id2).
     */
    public function getSessionId(int $userId1, int $userId2): string
    {
        $min = min($userId1, $userId2);
        $max = max($userId1, $userId2);
        return "{$min}_{$max}";
    }

    /**
     * Send initial automated order confirmation request ONLY to the Seller.
     */
    public function sendSellerConfirmationRequest(Order $order): void
    {
        try {
            $order->loadMissing(['orderItems.item', 'vendor', 'user']);

            $buyerId = $this->getBuyerUserId($order);
            $sellerId = $this->getSellerUserId($order);
            $itemId = $this->getItemId($order);

            if (!$buyerId || !$sellerId || !$itemId) {
                Log::warning("OrderChatNotificationService: Missing parties for order #{$order->id} (buyer: $buyerId, seller: $sellerId, item: $itemId)");
                return;
            }

            $rawTotal = (float) ($order->total_price ?? 0);
            $totalAmount = number_format($rawTotal, 0, '.', ' ');
            $itemTitle = $order->orderItems?->first()?->item?->title ?? 'Article';
            $messageText = "Nouvelle commande #{$order->order_code}\nArticle : {$itemTitle}\nMontant total : {$totalAmount} DZD\n\nVeuillez confirmer la disponibilité de l'article pour expédition.";
            $sessionId = $this->getSessionId($buyerId, $sellerId);
            $nowMs = (int) round(microtime(true) * 1000);
            $messageKey = "order_{$order->id}_{$nowMs}";

            // 1. Update or create record in psx_chat_histories
            $chatHistory = ChatHistory::where('buyer_user_id', $buyerId)
                ->where('seller_user_id', $sellerId)
                ->where('item_id', $itemId)
                ->first();

            if (!$chatHistory) {
                $chatHistory = new ChatHistory();
                $chatHistory->buyer_user_id = $buyerId;
                $chatHistory->seller_user_id = $sellerId;
                $chatHistory->item_id = $itemId;
                $chatHistory->nego_price = $order->total_price ?? 0;
                $chatHistory->buyer_unread_count = 0;
                $chatHistory->seller_unread_count = 1;
                $chatHistory->is_accept = 0;
                $chatHistory->offer_status = 0;
                $chatHistory->added_user_id = $buyerId;
            } else {
                $chatHistory->seller_unread_count = (int)($chatHistory->seller_unread_count ?? 0) + 1;
            }

            $chatHistory->order_id = $order->id;
            $chatHistory->order_code = (string) $order->order_code;
            $chatHistory->action_status = 'pending';
            $chatHistory->latest_chat_message = $messageText;
            $chatHistory->updated_date = Carbon::now();
            $chatHistory->save();

            // 2. Insert notification record into psx_chat_notis
            $chatNoti = new ChatNoti();
            $chatNoti->buyer_user_id = $buyerId;
            $chatNoti->seller_user_id = $sellerId;
            $chatNoti->item_id = $itemId;
            $chatNoti->order_id = $order->id;
            $chatNoti->order_code = (string) $order->order_code;
            $chatNoti->message_type = 'order_confirmation_request';
            $chatNoti->action_status = 'pending';
            $chatNoti->chat_noti_message = $messageText;
            $chatNoti->type = Constants::chatMessageType;
            $chatNoti->chat_flag = Constants::chatNotiFlag;
            $chatNoti->is_read = 0;
            $chatNoti->added_user_id = $buyerId;
            $chatNoti->save();

            // 3. Write message into Firebase Realtime Database
            $firebaseMessage = [
                'id' => $messageKey,
                'itemId' => (string) $itemId,
                'message' => $messageText,
                'sendByUserId' => (string) $buyerId,
                'sessionId' => $sessionId,
                'type' => 0,
                'offerStatus' => 0,
                'isSold' => false,
                'isUserBought' => false,
                'is_blocked' => false,
                'addedDate' => $nowMs,
                'messageType' => 'order_confirmation_request',
                'orderId' => (string) $order->id,
                'orderCode' => (string) $order->order_code,
                'actionStatus' => 'pending',
            ];
            $this->writeToFirebase($sessionId, $messageKey, $firebaseMessage);

            // 4. Send FCM Push Notification to Seller
            $this->sendFcmPush($sellerId, [
                'title' => "Nouvelle commande #{$order->order_code}",
                'message' => $messageText,
                'order_id' => (string) $order->id,
                'order_code' => (string) $order->order_code,
                'item_id' => (string) $itemId,
                'buyer_user_id' => (string) $buyerId,
                'seller_user_id' => (string) $sellerId,
                'flag' => Constants::chatNotiFlag,
                'message_type' => 'order_confirmation_request',
            ]);
        } catch (\Throwable $e) {
            Log::error('sendSellerConfirmationRequest error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
        }
    }

    /**
     * Send automated status notification message to the conversation thread & FCM.
     */
    public function sendOrderStatusUpdate(Order $order, string $statusLabel, string $recipient = 'both'): void
    {
        try {
            $order->loadMissing(['orderItems.item', 'vendor', 'user']);

            $buyerId = $this->getBuyerUserId($order);
            $sellerId = $this->getSellerUserId($order);
            $itemId = $this->getItemId($order);

            if (!$buyerId || !$sellerId || !$itemId) {
                return;
            }

            $messageText = "Commande #{$order->order_code} : {$statusLabel}";
            $sessionId = $this->getSessionId($buyerId, $sellerId);
            $nowMs = (int) round(microtime(true) * 1000);
            $messageKey = "status_{$order->id}_{$nowMs}";

            // 1. Update psx_chat_histories
            $chatHistory = ChatHistory::where('buyer_user_id', $buyerId)
                ->where('seller_user_id', $sellerId)
                ->where('item_id', $itemId)
                ->first();

            if ($chatHistory) {
                $chatHistory->order_id = $order->id;
                $chatHistory->order_code = (string) $order->order_code;
                $chatHistory->latest_chat_message = $messageText;
                $chatHistory->updated_date = Carbon::now();
                if ($recipient === 'buyer' || $recipient === 'both') {
                    $chatHistory->buyer_unread_count = (int)($chatHistory->buyer_unread_count ?? 0) + 1;
                }
                if ($recipient === 'seller' || $recipient === 'both') {
                    $chatHistory->seller_unread_count = (int)($chatHistory->seller_unread_count ?? 0) + 1;
                }
                $chatHistory->save();
            }

            // 2. Insert into psx_chat_notis
            $chatNoti = new ChatNoti();
            $chatNoti->buyer_user_id = $buyerId;
            $chatNoti->seller_user_id = $sellerId;
            $chatNoti->item_id = $itemId;
            $chatNoti->order_id = $order->id;
            $chatNoti->order_code = (string) $order->order_code;
            $chatNoti->message_type = 'order_status_update';
            $chatNoti->action_status = 'status_update';
            $chatNoti->chat_noti_message = $messageText;
            $chatNoti->type = Constants::chatMessageType;
            $chatNoti->chat_flag = Constants::chatNotiFlag;
            $chatNoti->is_read = 0;
            $chatNoti->added_user_id = ($recipient === 'buyer') ? $sellerId : $buyerId;
            $chatNoti->save();

            // 3. Write message into Firebase RTDB
            $firebaseMessage = [
                'id' => $messageKey,
                'itemId' => (string) $itemId,
                'message' => $messageText,
                'sendByUserId' => ($recipient === 'buyer') ? (string)$sellerId : (string)$buyerId,
                'sessionId' => $sessionId,
                'type' => 0,
                'offerStatus' => 0,
                'isSold' => false,
                'isUserBought' => false,
                'is_blocked' => false,
                'addedDate' => $nowMs,
                'messageType' => 'order_status_update',
                'orderId' => (string) $order->id,
                'orderCode' => (string) $order->order_code,
                'actionStatus' => 'status_update',
            ];
            $this->writeToFirebase($sessionId, $messageKey, $firebaseMessage);

            // 4. Send FCM Push Notification to designated recipient(s)
            $pushData = [
                'title' => "Commande #{$order->order_code}",
                'message' => $messageText,
                'order_id' => (string) $order->id,
                'order_code' => (string) $order->order_code,
                'item_id' => (string) $itemId,
                'buyer_user_id' => (string) $buyerId,
                'seller_user_id' => (string) $sellerId,
                'flag' => Constants::chatNotiFlag,
                'message_type' => 'order_status_update',
            ];

            if ($recipient === 'buyer' || $recipient === 'both') {
                $this->sendFcmPush($buyerId, $pushData);
            }
            if ($recipient === 'seller' || $recipient === 'both') {
                $this->sendFcmPush($sellerId, $pushData);
            }
        } catch (\Throwable $e) {
            Log::error('sendOrderStatusUpdate error: ' . $e->getMessage());
        }
    }

    /**
     * Update order action_status in psx_chat_histories, psx_chat_notis, and Firebase RTDB.
     */
    public function updateOrderActionStatus(Order $order, string $actionStatus): void
    {
        try {
            $buyerId = $this->getBuyerUserId($order);
            $sellerId = $this->getSellerUserId($order);
            $itemId = $this->getItemId($order);

            if ($buyerId && $sellerId) {
                // Update psx_chat_histories
                ChatHistory::where('buyer_user_id', $buyerId)
                    ->where('seller_user_id', $sellerId)
                    ->where('order_id', $order->id)
                    ->update(['action_status' => $actionStatus]);

                // Update psx_chat_notis
                ChatNoti::where('order_id', $order->id)
                    ->update(['action_status' => $actionStatus]);

                // Find & patch matching messages in Firebase RTDB
                $sessionId = $this->getSessionId($buyerId, $sellerId);
                $this->patchFirebaseOrderMessages($sessionId, (string)$order->id, $actionStatus);
            }
        } catch (\Throwable $e) {
            Log::error('updateOrderActionStatus error: ' . $e->getMessage());
        }
    }

    /**
     * Patch existing order messages in Firebase RTDB with new action status.
     */
    protected function patchFirebaseOrderMessages(string $sessionId, string $orderId, string $actionStatus): void
    {
        try {
            $token = $this->getFirebaseOAuthToken();
            if (!$token) {
                return;
            }

            $url = "https://dressydz-default-rtdb.firebaseio.com/Message/{$sessionId}.json";
            $response = Http::withToken($token)->get($url);
            if ($response->successful()) {
                $messages = $response->json();
                if (is_array($messages)) {
                    foreach ($messages as $msgKey => $msgData) {
                        if (is_array($msgData) && isset($msgData['orderId']) && (string)$msgData['orderId'] === $orderId) {
                            $this->patchFirebaseMessage($sessionId, (string)$msgKey, [
                                'actionStatus' => $actionStatus,
                            ]);
                        }
                    }
                }
            }
        } catch (\Throwable $e) {
            Log::warning('patchFirebaseOrderMessages error: ' . $e->getMessage());
        }
    }

    /**
     * Send FCM Push Notification to all active device tokens of a user.
     */
    protected function sendFcmPush(int $userId, array $data): void
    {
        try {
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

            foreach ($deviceIds as $deviceId) {
                $this->fcmService->sendAndroidFcm($deviceId, $data, $platformNames);
            }
        } catch (\Throwable $e) {
            Log::warning("FCM send error for user {$userId}: " . $e->getMessage());
        }
    }
}
