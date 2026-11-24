<?php

namespace App\Console\Commands;

use App\Services\OrderChatNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class CancelExpiredOrdersCommand extends Command
{
    protected $signature = 'orders:cancel-expired';

    protected $description = 'Automatically cancel orders whose 72-hour vendor fulfillment/acceptance deadline has expired.';

    public function handle(): int
    {
        $count = self::processExpiredOrders();
        $this->info("Cancelled {$count} expired order(s).");
        return Command::SUCCESS;
    }

    /**
     * Reusable due-check helper (safe to call from cron or throttled API/load hooks).
     */
    public static function processExpiredOrders(): int
    {
        try {
            if (!Schema::hasColumn('psx_orders', 'fulfillment_deadline_at')) {
                return 0;
            }

            $now = Carbon::now();
            $expiredOrders = Order::whereNotNull('fulfillment_deadline_at')
                ->where('fulfillment_deadline_at', '<', $now)
                ->whereIn('order_status_id', [
                    Constants::orderPendingStatus,
                    Constants::orderApprovedStatus,
                    Constants::orderDeliveringStatus,
                ])
                ->where(function ($q) {
                    $q->whereNull('yalidine_parcel_status')
                        ->orWhereIn('yalidine_parcel_status', ['', 'dispatched', 'En préparation']);
                })
                ->limit(50)
                ->get();

            $cancelledCount = 0;
            foreach ($expiredOrders as $order) {
                $reason = 'Délai de 72h expiré — annulation automatique.';
                $order->order_status_id = Constants::orderCancelledStatus;
                $order->status_reason = $reason;
                $order->save();

                try {
                    app(WalletService::class)->reverseOrderFunds($order, $reason, 1);
                } catch (\Throwable $e) {
                    Log::error("Auto-cancel wallet reversal failed for order #{$order->id}: " . $e->getMessage());
                }

                try {
                    $chatNotiService = app(OrderChatNotificationService::class);
                    $chatNotiService->updateOrderActionStatus($order, 'cancelled');
                    $chatNotiService->sendOrderStatusUpdate(
                        $order,
                        "La commande #{$order->order_code} a été annulée automatiquement (délai de 72h expiré).",
                        'both'
                    );
                } catch (\Throwable $e) {
                    Log::warning("Auto-cancel chat notification failed for order #{$order->id}: " . $e->getMessage());
                }

                $cancelledCount++;
            }

            return $cancelledCount;
        } catch (\Throwable $e) {
            Log::warning('processExpiredOrders error: ' . $e->getMessage());
            return 0;
        }
    }
}
