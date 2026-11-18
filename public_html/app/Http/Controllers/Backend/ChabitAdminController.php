<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\Controller;
use App\Models\Chabit\ChabitMessage;
use App\Models\Chabit\ChabitSetting;
use App\Models\Chabit\ChabitThread;
use App\Services\Chabit\ChabitAssistantService;
use App\Services\Chabit\ChabitGeminiClient;
use App\Services\Chabit\ChabitPushService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Inertia\Inertia;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Item;
use Modules\Core\Entities\Notification\ChatHistory;

class ChabitAdminController extends Controller
{
    public function __construct(
        protected ChabitGeminiClient $gemini,
        protected ChabitAssistantService $assistant,
        protected ChabitPushService $push
    ) {}

    public function settings()
    {
        $setting = ChabitSetting::current();

        return Inertia::render('Chabit/Settings', [
            'setting' => [
                'id' => $setting->id,
                'has_api_key' => ! empty($setting->getEffectiveApiKey()),
                'masked_api_key' => $setting->getMaskedApiKey(),
                'gemini_model' => $setting->gemini_model ?: 'gemini-3.6-flash',
                'is_enabled' => (bool) $setting->is_enabled,
                'auto_approve_items' => (bool) $setting->auto_approve_items,
                'auto_approve_confidence' => (int) ($setting->auto_approve_confidence ?: 85),
                'app_knowledge_base' => $setting->app_knowledge_base ?: ChabitSetting::defaultKnowledgeBase(),
            ],
            'availableModels' => [
                ['id' => 'gemini-3.6-flash', 'label' => 'gemini-3.6-flash (Default — Fast Vision & Chat)'],
                ['id' => 'gemini-3.8-flash', 'label' => 'gemini-3.8-flash (Fallback / Next-Gen Flash)'],
            ],
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'gemini_api_key' => 'nullable|string|max:500',
            'gemini_model' => 'required|string|max:100',
            'is_enabled' => 'required|boolean',
            'auto_approve_items' => 'required|boolean',
            'auto_approve_confidence' => 'required|integer|min:50|max:100',
            'app_knowledge_base' => 'nullable|string',
        ]);

        $setting = ChabitSetting::current();
        $update = [
            'gemini_model' => $validated['gemini_model'],
            'is_enabled' => $validated['is_enabled'],
            'auto_approve_items' => $validated['auto_approve_items'],
            'auto_approve_confidence' => $validated['auto_approve_confidence'],
            'app_knowledge_base' => $validated['app_knowledge_base'] ?: ChabitSetting::defaultKnowledgeBase(),
        ];

        if (! empty($validated['gemini_api_key']) && ! str_contains($validated['gemini_api_key'], '****')) {
            $update['gemini_api_key'] = trim($validated['gemini_api_key']);
        }

        $setting->update($update);

        return redirect()->route('admin.chabit.settings')->with('status', [
            'flag' => 'success',
            'msg' => 'Chabit AI settings saved successfully.',
        ]);
    }

    public function testConnection(Request $request)
    {
        $apiKey = $request->input('gemini_api_key');
        if (! empty($apiKey) && str_contains($apiKey, '****')) {
            $apiKey = null;
        }
        $model = $request->input('gemini_model') ?: 'gemini-3.6-flash';

        $result = $this->gemini->testConnection($apiKey, $model);

        return response()->json($result, $result['ok'] ? 200 : 422);
    }

