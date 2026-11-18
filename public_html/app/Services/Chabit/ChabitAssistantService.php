<?php

namespace App\Services\Chabit;

use App\Models\Chabit\ChabitMessage;
use App\Models\Chabit\ChabitSetting;
use App\Models\Chabit\ChabitThread;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Item;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WithdrawRequest;

class ChabitAssistantService
{
    public function __construct(
        protected ChabitGeminiClient $gemini,
        protected ChabitPushService $push
    ) {}

    /**
     * Get or create the authenticated user's main assistant thread.
     * On first launch (when thread.language is null), seeds the trilingual language prompt.
     */
    public function getOrCreateAssistantThread(int $userId): ChabitThread
    {
        $thread = ChabitThread::where('user_id', $userId)
            ->where('thread_type', 'assistant')
            ->first();

        if (! $thread) {
            $thread = ChabitThread::create([
                'user_id' => $userId,
                'thread_type' => 'assistant',
                'language' => null,
                'ai_paused' => false,
                'last_message_at' => now(),
                'unread_admin_count' => 0,
            ]);
        }

        if ($thread->messages()->count() === 0 && empty($thread->language)) {
            $this->addMessage(
                thread: $thread,
                senderType: 'ai',
                body: "مرحباً بك في شابيت (Chabit) ✨\nBienvenue sur Chabit, l'assistant Dressy ✨\nWelcome to Chabit, your Dressy AI Assistant ✨\n\nاختر لغتك المفضلة / Choisissez votre langue / Choose your language:",
                quickReplies: $this->languageQuickReplies(),
                sendPush: false
            );
        }

        return $thread->fresh(['messages']);
    }

    /**
     * Trigger Order Confirmation Threads (Buyer & Seller) when a new COD order is placed.
     */
    public function triggerNewCodOrderThreads(Order $order): void
    {
        try {
            if (! Schema::hasTable('chabit_threads') || ! Schema::hasTable('chabit_messages')) {
                return;
            }

            $order->loadMissing(['orderItems.item', 'shippingAndBilling', 'vendor']);
            $orderCode = $order->order_code ?: ('#'.$order->id);
            $rawTotal = (float) ($order->total_price ?? 0);
            $totalAmount = number_format($rawTotal, 0, '.', ' ');
            $itemTitles = $order->orderItems
                ->map(fn ($oi) => ($oi->item?->title ?? 'Article').' (x'.max(1, (int) $oi->quantity).')')
                ->implode(', ');

            // 1. Buyer Thread (order_buyer)
            if (! empty($order->user_id)) {
                $buyerLang = $this->resolveUserPreferredLanguage((int) $order->user_id);
                $buyerThread = ChabitThread::firstOrCreate(
                    [
                        'user_id' => (int) $order->user_id,
                        'order_id' => $order->id,
                        'thread_type' => 'order_buyer',
                    ],
                    [
                        'language' => $buyerLang,
                        'ai_paused' => false,
                        'last_message_at' => now(),
                    ]
                );

                if ($buyerThread->messages()->count() === 0) {
                    [$buyerBody, $buyerReplies, $buyerTitle] = $this->buildBuyerOrderConfirmationPayload($buyerLang, $orderCode, $itemTitles, $totalAmount);
                    $this->addMessage(
                        thread: $buyerThread,
                        senderType: 'system',
                        body: $buyerBody,
                        quickReplies: $buyerReplies,
                        metadata: ['order_id' => $order->id, 'order_code' => $orderCode],
                        sendPush: true,
                        pushTitle: $buyerTitle
                    );
                }
            }

            // 2. Seller Thread (order_seller)
            $sellerUserId = $this->resolveSellerUserId($order);
            if (! empty($sellerUserId)) {
                $sellerLang = $this->resolveUserPreferredLanguage((int) $sellerUserId);
                $sellerThread = ChabitThread::firstOrCreate(
                    [
                        'user_id' => (int) $sellerUserId,
                        'order_id' => $order->id,
                        'thread_type' => 'order_seller',
                    ],
                    [
                        'language' => $sellerLang,
                        'ai_paused' => false,
                        'last_message_at' => now(),
                    ]
                );

                if ($sellerThread->messages()->count() === 0) {
                    [$sellerBody, $sellerReplies, $sellerTitle] = $this->buildSellerOrderPayload($sellerLang, $orderCode, $itemTitles, $totalAmount);
                    $this->addMessage(
                        thread: $sellerThread,
                        senderType: 'system',
                        body: $sellerBody,
                        quickReplies: $sellerReplies,
                        metadata: ['order_id' => $order->id, 'order_code' => $orderCode],
                        sendPush: true,
                        pushTitle: $sellerTitle
                    );
                }
            }
        } catch (\Throwable $e) {
            Log::warning('ChabitAssistantService::triggerNewCodOrderThreads error: '.$e->getMessage());
        }
    }

