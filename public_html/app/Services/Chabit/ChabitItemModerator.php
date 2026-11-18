<?php

namespace App\Services\Chabit;

use App\Jobs\ModerateItemWithChabitJob;
use App\Models\Chabit\ChabitMessage;
use App\Models\Chabit\ChabitSetting;
use App\Models\Chabit\ChabitThread;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\CoreImage;
use Modules\Core\Entities\Item;

class ChabitItemModerator
{
    public function __construct(
        protected ChabitGeminiClient $gemini,
        protected ChabitPushService $push
    ) {}

    /**
     * Dispatch moderation asynchronously via database queue (or afterResponse fallback)
     * so item creation/photo upload never blocks the user.
     */
    public static function dispatchForItem(int|string $itemId): void
    {
        try {
            if (! Schema::hasTable('chabit_settings')) {
                return;
            }
            $settings = ChabitSetting::current();
            if (! $settings->auto_approve_items || empty($settings->getEffectiveApiKey())) {
                return;
            }

            $queueConn = config('queue.default', 'sync');
            if ($queueConn === 'database' && Schema::hasTable('jobs')) {
                ModerateItemWithChabitJob::dispatch((int) $itemId)->onConnection('database');
            } else {
                // Fast stateless fallback: runs right after HTTP response is flushed to user
                ModerateItemWithChabitJob::dispatchAfterResponse((int) $itemId);
            }
        } catch (\Throwable $e) {
            Log::warning('ChabitItemModerator::dispatchForItem error: '.$e->getMessage());
        }
    }

