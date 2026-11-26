<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\OrderChatNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class ChatMessagesApiController extends Controller
{
    public function __construct(protected OrderChatNotificationService $chatService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $sessionId = trim((string) ($request->query('session_id') ?? ''));
        if ($sessionId === '' || !preg_match('/^[a-zA-Z0-9_\-]+$/', $sessionId)) {
            return response()->json(['status' => 'error', 'messages' => []], 422);
        }

        $fallbackSessionId = trim((string) ($request->query('fallback_session_id') ?? ''));
        if ($fallbackSessionId !== '' && !preg_match('/^[a-zA-Z0-9_\-]+$/', $fallbackSessionId)) {
            $fallbackSessionId = '';
        }

        $raw = null;
        $token = $this->chatService->getFirebaseOAuthToken();
        if ($token) {
            $url = "https://dressydz-default-rtdb.firebaseio.com/Message/{$sessionId}.json";
            $response = Http::withToken($token)->timeout(10)->get($url);
            if ($response->successful()) {
                $raw = $response->json();
            }
            if (empty($raw) && $fallbackSessionId !== '' && $fallbackSessionId !== $sessionId) {
                $fbUrl = "https://dressydz-default-rtdb.firebaseio.com/Message/{$fallbackSessionId}.json";
                $fbResponse = Http::withToken($token)->timeout(10)->get($fbUrl);
                if ($fbResponse->successful()) {
                    $fbRaw = $fbResponse->json();
                    if (!empty($fbRaw)) {
                        $raw = $fbRaw;
                    }
                }
            }
        }

        // MySQL fallback from psx_chat_notis if RTDB is empty or unavailable
        if (empty($raw)) {
            $buyerId = trim((string) ($request->query('buyer_user_id') ?? ''));
            $sellerId = trim((string) ($request->query('seller_user_id') ?? ''));
            $itemId = trim((string) ($request->query('item_id') ?? ''));
            $orderId = null;
            if (preg_match('/_order_(\d+)$/', $sessionId, $m)) {
                $orderId = (int) $m[1];
            }
            if (($buyerId === '' || $sellerId === '') && preg_match('/^(\d+)_(\d+)/', $sessionId, $m)) {
                $buyerId = $m[1];
                $sellerId = $m[2];
            }

            if ($buyerId !== '' && $sellerId !== '') {
                $q = DB::table('psx_chat_notis')
                    ->where(function ($sub) use ($buyerId, $sellerId) {
                        $sub->where(function ($s1) use ($buyerId, $sellerId) {
                            $s1->where('buyer_user_id', $buyerId)->where('seller_user_id', $sellerId);
                        })->orWhere(function ($s2) use ($buyerId, $sellerId) {
                            $s2->where('buyer_user_id', $sellerId)->where('seller_user_id', $buyerId);
                        });
                    });
                if ($orderId !== null) {
                    $q->where('order_id', $orderId);
                } elseif ($itemId !== '') {
                    $q->where('item_id', $itemId);
                }
                $rows = $q->orderBy('added_date')->get();
                if ($rows->isEmpty() && ($orderId !== null || $itemId !== '')) {
                    $rows = DB::table('psx_chat_notis')
                        ->where(function ($sub) use ($buyerId, $sellerId) {
                            $sub->where(function ($s1) use ($buyerId, $sellerId) {
                                $s1->where('buyer_user_id', $buyerId)->where('seller_user_id', $sellerId);
                            })->orWhere(function ($s2) use ($buyerId, $sellerId) {
                                $s2->where('buyer_user_id', $sellerId)->where('seller_user_id', $buyerId);
                            });
                        })
                        ->orderBy('added_date')
                        ->get();
                }

                $mapped = [];
                foreach ($rows as $r) {
                    $tsMs = !empty($r->added_date) ? strtotime($r->added_date) * 1000 : time() * 1000;
                    $sendBy = (string) ($r->added_user_id ?: ($r->chat_flag === 'CHAT_FROM_SELLER' ? $r->seller_user_id : $r->buyer_user_id));
                    $mapped['db_' . $r->id] = [
                        'id' => 'db_' . $r->id,
                        'sessionId' => $sessionId,
                        'itemId' => (string) ($r->item_id ?? ''),
                        'sendByUserId' => $sendBy,
                        'message' => (string) ($r->chat_noti_message ?? ''),
                        'type' => 0,
                        'offerStatus' => 0,
                        'addedDateTimeStamp' => $tsMs,
                        'orderId' => $r->order_id ? (string) $r->order_id : '',
                        'orderCode' => (string) ($r->order_code ?? ''),
                        'messageType' => (string) ($r->message_type ?? ''),
                        'actionStatus' => (string) ($r->action_status ?? ''),
                    ];
                }
                if (!empty($mapped)) {
                    $raw = $mapped;
                }
            }
        }

        return response()->json([
            'status' => 'success',
            'messages' => is_array($raw) ? $raw : [],
        ]);
    }
}
