<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliverySetting;
use App\Services\OrderChatNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class YalidineWebhookController extends Controller
{
    /**
     * Handle Yalidine Webhook (parcel_status_updated).
     *
     * POST /api/v1/yalidine/webhook
     * POST /api/v1.0/delivery/yalidine/webhook
     */
    public function handle(
        Request $request,
        WalletService $walletService,
        OrderChatNotificationService $chatNotiService
    ): JsonResponse {
        $rawBody = (string) $request->getContent();
        $signature = $request->header('X-Yalidine-Signature')
            ?: ($request->header('X-Signature') ?: '');

        $setting = DeliverySetting::getSettings();
        $secret = !empty($setting->webhook_secret) ? trim((string) $setting->webhook_secret) : null;

        // 1. Verify HMAC-SHA256 signature if secret is configured
        if (!empty($secret)) {
            if (empty($signature)) {
                // Also check query param or legacy header if sent
                $fallbackSecret = $request->header('X-Yalidine-Secret')
                    ?: ($request->header('X-Webhook-Secret') ?: $request->query('secret'));

                if ($fallbackSecret !== $secret) {
                    Log::warning('Yalidine webhook rejected: missing X-Yalidine-Signature header.');
                    return response()->json(['error' => 'Unauthorized: Missing signature'], 401);
                }
            } else {
                $computed = hash_hmac('sha256', $rawBody, $secret);
                if (!hash_equals($computed, (string) $signature)) {
                    Log::warning('Yalidine webhook signature verification failed.', [
                        'received_signature' => $signature,
                    ]);
                    return response()->json(['error' => 'Unauthorized: Invalid signature'], 401);
                }
            }
        }

        // 2. Decode payload
        $payload = json_decode($rawBody, true);
        if (!is_array($payload)) {
            $payload = $request->all();
        }

        Log::info('Yalidine webhook received:', ['payload' => $payload]);

        // Yalidine may send { "events": [ ... ] } or a single event { "event_id": ..., "data": ... }
        $events = [];
        if (isset($payload['events']) && is_array($payload['events'])) {
            $events = $payload['events'];
        } elseif (!empty($payload)) {
            $events = [$payload];
        }

        $processedCount = 0;

        foreach ($events as $event) {
            if (!is_array($event)) {
                continue;
            }

            // Deduplicate retried webhook events by event_id
            $eventId = $event['event_id'] ?? ($event['id'] ?? null);
            if (!empty($eventId)) {
                $cacheKey = "yalidine_webhook_evt_{$eventId}";
                if (Cache::has($cacheKey)) {
                    Log::info("Yalidine webhook event #{$eventId} already processed (idempotent skip).");
                    continue;
                }
                Cache::put($cacheKey, true, 86400 * 7); // Cache for 7 days
            }

            $data = $event['data'] ?? $event;
            $tracking = $data['tracking'] ?? ($data['tracking_number'] ?? null);
            $orderCode = $data['order_id'] ?? ($data['reference'] ?? null);
            $rawStatus = trim((string) ($data['status'] ?? ($data['parcel_status'] ?? ($event['status'] ?? ''))));
            $reason = trim((string) ($data['reason'] ?? ($data['status_reason'] ?? ($event['reason'] ?? ''))));

            if (empty($tracking) && empty($orderCode)) {
                continue;
            }

            // Find order
            $order = null;
            if (!empty($tracking)) {
                $order = Order::where('yalidine_tracking', $tracking)->first();
            }
            if (!$order && !empty($orderCode)) {
                $order = Order::where('order_code', $orderCode)->first();
            }

            if (!$order) {
                Log::info("Yalidine webhook: Order not found for tracking {$tracking} or code {$orderCode}");
                continue;
            }

            // 3. Process status update & wallet credit inside DB Transaction
            DB::transaction(function () use ($order, $rawStatus, $reason, $tracking, $walletService, $chatNotiService) {
                $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->first();
                if (!$lockedOrder) {
                    return;
                }

                $lockedOrder->yalidine_status = $rawStatus;
                $lockedOrder->yalidine_parcel_status = $rawStatus;
                if (!empty($reason)) {
                    $lockedOrder->status_reason = $reason;
                }
                if (!empty($tracking) && empty($lockedOrder->yalidine_tracking)) {
                    $lockedOrder->yalidine_tracking = $tracking;
                }

                $cleanStatus = strtolower($rawStatus);

                // Map statuses according to Dressy business rules
                if (self::isDeliveredStatus($cleanStatus)) {
                    $lockedOrder->order_status_id = Constants::orderDeliveredStatus;
                    if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'delivered_at') && empty($lockedOrder->delivered_at)) {
                        $lockedOrder->delivered_at = now();
                    }
                    $lockedOrder->save();

                    // Idempotent wallet credit
                    $walletService->creditForOrder($lockedOrder);

                    $chatNotiService->updateOrderActionStatus($lockedOrder, 'delivered');
                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        'Commande livrée avec succès ! (Mise à jour transporteur Yalidine)',
                        'both'
                    );
                } elseif (self::isReturnedStatus($cleanStatus)) {
                    $lockedOrder->order_status_id = Constants::orderReturnedStatus;
                    if (empty($lockedOrder->status_reason)) {
                        $lockedOrder->status_reason = "Retour Yalidine: {$rawStatus}";
                    }
                    $lockedOrder->save();

                    $walletService->reverseOrderFunds($lockedOrder, "Retour Yalidine ({$rawStatus})");
                    $chatNotiService->updateOrderActionStatus($lockedOrder, 'cancelled');
                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        "Colis retourné au vendeur par Yalidine ({$rawStatus}).",
                        'both'
                    );
                } elseif (self::isCancelledStatus($cleanStatus)) {
                    $lockedOrder->order_status_id = Constants::orderCancelledStatus;
                    if (empty($lockedOrder->status_reason)) {
                        $lockedOrder->status_reason = "Annulation Yalidine: {$rawStatus}";
                    }
                    $lockedOrder->save();

                    $walletService->reverseOrderFunds($lockedOrder, "Annulation Yalidine ({$rawStatus})");
                    $chatNotiService->updateOrderActionStatus($lockedOrder, 'cancelled');
                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        "Commande annulée par le transporteur Yalidine ({$rawStatus}).",
                        'both'
                    );
                } elseif (self::isDeliveringStatus($cleanStatus)) {
                    $lockedOrder->order_status_id = Constants::orderDeliveringStatus;
                    $lockedOrder->save();

                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        "Colis en cours d'acheminement avec Yalidine ({$rawStatus})" . (!empty($lockedOrder->yalidine_tracking) ? " - Suivi: {$lockedOrder->yalidine_tracking}" : ''),
                        'both'
                    );
                } elseif (self::isPreparingStatus($cleanStatus)) {
                    $lockedOrder->order_status_id = Constants::orderApprovedStatus;
                    $lockedOrder->save();

                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        "Commande en cours de préparation ({$rawStatus}).",
                        'both'
                    );
                } else {
                    $lockedOrder->save();
                    $chatNotiService->sendOrderStatusUpdate(
                        $lockedOrder,
                        "Mise à jour statut Yalidine: {$rawStatus}",
                        'both'
                    );
                }
            });

            $processedCount++;
        }

        return response()->json([
            'received' => true,
            'processed' => $processedCount,
        ]);
    }

    /**
     * Check if status corresponds to "En préparation" / "Pas encore expédié".
     */
    protected static function isPreparingStatus(string $status): bool
    {
        return in_array($status, [
            'en préparation', 'en preparation', 'pas encore expédié', 'pas encore expedie',
            'en attente', 'pending', 'confirmed', 'dispatched'
        ], true);
    }

    /**
     * Check if status corresponds to "Expédié" / "En transit" / "Centre" / "Vers Wilaya" / "Sorti en livraison".
     */
    protected static function isDeliveringStatus(string $status): bool
    {
        foreach ([
            'expédié', 'expedie', 'en transit', 'centre', 'vers wilaya', 'reçu à wilaya',
            'recu a wilaya', 'sorti en livraison', 'in_transit', 'delivering', 'en cours', 'en_cours'
        ] as $keyword) {
            if (str_contains($status, $keyword)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if status corresponds to "Livré".
     */
    protected static function isDeliveredStatus(string $status): bool
    {
        return in_array($status, ['livré', 'livre', 'delivered', 'recu', 'reçu', 'livré et payé'], true)
            || str_contains($status, 'livré')
            || str_contains($status, 'delivered');
    }

    /**
     * Check if status corresponds to "Retourné au vendeur".
     */
    protected static function isReturnedStatus(string $status): bool
    {
        foreach ([
            'retour vers vendeur', 'retourné au vendeur', 'retourne au vendeur',
            'retour transfer', 'retourné', 'retourne', 'returned', 'retour'
        ] as $keyword) {
            if (str_contains($status, $keyword)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if status corresponds to "Annulé".
     */
    protected static function isCancelledStatus(string $status): bool
    {
        return in_array($status, ['annulé', 'annule', 'cancelled', 'canceled'], true)
            || str_contains($status, 'annul');
    }
}