    /**
     * Run Vision moderation against gemini-3.6-flash for the given item ID.
     */
    public function moderateItem(int $itemId): array
    {
        $settings = ChabitSetting::current();
        if (! $settings->auto_approve_items) {
            return ['skipped' => true, 'reason' => 'auto_approve_items disabled'];
        }

        if (empty($settings->getEffectiveApiKey())) {
            return ['skipped' => true, 'reason' => 'Gemini API key missing'];
        }

        $item = Item::with(['category', 'subcategory'])->find($itemId);
        if (! $item) {
            return ['skipped' => true, 'reason' => 'Item not found'];
        }

        // Respect manual admin override
        if (! empty($item->approved_by_admin)) {
            return ['skipped' => true, 'reason' => 'Already manually approved by admin'];
        }

        // Collect up to 4 item cover images
        $images = CoreImage::where('img_parent_id', $item->id)
            ->whereIn('img_type', [Constants::itemCoverImgType, 'item'])
            ->orderBy('ordering', 'asc')
            ->limit(4)
            ->get();

        if ($images->isEmpty()) {
            // Item created before images finished uploading; mark pending until image upload triggers moderation
            $this->updateItemModerationColumns($item->id, [
                'ai_moderation_status' => 'pending',
            ]);

            return ['skipped' => true, 'reason' => 'No images uploaded yet'];
        }

        $imageParts = [];
        foreach ($images as $img) {
            $encoded = $this->encodeImageToInlineData($img->img_path);
            if ($encoded) {
                $imageParts[] = $encoded;
            }
        }

        if (empty($imageParts)) {
            $this->updateItemModerationColumns($item->id, [
                'ai_moderation_status' => 'manual_review',
                'ai_moderation_reason' => 'Image files could not be read for AI inspection.',
                'ai_confidence' => 0,
            ]);

            return ['decision' => 'manual_review', 'reason' => 'Unreadable image files'];
        }

        $sizeValue = $this->extractItemSize($item->id);
        $categoryName = $item->category?->name ?? 'Unknown';
        $subcategoryName = $item->subcategory?->name ?? 'Unknown';

        $promptText = <<<PROMPT
You are Chabit, Dressy Algeria's strict fashion marketplace vision moderator.
Analyze the attached listing photos and metadata, then return STRICT JSON ONLY matching this exact schema:
{
  "decision": "approve | reject | manual_review",
  "confidence": 0-100,
  "matches_subcategory": true,
  "is_clean_image": true,
  "reason_fr": "Clear explanation in French",
  "reason_ar": "Clear explanation in Arabic",
  "reason_en": "Clear explanation in English"
}

LISTING METADATA:
- Title: {$item->title}
- Description: {$item->description}
- Category: {$categoryName}
- Subcategory: {$subcategoryName}
- Size: {$sizeValue}
- Price (DZD): {$item->original_price}

MODERATION RULES:
1. REJECT if ANY photo contains visible phone numbers (e.g. 05/06/07/021...), WhatsApp/Viber/Instagram/Facebook/TikTok handles, external links, or heavy stock watermarks.
2. REJECT if ANY text (title or description) contains phone numbers, WhatsApp, or social handles trying to bypass Dressy.
3. REJECT if the item is NSFW, counterfeit/prohibited, blank, pitch-dark, extremely blurry, or completely unrelated to the selected Category & Subcategory (e.g. subcategory is Shoes/Chaussures but photo shows a Dress or random object).
4. APPROVE with high confidence (85-100) if photos are clean, clear, authentic fashion/baby items matching the selected Category & Subcategory with zero policy violations.
5. MANUAL_REVIEW if borderline, ambiguous subcategory match, or confidence < {$settings->auto_approve_confidence}.
PROMPT;

        $parts = array_merge([['text' => $promptText]], $imageParts);

        $response = $this->gemini->generateContent(
            contents: [
                [
                    'role' => 'user',
                    'parts' => $parts,
                ],
            ],
            expectJson: true
        );

        if (! $response['ok']) {
            Log::warning("ChabitItemModerator Gemini error for item #{$item->id}: ".($response['error'] ?? 'unknown'));
            $this->updateItemModerationColumns($item->id, [
                'ai_moderation_status' => 'manual_review',
                'ai_moderation_reason' => 'AI moderation temporarily unavailable; queued for admin review.',
            ]);

            return ['decision' => 'manual_review', 'error' => $response['error'] ?? 'API error'];
        }

        $parsed = $this->parseJsonOutput($response['text'] ?? '');
        if (! is_array($parsed)) {
            $this->updateItemModerationColumns($item->id, [
                'ai_moderation_status' => 'manual_review',
                'ai_moderation_reason' => 'Invalid AI response format; queued for admin review.',
            ]);

            return ['decision' => 'manual_review', 'error' => 'Invalid JSON'];
        }

        $decision = strtolower((string) ($parsed['decision'] ?? 'manual_review'));
        $confidence = max(0, min(100, (int) ($parsed['confidence'] ?? 0)));
        $matchesSubcat = (bool) ($parsed['matches_subcategory'] ?? false);
        $isClean = (bool) ($parsed['is_clean_image'] ?? false);
        $threshold = (int) ($settings->auto_approve_confidence ?: 85);

        $reasonFr = trim((string) ($parsed['reason_fr'] ?? ''));
        $reasonAr = trim((string) ($parsed['reason_ar'] ?? ''));
        $reasonEn = trim((string) ($parsed['reason_en'] ?? ''));
        $combinedReason = $reasonFr ?: ($reasonEn ?: $reasonAr);

        // Enforce strict thresholds
        if ($decision === 'approve' && $matchesSubcat && $isClean && $confidence >= $threshold) {
            $finalDecision = 'approved';
            $newStatus = Constants::publishItem; // 1 = Published
        } elseif ($decision === 'reject') {
            $finalDecision = 'rejected';
            $newStatus = Constants::rejectItem; // 3 = Rejected
        } else {
            $finalDecision = 'manual_review';
            $newStatus = Constants::pendingItem; // 0 = Pending
        }

        $this->updateItemModerationColumns($item->id, [
            'status' => $newStatus,
            'ai_moderation_status' => $finalDecision,
            'ai_moderation_reason' => $combinedReason,
            'ai_confidence' => $confidence,
        ]);

        // Clear item caches if available
        try {
            \Modules\Core\Http\Facades\PsCache::clear(\App\Config\Cache\ItemCache::BASE);
        } catch (\Throwable $e) {
            // ignore cache clear failures
        }

        // Notify seller on rejection (and approval)
        $this->notifySeller($item, $finalDecision, $reasonFr, $reasonAr, $reasonEn);

        return [
            'item_id' => $item->id,
            'decision' => $finalDecision,
            'confidence' => $confidence,
            'reason' => $combinedReason,
        ];
    }

