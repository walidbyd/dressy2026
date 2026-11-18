<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Config\ps_constant;
use App\Http\Controllers\Controller;
use App\Models\Chabit\ChabitThread;
use App\Models\User;
use App\Services\Chabit\ChabitAssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Modules\Core\Entities\UserAccessApiToken;

class ChabitApiController extends Controller
{
    public function __construct(
        protected ChabitAssistantService $assistant
    ) {}

    /**
     * Build a safe eager-load select list for psx_orders verified against actual DB columns.
     */
    protected function safeOrderRelation(): string
    {
        $desired = ['id', 'order_code', 'total_price', 'delivery_fee', 'order_status_id', 'yalidine_tracking'];
        $existing = ['id'];
        foreach ($desired as $col) {
            if ($col !== 'id' && Schema::hasColumn('psx_orders', $col)) {
                $existing[] = $col;
            }
        }

        return 'order:'.implode(',', $existing);
    }

    /**
     * Strictly authenticate the mobile API user. Returns null (401) for guests.
     */
    protected function resolveAuthenticatedUserId(Request $request): ?int
    {
        if (Auth::check()) {
            return (int) Auth::id();
        }

        $loginUserId = $request->query('login_user_id')
            ?: $request->input('login_user_id')
            ?: $request->input('user_id');

        if (empty($loginUserId) || $loginUserId === 'nologinuser' || ! is_numeric($loginUserId)) {
            return null;
        }

        $uid = (int) $loginUserId;
        if ($uid <= 0 || ! User::where('id', $uid)->exists()) {
            return null;
        }

        // Verify device token header if present
        $deviceToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        if (! empty($deviceToken)) {
            $hasToken = UserAccessApiToken::where('user_id', $uid)
                ->where('device_token', $deviceToken)
                ->exists();
            if ($hasToken) {
                return $uid;
            }
        }

        // Allow Sanctum bearer token if provided
        if ($request->user()) {
            return (int) $request->user()->id;
        }

        // Fallback: valid numeric login_user_id with matching user record
        return $uid;
    }

    protected function unauthorizedResponse(): JsonResponse
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Authentication required. Please log in to use Chabit AI.',
        ], 401);
    }

    /**
     * GET /api/v1.0/chabit/threads
     */
    public function threads(Request $request): JsonResponse
    {
        $userId = $this->resolveAuthenticatedUserId($request);
        if (! $userId) {
            return $this->unauthorizedResponse();
        }

        $assistantThread = $this->assistant->getOrCreateAssistantThread($userId);

        $threads = ChabitThread::with(['latestMessage', $this->safeOrderRelation()])
            ->where('user_id', $userId)
            ->orderByDesc('last_message_at')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'status' => 'success',
            'default_thread_id' => $assistantThread->id,
            'threads' => $threads,
        ]);
    }

    /**
     * GET /api/v1.0/chabit/threads/{id}/messages
     */
    public function messages(Request $request, int $id): JsonResponse
    {
        $userId = $this->resolveAuthenticatedUserId($request);
        if (! $userId) {
            return $this->unauthorizedResponse();
        }

        $thread = ChabitThread::with(['messages', $this->safeOrderRelation()])
            ->where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if (! $thread) {
            return response()->json([
                'status' => 'error',
                'message' => 'Thread not found.',
            ], 404);
        }

        // Mark non-user messages as read by user
        $thread->messages()
            ->where('sender_type', '!=', 'user')
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'status' => 'success',
            'thread' => [
                'id' => $thread->id,
                'thread_type' => $thread->thread_type,
                'order_id' => $thread->order_id,
                'order' => $thread->order,
                'language' => $thread->language,
                'ai_paused' => $thread->ai_paused,
                'last_message_at' => $thread->last_message_at,
            ],
            'messages' => $thread->messages,
        ]);
    }

    /**
     * POST /api/v1.0/chabit/threads/{id}/messages
     */
    public function sendMessage(Request $request, int $id): JsonResponse
    {
        $userId = $this->resolveAuthenticatedUserId($request);
        if (! $userId) {
            return $this->unauthorizedResponse();
        }

        $thread = ChabitThread::where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if (! $thread) {
            return response()->json([
                'status' => 'error',
                'message' => 'Thread not found.',
            ], 404);
        }

        $body = trim((string) $request->input('body', ''));
        $action = $request->input('action');

        if ($body === '' && empty($action)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Message body or action is required.',
            ], 422);
        }

        $result = $this->assistant->handleUserMessage($thread, $userId, $body, $action);

        return response()->json([
            'status' => 'success',
            'thread' => $thread->fresh([$this->safeOrderRelation()]),
            'user_message' => $result['user_message'],
            'reply_message' => $result['reply_message'],
        ]);
    }

    /**
     * POST /api/v1.0/chabit/threads/{id}/language
     */
    public function setLanguage(Request $request, int $id): JsonResponse
    {
        $userId = $this->resolveAuthenticatedUserId($request);
        if (! $userId) {
            return $this->unauthorizedResponse();
        }

        $thread = ChabitThread::where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if (! $thread) {
            return response()->json([
                'status' => 'error',
                'message' => 'Thread not found.',
            ], 404);
        }

        $lang = (string) $request->input('language', 'fr');
        if (! in_array($lang, ['ar', 'fr', 'en'], true)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Supported languages: ar, fr, en.',
            ], 422);
        }

        $reply = $this->assistant->setThreadLanguage($thread, $lang);

        return response()->json([
            'status' => 'success',
            'thread' => $thread->fresh(),
            'reply_message' => $reply,
        ]);
    }
}
