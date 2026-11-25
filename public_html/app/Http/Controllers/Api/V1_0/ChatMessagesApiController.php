<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\OrderChatNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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

        $token = $this->chatService->getFirebaseOAuthToken();
        if (!$token) {
            return response()->json(['status' => 'error', 'messages' => []], 502);
        }

        $url = "https://dressydz-default-rtdb.firebaseio.com/Message/{$sessionId}.json";
        $response = Http::withToken($token)->timeout(10)->get($url);
        if (!$response->successful()) {
            return response()->json(['status' => 'error', 'messages' => []], 502);
        }

        $raw = $response->json();
        return response()->json([
            'status' => 'success',
            'messages' => is_array($raw) ? $raw : [],
        ]);
    }
}
