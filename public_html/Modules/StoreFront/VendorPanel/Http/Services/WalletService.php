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
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'payment_status')) {
                $lockedOrder->payment_status = 'paid';
            }
            $lockedOrder->save();

            // Mark vendor transaction as Paid (status 2 in psx_vendor_payment_statuses)
            if ($lockedOrder->vendorTransaction) {
                $lockedOrder->vendorTransaction->vendor_payment_status_id = 2; // Paid
                $lockedOrder->vendorTransaction->save();
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
            ->sum('amount');

        $totalWithdrawn = (float) WalletTransaction::where('wallet_id', $wallet->id)
            ->where('type', 'debit')
            ->sum('amount');

        $pendingWithdraw = (float) WithdrawRequest::where('wallet_id', $wallet->id)
            ->where('status', 'pending')
            ->sum('amount');

        return [
            'balance' => number_format($wallet->balance, 2, '.', ''),
            'currency' => $wallet->currency_code ?? 'DZD',
            'currency_symbol' => 'DA',
            'total_earned' => number_format($totalEarned, 2, '.', ''),
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

        $query = WalletTransaction::where('wallet_id', $wallet->id)->latest('id');
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
            ->where('order_status_id', \Modules\Core\Constants\Constants::orderDeliveredStatus);

        if ($vendor) {
            $query->where('vendor_id', $vendor->id);
        } else {
            $query->where('added_user_id', $userId);
        }

        if (!empty($dateFrom)) {
            $query->where(function ($q) use ($dateFrom) {
                $q->whereDate('wallet_credited_at', '>=', $dateFrom)
                  ->orWhere(function ($sq) use ($dateFrom) {
                      $sq->whereNull('wallet_credited_at')
                         ->whereDate('updated_date', '>=', $dateFrom);
                  });
            });
        }

        if (!empty($dateTo)) {
            $query->where(function ($q) use ($dateTo) {
                $q->whereDate('wallet_credited_at', '<=', $dateTo)
                  ->orWhere(function ($sq) use ($dateTo) {
                      $sq->whereNull('wallet_credited_at')
                         ->whereDate('updated_date', '<=', $dateTo);
                  });
            });
        }

        // Calculate KPI summary across all filtered delivered sales
        $allOrders = (clone $query)->get();
        $totalSalesCount = $allOrders->count();
        $grossSalesTotal = 0.0;
        $totalCommission = 0.0;
        $realisedProfit = 0.0;

        foreach ($allOrders as $ord) {
            $itemsSum = (float) $ord->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0, (float) ($ord->total_price - ($ord->delivery_fee ?? 0)));
                if ($itemsSum <= 0) {
                    $itemsSum = (float) $ord->total_price;
                }
            }

            $tx = WalletTransaction::where('order_code', $ord->order_code)
                ->where('type', 'credit')
                ->first();

            if ($tx) {
                $gross = (float) ($tx->gross_amount > 0 ? $tx->gross_amount : $itemsSum);
                $comm = (float) $tx->commission_amount;
                $net = (float) $tx->amount;
            } else {
                $commissionPercent = self::getCommissionPercent();
                $gross = $itemsSum;
                $comm = round(($gross * $commissionPercent) / 100, 2);
                $net = round(max(0, $gross - $comm), 2);
            }

            $grossSalesTotal += $gross;
            $totalCommission += $comm;
            $realisedProfit += $net;
        }

        // Paginate transaction orders
        $pagedOrders = $query->latest('updated_date')
            ->skip($offset)
            ->take($limit)
            ->get();

        $transactions = $pagedOrders->map(function ($order) {
            $itemsSum = (float) $order->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0, (float) ($order->total_price - ($order->delivery_fee ?? 0)));
                if ($itemsSum <= 0) {
                    $itemsSum = (float) $order->total_price;
                }
            }

            $tx = WalletTransaction::where('order_code', $order->order_code)
                ->where('type', 'credit')
                ->first();

            if ($tx) {
                $gross = (float) ($tx->gross_amount > 0 ? $tx->gross_amount : $itemsSum);
                $comm = (float) $tx->commission_amount;
                $net = (float) $tx->amount;
            } else {
                $commissionPercent = self::getCommissionPercent();
                $gross = $itemsSum;
                $comm = round(($gross * $commissionPercent) / 100, 2);
                $net = round(max(0, $gross - $comm), 2);
            }

            $firstItem = $order->orderItems->first();
            $coverImage = $firstItem?->item?->cover?->first();
            $imageUrl = '';
            if ($coverImage && !empty($coverImage->img_path)) {
                $imageUrl = asset('storage/' . $coverImage->img_path);
            }

            return [
                'id' => (string) $order->id,
                'order_id' => (string) $order->id,
                'order_code' => (string) $order->order_code,
                'order_date' => (string) \Carbon\Carbon::parse($order->order_date ?? $order->added_date)->format('M d, Y'),
                'delivery_date' => isset($order->wallet_credited_at)
                    ? (string) \Carbon\Carbon::parse($order->wallet_credited_at)->format('M d, Y H:i')
                    : (string) \Carbon\Carbon::parse($order->updated_date)->format('M d, Y H:i'),
                'status' => 'delivered',
                'status_label' => 'Livré et payé',
                'is_delivered_and_paid' => '1',
                'currency_symbol' => 'DA',
                'gross_amount' => number_format($gross, 2, '.', ''),
                'commission_amount' => number_format($comm, 2, '.', ''),
                'net_amount' => number_format($net, 2, '.', ''),
                'item_name' => (string) ($firstItem?->item_name ?? 'Produit'),
                'item_count' => (int) $order->orderItems->count(),
                'image_url' => (string) $imageUrl,
            ];
        });

        return [
            'summary' => [
                'total_sales_count' => $totalSalesCount,
                'gross_sales_total' => number_format($grossSalesTotal, 2, '.', ''),
                'total_commission' => number_format($totalCommission, 2, '.', ''),
                'realised_profit' => number_format($realisedProfit, 2, '.', ''),
                'currency_symbol' => 'DA',
            ],
            'transactions' => $transactions,
            'total' => $totalSalesCount,
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