    protected function notifySeller(Item $item, string $decision, string $reasonFr, string $reasonAr, string $reasonEn): void
    {
        if (empty($item->added_user_id)) {
            return;
        }

        try {
            $thread = ChabitThread::firstOrCreate(
                ['user_id' => $item->added_user_id, 'thread_type' => 'assistant'],
                ['last_message_at' => now()]
            );

            $lang = $thread->language ?: 'fr';

            if ($decision === 'rejected') {
                $reason = $lang === 'ar' ? ($reasonAr ?: $reasonFr) : ($lang === 'en' ? ($reasonEn ?: $reasonFr) : ($reasonFr ?: $reasonEn));
                if ($lang === 'ar') {
                    $title = 'تم رفض إعلانك مؤقتاً';
                    $body = "⚠️ لم تتم الموافقة على إعلانك \"{$item->title}\".\nالسبب: {$reason}\nيرجى تعديل الصور أو المعلومات وإعادة النشر.";
                } elseif ($lang === 'en') {
                    $title = 'Listing needs adjustment';
                    $body = "⚠️ Your listing \"{$item->title}\" was not approved.\nReason: {$reason}\nPlease update your photos or details and resubmit.";
                } else {
                    $title = 'Annonce à corriger';
                    $body = "⚠️ Votre annonce « {$item->title} » n'a pas été approuvée.\nRaison : {$reason}\nMerci de corriger les photos ou détails puis de republier.";
                }

                ChabitMessage::create([
                    'thread_id' => $thread->id,
                    'sender_type' => 'system',
                    'body' => $body,
                    'metadata' => ['item_id' => $item->id, 'moderation' => 'rejected'],
                ]);
                $thread->update(['last_message_at' => now()]);
                $this->push->sendToUser($item->added_user_id, $title, $body, $thread->id);
            } elseif ($decision === 'approved') {
                if ($lang === 'ar') {
                    $title = 'تم نشر إعلانك بنجاح! 🎉';
                    $body = "✅ تمت الموافقة على إعلانك \"{$item->title}\" وهو الآن متاح للمشترين على Dressy.";
                } elseif ($lang === 'en') {
                    $title = 'Your listing is live! 🎉';
                    $body = "✅ Your listing \"{$item->title}\" has been approved and is now live on Dressy.";
                } else {
                    $title = 'Votre annonce est en ligne ! 🎉';
                    $body = "✅ Votre annonce « {$item->title} » a été approuvée automatiquement et est maintenant visible sur Dressy.";
                }

                ChabitMessage::create([
                    'thread_id' => $thread->id,
                    'sender_type' => 'system',
                    'body' => $body,
                    'metadata' => ['item_id' => $item->id, 'moderation' => 'approved'],
                ]);
                $thread->update(['last_message_at' => now()]);
                $this->push->sendToUser($item->added_user_id, $title, $body, $thread->id);
            }
        } catch (\Throwable $e) {
            Log::warning('ChabitItemModerator notifySeller failed: '.$e->getMessage());
        }
    }

    protected function encodeImageToInlineData(?string $imgPath): ?array
    {
        if (empty($imgPath)) {
            return null;
        }

        $clean = ltrim($imgPath, '/');
        $candidates = [
            public_path('storage/PSX_MPC/uploads/'.$clean),
            public_path('uploads/'.$clean),
            storage_path('app/public/PSX_MPC/uploads/'.$clean),
            storage_path('app/public/uploads/'.$clean),
            public_path($clean),
        ];

        $filePath = null;
        foreach ($candidates as $path) {
            if (is_file($path) && filesize($path) > 0) {
                $filePath = $path;
                break;
            }
        }

        if (! $filePath) {
            return null;
        }

        // Skip overly huge files (> 4MB) or downscale if GD is available
        $mime = mime_content_type($filePath) ?: 'image/jpeg';
        if (! str_starts_with($mime, 'image/')) {
            return null;
        }

        $bytes = @file_get_contents($filePath);
        if ($bytes === false) {
            return null;
        }

        return [
            'inlineData' => [
                'mimeType' => $mime,
                'data' => base64_encode($bytes),
            ],
        ];
    }

    protected function extractItemSize(int $itemId): string
    {
        try {
            $row = DB::table('psx_item_infos')
                ->where('item_id', $itemId)
                ->whereIn('core_keys_id', ['itm00037', 'ps-itm00037'])
                ->first();

            if (! $row || empty($row->value)) {
                return 'N/A';
            }

            if (is_numeric($row->value)) {
                $attr = DB::table('psx_customize_ui_details')->where('id', $row->value)->value('name');
                if ($attr) {
                    return (string) $attr;
                }
            }

            return (string) $row->value;
        } catch (\Throwable $e) {
            return 'N/A';
        }
    }

    protected function parseJsonOutput(string $text): ?array
    {
        $clean = trim($text);
        if (str_starts_with($clean, '```')) {
            $clean = preg_replace('/^```[a-zA-Z]*\s*|\s*```$/', '', $clean);
        }

        $decoded = json_decode(trim($clean), true);
        if (is_array($decoded)) {
            return $decoded;
        }

        if (preg_match('/\{.*\}/s', $clean, $m)) {
            $decoded = json_decode($m[0], true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        return null;
    }

    protected function updateItemModerationColumns(int $itemId, array $data): void
    {
        $filtered = [];
        foreach ($data as $col => $val) {
            if ($col === 'status' || Schema::hasColumn('psx_items', $col)) {
                $filtered[$col] = $val;
            }
        }
        if (! empty($filtered)) {
            DB::table('psx_items')->where('id', $itemId)->update($filtered);
        }
    }
}