    public function messages(Request $request)
    {
        $assistantThreads = ChabitThread::with(['user:id,name,email,user_phone', 'latestMessage'])
            ->where('thread_type', 'assistant')
            ->orderByDesc('last_message_at')
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        $orderThreads = ChabitThread::with([
            'user:id,name,email,user_phone',
            'order:id,order_code,total_amount,order_status_id',
            'latestMessage',
        ])
            ->whereIn('thread_type', ['order_buyer', 'order_seller'])
            ->orderByDesc('last_message_at')
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        $marketplaceChats = ChatHistory::with([
            'buyer:id,name,email',
            'seller:id,name,email',
            'item:id,title,original_price,price',
        ])
            ->orderByDesc('updated_date')
            ->orderByDesc('id')
            ->limit(100)
            ->get()
            ->map(fn ($chat) => [
                'id' => $chat->id,
                'item_id' => $chat->item_id,
                'item_title' => $chat->item?->title ?? 'Deleted Item',
                'buyer_name' => $chat->buyer?->name ?? 'User #'.$chat->buyer_user_id,
                'buyer_email' => $chat->buyer?->email ?? '',
                'seller_name' => $chat->seller?->name ?? 'User #'.$chat->seller_user_id,
                'seller_email' => $chat->seller?->email ?? '',
                'latest_chat_message' => $chat->latest_chat_message,
                'buyer_unread_count' => $chat->buyer_unread_count,
                'seller_unread_count' => $chat->seller_unread_count,
                'updated_date' => (string) ($chat->updated_date ?: $chat->added_date),
            ]);

        return Inertia::render('Chabit/Messages', [
            'assistantThreads' => $assistantThreads,
            'orderThreads' => $orderThreads,
            'marketplaceChats' => $marketplaceChats,
        ]);
    }

    public function showThread(int $id)
    {
        $thread = ChabitThread::with([
            'user:id,name,email,user_phone',
            'order:id,order_code,total_amount,order_status_id,yalidine_tracking',
            'messages',
        ])->findOrFail($id);

        if ($thread->unread_admin_count > 0) {
            $thread->update(['unread_admin_count' => 0]);
        }

        return response()->json([
            'thread' => $thread,
        ]);
    }

    public function togglePause(int $id)
    {
        $thread = ChabitThread::findOrFail($id);
        $thread->update(['ai_paused' => ! $thread->ai_paused]);

        return response()->json([
            'ok' => true,
            'ai_paused' => (bool) $thread->ai_paused,
        ]);
    }

    public function reply(Request $request, int $id)
    {
        $validated = $request->validate([
            'body' => 'required|string|max:2000',
        ]);

        $thread = ChabitThread::findOrFail($id);

        $msg = $this->assistant->addMessage(
            thread: $thread,
            senderType: 'admin',
            body: trim($validated['body']),
            sendPush: true,
            pushTitle: 'Dressy Support'
        );

        $thread->update(['unread_admin_count' => 0]);

        return response()->json([
            'ok' => true,
            'message' => $msg,
        ]);
    }

    /**
     * Manual Admin Override: Approve an AI-rejected or pending item.
     */
    public function approveItem(int $id)
    {
        $item = Item::findOrFail($id);

        $update = ['status' => Constants::publishItem];
        if (Schema::hasColumn('psx_items', 'approved_by_admin')) {
            $update['approved_by_admin'] = 1;
        }
        if (Schema::hasColumn('psx_items', 'ai_moderation_status')) {
            $update['ai_moderation_status'] = 'approved';
        }
        DB::table('psx_items')->where('id', $item->id)->update($update);

        try {
            \Modules\Core\Http\Facades\PsCache::clear(\App\Config\Cache\ItemCache::BASE);
        } catch (\Throwable $e) {
            // ignore
        }

        if (! empty($item->added_user_id)) {
            $thread = ChabitThread::firstOrCreate(
                ['user_id' => $item->added_user_id, 'thread_type' => 'assistant'],
                ['last_message_at' => now()]
            );
            $lang = $thread->language ?: 'fr';
            $body = match ($lang) {
                'ar' => "✅ تمت مراجعة إعلانك \"{$item->title}\" والموافقة عليه من طرف فريق Dressy! إعلانك منشور الآن.",
                'en' => "✅ Your listing \"{$item->title}\" was manually approved by Dressy Admin and is now live!",
                default => "✅ Votre annonce « {$item->title} » a été approuvée par l'équipe Dressy et est désormais en ligne !",
            };
            $this->assistant->addMessage($thread, 'admin', $body, sendPush: true, pushTitle: 'Dressy • Annonce approuvée');
        }

        return back()->with('status', [
            'flag' => 'success',
            'msg' => "Item #{$item->id} manually approved and seller notified.",
        ]);
    }
}
