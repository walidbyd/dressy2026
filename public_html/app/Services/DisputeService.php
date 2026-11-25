<?php

namespace App\Services;

use App\Models\OrderDispute;
use Carbon\Carbon;
use Illuminate\Support\Facades\Schema;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\StoreFront\VendorPanel\Entities\Order;

class DisputeService
{
    public const DISPUTE_WINDOW_DAYS = 7;

    public const DISPUTE_TYPES = [
        'not_as_described',
        'damaged_defective',
        'wrong_item',
        'missing_item',
        'return_request',
        'other',
    ];

    public function __construct(
        protected OrderChatNotificationService $chatNotiService
    ) {}

    public function resolveDeliveredAt(Order $order): ?Carbon
    {
        if (!empty($order->delivered_at)) {
            return Carbon::parse($order->delivered_at);
        }
        if (!empty($order->wallet_credited_at)) {
            return Carbon::parse($order->wallet_credited_at);
        }
        if ((int) $order->order_status_id === 4 && !empty($order->updated_at)) {
            return Carbon::parse($order->updated_at);
        }
        return null;
    }

    public function isOrderDelivered(Order $order): bool
    {
        if ((int) $order->order_status_id === 4) {
            return true;
        }
        $yStatus = mb_strtolower((string) ($order->yalidine_parcel_status ?? $order->yalidine_status ?? ''), 'UTF-8');
        return str_contains($yStatus, 'livré') || str_contains($yStatus, 'livre') || str_contains($yStatus, 'delivered');
    }

    public function getEligibility(Order $order): array
    {
        $existing = Schema::hasTable('psx_order_disputes')
            ? OrderDispute::where('order_id', $order->id)->first()
            : null;

        if ($existing) {
            return [
                'eligible' => false,
                'reason' => 'already_opened',
                'days_remaining' => 0,
                'delivered_at' => $existing->delivered_at?->toIso8601String(),
                'dispute' => $existing,
            ];
        }

        if (!$this->isOrderDelivered($order)) {
            return [
                'eligible' => false,
                'reason' => 'not_delivered',
                'days_remaining' => 0,
                'delivered_at' => null,
                'dispute' => null,
            ];
        }

        $deliveredAt = $this->resolveDeliveredAt($order);
        if (!$deliveredAt) {
            return [
                'eligible' => true,
                'reason' => null,
                'days_remaining' => self::DISPUTE_WINDOW_DAYS,
                'delivered_at' => null,
                'dispute' => null,
            ];
        }

        $deadline = $deliveredAt->copy()->addDays(self::DISPUTE_WINDOW_DAYS);
        $now = Carbon::now();
        if ($now->gt($deadline)) {
            return [
                'eligible' => false,
                'reason' => 'window_expired',
                'days_remaining' => 0,
                'delivered_at' => $deliveredAt->toIso8601String(),
                'dispute' => null,
            ];
        }

        $daysRemaining = max(1, (int) ceil($now->diffInSeconds($deadline) / 86400));

        return [
            'eligible' => true,
            'reason' => null,
            'days_remaining' => $daysRemaining,
            'delivered_at' => $deliveredAt->toIso8601String(),
            'dispute' => null,
        ];
    }

    public function createDispute(Order $order, int $buyerUserId, string $disputeType, string $description): array
    {
        if ((int) $order->user_id !== $buyerUserId && (int) $order->added_user_id !== $buyerUserId) {
            return ['success' => false, 'status_code' => 403, 'message' => 'Accès refusé pour cette commande.'];
        }

        $eligibility = $this->getEligibility($order);
        if (empty($eligibility['eligible'])) {
            $msg = match ($eligibility['reason']) {
                'already_opened' => 'Un litige existe déjà pour cette commande.',
                'window_expired' => 'Le délai de 7 jours après livraison est expiré.',
                default => 'Un litige ne peut être ouvert qu\'après la livraison de la commande.',
            };
            return ['success' => false, 'status_code' => 422, 'message' => $msg];
        }

        $sellerUserId = $order->vendor?->owner_user_id;
        if (!$sellerUserId && $order->vendor_id) {
            $sellerUserId = Vendor::where('id', $order->vendor_id)->value('owner_user_id');
        }

        $deliveredAt = $this->resolveDeliveredAt($order);

        $dispute = OrderDispute::create([
            'order_id' => $order->id,
            'order_code' => (string) $order->order_code,
            'buyer_user_id' => $buyerUserId,
            'vendor_id' => $order->vendor_id,
            'seller_user_id' => $sellerUserId,
            'dispute_type' => $disputeType,
            'description' => trim($description),
            'status' => 'open',
            'delivered_at' => $deliveredAt,
        ]);

        // Notify vendor & enable buyer-vendor conversation in the order thread
        $typeLabel = $this->humanType($disputeType);
        $msg = "⚠️ Litige ouvert pour la commande #{$order->order_code}\nMotif : {$typeLabel}\nDétails : {$dispute->description}\n\nVous pouvez échanger ici ou contacter le support.";
        $this->chatNotiService->sendOrderStatusUpdate($order, $msg, 'both');

        return [
            'success' => true,
            'status_code' => 200,
            'message' => 'Votre litige a été ouvert et transmis au vendeur et à l\'administration.',
            'dispute' => $dispute,
        ];
    }

    public function resolveDispute(OrderDispute $dispute, string $newStatus, ?string $adminNote, ?int $adminUserId): OrderDispute
    {
        $dispute->status = $newStatus;
        $dispute->admin_note = $adminNote;
        if (in_array($newStatus, ['resolved_buyer', 'resolved_vendor', 'closed'], true)) {
            $dispute->resolved_by = $adminUserId;
            $dispute->resolved_at = Carbon::now();
        }
        $dispute->save();

        if ($dispute->order) {
            $statusText = match ($newStatus) {
                'resolved_buyer' => 'Litige résolu en faveur de l\'acheteur',
                'resolved_vendor' => 'Litige résolu en faveur du vendeur',
                'under_review' => 'Litige en cours d\'examen par l\'administration',
                'closed' => 'Litige clôturé par l\'administration',
                default => 'Mise à jour du litige',
            };
            $msg = "⚖️ {$statusText} (Commande #{$dispute->order_code})" . (!empty($adminNote) ? "\nNote Admin : {$adminNote}" : '');
            $this->chatNotiService->sendOrderStatusUpdate($dispute->order, $msg, 'both');
        }

        return $dispute;
    }

    public function humanType(string $type): string
    {
        return match ($type) {
            'not_as_described' => 'Non conforme à la description',
            'damaged_defective' => 'Endommagé / Défectueux',
            'wrong_item' => 'Mauvais article reçu',
            'missing_item' => 'Article manquant',
            'return_request' => 'Demande de retour',
            default => 'Autre',
        };
    }
}
