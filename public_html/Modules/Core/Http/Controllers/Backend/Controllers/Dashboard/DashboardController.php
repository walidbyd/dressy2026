<?php

namespace Modules\Core\Http\Controllers\Backend\Controllers\Dashboard;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Modules\Core\Http\Services\DashboardService;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Entities\WithdrawRequest;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class DashboardController extends Controller
{
    const parentPath = 'dashboard/';

    const indexPath = self::parentPath.'Index';

    const createPath = self::parentPath.'Create';

    const editPath = self::parentPath.'Edit';

    const indexRoute = 'admin.index';

    const createRoute = 'admin.create';

    const editRoute = 'admin.edit';

    protected $dashboardService;

    public function __construct(DashboardService $dashboardService)
    {
        $this->dashboardService = $dashboardService;
    }

    public function refresh(Request $request)
    {
        $dataArr = $this->dashboardService->refresh($request);

        return redirectView(self::indexRoute, 'test');
    }

    public function index(Request $request)
    {
        $dataArr = $this->dashboardService->index($request);
        $c2cData = $this->getC2CFinanceDashboardData($request);
        $dataArr = array_merge($dataArr, $c2cData);

        return renderView(self::indexPath, $dataArr);
    }

    public function search(Request $request)
    {
        $dataArr = $this->dashboardService->search($request);
        $c2cData = $this->getC2CFinanceDashboardData($request);
        $dataArr = array_merge($dataArr, $c2cData);

        return renderView(self::indexPath, $dataArr);
    }

    public function omniSearch(Request $request)
    {
        $query = trim($request->input('q', ''));
        if (empty($query)) {
            return response()->json([
                'users' => [],
                'orders' => [],
                'transactions' => [],
            ]);
        }

        $users = User::where('name', 'like', "%{$query}%")
            ->orWhere('email', 'like', "%{$query}%")
            ->orWhere('user_phone', 'like', "%{$query}%")
            ->take(5)
            ->get(['id', 'name', 'email', 'user_phone', 'role_id', 'status']);

        $orders = Order::with(['user', 'vendor'])
            ->where('order_code', 'like', "%{$query}%")
            ->orWhere('yalidine_tracking', 'like', "%{$query}%")
            ->orWhere('id', $query)
            ->take(5)
            ->get();

        $transactions = WalletTransaction::with('user')
            ->where('note', 'like', "%{$query}%")
            ->orWhere('reference_id', 'like', "%{$query}%")
            ->orWhere('id', $query)
            ->take(5)
            ->get();

        return response()->json([
            'users' => $users,
            'orders' => $orders,
            'transactions' => $transactions,
        ]);
    }

