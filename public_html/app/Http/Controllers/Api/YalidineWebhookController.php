<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliverySetting;
use App\Services\OrderChatNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class YalidineWebhookController extends Controller
{
    public function handle(Request $request, WalletService $walletService, OrderChatNotificationService $chatNotiService): JsonResponse
    {
        $setting = DeliverySetting::getSettings();

        // Optional webhook secret verification
        if (!empty($setting->webhook_secret)) {
            $incomingSecret = $request->header('X-Yalidine-Secret')
                ?: ($request->header('X-Webhook-Secret') ?: $request->query('secret'));

            if ($incomingSecret !== $setting->webhook_secret) {
                Log::warning('Yalidine webhook unauthorized attempt with invalid secret.');
                return response()->json(['error' => 'Unauthorized: Invalid webhook secret'], 401);
            }
        }

        $payload = $request->all();
        Log::info('Yalidine webhook received:', $payload);

        $tracking = $payload['tracking'] ?? ($payload['tracking_number'] ?? null);
        $orderCode = $payload['order_id'] ?? ($payload['reference'] ?? null);
        $rawStatus = strtolower(trim((string) ($payload['status'] ?? ($payload['event'] ?? ''))));

        $order = null;
        if (!empty($tracking)) {
            $order = Order::where('yalidine_tracking', $tracking)->first();
        }
        if (!$order && !empty($orderCode)) {
            $order = Order::where('order_code', $orderCode)->first();
        }

        if (!$order) {
            return response()->json(['status' => 'ignored', 'message' => 'Order not found for tracking or code'], 200);
        }

        $order->yalidine_status = $rawStatus;
        $order->yalidine_parcel_status = $rawStatus;

        if (in_array($rawStatus, ['livré', 'livre', 'delivered', 'recu', 'reçu'])) {
            $walletService->creditForOrder($order);
            $chatNotiService->updateOrderActionStatus($order, 'delivered');
            $chatNotiService->sendOrderStatusUpdate($order, 'Commande livrée avec succès ! (Mise à jour transporteur Yalidine)', 'both');
        } elseif (in_array($rawStatus, ['retourné', 'retourne', 'returned', 'annulé', 'annule', 'cancelled', 'echoue', 'échoué', 'failed'])) {
            $order->order_status_id = Constants::orderReturnedStatus;
            $order->status_reason = "Retour / Échec de livraison Yalidine ({$rawStatus})";
            $order->save();
            $walletService->reverseOrderFunds($order, "Retour Yalidine ({$rawStatus})");
            $chatNotiService->updateOrderActionStatus($order, 'cancelled');
            $chatNotiService->sendOrderStatusUpdate($order, "Colis retourné par le transporteur Yalidine ({$rawStatus}).", 'both');
        } elseif (in_array($rawStatus, ['en cours', 'en_cours', 'dispatched', 'in_transit', 'transit', 'centre'])) {
            $order->order_status_id = Constants::orderDeliveringStatus;
            $order->save();
        }

        return response()->json(['status' => 'success', 'order_code' => $order->order_code]);
    }
}