    /**
     * Handle an incoming user message or quick-reply action on an authenticated thread.
     */
    public function handleUserMessage(ChabitThread $thread, int $userId, string $body, ?string $action = null): array
    {
        if ((int) $thread->user_id !== $userId) {
            abort(403, 'Unauthorized access to thread.');
        }

        // Save the user's message
        $userMessage = $this->addMessage(
            thread: $thread,
            senderType: 'user',
            body: trim($body) !== '' ? trim($body) : ($action ?: ''),
            metadata: $action ? ['action' => $action] : null,
            sendPush: false
        );

        $thread->increment('unread_admin_count');

        // 1. Handle explicit language selection action
        if ($action && str_starts_with($action, 'set_language:')) {
            $chosen = substr($action, strlen('set_language:'));
            if (in_array($chosen, ['ar', 'fr', 'en'], true)) {
                $reply = $this->setThreadLanguage($thread, $chosen);

                return ['user_message' => $userMessage, 'reply_message' => $reply];
            }
        }

        // 2. Handle Order Quick-Reply Actions
        if ($action && in_array($action, ['confirm_order', 'cancel_order', 'parcel_ready', 'shipping_help'], true)) {
            $reply = $this->handleOrderQuickReply($thread, $userId, $action);

            return ['user_message' => $userMessage, 'reply_message' => $reply];
        }

        // 3. If thread language not chosen yet and user typed free text, infer or prompt
        if (empty($thread->language)) {
            $inferred = $this->inferLanguageFromText($body);
            $thread->update(['language' => $inferred]);
        }

        // 4. If human admin has paused AI on this thread, do not auto-reply
        $settings = ChabitSetting::current();
        if ($thread->ai_paused || ! $settings->is_enabled) {
            return ['user_message' => $userMessage, 'reply_message' => null];
        }

        // 5. Generate AI response via Gemini with per-user isolated tools
        $reply = $this->generateAiReply($thread, $userId);

        return ['user_message' => $userMessage, 'reply_message' => $reply];
    }

    public function setThreadLanguage(ChabitThread $thread, string $lang): ChabitMessage
    {
        $lang = in_array($lang, ['ar', 'fr', 'en'], true) ? $lang : 'fr';
        $thread->update(['language' => $lang]);

        // Also update the user's main assistant thread language preference
        ChabitThread::where('user_id', $thread->user_id)
            ->whereNull('language')
            ->update(['language' => $lang]);

        if ($lang === 'ar') {
            $text = "تم اختيار العربية ✅\nأنا شابيت، مساعدك الذكي على Dressy. كيف يمكنني مساعدتك اليوم؟ (الطلبات، الإعلانات، التوصيل عبر ياليدين، أو المحفظة)";
        } elseif ($lang === 'en') {
            $text = "English selected ✅\nI'm Chabit, your Dressy AI assistant. How can I help you today? (Orders, listings, Yalidine shipping, or wallet summary)";
        } else {
            $text = "Français sélectionné ✅\nJe suis Chabit, votre assistant Dressy. Comment puis-je vous aider aujourd'hui ? (Commandes, annonces, livraison Yalidine ou portefeuille)";
        }

        return $this->addMessage(
            thread: $thread,
            senderType: 'ai',
            body: $text,
            sendPush: false
        );
    }

    /**
     * Save a message and optionally trigger an FCM push notification.
     */
    public function addMessage(
        ChabitThread $thread,
        string $senderType,
        string $body,
        ?array $quickReplies = null,
        ?array $metadata = null,
        bool $sendPush = true,
        ?string $pushTitle = null
    ): ChabitMessage {
        $msg = ChabitMessage::create([
            'thread_id' => $thread->id,
            'sender_type' => $senderType,
            'body' => $body,
            'quick_replies' => $quickReplies,
            'metadata' => $metadata,
            'is_read' => $senderType === 'user',
        ]);

        $thread->update(['last_message_at' => now()]);

        if ($sendPush && in_array($senderType, ['ai', 'admin', 'system'], true)) {
            $title = $pushTitle ?: ($senderType === 'admin' ? 'Dressy Support' : 'Chabit AI • Dressy');
            $this->push->sendToUser($thread->user_id, $title, $body, $thread->id);
        }

        return $msg;
    }