    protected function getC2CFinanceDashboardData(Request $request): array
    {
        $commissionPercent = WalletService::getCommissionPercent();

        // 1. Pending Escrow Orders (uncredited seller wallets)
        $pendingEscrowQuery = Order::where(function ($q) {
            $q->whereNull('is_wallet_credited')->orWhere('is_wallet_credited', 0);
        });
        $pendingEscrowOrdersCount = (int) $pendingEscrowQuery->count();
        $pendingEscrowTotalAmount = (float) $pendingEscrowQuery->sum('total_price');

        // 2. Pending Withdrawal Requests
        $pendingWithdrawalsQuery = WithdrawRequest::where('status', 'pending');
        $pendingWithdrawalsCount = (int) $pendingWithdrawalsQuery->count();
        $pendingWithdrawalsAmount = (float) $pendingWithdrawalsQuery->sum('amount');

        // 3. Total Active Seller Wallets Balance (in DZD)
        $totalSellerWalletsAmount = (float) DB::table('psx_wallets')->sum('balance');
        $totalActiveWalletsCount = (int) DB::table('psx_wallets')->count();

        // 4. Platform Commission
        $totalCommissionEarned = (float) DB::table('psx_wallet_transactions')
            ->where('type', 'commission')
            ->sum('amount');

        // Quick Table: Pending Escrow Orders (with calculated commission & net payout)
        $pendingEscrowOrders = Order::with(['orderItems', 'shippingAndBilling', 'vendorTransaction', 'user', 'vendor.owner'])
            ->where(function ($q) {
                $q->whereNull('is_wallet_credited')->orWhere('is_wallet_credited', 0);
            })
            ->latest('id')
            ->take(6)
            ->get()
            ->map(function ($order) use ($commissionPercent) {
                $itemSubtotal = (float) $order->orderItems->sum('sub_total');
                if ($itemSubtotal <= 0) {
                    $itemSubtotal = max(0, (float) ($order->total_price - ($order->delivery_fee ?? 0)));
                    if ($itemSubtotal <= 0) {
                        $itemSubtotal = (float) $order->total_price;
                    }
                }
                $commissionAmount = round(($itemSubtotal * $commissionPercent) / 100, 2);
                $netSellerPayout = round(max(0, $itemSubtotal - $commissionAmount), 2);

                $sellerOwner = $order->vendor?->owner;
                $sellerName = $sellerOwner?->name ?? ($order->vendor?->name ?? 'N/A');

                $buyerName = $order->shippingAndBilling?->shipping_first_name
                    ? trim($order->shippingAndBilling->shipping_first_name . ' ' . $order->shippingAndBilling->shipping_last_name)
                    : ($order->user?->name ?? 'Buyer #' . $order->user_id);

                return [
                    'id' => $order->id,
                    'order_code' => $order->order_code,
                    'seller_name' => $sellerName,
                    'buyer_name' => $buyerName,
                    'total_price' => (float) $order->total_price,
                    'item_subtotal' => $itemSubtotal,
                    'commission_amount' => $commissionAmount,
                    'seller_payout' => $netSellerPayout,
                    'yalidine_tracking' => $order->yalidine_tracking,
                    'order_date' => $order->order_date ? date('Y-m-d H:i', strtotime($order->order_date)) : null,
                ];
            });

        // Quick Table: Pending Withdrawals
        $pendingWithdrawals = WithdrawRequest::with(['user.vendor', 'wallet'])
            ->where('status', 'pending')
            ->latest('id')
            ->take(6)
            ->get()
            ->map(function ($req) {
                return [
                    'id' => $req->id,
                    'user_name' => $req->user?->name ?? 'User #' . $req->user_id,
                    'user_email' => $req->user?->email,
                    'amount' => (float) $req->amount,
                    'note' => $req->note,
                    'wallet_balance' => (float) ($req->wallet?->balance ?? 0),
                    'created_at' => $req->created_at ? $req->created_at->format('Y-m-d H:i') : null,
                ];
            });

        // Quick Table: Recent Ledger Movements
        $recentTransactions = WalletTransaction::with('user')
            ->latest('id')
            ->take(6)
            ->get()
            ->map(function ($tx) {
                return [
                    'id' => $tx->id,
                    'user_name' => $tx->user?->name ?? 'User #' . $tx->user_id,
                    'type' => $tx->type,
                    'amount' => (float) $tx->amount,
                    'balance_after' => (float) $tx->balance_after,
                    'note' => $tx->note,
                    'reference_type' => $tx->reference_type,
                    'reference_id' => $tx->reference_id,
                    'created_at' => $tx->created_at ? $tx->created_at->format('Y-m-d H:i') : null,
                ];
            });

        // Omni-search results if search param provided
        $omniQuery = trim($request->input('q') ?? $request->input('omni_query') ?? '');
        $omniResults = null;
        if (!empty($omniQuery)) {
            $omniResults = [
                'users' => User::where('name', 'like', "%{$omniQuery}%")
                    ->orWhere('email', 'like', "%{$omniQuery}%")
                    ->take(5)
                    ->get(['id', 'name', 'email', 'user_phone']),
                'orders' => Order::where('order_code', 'like', "%{$omniQuery}%")
                    ->orWhere('yalidine_tracking', 'like', "%{$omniQuery}%")
                    ->take(5)
                    ->get(['id', 'order_code', 'total_price', 'yalidine_tracking', 'is_wallet_credited']),
                'transactions' => WalletTransaction::where('note', 'like', "%{$omniQuery}%")
                    ->orWhere('reference_id', 'like', "%{$omniQuery}%")
                    ->take(5)
                    ->get(['id', 'type', 'amount', 'balance_after', 'note', 'created_at']),
            ];
        }

        return [
            'c2c_kpis' => [
                'pending_escrow_orders_count' => $pendingEscrowOrdersCount,
                'pending_escrow_amount' => $pendingEscrowTotalAmount,
                'pending_withdrawals_count' => $pendingWithdrawalsCount,
                'pending_withdrawals_amount' => $pendingWithdrawalsAmount,
                'total_seller_wallets_amount' => $totalSellerWalletsAmount,
                'total_active_wallets_count' => $totalActiveWalletsCount,
                'total_commission_earned' => $totalCommissionEarned,
                'commission_percent' => $commissionPercent,
                'currency' => 'DA',
            ],
            'pending_escrow_orders' => $pendingEscrowOrders,
            'pending_withdrawals' => $pendingWithdrawals,
            'recent_transactions' => $recentTransactions,
            'omni_query' => $omniQuery,
            'omni_results' => $omniResults,
        ];
    }
}
