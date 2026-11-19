<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Controllers\Order;

use App\Http\Controllers\PsController;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;

class AdminOrderController extends PsController
{
    public function __construct()
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $statusFilter = $request->input('status', 'all');
        $search = $request->input('search', '');

        $query = Order::with(['orderItems.item', 'shippingAndBilling', 'vendorTransaction', 'user', 'vendor.owner'])
            ->latest('id');

        // Status filter
        if ($statusFilter !== 'all') {
            $statusMap = [
                'pending' => Constants::orderPendingStatus,
                'approved' => Constants::orderApprovedStatus,
                'delivering' => Constants::orderDeliveringStatus,
                'delivered' => Constants::orderDeliveredStatus,
                'cancelled' => Constants::orderCancelledStatus,
                'returned' => Constants::orderReturnedStatus,
            ];

            if (isset($statusMap[$statusFilter])) {
                $query->where('order_status_id', $statusMap[$statusFilter]);
            } elseif (is_numeric($statusFilter)) {
                $query->where('order_status_id', (int) $statusFilter);
            }
        }

        // Search filter
        if (! empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('order_code', 'like', "%{$search}%")
                    ->orWhere('id', 'like', "%{$search}%")
                    ->orWhere('yalidine_tracking', 'like', "%{$search}%")
                    ->orWhereHas('user', function ($uq) use ($search) {
                        $uq->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('user_phone', 'like', "%{$search}%");
                    })
                    ->orWhereHas('shippingAndBilling', function ($sq) use ($search) {
                        $sq->where('shipping_first_name', 'like', "%{$search}%")
                            ->orWhere('shipping_last_name', 'like', "%{$search}%")
                            ->orWhere('shipping_phone_no', 'like', "%{$search}%");
                    })
                    ->orWhereHas('vendor', function ($vq) use ($search) {
                        $vq->where('name', 'like', "%{$search}%");
                    });
            });
        }

        $orders = $query->paginate(15)->withQueryString();

        $statusLabels = [
            1 => ['label' => 'Pending', 'color' => 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300'],
            2 => ['label' => 'Approved', 'color' => 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'],
            3 => ['label' => 'Delivering', 'color' => 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-300'],
            4 => ['label' => 'Delivered', 'color' => 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300'],
            5 => ['label' => 'Cancelled', 'color' => 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'],
            6 => ['label' => 'Returned', 'color' => 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'],
        ];

        $orders->getCollection()->transform(function ($order) use ($statusLabels) {
            $sellerOwner = $order->vendor?->owner;
            $order->seller_name = $sellerOwner?->name ?? ($order->vendor?->name ?? 'N/A');
            $order->seller_phone = $sellerOwner?->user_phone ?? 'N/A';

            $buyerName = $order->shippingAndBilling?->shipping_first_name
                ? trim($order->shippingAndBilling->shipping_first_name . ' ' . $order->shippingAndBilling->shipping_last_name)
                : ($order->user?->name ?? 'Buyer #' . $order->user_id);
            $order->buyer_name = $buyerName;
            $order->buyer_phone = $order->shippingAndBilling?->shipping_phone_no
                ?? ($order->shippingAndBilling?->shipping_phone ?? ($order->user?->user_phone ?? 'N/A'));

            $statusMeta = $statusLabels[$order->order_status_id] ?? ['label' => 'Status #' . $order->order_status_id, 'color' => 'bg-gray-100 text-gray-800'];
            $order->status_label = $statusMeta['label'];
            $order->status_badge_color = $statusMeta['color'];

            $order->created_at = $order->order_date ? Carbon::parse($order->order_date)->format('M d, Y H:i') : ($order->added_date ? Carbon::parse($order->added_date)->format('M d, Y H:i') : 'N/A');

            $order->delivery_fee_formatted = number_format((float) ($order->delivery_fee ?? 0), 2);
            $order->total_price_formatted = number_format((float) ($order->total_price ?? 0), 2);
            $order->delivery_type = $order->delivery_type ?? 'home';
            $order->yalidine_label_url = $order->yalidine_label_url ?? '';
            $order->yalidine_status = $order->yalidine_parcel_status ?? $order->yalidine_status ?? '';

            return $order;
        });

        // Compute global order counts
        $stats = [
            'total' => Order::count(),
            'pending' => Order::where('order_status_id', Constants::orderPendingStatus)->count(),
            'approved' => Order::where('order_status_id', Constants::orderApprovedStatus)->count(),
            'delivering' => Order::where('order_status_id', Constants::orderDeliveringStatus)->count(),
            'delivered' => Order::where('order_status_id', Constants::orderDeliveredStatus)->count(),
            'cancelled' => Order::where('order_status_id', Constants::orderCancelledStatus)->count(),
            'returned' => Order::where('order_status_id', Constants::orderReturnedStatus)->count(),
        ];

        return renderView('admin/orders/Index', [
            'orders' => $orders,
            'filters' => [
                'status' => $statusFilter,
                'search' => $search,
            ],
            'stats' => $stats,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'order_status_id' => 'required|in:1,2,3,4,5,6',
            'status_reason' => 'nullable|string|max:500',
        ]);

        $order = Order::findOrFail($id);
        $newStatusId = (int) $request->order_status_id;

        if (in_array($newStatusId, [Constants::orderCancelledStatus, Constants::orderReturnedStatus]) && empty($request->status_reason)) {
            return redirect()->back()->with('status', [
                'flag' => Constants::danger,
                'msg' => __('Please provide a reason when marking an order as Cancelled or Returned.'),
            ]);
        }

        $order->order_status_id = $newStatusId;
        if (! empty($request->status_reason)) {
            $order->status_reason = $request->status_reason;
        }
        $order->updated_user_id = Auth::id() ?? 1;
        $order->save();

        // Send automated status message to unified chat & FCM push
        try {
            $statusLabels = [
                1 => 'En attente',
                2 => 'Confirmée par le vendeur',
                3 => 'En cours d\'acheminement avec Yalidine' . (!empty($order->yalidine_tracking) ? " (Suivi: {$order->yalidine_tracking})" : ''),
                4 => 'Livrée avec succès !',
                5 => 'Annulée' . (!empty($order->status_reason) ? " (Motif: {$order->status_reason})" : ''),
                6 => 'Retournée' . (!empty($order->status_reason) ? " (Motif: {$order->status_reason})" : ''),
            ];
            $statusLabel = $statusLabels[$newStatusId] ?? "Statut mis à jour (#{$newStatusId})";
            app(\App\Services\OrderChatNotificationService::class)->sendOrderStatusUpdate($order, $statusLabel, 'both');
            if ($newStatusId === 2) {
                app(\App\Services\OrderChatNotificationService::class)->updateOrderActionStatus($order, 'accepted');
            } elseif ($newStatusId === 5) {
                app(\App\Services\OrderChatNotificationService::class)->updateOrderActionStatus($order, 'cancelled');
            }
        } catch (\Throwable $e) {
            \Log::warning('Admin status update chat noti error: ' . $e->getMessage());
        }

        return redirect()->back()->with('status', [
            'flag' => Constants::success,
            'msg' => __("Order #{$order->order_code} status updated successfully!"),
        ]);
    }

    public function generateParcel(Request $request, $id)
    {
        $order = Order::with(['shippingAndBilling', 'orderItems.item', 'user', 'vendorTransaction'])->findOrFail($id);
        $yalidineService = app(\App\Services\YalidineService::class);
        $result = $yalidineService->createParcelForOrder($order);

        if (empty($result['success'])) {
            return redirect()->back()->withErrors([
                'msg' => $result['error'] ?? __('Failed to generate Yalidine parcel.')
            ]);
        }

        return redirect()->back()->with('status', [
            'flag' => Constants::success,
            'msg' => __("Yalidine parcel generated successfully! Tracking: :tracking", ['tracking' => $result['tracking']]),
        ]);
    }

    public function printLabel(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        if (!empty($order->yalidine_label_url)) {
            return redirect()->away($order->yalidine_label_url);
        }
        if (!empty($order->yalidine_tracking)) {
            return redirect()->away("https://api.yalidine.app/v1/parcels/print/?tracking={$order->yalidine_tracking}");
        }
        return redirect()->back()->withErrors(['msg' => __('No shipping label available for this order.')]);
    }
}
