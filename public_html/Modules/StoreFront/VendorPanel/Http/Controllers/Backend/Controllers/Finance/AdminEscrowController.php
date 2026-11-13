<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Controllers\Finance;

use App\Http\Controllers\PsController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class AdminEscrowController extends PsController
{
    public function __construct(protected WalletService $walletService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $statusFilter = $request->input('status', 'all');
        $search = $request->input('search', '');

        $query = Order::with(['orderItems', 'shippingAndBilling', 'vendorTransaction', 'user', 'vendor.owner'])
            ->latest('id');

        if ($statusFilter === 'unpaid') {
            $query->where(function ($q) {
                $q->whereNull('is_wallet_credited')->orWhere('is_wallet_credited', 0);
            });
        } elseif ($statusFilter === 'paid') {
            $query->where('is_wallet_credited', 1);
        }

        if (! empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('order_code', 'like', "%{$search}%")
                    ->orWhere('id', 'like', "%{$search}%")
                    ->orWhere('yalidine_tracking', 'like', "%{$search}%")
                    ->orWhereHas('user', function ($uq) use ($search) {
                        $uq->where('name', 'like', "%{$search}%")->orWhere('email', 'like', "%{$search}%");
                    })
                    ->orWhereHas('vendor', function ($vq) use ($search) {
                        $vq->where('name', 'like', "%{$search}%");
                    });
            });
        }

        $commissionPercent = WalletService::getCommissionPercent();
        $orders = $query->paginate(15)->withQueryString();

        $orders->getCollection()->transform(function ($order) use ($commissionPercent) {
            $itemSubtotal = (float) $order->orderItems->sum('sub_total');
            if ($itemSubtotal <= 0) {
                $itemSubtotal = max(0, (float) ($order->total_price - ($order->delivery_fee ?? 0)));
                if ($itemSubtotal <= 0) {
                    $itemSubtotal = (float) $order->total_price;
                }
            }
            $commissionAmount = round(($itemSubtotal * $commissionPercent) / 100, 2);
            $netSellerPayout = round(max(0, $itemSubtotal - $commissionAmount), 2);

            $order->order_sub_total = $itemSubtotal;
            $order->calculated_subtotal = $itemSubtotal;
            $order->commission_amount = $commissionAmount;
            $order->calculated_commission = $commissionAmount;
            $order->seller_payout = $netSellerPayout;
            $order->calculated_net_payout = $netSellerPayout;

            $sellerOwner = $order->vendor?->owner;
            $order->seller_name = $sellerOwner?->name ?? ($order->vendor?->name ?? 'N/A');
            $order->vendor_name = $order->vendor?->name ?? 'N/A';

            $buyerName = $order->shippingAndBilling?->shipping_first_name
                ? trim($order->shippingAndBilling->shipping_first_name.' '.$order->shippingAndBilling->shipping_last_name)
                : ($order->user?->name ?? 'Buyer #'.$order->user_id);
            $order->buyer_name = $buyerName;
            $order->buyer_phone = $order->shippingAndBilling?->shipping_phone
                ?? ($order->user?->user_phone ?? 'N/A');

            $order->created_at = $order->order_date ?? $order->added_date;

            return $order;
        });

        $totalEscrowOrders = Order::count();
        $unpaidCount = Order::where(function ($q) {
            $q->whereNull('is_wallet_credited')->orWhere('is_wallet_credited', 0);
        })->count();
        $creditedCount = Order::where('is_wallet_credited', 1)->count();

        // Calculate pending escrow amount, paid amount, and commission
        $pendingEscrowAmount = (float) Order::where(function ($q) {
            $q->whereNull('is_wallet_credited')->orWhere('is_wallet_credited', 0);
        })->sum('total_price');

        $paidSellersAmount = 0.0;
        $platformCommissionAmount = 0.0;

        $creditedOrders = Order::where('is_wallet_credited', 1)->get(['total_price', 'delivery_fee']);
        foreach ($creditedOrders as $cord) {
            $base = max(0, (float) ($cord->total_price - ($cord->delivery_fee ?? 0)));
            if ($base <= 0) {
                $base = (float) $cord->total_price;
            }
            $comm = round(($base * $commissionPercent) / 100, 2);
            $platformCommissionAmount += $comm;
            $paidSellersAmount += ($base - $comm);
        }

        return renderView('admin/escrow/Index', [
            'orders' => $orders,
            'filters' => [
                'status' => $statusFilter,
                'search' => $search,
            ],
            'stats' => [
                'total_orders' => $totalEscrowOrders,
                'unpaid_orders_count' => $unpaidCount,
                'paid_orders_count' => $creditedCount,
                'pending_escrow_amount' => round($pendingEscrowAmount, 2),
                'paid_sellers_amount' => round($paidSellersAmount, 2),
                'platform_commission_amount' => round($platformCommissionAmount, 2),
                'total' => $totalEscrowOrders,
                'unpaid' => $unpaidCount,
                'credited' => $creditedCount,
            ],
            'commission_percent' => $commissionPercent,
        ]);
    }

    public function markPaid(Request $request, $id)
    {
        if (Auth::user()?->role_id != Constants::superAdminRoleId) {
            abort(403, 'Unauthorized. Super Admin access required.');
        }

        $order = Order::findOrFail($id);

        $result = $this->walletService->creditForOrder($order, Auth::id());

        if (! empty($result['error'])) {
            return redirect()->back()->with('status', [
                'flag' => Constants::danger,
                'msg' => $result['error'],
            ]);
        }

        if (! empty($result['already_credited'])) {
            return redirect()->back()->with('status', [
                'flag' => Constants::warning,
                'msg' => __('Order has already been credited to seller wallet.'),
            ]);
        }

        return redirect()->back()->with('status', [
            'flag' => Constants::success,
            'msg' => __("Order #{$order->order_code} marked as paid! Credited {$result['credited_amount']} DZD to seller wallet."),
        ]);
    }
}
