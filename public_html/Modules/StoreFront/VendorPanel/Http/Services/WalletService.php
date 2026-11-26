<?php

namespace Modules\StoreFront\VendorPanel\Http\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Entities\WithdrawRequest;

class WalletService
{
    /**
     * Get or create a wallet for the specified user.
     *
     * @param  int|string  $userId
     * @param  int|string|null  $vendorId
     * @return Wallet
     */
    public function getOrCreateWalletForUser($userId, $vendorId = null): Wallet
    {
        if (! $vendorId) {
            $vendorId = Vendor::where('owner_user_id', $userId)->value('id');
        }

        return Wallet::firstOrCreate(
            ['user_id' => $userId],
            [
                'vendor_id' => $vendorId,
                'balance' => 0.00,
                'currency_code' => 'DZD',
            ]
        );
    }

    /**
     * Credit the seller's wallet for a settled order (Idempotent).
     *
     * Rule: Amount credited = Item Subtotal minus Platform Commission (COMMISSION_PERCENT in .env, default 10%).
     * Delivery fees are collected by the courier/platform for delivery logistics and not credited to seller item earnings.
     *
     * @param  Order  $order
     * @param  int|string|null  $adminUserId
     * @return array
     */
    public function creditForOrder(Order $order, $adminUserId = null): array
    {
        // Pre-check for idempotency before locking
        if ((int) $order->is_wallet_credited === 1 || ! empty($order->wallet_credited_at)) {
            try {
                app(\App\Services\AffiliationService::class)->creditIssuerForDeliveredOrder($order);
            } catch (\Throwable $e) {
                Log::warning('Affiliation credit on already-credited order failed: ' . $e->getMessage());
            }
            return [
                'success' => true,
                'already_credited' => true,
                'message' => 'Order has already been credited to seller wallet.',
            ];
        }

        return DB::transaction(function () use ($order, $adminUserId) {
            // Row-level lock to prevent race conditions and double credit
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->first();
            if (! $lockedOrder) {
                return [
                    'success' => false,
                    'error' => 'Order not found.',
                ];
            }

            if ((int) $lockedOrder->is_wallet_credited === 1 || ! empty($lockedOrder->wallet_credited_at)) {
                return [
                    'success' => true,
                    'already_credited' => true,
                    'message' => 'Order has already been credited to seller wallet.',
                ];
            }

            // Also check idempotency in transaction ledger by order_code or reference_id
            $existingTx = WalletTransaction::where(function ($q) use ($lockedOrder) {
                $q->where('reference_id', (string) $lockedOrder->id)
                  ->orWhere('order_code', $lockedOrder->order_code);
            })->where('type', 'credit')->first();

            if ($existingTx) {
                $lockedOrder->is_wallet_credited = 1;
                $lockedOrder->wallet_credited_at = $existingTx->created_at ?? now();
                $lockedOrder->order_status_id = \Modules\Core\Constants\Constants::orderDeliveredStatus;
                if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'payment_status')) {
                    $lockedOrder->payment_status = 'paid';
                }
                $lockedOrder->save();

                return [
                    'success' => true,
                    'already_credited' => true,
                    'message' => 'Order has already been credited in transaction ledger.',
                ];
            }

            // Resolve seller user ID via vendor ownership
            $vendor = Vendor::find($lockedOrder->vendor_id);
            $sellerUserId = $vendor?->owner_user_id ?? $lockedOrder->added_user_id;

            if (! $sellerUserId) {
                return [
                    'success' => false,
                    'error' => 'Seller user not found for this order.',
                ];
            }

            // Get or create wallet and lock it
            $wallet = $this->getOrCreateWalletForUser($sellerUserId, $lockedOrder->vendor_id);
            $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

            // Calculate item subtotal and platform commission
            $lockedOrder->loadMissing(['orderItems', 'vendorTransaction']);
            $itemsSum = (float) $lockedOrder->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0, (float) ($lockedOrder->total_price - ($lockedOrder->delivery_fee ?? 0)));
                if ($itemsSum <= 0) {
                    $itemsSum = (float) $lockedOrder->total_price;
                }
            }

            $commissionPercent = self::getCommissionPercent();
            $commissionAmount = round(($itemsSum * $commissionPercent) / 100, 2);
            $creditedAmount = round(max(0, $itemsSum - $commissionAmount), 2);

            $newBalance = round($lockedWallet->balance + $creditedAmount, 2);

            $description = "Vente livrée #{$lockedOrder->order_code} (Net après commission)";

            // Record transaction
            $transaction = WalletTransaction::create([
                'wallet_id' => $lockedWallet->id,
                'user_id' => $sellerUserId,
                'type' => 'credit',
                'source' => 'sale_earning',
                'order_code' => $lockedOrder->order_code,
                'amount' => $creditedAmount,
                'gross_amount' => $itemsSum,
                'commission_amount' => $commissionAmount,
                'balance_after' => $newBalance,
                'reference_type' => 'order',
                'reference_id' => (string) $lockedOrder->id,
                'note' => $description,
                'description' => $description,
                'added_user_id' => $adminUserId ?? $sellerUserId,
            ]);

            // Update wallet balance
            $lockedWallet->balance = $newBalance;
            $lockedWallet->save();

            // Mark order as Delivered and Paid
            $lockedOrder->order_status_id = \Modules\Core\Constants\Constants::orderDeliveredStatus;
            $lockedOrder->is_wallet_credited = 1;
            $lockedOrder->wallet_credited_at = now();
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'delivered_at') && empty($lockedOrder->delivered_at)) {
                $lockedOrder->delivered_at = now();
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'payment_status')) {
                $lockedOrder->payment_status = 'paid';
            }
            $lockedOrder->save();

            // Mark vendor transaction as Paid (status 2 in psx_vendor_payment_statuses)
            if ($lockedOrder->vendorTransaction) {
                $lockedOrder->vendorTransaction->vendor_payment_status_id = 2; // Paid
                $lockedOrder->vendorTransaction->save();
            }

            // Credit affiliation issuer wallet if this order used a referral code (idempotent)
            try {
                app(\App\Services\AffiliationService::class)->creditIssuerForDeliveredOrder($lockedOrder);
            } catch (\Throwable $e) {
                Log::warning('Affiliation credit on delivered order failed: ' . $e->getMessage());
            }

            Log::info('Wallet credited for order:', [
                'order_id' => $lockedOrder->id,
                'order_code' => $lockedOrder->order_code,
                'seller_user_id' => $sellerUserId,
                'gross_amount' => $itemsSum,
                'commission' => $commissionAmount,
                'credited_amount' => $creditedAmount,
                'balance_after' => $newBalance,
            ]);

            return [
                'success' => true,
                'already_credited' => false,
                'credited_amount' => $creditedAmount,
                'commission_amount' => $commissionAmount,
                'balance_after' => $newBalance,
                'transaction_id' => $transaction->id,
            ];
        });
    }

    /**
     * Reverse / deduct wallet credit when an order is cancelled or returned,
     * and refund any buyer wallet balance used on the order.
     *
     * @param  Order  $order
     * @param  string|null  $reason
     * @param  int|string|null  $adminUserId
     * @return array
     */
    public function reverseOrderFunds(Order $order, ?string $reason = null, $adminUserId = null): array
    {
        return DB::transaction(function () use ($order, $reason, $adminUserId) {
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->first();
            if (! $lockedOrder) {
                return [
                    'success' => false,
                    'error' => 'Order not found.',
                ];
            }

            $orderCode = $lockedOrder->order_code;
            $sellerReversed = false;
            $buyerRefunded = false;
            $reversalAmount = 0.0;
            $refundAmount = 0.0;

            // --- 1. CASE A: SELLER REVERSAL ---
            // Check if seller was previously credited for this order
            $sellerCreditTx = WalletTransaction::where('order_code', $orderCode)
                ->where('type', 'credit')
                ->where('source', 'sale_earning')
                ->first();

            $alreadyReversed = WalletTransaction::where('order_code', $orderCode)
                ->where('type', 'debit')
                ->where('source', 'sale_reversal')
                ->exists();

            if ($sellerCreditTx && ! $alreadyReversed) {
                $vendor = Vendor::find($lockedOrder->vendor_id);
                $sellerUserId = $vendor?->owner_user_id ?? $lockedOrder->added_user_id ?? $sellerCreditTx->user_id;

                if ($sellerUserId) {
                    $sellerWallet = $this->getOrCreateWalletForUser($sellerUserId, $lockedOrder->vendor_id);
                    $lockedSellerWallet = Wallet::where('id', $sellerWallet->id)->lockForUpdate()->first();

                    $reversalAmount = (float) $sellerCreditTx->amount;
                    // Deduct from seller balance (allowing negative if seller already withdrew)
                    $newSellerBalance = round($lockedSellerWallet->balance - $reversalAmount, 2);
                    $lockedSellerWallet->balance = $newSellerBalance;
                    $lockedSellerWallet->save();

                    $desc = "Annulation / Retour commande #{$orderCode} (Débit net après commission)";
                    if (! empty($reason)) {
                        $desc .= " - Motif: {$reason}";
                    }

                    WalletTransaction::create([
                        'wallet_id' => $lockedSellerWallet->id,
                        'user_id' => $sellerUserId,
                        'type' => 'debit',
                        'source' => 'sale_reversal',
                        'order_code' => $orderCode,
                        'amount' => $reversalAmount,
                        'gross_amount' => $sellerCreditTx->gross_amount,
                        'commission_amount' => $sellerCreditTx->commission_amount,
                        'balance_after' => $newSellerBalance,
                        'reference_type' => 'order',
                        'reference_id' => (string) $lockedOrder->id,
                        'note' => $desc,
                        'description' => $desc,
                        'added_user_id' => $adminUserId ?? $sellerUserId,
                    ]);

                    $sellerReversed = true;

                    Log::info("Seller wallet reversed for order #{$orderCode}:", [
                        'seller_user_id' => $sellerUserId,
                        'reversal_amount' => $reversalAmount,
                        'balance_after' => $newSellerBalance,
                    ]);
                }
            }

            // --- 2. CASE B: BUYER REFUND ---
            // If buyer paid with wallet and hasn't been refunded yet
            $alreadyRefunded = WalletTransaction::where('order_code', $orderCode)
                ->where('type', 'credit')
                ->where('source', 'order_refund')
                ->exists();

            $buyerWalletUsed = (float) ($lockedOrder->wallet_amount_used ?? 0);
            if ($buyerWalletUsed > 0 && ! $alreadyRefunded && $lockedOrder->user_id) {
                $buyerUserId = $lockedOrder->user_id;
                $buyerWallet = $this->getOrCreateWalletForUser($buyerUserId);
                $lockedBuyerWallet = Wallet::where('id', $buyerWallet->id)->lockForUpdate()->first();

                $refundAmount = $buyerWalletUsed;
                $newBuyerBalance = round($lockedBuyerWallet->balance + $refundAmount, 2);
                $lockedBuyerWallet->balance = $newBuyerBalance;
                $lockedBuyerWallet->save();

                $buyerDesc = "Remboursement commande #{$orderCode}";
                if (! empty($reason)) {
                    $buyerDesc .= " - Motif: {$reason}";
                }

                WalletTransaction::create([
                    'wallet_id' => $lockedBuyerWallet->id,
                    'user_id' => $buyerUserId,
                    'type' => 'credit',
                    'source' => 'order_refund',
                    'order_code' => $orderCode,
                    'amount' => $refundAmount,
                    'gross_amount' => $refundAmount,
                    'commission_amount' => 0.00,
                    'balance_after' => $newBuyerBalance,
                    'reference_type' => 'order',
                    'reference_id' => (string) $lockedOrder->id,
                    'note' => $buyerDesc,
                    'description' => $buyerDesc,
                    'added_user_id' => $adminUserId ?? $buyerUserId,
                ]);

                $buyerRefunded = true;

                Log::info("Buyer wallet refunded for order #{$orderCode}:", [
                    'buyer_user_id' => $buyerUserId,
                    'refund_amount' => $refundAmount,
                    'balance_after' => $newBuyerBalance,
                ]);
            }

            // Mark order flags
            $lockedOrder->is_wallet_credited = 0;
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'wallet_reversed_at')) {
                $lockedOrder->wallet_reversed_at = now();
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'payment_status')) {
                $lockedOrder->payment_status = 'refunded';
            }
            if ($lockedOrder->vendorTransaction) {
                $lockedOrder->vendorTransaction->vendor_payment_status_id = 4; // Refunded
                $lockedOrder->vendorTransaction->save();
            }
            $lockedOrder->save();

            return [
                'success' => true,
                'seller_reversed' => $sellerReversed,
                'reversal_amount' => $reversalAmount,
                'buyer_refunded' => $buyerRefunded,
                'refund_amount' => $refundAmount,
            ];
        });
    }

    /**
     * Retrieve wallet balance summary for a user.
     *
     * @param  int|string  $userId
     * @return array
     */
    public function getWalletBalance($userId): array
    {
        $wallet = $this->getOrCreateWalletForUser($userId);

        $totalEarned = (float) WalletTransaction::where('wallet_id', $wallet->id)
            ->where('type', 'credit')
            ->where('source', 'sale_earning')
            ->sum('amount');

        $totalReversed = (float) WalletTransaction::where('wallet_id', $wallet->id)
            ->where('type', 'debit')
            ->where('source', 'sale_reversal')
            ->sum('amount');

        $netEarned = max(0, $totalEarned - $totalReversed);

        $totalWithdrawn = (float) WalletTransaction::where('wallet_id', $wallet->id)
            ->where('type', 'debit')
            ->where('source', 'withdrawal')
            ->sum('amount');

        $pendingWithdraw = (float) WithdrawRequest::where('wallet_id', $wallet->id)
            ->where('status', 'pending')
            ->sum('amount');

        return [
            'balance' => number_format($wallet->balance, 2, '.', ''),
            'currency' => $wallet->currency_code ?? 'DZD',
            'currency_symbol' => 'DA',
            'total_earned' => number_format($netEarned, 2, '.', ''),
            'total_withdrawn' => number_format($totalWithdrawn, 2, '.', ''),
            'pending_withdraw' => number_format($pendingWithdraw, 2, '.', ''),
        ];
    }

    /**
     * Retrieve paginated wallet transactions for a user.
     *
     * @param  int|string  $userId
     * @param  int  $limit
     * @param  int  $offset
     * @return array
     */
    public function getWalletTransactions($userId, int $limit = 20, int $offset = 0): array
    {
        $wallet = $this->getOrCreateWalletForUser($userId);

        $query = WalletTransaction::where(function ($q) use ($wallet, $userId) {
            $q->where('wallet_id', $wallet->id)
              ->orWhere('user_id', $userId);
        })->latest('id');
        $total = $query->count();

        $transactions = $query->skip($offset)->take($limit)->get();

        $data = $transactions->map(function ($item) {
            return [
                'id' => (string) $item->id,
                'type' => (string) $item->type,
                'source' => (string) ($item->source ?? ($item->type === 'credit' ? 'sale_earning' : 'withdrawal')),
                'order_code' => (string) ($item->order_code ?? ''),
                'amount' => number_format($item->amount, 2, '.', ''),
                'gross_amount' => number_format((float) ($item->gross_amount ?? $item->amount), 2, '.', ''),
                'commission_amount' => number_format((float) ($item->commission_amount ?? 0), 2, '.', ''),
                'balance_after' => number_format($item->balance_after, 2, '.', ''),
                'reference_type' => (string) ($item->reference_type ?? ''),
                'reference_id' => (string) ($item->reference_id ?? ''),
                'note' => (string) ($item->note ?? ''),
                'description' => (string) ($item->description ?? $item->note ?? ''),
                'created_at' => (string) $item->created_at?->format('M d, Y H:i'),
            ];
        });

        return [
            'total' => $total,
            'limit' => $limit,
            'offset' => $offset,
            'transactions' => $data,
        ];
    }

    /**
     * Retrieve seller sales transactions with KPI summary and date filtering.
     *
     * @param  int|string  $userId
     * @param  string|null  $dateFrom
     * @param  string|null  $dateTo
     * @param  int  $limit
     * @param  int  $offset
     * @return array
     */
    public function getSellerSalesTransactions($userId, ?string $dateFrom = null, ?string $dateTo = null, int $limit = 20, int $offset = 0): array
    {
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        $query = Order::with(['orderItems.item.cover', 'vendorTransaction.currency'])
            ->whereIn('order_status_id', [
                \Modules\Core\Constants\Constants::orderDeliveredStatus,
                \Modules\Core\Constants\Constants::orderCancelledStatus,
                \Modules\Core\Constants\Constants::orderReturnedStatus,
            ]);

        if ($vendor) {
            $query->where('vendor_id', $vendor->id);
        } else {
            $query->where('added_user_id', $userId);
        }

        if (!empty($dateFrom)) {
            $query->where(function ($q) use ($dateFrom) {
                $q->whereDate('wallet_credited_at', '>=', $dateFrom)
                  ->orWhereDate('wallet_reversed_at', '>=', $dateFrom)
                  ->orWhere(function ($sq) use ($dateFrom) {
                      $sq->whereNull('wallet_credited_at')
                         ->whereNull('wallet_reversed_at')
                         ->whereDate('updated_date', '>=', $dateFrom);
                  });
            });
        }

        if (!empty($dateTo)) {
            $query->where(function ($q) use ($dateTo) {
                $q->whereDate('wallet_credited_at', '<=', $dateTo)
                  ->orWhereDate('wallet_reversed_at', '<=', $dateTo)
                  ->orWhere(function ($sq) use ($dateTo) {
                      $sq->whereNull('wallet_credited_at')
                         ->whereNull('wallet_reversed_at')
                         ->whereDate('updated_date', '<=', $dateTo);
                  });
            });
        }

        // Calculate KPI summary across all filtered delivered sales and reversals
        // total_sales_count, gross_sales_total, total_commission: strictly Delivered & Paid orders
        // realised_profit: net profit realized (gross - commission on delivered) minus reversals from cancelled/returned orders that were previously delivered
        $allOrders = (clone $query)->get();
        $totalSalesCount = 0;
        $grossSalesTotal = 0.0;
        $totalCommission = 0.0;
        $totalReversalsDeducted = 0.0;

        foreach ($allOrders as $ord) {
            $isDelivered = ((int) $ord->order_status_id === (int) \Modules\Core\Constants\Constants::orderDeliveredStatus);
            $isCancelled = ((int) $ord->order_status_id === (int) \Modules\Core\Constants\Constants::orderCancelledStatus);
            $isReturned = ((int) $ord->order_status_id === (int) \Modules\Core\Constants\Constants::orderReturnedStatus);

            $itemsSum = (float) $ord->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0, (float) ($ord->total_price - ($ord->delivery_fee ?? 0)));
                if ($itemsSum <= 0) {
                    $itemsSum = (float) $ord->total_price;
                }
            }

            $creditTx = WalletTransaction::where('order_code', $ord->order_code)
                ->where('type', 'credit')
                ->where('source', 'sale_earning')
                ->first();

            if ($creditTx) {
                $gross = (float) ($creditTx->gross_amount > 0 ? $creditTx->gross_amount : $itemsSum);
                $comm = (float) $creditTx->commission_amount;
                $net = (float) $creditTx->amount;
            } else {
                $commissionPercent = self::getCommissionPercent();
                $gross = $itemsSum;
                $comm = round(($gross * $commissionPercent) / 100, 2);
                $net = round(max(0, $gross - $comm), 2);
            }

            if ($isDelivered) {
                $totalSalesCount++;
                $grossSalesTotal += $gross;
                $totalCommission += $comm;
            } elseif ($isCancelled || $isReturned) {
                $reversalTx = WalletTransaction::where('order_code', $ord->order_code)
                    ->where('type', 'debit')
                    ->where('source', 'sale_reversal')
                    ->first();
                if ($reversalTx) {
                    $totalReversalsDeducted += (float) $reversalTx->amount;
                } elseif (!empty($ord->wallet_reversed_at) && $creditTx) {
                    $totalReversalsDeducted += $net;
                }
            }
        }

        $grossSalesTotal = round(max(0, $grossSalesTotal), 2);
        $totalCommission = round(max(0, $totalCommission), 2);
        $realisedProfit = round(max(0, ($grossSalesTotal - $totalCommission) - $totalReversalsDeducted), 2);

        // Include wallet ledger activity (ads/boosts, referral gains, CIB/Edahabia top-ups, wallet payments/withdrawals)
        $wallet = $this->getOrCreateWalletForUser($userId, $vendor?->id);
        $ledgerQuery = WalletTransaction::where(function ($q) use ($wallet, $userId) {
            $q->where('wallet_id', $wallet->id)->orWhere('user_id', $userId);
        })->whereNotIn('source', ['sale_earning', 'sale_reversal']);

        if (!empty($dateFrom)) {
            $ledgerQuery->whereDate('created_at', '>=', $dateFrom);
        }
        if (!empty($dateTo)) {
            $ledgerQuery->whereDate('created_at', '<=', $dateTo);
        }

        $ledgerRows = $ledgerQuery->latest('id')->get();
        $totalAdsSpend = 0.0;
        $totalAffiliationGains = 0.0;
        $totalTopups = 0.0;
        $totalWalletPayments = 0.0;

        $ledgerItems = $ledgerRows->map(function ($tx) use (&$totalAdsSpend, &$totalAffiliationGains, &$totalTopups, &$totalWalletPayments) {
            $src = strtolower((string) ($tx->source ?? ''));
            $isCredit = strtolower((string) $tx->type) === 'credit';
            $amt = (float) $tx->amount;

            if (in_array($src, ['ad_story_boost', 'ad_item_boost', 'story_boost', 'article_boost'], true)) {
                $category = 'ads';
                $statusLabel = 'Publicité / Boost';
                $totalAdsSpend += $amt;
            } elseif (in_array($src, ['affiliation_reward', 'referral_bonus'], true)) {
                $category = 'referral';
                $statusLabel = 'Gain Parrainage';
                $totalAffiliationGains += $amt;
            } elseif ($src === 'silkpay_topup') {
                $category = 'topup';
                $statusLabel = 'Rechargement CIB / Edahabia';
                $totalTopups += $amt;
            } else {
                $category = 'wallet';
                $statusLabel = $isCredit ? 'Crédit Portefeuille' : 'Paiement / Retrait';
                if (!$isCredit) {
                    $totalWalletPayments += $amt;
                }
            }

            $ts = $tx->created_at ? \Carbon\Carbon::parse($tx->created_at) : now();
            $netFormatted = ($isCredit ? '' : '-') . number_format($amt, 2, '.', '');
            $title = trim((string) ($tx->description ?? $tx->note ?? $statusLabel));

            return [
                'id' => 'wt_' . $tx->id,
                'order_id' => '',
                'order_code' => (string) ($tx->order_code ?? $tx->reference_id ?? ''),
                'order_date' => (string) $ts->format('M d, Y'),
                'delivery_date' => (string) $ts->format('M d, Y H:i'),
                'timestamp' => (int) $ts->timestamp,
                'category' => $category,
                'type' => (string) $tx->type,
                'source' => $src,
                'status' => $category,
                'status_type' => $category,
                'status_label' => $statusLabel,
                'is_delivered_and_paid' => $isCredit ? '1' : '0',
                'currency_symbol' => 'DA',
                'gross_amount' => number_format($amt, 2, '.', ''),
                'commission_amount' => '0.00',
                'net_amount' => $netFormatted,
                'item_name' => $title,
                'item_title' => $title,
                'item_count' => 1,
                'image_url' => '',
                'item_image' => '',
                'default_photo' => null,
            ];
        })->values()->all();

        $allOrderRows = $allOrders->sortByDesc('updated_date')->values();

        $orderItems = $allOrderRows->map(function ($order) {
            $isDelivered = ((int) $order->order_status_id === (int) \Modules\Core\Constants\Constants::orderDeliveredStatus);
            $isCancelled = ((int) $order->order_status_id === (int) \Modules\Core\Constants\Constants::orderCancelledStatus);
            $isReturned = ((int) $order->order_status_id === (int) \Modules\Core\Constants\Constants::orderReturnedStatus);

            $itemsSum = (float) $order->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0, (float) ($order->total_price - ($order->delivery_fee ?? 0)));
                if ($itemsSum <= 0) {
                    $itemsSum = (float) $order->total_price;
                }
            }

            $creditTx = WalletTransaction::where('order_code', $order->order_code)
                ->where('type', 'credit')
                ->where('source', 'sale_earning')
                ->first();

            $reversalTx = WalletTransaction::where('order_code', $order->order_code)
                ->where('type', 'debit')
                ->where('source', 'sale_reversal')
                ->first();

            if ($creditTx) {
                $gross = (float) ($creditTx->gross_amount > 0 ? $creditTx->gross_amount : $itemsSum);
                $comm = (float) $creditTx->commission_amount;
                $net = (float) $creditTx->amount;
            } else {
                $commissionPercent = self::getCommissionPercent();
                $gross = $itemsSum;
                $comm = round(($gross * $commissionPercent) / 100, 2);
                $net = round(max(0, $gross - $comm), 2);
            }

            $firstItem = $order->orderItems->first();
            $item = $firstItem?->item;
            $coverImage = $item?->cover?->first();
            $imageUrl = '';
            $defaultPhoto = null;
            if ($coverImage) {
                if (!empty($coverImage->img_path)) {
                    $imageUrl = asset('storage/' . $coverImage->img_path);
                }
                $defaultPhoto = [
                    'img_id' => (string) $coverImage->id,
                    'img_parent_id' => (string) ($coverImage->img_parent_id ?? $item?->id ?? ''),
                    'img_type' => (string) ($coverImage->img_type ?? 'item'),
                    'img_path' => (string) ($coverImage->img_path ?? ''),
                    'img_width' => (string) ($coverImage->img_width ?? ''),
                    'img_height' => (string) ($coverImage->img_height ?? ''),
                    'img_desc' => (string) ($coverImage->img_desc ?? ''),
                    'ordering' => (string) ($coverImage->ordering ?? '1'),
                ];
            }

            $itemTitle = (string) ($item?->title ?? $firstItem?->item_name ?? 'Produit');

            if ($isCancelled) {
                $statusSlug = 'cancelled';
                $statusLabel = 'Annulée';
                $displayDate = isset($order->wallet_reversed_at)
                    ? (string) \Carbon\Carbon::parse($order->wallet_reversed_at)->format('M d, Y H:i')
                    : (string) \Carbon\Carbon::parse($order->updated_date)->format('M d, Y H:i');
                if ($reversalTx || !empty($order->wallet_reversed_at)) {
                    $reversedAmount = $reversalTx ? (float) $reversalTx->amount : $net;
                    $netAmountFormatted = '-' . number_format($reversedAmount, 2, '.', '');
                } else {
                    $comm = 0.00;
                    $netAmountFormatted = '0.00';
                }
                $isDeliveredAndPaid = '0';
            } elseif ($isReturned) {
                $statusSlug = 'returned';
                $statusLabel = 'Retournée';
                $displayDate = isset($order->wallet_reversed_at)
                    ? (string) \Carbon\Carbon::parse($order->wallet_reversed_at)->format('M d, Y H:i')
                    : (string) \Carbon\Carbon::parse($order->updated_date)->format('M d, Y H:i');
                if ($reversalTx || !empty($order->wallet_reversed_at)) {
                    $reversedAmount = $reversalTx ? (float) $reversalTx->amount : $net;
                    $netAmountFormatted = '-' . number_format($reversedAmount, 2, '.', '');
                } else {
                    $comm = 0.00;
                    $netAmountFormatted = '0.00';
                }
                $isDeliveredAndPaid = '0';
            } else {
                $statusSlug = 'delivered';
                $statusLabel = 'Livré et payé';
                $displayDate = isset($order->wallet_credited_at)
                    ? (string) \Carbon\Carbon::parse($order->wallet_credited_at)->format('M d, Y H:i')
                    : (string) \Carbon\Carbon::parse($order->updated_date)->format('M d, Y H:i');
                $netAmountFormatted = number_format($net, 2, '.', '');
                $isDeliveredAndPaid = '1';
            }

            $displayCarbon = !empty($order->wallet_reversed_at)
                ? \Carbon\Carbon::parse($order->wallet_reversed_at)
                : (!empty($order->wallet_credited_at)
                    ? \Carbon\Carbon::parse($order->wallet_credited_at)
                    : \Carbon\Carbon::parse($order->updated_date ?? now()));

            return [
                'id' => (string) $order->id,
                'order_id' => (string) $order->id,
                'order_code' => (string) $order->order_code,
                'order_date' => (string) \Carbon\Carbon::parse($order->order_date ?? $order->added_date)->format('M d, Y'),
                'delivery_date' => $displayDate,
                'timestamp' => (int) $displayCarbon->timestamp,
                'category' => ($isCancelled || $isReturned) ? 'reversal' : 'sale',
                'type' => ($isCancelled || $isReturned) ? 'debit' : 'credit',
                'source' => ($isCancelled || $isReturned) ? 'sale_reversal' : 'sale_earning',
                'status' => $statusSlug,
                'status_type' => $statusSlug,
                'status_label' => $statusLabel,
                'is_delivered_and_paid' => $isDeliveredAndPaid,
                'currency_symbol' => 'DA',
                'gross_amount' => number_format($gross, 2, '.', ''),
                'commission_amount' => number_format($comm, 2, '.', ''),
                'net_amount' => $netAmountFormatted,
                'item_name' => $itemTitle,
                'item_title' => $itemTitle,
                'item_count' => (int) $order->orderItems->count(),
                'image_url' => (string) $imageUrl,
                'item_image' => (string) $imageUrl,
                'default_photo' => $defaultPhoto,
            ];
        })->values()->all();

        $merged = array_merge($orderItems, $ledgerItems);
        usort($merged, fn ($a, $b) => ($b['timestamp'] ?? 0) <=> ($a['timestamp'] ?? 0));
        $totalCount = count($merged);
        $pagedMerged = array_slice($merged, $offset, $limit);

        $netAccountProfit = round($realisedProfit + $totalAffiliationGains - $totalAdsSpend, 2);

        return [
            'summary' => [
                'total_sales_count' => $totalSalesCount,
                'total_sales_amount' => number_format($grossSalesTotal, 2, '.', ''),
                'gross_sales_total' => number_format($grossSalesTotal, 2, '.', ''),
                'total_commission' => number_format($totalCommission, 2, '.', ''),
                'realised_profit' => number_format($realisedProfit, 2, '.', ''),
                'total_ads_spend' => number_format(round($totalAdsSpend, 2), 2, '.', ''),
                'total_affiliation_gains' => number_format(round($totalAffiliationGains, 2), 2, '.', ''),
                'total_topups' => number_format(round($totalTopups, 2), 2, '.', ''),
                'total_wallet_payments' => number_format(round($totalWalletPayments, 2), 2, '.', ''),
                'net_account_profit' => number_format($netAccountProfit, 2, '.', ''),
                'wallet_balance' => number_format(round((float) $wallet->balance, 2), 2, '.', ''),
                'currency_symbol' => 'DA',
            ],
            'transactions' => $pagedMerged,
            'total' => $totalCount,
            'limit' => $limit,
            'offset' => $offset,
        ];
    }

    /**
     * Submit a withdrawal request for the user.
     *
     * @param  int|string  $userId
     * @param  float  $amount
     * @param  string|null  $note
     * @return array
     */
    public function submitWithdrawRequest($userId, float $amount, ?string $note = null): array
    {
        if ($amount <= 0) {
            return [
                'success' => false,
                'error' => 'Withdrawal amount must be greater than zero.',
            ];
        }

        $minWithdraw = self::getMinWithdrawAmount();
        if ($amount < $minWithdraw) {
            return [
                'success' => false,
                'error' => "Minimum withdrawal amount is {$minWithdraw} DZD.",
            ];
        }

        $wallet = $this->getOrCreateWalletForUser($userId);

        if ($wallet->balance < $amount) {
            return [
                'success' => false,
                'error' => 'Insufficient wallet balance for this withdrawal request.',
            ];
        }

        $withdraw = WithdrawRequest::create([
            'wallet_id' => $wallet->id,
            'user_id' => $userId,
            'amount' => $amount,
            'status' => 'pending',
            'note' => $note,
        ]);

        return [
            'success' => true,
            'message' => 'Withdrawal request submitted successfully.',
            'withdraw_id' => $withdraw->id,
        ];
    }

    public static function getCommissionPercent(): float
    {
        try {
            $setting = \Modules\Core\Entities\Configuration\Setting::where('setting_env', 'c2c_finance_setting')->first();
            if ($setting && !empty($setting->setting)) {
                $data = is_array($setting->setting) ? $setting->setting : json_decode($setting->setting, true);
                if (isset($data['commission_percent']) && is_numeric($data['commission_percent'])) {
                    return (float) $data['commission_percent'];
                }
            }
        } catch (\Throwable $e) {
            // fallback
        }
        return (float) env('COMMISSION_PERCENT', 10);
    }

    public static function getMinWithdrawAmount(): float
    {
        try {
            $setting = \Modules\Core\Entities\Configuration\Setting::where('setting_env', 'c2c_finance_setting')->first();
            if ($setting && !empty($setting->setting)) {
                $data = is_array($setting->setting) ? $setting->setting : json_decode($setting->setting, true);
                if (isset($data['min_withdraw_amount']) && is_numeric($data['min_withdraw_amount'])) {
                    return (float) $data['min_withdraw_amount'];
                }
            }
        } catch (\Throwable $e) {
            // fallback
        }
        return 1000.0;
    }

    public static function isYalidineStubMode(): bool
    {
        try {
            $deliverySetting = \App\Models\DeliverySetting::first();
            if ($deliverySetting) {
                if (!$deliverySetting->is_enabled || $deliverySetting->environment === 'sandbox') {
                    return true;
                }
                return empty($deliverySetting->api_id) || empty($deliverySetting->api_token);
            }
        } catch (\Throwable $e) {
            // fallback
        }

        try {
            $setting = \Modules\Core\Entities\Configuration\Setting::where('setting_env', 'c2c_finance_setting')->first();
            if ($setting && !empty($setting->setting)) {
                $data = is_array($setting->setting) ? $setting->setting : json_decode($setting->setting, true);
                if (isset($data['yalidine_stub_mode'])) {
                    return (bool) $data['yalidine_stub_mode'];
                }
            }
        } catch (\Throwable $e) {
            // fallback
        }
        return (bool) env('YALIDINE_STUB_MODE', true);
    }
}