    protected function handleOrderQuickReply(ChabitThread $thread, int $userId, string $action): ChabitMessage
    {
        $lang = $thread->language ?: 'fr';
        $order = $thread->order_id ? Order::with(['orderItems.item', 'vendor'])->find($thread->order_id) : null;

        if ($action === 'shipping_help') {
            $body = match ($lang) {
                'ar' => "📦 كيفية شحن طلبك عبر ياليدين (Yalidine Express):\n1. غلّف القطعة جيداً وبشكل نظيف.\n2. افتح قسم «مبيعاتي» في التطبيق واضغط على قبول الطلب لتوليد بوليصة الشحن.\n3. قم بإيداع الطرد في أقرب مكتب ياليدين.\n4. بمجرد استلام المشتري والدفع عند الاستلام، يُضاف المبلغ تلقائياً إلى محفظتك في Dressy!",
                'en' => "📦 How to ship with Yalidine Express:\n1. Pack the item cleanly and securely.\n2. Open «My Sales» in the Dressy app and accept the order to generate the Yalidine tracking label.\n3. Drop off the parcel at your nearest Yalidine Express desk.\n4. Once delivered & COD settled, your earnings are safely credited to your Dressy wallet!",
                default => "📦 Comment expédier avec Yalidine Express :\n1. Emballez soigneusement l'article.\n2. Ouvrez « Mes Ventes » dans Dressy et acceptez la commande pour générer le bordereau Yalidine.\n3. Déposez le colis au bureau Yalidine le plus proche.\n4. Dès la livraison et l'encaissement COD, vos gains sont crédités dans votre portefeuille Dressy !",
            };

            return $this->addMessage($thread, 'ai', $body, sendPush: true);
        }

        if (! $order) {
            $notFound = match ($lang) {
                'ar' => 'عذراً، لم أتمكن من العثور على هذا الطلب.',
                'en' => 'Sorry, I could not find this order.',
                default => 'Désolé, impossible de retrouver cette commande.',
            };

            return $this->addMessage($thread, 'system', $notFound, sendPush: true);
        }

        $orderCode = $order->order_code ?: ('#'.$order->id);
        $sellerUserId = $this->resolveSellerUserId($order);

        if ($action === 'confirm_order' && (int) $order->user_id === $userId) {
            if ((int) $order->order_status_id === (int) Constants::orderPendingStatus) {
                $order->order_status_id = Constants::orderApprovedStatus;
                $order->updated_user_id = $userId;
                $order->save();
            }

            // Notify Seller
            if ($sellerUserId) {
                $sellerThread = ChabitThread::firstOrCreate(
                    ['user_id' => $sellerUserId, 'order_id' => $order->id, 'thread_type' => 'order_seller'],
                    ['language' => $this->resolveUserPreferredLanguage($sellerUserId), 'last_message_at' => now()]
                );
                $sLang = $sellerThread->language ?: 'fr';
                $sellerNotice = match ($sLang) {
                    'ar' => "✅ أكد المشتري الطلب {$orderCode}! يمكنك الآن تجهيز الطرد لشحنه عبر ياليدين.",
                    'en' => "✅ Buyer confirmed order {$orderCode}! You can now prepare the parcel for Yalidine drop-off.",
                    default => "✅ L'acheteur a confirmé la commande {$orderCode} ! Vous pouvez préparer le colis pour le dépôt Yalidine.",
                };
                $this->addMessage($sellerThread, 'system', $sellerNotice, sendPush: true, pushTitle: 'Dressy • Commande confirmée');
            }

            $buyerAck = match ($lang) {
                'ar' => "✅ شكراً لتأكيدك! تم تأكيد الطلب {$orderCode} وإشعار البائع لتجهيز الشحنة عبر ياليدين.",
                'en' => "✅ Thank you! Order {$orderCode} is now confirmed and the seller has been notified to prepare your Yalidine shipment.",
                default => "✅ Merci ! Votre commande {$orderCode} est confirmée et le vendeur a été notifié pour préparer l'expédition Yalidine.",
            };

            return $this->addMessage($thread, 'system', $buyerAck, sendPush: true);
        }

        if ($action === 'cancel_order' && (int) $order->user_id === $userId) {
            $cancelRes = $this->cancelUnshippedOrderForBuyer($order, $userId, $lang);

            if ($cancelRes['cancelled'] && $sellerUserId) {
                $sellerThread = ChabitThread::firstOrCreate(
                    ['user_id' => $sellerUserId, 'order_id' => $order->id, 'thread_type' => 'order_seller'],
                    ['language' => $this->resolveUserPreferredLanguage($sellerUserId), 'last_message_at' => now()]
                );
                $sLang = $sellerThread->language ?: 'fr';
                $sellerNotice = match ($sLang) {
                    'ar' => "❌ قام المشتري بإلغاء الطلب {$orderCode} قبل الشحن. تمت إعادة الكمية تلقائياً إلى إعلانك.",
                    'en' => "❌ Buyer cancelled order {$orderCode} before shipment. Your listing stock has been restored.",
                    default => "❌ L'acheteur a annulé la commande {$orderCode} avant expédition. Votre stock a été rétabli automatiquement.",
                };
                $this->addMessage($sellerThread, 'system', $sellerNotice, sendPush: true, pushTitle: 'Dressy • Commande annulée');
            }

            return $this->addMessage($thread, 'system', $cancelRes['message'], sendPush: true);
        }

        if ($action === 'parcel_ready' && $sellerUserId && (int) $sellerUserId === $userId) {
            // Notify Buyer
            if (! empty($order->user_id)) {
                $buyerThread = ChabitThread::firstOrCreate(
                    ['user_id' => (int) $order->user_id, 'order_id' => $order->id, 'thread_type' => 'order_buyer'],
                    ['language' => $this->resolveUserPreferredLanguage((int) $order->user_id), 'last_message_at' => now()]
                );
                $bLang = $buyerThread->language ?: 'fr';
                $buyerNotice = match ($bLang) {
                    'ar' => "📦 طردك للطلب {$orderCode} جاهز لدى البائع وسيتم إيداعه قريباً لدى Yalidine Express!",
                    'en' => "📦 Your parcel for order {$orderCode} is packed and ready for Yalidine Express drop-off!",
                    default => "📦 Bonne nouvelle ! Votre colis pour la commande {$orderCode} est prêt à être déposé chez Yalidine Express.",
                };
                $this->addMessage($buyerThread, 'system', $buyerNotice, sendPush: true, pushTitle: 'Dressy • Colis prêt');
            }

            $sellerAck = match ($lang) {
                'ar' => "📦 ممتاز! تم إشعار المشتري بأن الطرد {$orderCode} جاهز للشحن عبر ياليدين.",
                'en' => "📦 Awesome! The buyer has been notified that parcel {$orderCode} is ready for Yalidine drop-off.",
                default => "📦 Parfait ! L'acheteur a été informé que le colis {$orderCode} est prêt pour le dépôt Yalidine.",
            };

            return $this->addMessage($thread, 'system', $sellerAck, sendPush: true);
        }

        $fallback = match ($lang) {
            'ar' => 'تم استلام طلبك. كيف يمكنني مساعدتك أكثر؟',
            'en' => 'Action received. How else can I assist you?',
            default => 'Action enregistrée. Comment puis-je vous aider davantage ?',
        };

        return $this->addMessage($thread, 'system', $fallback, sendPush: true);
    }

