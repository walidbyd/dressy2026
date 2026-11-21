<?php

namespace App\Console\Commands;

use App\Models\DeliverySetting;
use App\Services\OrderChatNotificationService;
use App\Services\YalidineService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class SyncYalidineStatusesCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'yalidine:sync-statuses {--limit=50 : Maximum number of active orders to check}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Polls Yalidine logistics API to sync parcel delivery statuses and trigger automatic escrow credit or reversal';

    /**
     * Execute the console command.
     */
    public function handle(WalletService $walletService, OrderChatNotificationService $chatNotiService): int
    {
        $setting = DeliverySetting::getSettings();
        if (!$setting->is_enabled || !$setting->auto_sync_status) {
            $this->info('Yalidine automatic status synchronization is currently disabled in delivery settings.');
            return 0;
        }

        $limit = (int) $this->option('limit');
        $orders = Order::whereNotNull('yalidine_tracking')
            ->whereIn('order_status_id', [
                Constants::orderDeliveringStatus,
                Constants::orderApprovedStatus,
            ])
            ->latest('updated_date')
            ->take($limit)
            ->get();

        if ($orders->isEmpty()) {
            $this->info('No in-transit Yalidine orders to sync.');
            return 0;
        }

        $this->info("Checking status for {$orders->count()} orders...");

        $apiId = $setting->api_id;
        $apiToken = $setting->api_token;
        $baseUrl = rtrim((string) ($setting->api_base_url ?: 'https://api.yalidine.app/v1'), '/');

        $isSandbox = ($setting->environment === 'sandbox' || empty($apiId) || empty($apiToken));

        foreach ($orders as $order) {
            $tracking = $order->yalidine_tracking;
            $this->line("Checking Order #{$order->order_code} (Tracking: {$tracking})...");

            if ($isSandbox) {
                // In sandbox or stub mode, do not fail
                $this->line("  [Sandbox/Stub Mode] Skipping live API polling for tracking {$tracking}");
                continue;
            }

            try {
                $response = Http::withHeaders([
                    'X-API-ID' => $apiId,
                    'X-API-TOKEN' => $apiToken,
                    'Accept' => 'application/json',
                ])->timeout(12)->get("{$baseUrl}/histories/", [
                    'tracking' => $tracking,
                ]);

                if (!$response->successful()) {
                    $this->warn("  Yalidine API returned HTTP {$response->status()} for tracking {$tracking}");
                    continue;
                }

                $json = $response->json();
                $histories = $json['data'] ?? ($json[$tracking] ?? $json);
                if (!is_array($histories) || empty($histories)) {
                    continue;
                }

                $latestStatus = null;
                if (isset($histories[0]['status'])) {
                    $latestStatus = strtolower(trim((string) $histories[0]['status']));
                } elseif (isset($histories['status'])) {
                    $latestStatus = strtolower(trim((string) $histories['status']));
                }

                if (!$latestStatus) {
                    continue;
                }

                $order->yalidine_status = $latestStatus;
                $order->yalidine_parcel_status = $latestStatus;

                // Check for Delivered
                if (in_array($latestStatus, ['livré', 'livre', 'delivered', 'recu', 'reçu'])) {
                    $this->info("  Order #{$order->order_code} is DELIVERED! Triggering wallet credit...");
                    $walletService->creditForOrder($order);
                    $chatNotiService->updateOrderActionStatus($order, 'delivered');
                    $chatNotiService->sendOrderStatusUpdate($order, 'Commande livrée avec succès selon le suivi Yalidine !', 'both');
                }
                // Check for Returned / Cancelled / Failed
                elseif (in_array($latestStatus, ['retourné', 'retourne', 'returned', 'annulé', 'annule', 'cancelled', 'echoue', 'échoué', 'failed'])) {
                    $this->warn("  Order #{$order->order_code} was RETURNED/CANCELLED ({$latestStatus})! Triggering wallet reversal...");
                    $order->order_status_id = Constants::orderReturnedStatus;
                    $order->status_reason = "Retour / Échec de livraison Yalidine ({$latestStatus})";
                    $order->save();
                    $walletService->reverseOrderFunds($order, "Retour Yalidine ({$latestStatus})");
                    $chatNotiService->updateOrderActionStatus($order, 'cancelled');
                    $chatNotiService->sendOrderStatusUpdate($order, "Colis retourné par le transporteur Yalidine ({$latestStatus}).", 'both');
                } else {
                    // Update in-transit status
                    $order->order_status_id = Constants::orderDeliveringStatus;
                    $order->save();
                }
            } catch (\Throwable $e) {
                Log::warning("Yalidine status sync error for {$tracking}: " . $e->getMessage());
                $this->error("  Error checking {$tracking}: " . $e->getMessage());
            }
        }

        $this->info('Yalidine status synchronization completed.');
        return 0;
    }
}