    /**
     * Call Gemini with conversation history + per-user isolated tools.
     */
    protected function generateAiReply(ChabitThread $thread, int $userId): ChabitMessage
    {
        $settings = ChabitSetting::current();
        $lang = $thread->language ?: 'fr';
        $langName = match ($lang) {
            'ar' => 'Arabic (العربية)',
            'en' => 'English',
            default => 'French (Français)',
        };

        $orderContext = '';
        if ($thread->order_id) {
            $orderContext = "\nThis conversation is specifically about Order ID #{$thread->order_id} (thread_type: {$thread->thread_type}).";
        }

        $systemInstruction = <<<SYS
You are Chabit, the official AI Assistant of Dressy (Algeria's fashion marketplace).
STRICT RULES:
1. ALWAYS reply strictly in {$langName}. Never switch languages unless the user explicitly switches language.
2. Keep replies warm, concise, helpful, and easy to read on mobile.
3. ACCOUNT ISOLATION: You may ONLY access data returned by your tools for the currently logged-in user (User ID: {$userId}). Never guess or invent order codes, prices, or wallet balances.
4. WITHDRAWAL SECURITY: You are STRICTLY FORBIDDEN from approving, processing, or modifying withdrawals. Explain clearly that Dressy admins review and process CCP/BaridiMob payouts twice per week.
5. NO PHONE NUMBERS: Remind users that sharing phone numbers/WhatsApp in listings or chat is prohibited for their safety.{$orderContext}

DRESSY KNOWLEDGE BASE:
{$settings->app_knowledge_base}
SYS;

        // Build recent history (last 14 messages)
        $history = $thread->messages()->latest('id')->limit(14)->get()->reverse()->values();
        $contents = [];
        foreach ($history as $m) {
            $role = $m->sender_type === 'user' ? 'user' : 'model';
            $contents[] = [
                'role' => $role,
                'parts' => [['text' => $m->body]],
            ];
        }

        $tools = $this->geminiToolDeclarations();

        $response = $this->gemini->generateContent(
            contents: $contents,
            systemInstruction: $systemInstruction,
            tools: $tools
        );

        // Execute tool calls (max 2 tool round-trips, strictly bound to $userId)
        $round = 0;
        while ($response['ok'] && ! empty($response['function_calls']) && $round < 2) {
            $round++;
            $modelParts = $response['data']['candidates'][0]['content']['parts'] ?? [];
            $contents[] = [
                'role' => 'model',
                'parts' => $modelParts,
            ];

            $toolResponseParts = [];
            foreach ($response['function_calls'] as $call) {
                $name = $call['name'] ?? '';
                $args = is_array($call['args'] ?? null) ? $call['args'] : [];
                $result = $this->executeIsolatedTool($name, $args, $userId, $lang);

                $toolResponseParts[] = [
                    'functionResponse' => [
                        'name' => $name,
                        'response' => ['result' => $result],
                    ],
                ];
            }

            $contents[] = [
                'role' => 'user',
                'parts' => $toolResponseParts,
            ];

            $response = $this->gemini->generateContent(
                contents: $contents,
                systemInstruction: $systemInstruction,
                tools: $tools
            );
        }

        $replyText = $response['ok'] && ! empty($response['text'])
            ? $response['text']
            : match ($lang) {
                'ar' => 'عذراً، أواجه ضغطاً مؤقتاً الآن. سيقوم فريق الدعم بالرد عليك قريباً.',
                'en' => 'Sorry, I am temporarily busy right now. Our Dressy support team will assist you shortly.',
                default => 'Désolé, je rencontre un souci temporaire. Notre équipe support Dressy prendra le relais rapidement.',
            };

        return $this->addMessage(
            thread: $thread,
            senderType: 'ai',
            body: $replyText,
            sendPush: true
        );
    }

    /**
     * Strictly per-user isolated Gemini function declarations.
     */
    protected function geminiToolDeclarations(): array
    {
        return [
            [
                'functionDeclarations' => [
                    [
                        'name' => 'get_my_orders',
                        'description' => 'Get the authenticated user\'s own recent orders (both as buyer and as seller).',
                        'parameters' => [
                            'type' => 'OBJECT',
                            'properties' => [
                                'role' => [
                                    'type' => 'STRING',
                                    'description' => 'Filter by "buyer", "seller", or "all".',
                                ],
                            ],
                        ],
                    ],
                    [
                        'name' => 'cancel_my_unshipped_order',
                        'description' => 'Cancel an unshipped order belonging strictly to the authenticated buyer.',
                        'parameters' => [
                            'type' => 'OBJECT',
                            'properties' => [
                                'order_id' => [
                                    'type' => 'INTEGER',
                                    'description' => 'Numeric ID of the order to cancel.',
                                ],
                            ],
                            'required' => ['order_id'],
                        ],
                    ],
                    [
                        'name' => 'get_my_listings',
                        'description' => 'Get the authenticated user\'s own product listings including status and AI moderation reason.',
                        'parameters' => [
                            'type' => 'OBJECT',
                            'properties' => [
                                'limit' => [
                                    'type' => 'INTEGER',
                                    'description' => 'Max listings to return (default 10).',
                                ],
                            ],
                        ],
                    ],
                    [
                        'name' => 'get_my_wallet_summary',
                        'description' => 'Get read-only wallet balance, pending escrow, and recent withdrawal requests for the authenticated user. NEVER approves withdrawals.',
                        'parameters' => [
                            'type' => 'OBJECT',
                            'properties' => (object) [],
                        ],
                    ],
                ],
            ],
        ];
    }

    /**
     * Execute a Gemini tool strictly bound to $userId (authenticated user).
     */
    protected function executeIsolatedTool(string $name, array $args, int $userId, string $lang): array
    {
        try {
            if ($name === 'get_my_orders') {
                $role = $args['role'] ?? 'all';
                $vendorIds = Vendor::where('owner_user_id', $userId)->pluck('id')->all();
                $orders = collect();

                if ($role === 'all' || $role === 'buyer') {
                    $buyerOrders = Order::with(['orderItems.item'])
                        ->where('user_id', $userId)
                        ->orderByDesc('id')
                        ->limit(8)
                        ->get()
                        ->map(fn ($o) => [
                            'id' => $o->id,
                            'order_code' => $o->order_code,
                            'role' => 'buyer',
                            'status_id' => $o->order_status_id,
                            'status_label' => $this->orderStatusLabel((int) $o->order_status_id),
                            'total_dzd' => (float) ($o->total_price ?? 0),
                            'delivery_fee_dzd' => (float) ($o->delivery_fee ?? 0),
                            'yalidine_tracking' => $o->yalidine_tracking ?? null,
                            'items' => $o->orderItems->map(fn ($i) => $i->item?->title)->filter()->values()->all(),
                            'date' => (string) $o->added_date,
                        ]);
                    $orders = $orders->merge($buyerOrders);
                }

                if (($role === 'all' || $role === 'seller') && ! empty($vendorIds)) {
                    $sellerOrders = Order::with(['orderItems.item'])
                        ->whereIn('vendor_id', $vendorIds)
                        ->orderByDesc('id')
                        ->limit(8)
                        ->get()
                        ->map(fn ($o) => [
                            'id' => $o->id,
                            'order_code' => $o->order_code,
                            'role' => 'seller',
                            'status_id' => $o->order_status_id,
                            'status_label' => $this->orderStatusLabel((int) $o->order_status_id),
                            'total_dzd' => (float) ($o->total_price ?? 0),
                            'delivery_fee_dzd' => (float) ($o->delivery_fee ?? 0),
                            'yalidine_tracking' => $o->yalidine_tracking ?? null,
                            'items' => $o->orderItems->map(fn ($i) => $i->item?->title)->filter()->values()->all(),
                            'date' => (string) $o->added_date,
                        ]);
                    $orders = $orders->merge($sellerOrders);
                }

                return ['orders' => $orders->values()->all()];
            }

            if ($name === 'cancel_my_unshipped_order') {
                $orderId = (int) ($args['order_id'] ?? 0);
                $order = Order::with('orderItems')->where('id', $orderId)->where('user_id', $userId)->first();
                if (! $order) {
                    return ['cancelled' => false, 'error' => 'Order not found in your account.'];
                }

                return $this->cancelUnshippedOrderForBuyer($order, $userId, $lang);
            }

            if ($name === 'get_my_listings') {
                $limit = min(15, max(1, (int) ($args['limit'] ?? 10)));
                $items = Item::where('added_user_id', $userId)
                    ->orderByDesc('id')
                    ->limit($limit)
                    ->get()
                    ->map(fn ($i) => [
                        'id' => $i->id,
                        'title' => $i->title,
                        'price_dzd' => $i->original_price ?: $i->price,
                        'status' => $this->itemStatusLabel((int) $i->status),
                        'is_sold_out' => (bool) $i->is_sold_out,
                        'ai_moderation_status' => $i->ai_moderation_status ?? null,
                        'ai_moderation_reason' => $i->ai_moderation_reason ?? null,
                    ])
                    ->all();

                return ['listings' => $items];
            }

            if ($name === 'get_my_wallet_summary') {
                $wallet = Wallet::where('user_id', $userId)->first();
                $withdrawals = WithdrawRequest::where('user_id', $userId)
                    ->orderByDesc('id')
                    ->limit(5)
                    ->get()
                    ->map(fn ($w) => [
                        'id' => $w->id,
                        'amount_dzd' => $w->amount,
                        'status' => $w->status,
                        'created_at' => (string) $w->created_at,
                    ])
                    ->all();

                return [
                    'available_balance_dzd' => (float) ($wallet->balance ?? 0),
                    'currency' => $wallet->currency_code ?? 'DZD',
                    'recent_withdrawals' => $withdrawals,
                    'payout_policy' => 'Withdrawals (CCP / BaridiMob) are manually reviewed and paid by Dressy admins twice per week.',
                ];
            }

            return ['error' => 'Unknown tool'];
        } catch (\Throwable $e) {
            Log::warning("Chabit tool '{$name}' failed: ".$e->getMessage());

            return ['error' => 'Unable to fetch requested information right now.'];
        }
    }

    protected function cancelUnshippedOrderForBuyer(Order $order, int $userId, string $lang): array
    {
        if ((int) $order->user_id !== $userId) {
            return ['cancelled' => false, 'message' => 'Unauthorized.'];
        }

        $cancellableStatuses = [(int) Constants::orderPendingStatus, (int) Constants::orderApprovedStatus];
        $hasTracking = Schema::hasColumn('psx_orders', 'yalidine_tracking') && ! empty($order->yalidine_tracking);
        if (! in_array((int) $order->order_status_id, $cancellableStatuses, true) || $hasTracking) {
            $msg = match ($lang) {
                'ar' => 'عذراً، لا يمكن إلغاء هذا الطلب لأنه تم شحنه بالفعل أو تمت معالجته.',
                'en' => 'Sorry, this order can no longer be cancelled because it has already been shipped or processed.',
                default => 'Désolé, cette commande ne peut plus être annulée car elle est déjà expédiée ou traitée.',
            };

            return ['cancelled' => false, 'message' => $msg];
        }

        DB::transaction(function () use ($order, $userId) {
            $order->order_status_id = Constants::orderCancelledStatus;
            if (Schema::hasColumn('psx_orders', 'status_reason')) {
                $order->status_reason = 'Cancelled by buyer via Chabit';
            }
            $order->updated_user_id = $userId;
            $order->save();

            // Restore item stock
            foreach ($order->orderItems as $orderItem) {
                if (! $orderItem->item_id) {
                    continue;
                }
                $qtyToRestore = max(1, (int) ($orderItem->quantity ?? 1));
                $qtyRow = DB::table('psx_item_infos')
                    ->where('item_id', $orderItem->item_id)
                    ->where('core_keys_id', Constants::itemQty)
                    ->first();

                if ($qtyRow) {
                    $newQty = (int) $qtyRow->value + $qtyToRestore;
                    DB::table('psx_item_infos')->where('id', $qtyRow->id)->update(['value' => (string) $newQty]);
                }

                DB::table('psx_items')->where('id', $orderItem->item_id)->update(['is_sold_out' => 0]);
            }
        });

        $orderCode = $order->order_code ?: ('#'.$order->id);
        $msg = match ($lang) {
            'ar' => "❌ تم إلغاء الطلب {$orderCode} بنجاح وإشعار البائع.",
            'en' => "❌ Order {$orderCode} has been cancelled and the seller has been notified.",
            default => "❌ La commande {$orderCode} a bien été annulée et le vendeur a été informé.",
        };

        return ['cancelled' => true, 'message' => $msg];
    }

    protected function languageQuickReplies(): array
    {
        return [
            ['id' => 'lang_ar', 'label' => 'العربية', 'action' => 'set_language:ar'],
            ['id' => 'lang_fr', 'label' => 'Français', 'action' => 'set_language:fr'],
            ['id' => 'lang_en', 'label' => 'English', 'action' => 'set_language:en'],
        ];
    }

    protected function buildBuyerOrderConfirmationPayload(string $lang, string $orderCode, string $items, string $total): array
    {
        if ($lang === 'ar') {
            return [
                "🛍️ تم تسجيل طلبك الجديد {$orderCode}\nالمنتجات: {$items}\nالمبلغ عند الاستلام: {$total} دج\n\nهل تؤكد هذا الطلب ليبدأ البائع بتجهيز الشحنة عبر ياليدين؟",
                [
                    ['id' => 'confirm_order', 'label' => '✅ نعم، أؤكد الطلب', 'action' => 'confirm_order'],
                    ['id' => 'cancel_order', 'label' => '❌ لا، إلغاء الطلب', 'action' => 'cancel_order'],
                ],
                'تأكيد طلبك على Dressy',
            ];
        }

        if ($lang === 'en') {
            return [
                "🛍️ New COD Order Placed: {$orderCode}\nItems: {$items}\nCash on Delivery Total: {$total} DZD\n\nPlease confirm your order so the seller can prepare your Yalidine parcel:",
                [
                    ['id' => 'confirm_order', 'label' => '✅ Yes, I confirm', 'action' => 'confirm_order'],
                    ['id' => 'cancel_order', 'label' => '❌ No, cancel order', 'action' => 'cancel_order'],
                ],
                'Confirm your Dressy order',
            ];
        }

        return [
            "🛍️ Nouvelle commande enregistrée : {$orderCode}\nArticles : {$items}\nTotal à la livraison (COD) : {$total} DZD\n\nConfirmez-vous cette commande pour lancer l'expédition Yalidine ?",
            [
                ['id' => 'confirm_order', 'label' => '✅ Oui, je confirme', 'action' => 'confirm_order'],
                ['id' => 'cancel_order', 'label' => "❌ Non, j'annule", 'action' => 'cancel_order'],
            ],
            'Confirmez votre commande Dressy',
        ];
    }

    protected function buildSellerOrderPayload(string $lang, string $orderCode, string $items, string $total): array
    {
        if ($lang === 'ar') {
            return [
                "🎉 مبروك! لديك طلب جديد {$orderCode}\nالمنتجات: {$items}\nالمبلغ الإجمالي: {$total} دج\n\nيرجى تجهيز الطرد وتغليفه لإيداعه لدى Yalidine Express بعد تأكيد المشتري:",
                [
                    ['id' => 'parcel_ready', 'label' => '📦 الطرد جاهز للشحن', 'action' => 'parcel_ready'],
                    ['id' => 'shipping_help', 'label' => '❓ كيف أشحن الطلب؟', 'action' => 'shipping_help'],
                ],
                'طلب جديد على Dressy! 🎉',
            ];
        }

        if ($lang === 'en') {
            return [
                "🎉 Congrats! You received a new order {$orderCode}\nItems: {$items}\nTotal: {$total} DZD\n\nPlease prepare and pack the item for Yalidine Express drop-off:",
                [
                    ['id' => 'parcel_ready', 'label' => '📦 Parcel ready to ship', 'action' => 'parcel_ready'],
                    ['id' => 'shipping_help', 'label' => '❓ How do I ship?', 'action' => 'shipping_help'],
                ],
                'New sale on Dressy! 🎉',
            ];
        }

        return [
            "🎉 Félicitations ! Nouvelle vente {$orderCode}\nArticles : {$items}\nMontant total : {$total} DZD\n\nPréparez soigneusement le colis pour le dépôt au bureau Yalidine Express :",
            [
                ['id' => 'parcel_ready', 'label' => '📦 Colis prêt à expédier', 'action' => 'parcel_ready'],
                ['id' => 'shipping_help', 'label' => '❓ Comment expédier ?', 'action' => 'shipping_help'],
            ],
            'Nouvelle vente sur Dressy ! 🎉',
        ];
    }

    protected function resolveSellerUserId(Order $order): ?int
    {
        if ($order->vendor && $order->vendor->owner_user_id) {
            return (int) $order->vendor->owner_user_id;
        }
        $ownerId = Vendor::where('id', $order->vendor_id)->value('owner_user_id');
        if ($ownerId) {
            return (int) $ownerId;
        }
        $firstItemOwner = $order->orderItems->first()?->item?->added_user_id;

        return $firstItemOwner ? (int) $firstItemOwner : null;
    }

    protected function resolveUserPreferredLanguage(int $userId): string
    {
        $existing = ChabitThread::where('user_id', $userId)
            ->whereNotNull('language')
            ->latest('id')
            ->value('language');

        return in_array($existing, ['ar', 'fr', 'en'], true) ? $existing : 'fr';
    }

    protected function inferLanguageFromText(string $text): string
    {
        if (preg_match('/[\x{0600}-\x{06FF}]/u', $text)) {
            return 'ar';
        }
        $lower = strtolower($text);
        if (preg_match('/\b(hello|hi|order|shipping|wallet|cancel|help|price|item)\b/', $lower)) {
            return 'en';
        }

        return 'fr';
    }

    protected function orderStatusLabel(int $statusId): string
    {
        return match ($statusId) {
            (int) Constants::orderPendingStatus => 'Pending',
            (int) Constants::orderApprovedStatus => 'Confirmed / Approved',
            (int) Constants::orderDeliveringStatus => 'Delivering (Yalidine)',
            (int) Constants::orderDeliveredStatus => 'Delivered',
            (int) Constants::orderCancelledStatus => 'Cancelled',
            (int) Constants::orderReturnedStatus => 'Returned',
            default => 'Status #'.$statusId,
        };
    }

    protected function itemStatusLabel(int $status): string
    {
        return match ($status) {
            (int) Constants::publishItem => 'Published',
            (int) Constants::pendingItem => 'Pending Review',
            (int) Constants::rejectItem => 'Rejected',
            (int) Constants::disableItem => 'Disabled',
            default => 'Status #'.$status,
        };
    }
}
