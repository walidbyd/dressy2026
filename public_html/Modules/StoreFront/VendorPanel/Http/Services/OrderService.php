<?php

namespace Modules\StoreFront\VendorPanel\Http\Services;

use App\Config\ps_config;
use App\Config\ps_constant;
use App\Http\Services\PsService;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\Core\Http\Services\UserAccessApiTokenService;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;
use Modules\StoreFront\VendorPanel\Http\Services\YalidineService;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\OrderItem;
use Modules\StoreFront\VendorPanel\Entities\OrderStatus;
use Modules\StoreFront\VendorPanel\Entities\ShippingAndBilling;
use Modules\StoreFront\VendorPanel\Entities\VendorPaymentStatus;
use Modules\StoreFront\VendorPanel\Entities\VendorTransaction;
use Modules\StoreFront\VendorPanel\Transformers\Api\App\V1_0\Order\OrderHistoryApiResource;
use Modules\StoreFront\VendorPanel\Transformers\Api\App\V1_0\Order\OrderSummaryApiResource;
use Modules\StoreFront\VendorPanel\Transformers\Backend\Model\Order\OrderWithKeyResource;

class OrderService extends PsService
{
    const parentPath = 'Pages/vendor/views/order_list/';

    const indexPath = self::parentPath.'Index';

    const createPath = self::parentPath.'Create';

    const editPath = self::parentPath.'Edit';

    const indexRoute = 'vendor_order_list.index';

    const createRoute = 'vendor_order_list.create';

    const editRoute = 'vendor_order_list.edit';

    protected $userAccessApiTokenService;

    protected $vendorPaymentStatusService;

    protected $vendorOrderStatusService;

    public function __construct(UserAccessApiTokenService $userAccessApiTokenService, VendorPaymentStatusService $vendorPaymentStatusService, VendorOrderStatusService $vendorOrderStatusService)
    {
        $this->userAccessApiTokenService = $userAccessApiTokenService;
        $this->vendorPaymentStatusService = $vendorPaymentStatusService;
        $this->vendorOrderStatusService = $vendorOrderStatusService;
    }

    public function getOrder($id = null, $relation = null)
    {
        $order = Order::when($id, function ($query, $id) {
            $query->where(Order::id, $id);
        })
            ->when($relation, function ($query, $relation) {
                $query->with($relation);
            })
            ->first();

        return $order;
    }

    public function getOrderSummaryFromApi($request)
    {
        // / check permission start
        $deviceToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $userId = $request->login_user_id;

        // user token layer permission start
        $userAccessApiToken = $this->userAccessApiTokenService->getUserAccessApiToken($userId, $deviceToken);
        // user token layer permission end

        if (empty($userAccessApiToken)) {
            $msg = __('shipping_and_billing__api_store_info_no_permission', [], $request->language_symbol);

            return responseMsgApi($msg, Constants::forbiddenStatusCode);
        }
        // / check permission end

        $rawOrderId = $request->order_id;
        $order = Order::where('id', $rawOrderId)->orWhere('order_code', $rawOrderId)->first();
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $relation = [
            'orderItems' => ['item.cover'],
            'shippingAndBilling',
            'vendorTransaction' => [
                'vendorPaymentStatus',
                'currency', 'vendor',
            ],
            'orderStatus',
            'vendor',
        ];

        $order->load($relation);
        $data = new OrderSummaryApiResource($order);

        return responseDataApi($data);

    }

    public function index($request)
    {
        $vendorId = getVendorIdFromSession();

        $conds['searchterm'] = $request->input('search') ?? '';
        $conds['order_by'] = null;
        $conds['order_type'] = null;
        $row = $request->input('row') ?? Constants::dataTableDefaultRow;
        if ($request->sort_field) {
            $conds['order_by'] = $request->sort_field;
            $conds['order_type'] = $request->sort_order;
        }

        $relations = ['vendorTransaction' => function ($q) use ($vendorId) {
            $q->with(['currency', 'vendorPaymentStatus' => function ($q) use ($vendorId) {
                $q->where('vendor_id', $vendorId);
            }]);
        }, 'orderStatus'];
        $orders = OrderWithKeyResource::collection($this->getOrders($vendorId, $relations, null, null, $conds, false, $row));
        $vendorPaymentStatuses = $this->vendorPaymentStatusService->getPaymentStatuses($vendorId, null, null, null, null, true, null);
        if ($conds['order_by']) {
            $dataArr = [
                'orders' => $orders,
                'vendorPaymentStatuses' => $vendorPaymentStatuses,
                'sort_field' => $conds['order_by'],
                'sort_order' => $request->sort_order,
                'search' => $conds['searchterm'],
            ];
        } else {
            $dataArr = [
                'orders' => $orders,
                'vendorPaymentStatuses' => $vendorPaymentStatuses,
                'search' => $conds['searchterm'],
            ];
        }

        return renderView(self::indexPath, $dataArr);
    }

    public function edit($id)
    {
        $vendorId = getVendorIdFromSession();

        $relations = [
            'orderItems' => function ($q) {
                $q->with(['item' => function ($q) {
                    $q->with(['cover']);
                }]);
            },
            'shippingAndBilling',
            'vendorTransaction' => function ($q) use ($vendorId) {
                $q->with(['currency', 'vendorPaymentStatus' => function ($q) use ($vendorId) {
                    $q->where('vendor_id', $vendorId);
                }]);
            },
        ];

        $order = new OrderWithKeyResource($this->getOrder($id, $relations));
        $paymentStatuses = $this->vendorPaymentStatusService->getPaymentStatuses($vendorId, null, null, null, null, true, null);
        $orderStatuses = $this->vendorOrderStatusService->getOrderStatuses($vendorId, null, null, null, null, true, null);

        $dataArr = [
            'order' => $order,
            'paymentStatuses' => $paymentStatuses,
            'orderStatuses' => $orderStatuses,
        ];

        return renderView(self::editPath, $dataArr);
    }

    public function update($request, $id)
    {
        $vendorId = getVendorIdFromSession();
        $relations = [
            'vendor',
            'shippingAndBilling',
            'vendorTransaction' => function ($q) use ($vendorId) {
                $q->with(['currency', 'vendorPaymentStatus' => function ($q) use ($vendorId) {
                    $q->where('vendor_id', $vendorId);
                }]);
            },
        ];

        DB::beginTransaction();

        try {
            $order = $this->getOrder($id, $relations);
            $order->order_status_id = $request->order_status_id;
            $order->updated_user_id = Auth::user()->id;
            $order->update();

            $vendorTransaction = VendorTransaction::where(VendorTransaction::orderId, $id)->first();
            $vendorTransaction->vendor_payment_status_id = $request->payment_status_id;
            $vendorTransaction->updated_user_id = Auth::user()->id;
            $vendorTransaction->update();

            sendBuyerForOrderStatusMail($order);

            DB::commit();

            return redirect()->back();
        } catch (\Throwable $e) {
            DB::rollBack();

            return redirect()->back();
        }
    }

    public function getOrders($vendorId, $relations = null, $limit = null, $offset = null, $conds = null, $noPagination = null, $pagPerPage = null)
    {
        $sort = '';
        if (isset($conds['order_by'])) {
            $sort = $conds['order_by'];
        }
        $orders = Order::
                        // join(OrderItem::tableName, OrderItem::tableName.'.'.OrderItem::orderId, Order::tableName.'.'.Order::id)
                        // ->join(VendorTransaction::tableName, VendorTransaction::tableName.'.'.VendorTransaction::orderId, Order::tableName.'.'.Order::id)
                        // ->select(Order::tableName.'.*', OrderItem::tableName.'.*')
                        when(isset($conds['order_by']) && $conds['order_by'], function ($q) use ($sort, $vendorId) {
                            if ($sort == 'owner_id@@name') {
                                $q->join(User::tableName, User::tableName.'.'.User::id, '=', Order::tableName.'.'.Order::userId);
                                $q->select(User::tableName.'.'.User::name.' as owner_name', Order::tableName.'.*');
                            }
                            if ($sort == 'order_status_id@@name') {
                                $q->join(OrderStatus::tableName, OrderStatus::tableName.'.'.OrderStatus::id, '=', Order::tableName.'.'.Order::orderStatusId);
                                $q->where([OrderStatus::tableName.'.'.OrderStatus::vendorId => $vendorId]);
                                $q->select(OrderStatus::tableName.'.'.OrderStatus::name.' as order_status_name', Order::tableName.'.*');
                            }
                            if ($sort == 'vendor_payment_status_id@@name') {
                                $q->join(VendorTransaction::tableName, VendorTransaction::tableName.'.'.VendorTransaction::orderId, '=', Order::tableName.'.'.Order::id);
                                $q->join(VendorPaymentStatus::tableName, VendorPaymentStatus::tableName.'.'.VendorPaymentStatus::id, '=', VendorTransaction::tableName.'.'.VendorTransaction::vendorPaymentStatusId);
                                $q->where([VendorPaymentStatus::tableName.'.'.VendorPaymentStatus::vendorId => $vendorId]);
                                $q->select(VendorPaymentStatus::tableName.'.'.VendorPaymentStatus::name.' as vendor_payment_status_name', Order::tableName.'.*');
                            }
                        })
                            ->when($relations, function ($query, $relations) {
                                $query->with($relations);
                            })
                            ->when($limit, function ($query, $limit) {
                                $query->limit($limit);
                            })
                            ->when($conds, function ($query, $conds) {
                                $query = $this->searching($query, $conds);
                            })
                            ->when($offset, function ($query, $offset) {
                                $query->offset($offset);
                            })
                            ->when(empty($sort), function ($query, $conds) {
                                $query->orderBy(Order::tableName.'.'.Order::id, 'desc');
                            })
                            ->where([Order::tableName.'.'.Order::vendorId => $vendorId, Order::tableName.'.'.Order::isPaymentFail => 0]);
        if ($pagPerPage) {
            $orders = $orders->paginate($pagPerPage)->onEachSide(1)->withQueryString();
        } elseif ($noPagination) {
            $orders = $orders->get();
        }

        return $orders;
    }

    public function searching($query, $conds)
    {

        // search term
        if (isset($conds['searchterm']) && $conds['searchterm']) {
            $search = $conds['searchterm'];
            $query->join(User::tableName, User::tableName.'.'.User::id, Order::tableName.'.'.Order::userId);
            $query->where(function ($query) use ($search) {
                $query->where(User::tableName.'.'.User::name, 'like', '%'.$search.'%');
                $query->orWhere(Order::tableName.'.'.Order::orderCode, 'like', '%'.$search.'%');
            });
        }

        // order status
        if (isset($conds['order_status_id']) && $conds['order_status_id']) {
            $query->where(Order::orderStatusId, $conds['order_status_id']);
        }

        // order by
        if (isset($conds['order_by']) && isset($conds['order_type']) && $conds['order_by'] && $conds['order_type']) {
            if ($conds['order_by'] == 'id') {
                $query->orderBy(Order::id, $conds['order_type']);
            } elseif ($conds['order_by'] == 'order_code') {
                $query->orderBy(Order::orderCode, $conds['order_type']);
            } elseif ($conds['order_by'] == 'owner_id@@name') {
                $query->orderBy('owner_name', $conds['order_type']);
            } elseif ($conds['order_by'] == 'quantity') {
                $query->orderBy('quantity', $conds['order_type']);
            } elseif ($conds['order_by'] == 'total_price') {
                $query->orderBy('total_price', $conds['order_type']);
            } elseif ($conds['order_by'] == 'order_date') {
                $query->orderBy('order_date', $conds['order_type']);
            } elseif ($conds['order_by'] == 'added_date') {
                $query->orderBy('added_date', $conds['order_type']);
            } elseif ($conds['order_by'] == 'order_status_id@@name') {
                $query->orderBy('order_status_name', $conds['order_type']);
            } elseif ($conds['order_by'] == 'vendor_payment_status_id@@name') {
                $query->orderBy('vendor_payment_status_name', $conds['order_type']);
            } else {
                $query->orderBy($conds['order_by'], $conds['order_type']);
            }
        } else {
            $query->orderBy(Order::tableName.'.'.Order::CREATED_AT, 'desc');
        }

        return $query;
    }

    public function destroy($id)
    {
        $vendorId = getVendorIdFromSession();

        $order = $this->getOrder($id);
        $orderItems = OrderItem::where(OrderItem::orderId, $id)->get();
        $vendorTransactions = VendorTransaction::where(VendorTransaction::orderId, $id)->get();
        $shippingAndBilling = ShippingAndBilling::where(ShippingAndBilling::orderId, $id)->first();
        $shippingAndBilling->delete();

        foreach ($vendorTransactions as $transaction) {
            $transaction->delete();
        }
        foreach ($orderItems as $item) {
            $item->delete();
        }
        $order->delete();

        $dataArr = [
            'msg' => __('core__be_delete_success', ['attribute' => $order->order_code]),
            'flag' => Constants::success,
        ];

        return redirectView(self::indexRoute, $dataArr['msg'], $dataArr['flag']);
    }

    public function getOrderHistoryFromApi($userId, $relations = null, $conds = null, $limit = null, $offset = null, $noPagination = null, $pagPerPage = null)
    {
        $orders = Order::where([Order::userId => $userId, Order::isPaymentFail => 0])
            ->when($relations, function ($query, $relations) {
                $query->with($relations);
            })
            ->when($limit, function ($query, $limit) {
                $query->limit($limit);
            })
            ->when($conds, function ($query, $conds) {
                $query = $this->searching($query, $conds);
            })
            ->when($offset, function ($query, $offset) {
                $query->offset($offset);
            });
        if ($pagPerPage) {
            $orders = $orders->paginate($pagPerPage)->onEachSide(1)->withQueryString();
        } elseif ($noPagination) {
            $orders = $orders->get();
        }

        return $orders;
    }

    public function searchFromApi($request)
    {
        $userId = $request->login_user_id;
        $limit = $request->limit;
        $offset = $request->offset;
        $perPage = ps_config::pagPerPage;
        $noPagination = false;
        if (isset($request->noPagination) && $request->noPagination) {
            $perPage = null;
            $noPagination = $request->noPagination;
        }
        try {
            \Illuminate\Support\Facades\Cache::remember('orders_due_check_lock', 60, function () {
                return \App\Console\Commands\CancelExpiredOrdersCommand::processExpiredOrders();
            });
        } catch (\Throwable $e) {}

        $conds = [];
        $relations = [
            'vendor',
            'shippingAndBilling',
            'vendorTransaction' => function ($q) {
                $q->with(['currency']);
            },
            'orderItems' => function ($q) {
                $q->with(['item' => function ($q) {
                    $q->with(['cover']);
                }]);
            },
        ];
        if (isset($request->order_status)) {
            $conds['order_status_id'] = $request->order_status;
        }
        $conds['order_by'] = $request->order_by;
        $conds['order_type'] = $request->order_type;

        $orders = $this->getOrderHistoryFromApi($userId, $relations, $conds, $limit, $offset, $noPagination, $perPage);
        $totalOrders = Order::where([Order::userId => $userId, Order::isPaymentFail => 0])->get();
        $data = [];
        if ($noPagination || $request->has('noPagination') || (isset($request->noPagination) && $request->noPagination)) {
            $data = OrderHistoryApiResource::collection($orders);
        } else {
            $data = [
                'all_order_count' => $totalOrders->count(),
                'pending_order_count' => $totalOrders->where('order_status_id', constants::orderPendingStatus)->count(),
                'approved_order_count' => $totalOrders->where('order_status_id', constants::orderApprovedStatus)->count(),
                'delivering_order_count' => $totalOrders->where('order_status_id', constants::orderDeliveringStatus)->count(),
                'delivered_order_count' => $totalOrders->where('order_status_id', constants::orderDeliveredStatus)->count(),
                'order_history' => OrderHistoryApiResource::collection($orders),
                // 'order_history' => $orders,
                'meta' => [
                    'current_page' => $orders->currentPage(),
                    'from' => $orders->firstItem(),
                    'last_page' => $orders->lastPage(),
                    'path' => $orders->path(),
                    'per_page' => $orders->perPage(),
                    'to' => $orders->lastItem(),
                    'total' => $orders->total(),
                    'links' => $orders->toArray()['links'],
                ],
            ];
        }

        return responseDataApi($data);
    }

    public function downloadOrderPDF($request)
    {
        $orderId = $request->order_id;
        $relations = [
            'vendor', 'orderStatus',
            'shippingAndBilling',
            'vendorTransaction' => function ($q) {
                $q->with(['currency', 'vendorPaymentStatus']);
            },
            'orderItems' => function ($q) {
                $q->with(['item' => function ($q) {
                    $q->with(['cover']);
                }]);
            },
        ];
        $order = $this->getOrder($orderId, $relations);
        if ($order) {
            // dd($order->toArray());
            $pdf = PDF::loadView('order.order', compact('order'));
            $file = 'order_'.$order->order_code.'.pdf';

            return $pdf->download($file);
        }

    }

    public function getSellerOrdersFromApi($request)
    {
        $userId = $request->login_user_id;
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        // Check if seller has any orders either via vendor_id or via owned items
        $hasAnyOrders = Order::where('is_payment_fail', 0)
            ->where(function ($query) use ($vendor, $userId) {
                if ($vendor) {
                    $query->where('vendor_id', $vendor->id);
                }
                $query->orWhereHas('orderItems.item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                });
            })
            ->exists();

        if (! $vendor && ! $hasAnyOrders) {
            if ($request->has('noPagination') || (isset($request->noPagination) && $request->noPagination)) {
                return responseDataApi([]);
            }
            $data = [
                'all_order_count' => 0,
                'pending_order_count' => 0,
                'approved_order_count' => 0,
                'delivering_order_count' => 0,
                'delivered_order_count' => 0,
                'cancelled_order_count' => 0,
                'returned_order_count' => 0,
                'order_history' => [],
                'meta' => [
                    'current_page' => 1,
                    'from' => null,
                    'last_page' => 1,
                    'path' => '',
                    'per_page' => ps_config::pagPerPage,
                    'to' => null,
                    'total' => 0,
                    'links' => [],
                ],
            ];

            return responseDataApi($data);
        }

        $limit = $request->limit;
        $offset = $request->offset;
        $perPage = ps_config::pagPerPage;
        $noPagination = false;
        if (isset($request->noPagination) && $request->noPagination) {
            $perPage = null;
            $noPagination = $request->noPagination;
        }

        try {
            \Illuminate\Support\Facades\Cache::remember('orders_due_check_lock', 60, function () {
                return \App\Console\Commands\CancelExpiredOrdersCommand::processExpiredOrders();
            });
        } catch (\Throwable $e) {}

        $conds = [];
        $relations = [
            'vendor',
            'orderStatus',
            'shippingAndBilling',
            'vendorTransaction' => function ($q) {
                $q->with(['currency']);
            },
            'orderItems' => function ($q) {
                $q->with(['item' => function ($q) {
                    $q->with(['cover']);
                }]);
            },
        ];

        if (isset($request->order_status)) {
            $conds['order_status_id'] = $request->order_status;
        }
        $conds['order_by'] = $request->order_by;
        $conds['order_type'] = $request->order_type;

        $ordersQuery = Order::where('is_payment_fail', 0)
            ->where(function ($query) use ($vendor, $userId) {
                if ($vendor) {
                    $query->where('vendor_id', $vendor->id);
                }
                $query->orWhereHas('orderItems.item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                });
            })
            ->when($relations, function ($query, $relations) {
                $query->with($relations);
            })
            ->when($limit, function ($query, $limit) {
                $query->limit($limit);
            })
            ->when($conds, function ($query, $conds) {
                $query = $this->searching($query, $conds);
            })
            ->when($offset, function ($query, $offset) {
                $query->offset($offset);
            });

        if ($perPage) {
            $orders = $ordersQuery->paginate($perPage)->onEachSide(1)->withQueryString();
        } elseif ($noPagination) {
            $orders = $ordersQuery->get();
        } else {
            $orders = $ordersQuery->get();
        }

        $totalOrders = Order::where('is_payment_fail', 0)
            ->where(function ($query) use ($vendor, $userId) {
                if ($vendor) {
                    $query->where('vendor_id', $vendor->id);
                }
                $query->orWhereHas('orderItems.item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                });
            })
            ->get();

        if ($noPagination || $request->has('noPagination') || (isset($request->noPagination) && $request->noPagination)) {
            $data = OrderHistoryApiResource::collection($orders);
        } else {
            $data = [
                'all_order_count' => $totalOrders->count(),
                'pending_order_count' => $totalOrders->where('order_status_id', Constants::orderPendingStatus)->count(),
                'approved_order_count' => $totalOrders->where('order_status_id', Constants::orderApprovedStatus)->count(),
                'delivering_order_count' => $totalOrders->where('order_status_id', Constants::orderDeliveringStatus)->count(),
                'delivered_order_count' => $totalOrders->where('order_status_id', Constants::orderDeliveredStatus)->count(),
                'cancelled_order_count' => $totalOrders->where('order_status_id', Constants::orderCancelledStatus)->count(),
                'returned_order_count' => $totalOrders->where('order_status_id', Constants::orderReturnedStatus)->count(),
                'order_history' => OrderHistoryApiResource::collection($orders),
                'meta' => [
                    'current_page' => $orders->currentPage(),
                    'from' => $orders->firstItem(),
                    'last_page' => $orders->lastPage(),
                    'path' => $orders->path(),
                    'per_page' => $orders->perPage(),
                    'to' => $orders->lastItem(),
                    'total' => $orders->total(),
                    'links' => $orders->toArray()['links'],
                ],
            ];
        }

        return responseDataApi($data);
    }

    public function getSellerOrderDetailFromApi($request)
    {
        $userId = $request->login_user_id;
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        $rawOrderId = $request->order_id;
        $order = Order::where('id', $rawOrderId)->orWhere('order_code', $rawOrderId)->first();
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $isOwner = false;
        if (!empty($order->vendor_id) && Vendor::where('id', $order->vendor_id)->where('owner_user_id', $userId)->exists()) {
            $isOwner = true;
        } elseif ($vendor && $order->vendor_id == $vendor->id) {
            $isOwner = true;
        } else {
            $userVendors = Vendor::where('owner_user_id', $userId)->pluck('id')->toArray();
            if (!empty($userVendors) && in_array($order->vendor_id, $userVendors)) {
                $isOwner = true;
            } else {
                $isOwner = $order->orderItems()->whereHas('item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                })->exists();
            }
        }

        if (! $isOwner) {
            return responseMsgApi(__('Unauthorized: You do not own this order.'), Constants::forbiddenStatusCode);
        }

        $relations = [
            'orderItems' => ['item.cover'],
            'shippingAndBilling',
            'vendorTransaction' => [
                'vendorPaymentStatus',
                'currency', 'vendor',
            ],
            'orderStatus',
            'vendor',
        ];

        $order->load($relations);

        return responseDataApi(new OrderSummaryApiResource($order));
    }

    public function acceptOrderFromApi($request)
    {
        $userId = $request->login_user_id;
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        $rawOrderId = $request->order_id;
        $order = Order::where('id', $rawOrderId)->orWhere('order_code', $rawOrderId)->first();
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $isOwner = false;
        if (!empty($order->vendor_id) && Vendor::where('id', $order->vendor_id)->where('owner_user_id', $userId)->exists()) {
            $isOwner = true;
        } elseif ($vendor && $order->vendor_id == $vendor->id) {
            $isOwner = true;
        } else {
            $userVendors = Vendor::where('owner_user_id', $userId)->pluck('id')->toArray();
            if (!empty($userVendors) && in_array($order->vendor_id, $userVendors)) {
                $isOwner = true;
            } else {
                $isOwner = $order->orderItems()->whereHas('item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                })->exists();
            }
        }

        if (! $isOwner) {
            return responseMsgApi(__('Unauthorized: You do not own this order.'), Constants::forbiddenStatusCode);
        }

        if ((int) $order->order_status_id !== (int) Constants::orderPendingStatus) {
            return responseMsgApi(__('Only pending orders can be accepted.'), Constants::badRequestStatusCode);
        }

        // Generate Yalidine parcel on seller order approval
        $order->load(['shippingAndBilling', 'orderItems.item', 'vendorTransaction', 'user']);
        $dzshipService = app(\App\Services\DzshipYalidineService::class);
        $yalResult = empty($order->yalidine_tracking)
            ? $dzshipService->createShipment($order)
            : [
                'success' => true,
                'tracking' => $order->yalidine_tracking,
                'parcel_id' => $order->yalidine_parcel_id,
                'label_url' => $order->yalidine_label_url,
                'status' => $order->yalidine_parcel_status ?? 'dispatched',
            ];

        if (empty($yalResult['success']) || empty($yalResult['tracking'])) {
            $errMsg = $yalResult['error'] ?? __('Failed to create Yalidine shipment.');
            return responseMsgApi($errMsg, Constants::badRequestStatusCode);
        }

        $order->order_status_id = Constants::orderDeliveringStatus;
        try {
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'fulfillment_deadline_at')) {
                $order->fulfillment_deadline_at = \Carbon\Carbon::now()->addHours(72);
            }
        } catch (\Throwable $e) {}
        $order->yalidine_tracking = $yalResult['tracking'];
        $order->yalidine_parcel_id = $yalResult['parcel_id'] ?? $yalResult['tracking'];
        $order->yalidine_label_url = $yalResult['label_url'] ?? null;
        $order->yalidine_parcel_status = $yalResult['status'] ?? 'dispatched';
        $order->yalidine_status = $yalResult['status'] ?? 'dispatched';
        $order->save();

        try {
            $chatNotiService = app(\App\Services\OrderChatNotificationService::class);
            $chatNotiService->updateOrderActionStatus($order, 'in_delivery');
            $trackingText = !empty($order->yalidine_tracking) ? " (Numéro de suivi Yalidine: {$order->yalidine_tracking})" : "";
            $chatNotiService->sendOrderStatusUpdate($order, "Votre commande #{$order->order_code} a été acceptée par le vendeur et est en cours d'acheminement.{$trackingText}", 'both');
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('acceptOrder chat noti error: ' . $e->getMessage());
        }

        $shippingInstructions = [
            'title' => "Instructions d'expédition",
            'steps' => [
                "1. Imprimez le bordereau d'envoi Yalidine et collez-le soigneusement sur le colis.",
                "2. Emballez le produit de façon sécurisée pour le protéger durant le transport.",
                "3. Déposez le colis au bureau Yalidine ou remettez-le au livreur.",
                "4. Le suivi du colis et le paiement seront automatiquement mis à jour à la livraison.",
            ],
            'tracking' => $order->yalidine_tracking,
            'label_url' => $order->yalidine_label_url,
        ];

        return response()->json([
            'status' => 'success',
            'action_status' => 'in_delivery',
            'order_status_id' => $order->order_status_id,
            'order_code' => $order->order_code,
            'message' => __('Order has been accepted and Yalidine parcel created.'),
            'tracking' => $order->yalidine_tracking,
            'label_url' => $order->yalidine_label_url,
            'shipping_instructions' => $shippingInstructions,
        ], Constants::okStatusCode);
    }

    public function dispatchOrderFromApi($request)
    {
        $userId = $request->login_user_id;
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        $rawOrderId = $request->order_id;
        $order = Order::where('id', $rawOrderId)->orWhere('order_code', $rawOrderId)->first();
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $isOwner = false;
        if (!empty($order->vendor_id) && Vendor::where('id', $order->vendor_id)->where('owner_user_id', $userId)->exists()) {
            $isOwner = true;
        } elseif ($vendor && $order->vendor_id == $vendor->id) {
            $isOwner = true;
        } else {
            $userVendors = Vendor::where('owner_user_id', $userId)->pluck('id')->toArray();
            if (!empty($userVendors) && in_array($order->vendor_id, $userVendors)) {
                $isOwner = true;
            } else {
                $isOwner = $order->orderItems()->whereHas('item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                })->exists();
            }
        }

        if (! $isOwner) {
            return responseMsgApi(__('Unauthorized: You do not own this order.'), Constants::forbiddenStatusCode);
        }

        if ((int) $order->order_status_id !== (int) Constants::orderApprovedStatus && (int) $order->order_status_id !== (int) Constants::orderPendingStatus) {
            return responseMsgApi(__('Only pending or accepted orders can be dispatched.'), Constants::badRequestStatusCode);
        }

        // Load relations needed for shipment creation
        $order->load(['shippingAndBilling', 'orderItems.item', 'vendorTransaction', 'user']);

        // Call Yalidine parcel creation service via DZBuild dzship if not already generated
        if (empty($order->yalidine_tracking)) {
            $dzshipService = app(\App\Services\DzshipYalidineService::class);
            $yalidineResult = $dzshipService->createShipment($order);

            if (empty($yalidineResult['success'])) {
                $errorMessage = $yalidineResult['error'] ?? __('Failed to create Yalidine shipment.');

                return responseMsgApi($errorMessage, Constants::badRequestStatusCode);
            }

            $order->yalidine_tracking = $yalidineResult['tracking'] ?? null;
            $order->yalidine_parcel_id = $yalidineResult['parcel_id'] ?? null;
            $order->yalidine_label_url = $yalidineResult['label_url'] ?? null;
            $order->yalidine_parcel_status = $yalidineResult['status'] ?? 'dispatched';
            $order->yalidine_status = $yalidineResult['status'] ?? 'dispatched';
        }

        $order->order_status_id = Constants::orderDeliveringStatus;
        $order->save();

        try {
            $chatNotiService = app(\App\Services\OrderChatNotificationService::class);
            $trackingText = !empty($order->yalidine_tracking) ? " (Suivi Yalidine: {$order->yalidine_tracking})" : "";
            $chatNotiService->sendOrderStatusUpdate($order, "Votre commande est en cours de livraison avec Yalidine.{$trackingText}", 'both');
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('dispatchOrder chat noti error: ' . $e->getMessage());
        }

        return response()->json([
            'status' => 'success',
            'message' => __('Order has been dispatched and Yalidine shipment created.'),
            'tracking' => $order->yalidine_tracking,
            'label_url' => $order->yalidine_label_url,
        ], Constants::okStatusCode);
    }

    public function sendToDeliveryOrderFromApi($request)
    {
        return $this->dispatchOrderFromApi($request);
    }

    public function cancelOrderFromApi($request)
    {
        $userId = $request->login_user_id;
        $vendor = Vendor::where('owner_user_id', $userId)->first();

        $rawOrderId = $request->order_id;
        $order = Order::where('id', $rawOrderId)->orWhere('order_code', $rawOrderId)->first();
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $isOwner = false;
        if (!empty($order->vendor_id) && Vendor::where('id', $order->vendor_id)->where('owner_user_id', $userId)->exists()) {
            $isOwner = true;
        } elseif ($vendor && $order->vendor_id == $vendor->id) {
            $isOwner = true;
        } else {
            $userVendors = Vendor::where('owner_user_id', $userId)->pluck('id')->toArray();
            if (!empty($userVendors) && in_array($order->vendor_id, $userVendors)) {
                $isOwner = true;
            } else {
                $isOwner = $order->orderItems()->whereHas('item', function ($q) use ($userId) {
                    $q->where('added_user_id', $userId);
                })->exists();
            }
        }

        if (! $isOwner) {
            return responseMsgApi(__('Unauthorized: You do not own this order.'), Constants::forbiddenStatusCode);
        }

        $reason = $request->cancel_reason ?? $request->status_reason ?? $request->reason;
        if (empty($reason)) {
            return responseMsgApi(__('Please provide a cancellation reason.'), Constants::badRequestStatusCode);
        }

        if ((int) $order->order_status_id === (int) Constants::orderDeliveredStatus) {
            return responseMsgApi(__('Delivered orders cannot be cancelled.'), Constants::badRequestStatusCode);
        }

        $order->order_status_id = Constants::orderCancelledStatus;
        $order->status_reason = $reason;
        $order->save();

        // Process automatic wallet reversal (if credited) and refund buyer wallet balance (if used)
        try {
            app(WalletService::class)->reverseOrderFunds($order, $reason, $userId);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Wallet reversal on cancelOrderFromApi failed: ' . $e->getMessage());
        }

        try {
            $chatNotiService = app(\App\Services\OrderChatNotificationService::class);
            $chatNotiService->updateOrderActionStatus($order, 'cancelled');
            $chatNotiService->sendOrderStatusUpdate($order, "La commande a été annulée par le vendeur. Motif: {$reason}", 'both');
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('cancelOrder chat noti error: ' . $e->getMessage());
        }

        return responseMsgApi(__('Order has been cancelled successfully.'), Constants::okStatusCode, Constants::successStatus);
    }

    public function sellerActionFromApi($request, $orderId = null)
    {
        $userId = $request->login_user_id ?: ($request->user_id ?? $request->user()?->id);
        $orderId = $orderId ?: $request->order_id;

        if (empty($orderId)) {
            return responseMsgApi(__('Order ID is required.'), Constants::badRequestStatusCode);
        }

        $order = Order::with(['orderItems.item', 'vendor', 'user', 'shippingAndBilling'])
            ->where('id', $orderId)
            ->orWhere('order_code', $orderId)
            ->first();
        if (!$order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        // Verify seller ownership
        $isOwner = false;
        if (!empty($order->vendor_id) && Vendor::where('id', $order->vendor_id)->where('owner_user_id', $userId)->exists()) {
            $isOwner = true;
        } else {
            $vendor = Vendor::where('owner_user_id', $userId)->first();
            if ($vendor && $order->vendor_id == $vendor->id) {
                $isOwner = true;
            } else {
                $userVendors = Vendor::where('owner_user_id', $userId)->pluck('id')->toArray();
                if (!empty($userVendors) && in_array($order->vendor_id, $userVendors)) {
                    $isOwner = true;
                } else {
                    $isOwner = $order->orderItems()->whereHas('item', function ($q) use ($userId) {
                        $q->where('added_user_id', $userId);
                    })->exists();
                }
            }
        }

        if (!$isOwner) {
            return responseMsgApi(__('Unauthorized: You do not own this order.'), Constants::forbiddenStatusCode);
        }

        $action = strtolower(trim((string) $request->input('action', '')));
        if (!in_array($action, ['confirm', 'accept', 'cancel', 'reject', 'delivered', 'deliver'])) {
            return responseMsgApi(__('Invalid action. Allowed values: confirm, cancel, delivered.'), Constants::badRequestStatusCode);
        }

        $chatNotiService = app(\App\Services\OrderChatNotificationService::class);

        if ($action === 'delivered' || $action === 'deliver') {
            $walletService = app(WalletService::class);
            $result = $walletService->creditForOrder($order, $userId);

            if (! empty($result['error'])) {
                return responseMsgApi($result['error'], Constants::badRequestStatusCode);
            }

            $chatNotiService->updateOrderActionStatus($order, 'delivered');
            $buyerMsg = "Votre commande a été livrée avec succès !";
            $chatNotiService->sendOrderStatusUpdate($order, $buyerMsg, 'both');

            return response()->json([
                'status' => 'success',
                'action_status' => 'delivered',
                'order_status_id' => $order->order_status_id,
                'order_code' => $order->order_code,
                'message' => __('Order marked as delivered and seller wallet credited.'),
                'wallet_credited' => true,
            ], Constants::okStatusCode);
        }

        if ($action === 'confirm' || $action === 'accept') {
            if ((int) $order->order_status_id !== (int) Constants::orderPendingStatus && (int) $order->order_status_id !== (int) Constants::orderApprovedStatus) {
                return responseMsgApi(__('Only pending orders can be confirmed.'), Constants::badRequestStatusCode);
            }

            // Create Yalidine shipment parcel via direct Yalidine API if not already created
            if (empty($order->yalidine_tracking)) {
                $order->loadMissing(['shippingAndBilling', 'orderItems.item', 'vendorTransaction', 'user']);
                $dzshipService = app(\App\Services\DzshipYalidineService::class);
                $yalResult = $dzshipService->createShipment($order);

                if (empty($yalResult['success']) || empty($yalResult['tracking'])) {
                    $errMsg = $yalResult['error'] ?? __('Failed to create Yalidine shipment.');
                    return responseMsgApi($errMsg, Constants::badRequestStatusCode);
                }

                $order->yalidine_tracking = $yalResult['tracking'];
                $order->yalidine_parcel_id = $yalResult['parcel_id'] ?? $yalResult['tracking'];
                $order->yalidine_label_url = $yalResult['label_url'] ?? null;
                $order->yalidine_parcel_status = $yalResult['status'] ?? 'dispatched';
                $order->yalidine_status = $yalResult['status'] ?? 'dispatched';
            }

            $order->order_status_id = Constants::orderDeliveringStatus;
            $order->save();

            // Update action status across DB and Firebase RTDB
            $chatNotiService->updateOrderActionStatus($order, 'in_delivery');

            // Send automated status message to Buyer
            $trackingText = !empty($order->yalidine_tracking) ? " (Numéro de suivi Yalidine: {$order->yalidine_tracking})" : "";
            $buyerMsg = "Votre commande #{$order->order_code} a été acceptée par le vendeur et est en cours d'acheminement.{$trackingText}";
            $chatNotiService->sendOrderStatusUpdate($order, $buyerMsg, 'buyer');

            $shippingInstructions = [
                'title' => "Instructions d'expédition",
                'steps' => [
                    "1. Imprimez le bordereau d'envoi Yalidine et collez-le soigneusement sur le colis.",
                    "2. Emballez le produit de façon sécurisée pour le protéger durant le transport.",
                    "3. Déposez le colis au bureau Yalidine ou remettez-le au livreur.",
                    "4. Le suivi du colis et le paiement seront automatiquement mis à jour à la livraison.",
                ],
                'tracking' => $order->yalidine_tracking,
                'label_url' => $order->yalidine_label_url,
            ];

            return response()->json([
                'status' => 'success',
                'action_status' => 'in_delivery',
                'order_status_id' => $order->order_status_id,
                'order_code' => $order->order_code,
                'message' => __('Order has been accepted by seller.'),
                'tracking' => $order->yalidine_tracking,
                'label_url' => $order->yalidine_label_url,
                'shipping_instructions' => $shippingInstructions,
            ], Constants::okStatusCode);
        }

        if ($action === 'cancel' || $action === 'reject') {
            if ((int) $order->order_status_id === (int) Constants::orderDeliveredStatus) {
                return responseMsgApi(__('Delivered orders cannot be cancelled.'), Constants::badRequestStatusCode);
            }

            $reason = $request->reason ?? $request->cancel_reason ?? $request->status_reason ?? 'Annulée par le vendeur';
            $order->order_status_id = Constants::orderCancelledStatus;
            $order->status_reason = $reason;
            $order->save();

            // Process automatic wallet reversal (if credited) and refund buyer wallet balance (if used)
            try {
                app(WalletService::class)->reverseOrderFunds($order, $reason, $userId);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('Wallet reversal on sellerAction cancel failed: ' . $e->getMessage());
            }

            // Update action status across DB and Firebase RTDB
            $chatNotiService->updateOrderActionStatus($order, 'cancelled');

            // Send automated status message to Buyer
            $buyerMsg = "La commande a été annulée par le vendeur." . ($reason ? " Motif: {$reason}" : "");
            $chatNotiService->sendOrderStatusUpdate($order, $buyerMsg, 'buyer');

            return response()->json([
                'status' => 'success',
                'action_status' => 'cancelled',
                'order_status_id' => $order->order_status_id,
                'order_code' => $order->order_code,
                'message' => __('Order has been cancelled by seller.'),
                'reason' => $reason,
            ], Constants::okStatusCode);
        }
    }

    public function markOrderPaidFromApi($request)
    {
        $userId = $request->login_user_id;

        // Security lockdown: Only Super Admin (role_id = 1) can trigger mark_paid
        $adminUser = \App\Models\User::find($userId);
        if (! $adminUser || (int) $adminUser->role_id !== Constants::superAdminRoleId) {
            return responseMsgApi(__('Unauthorized. Admin privileges required to mark orders as paid.'), Constants::forbiddenStatusCode);
        }

        $order = Order::find($request->order_id);
        if (! $order) {
            return responseMsgApi(__('Order not found.'), Constants::notFoundStatusCode);
        }

        $walletService = app(WalletService::class);
        $result = $walletService->creditForOrder($order, $userId);

        if (! empty($result['error'])) {
            return responseMsgApi($result['error'], Constants::badRequestStatusCode);
        }

        if (! empty($result['already_credited'])) {
            return responseMsgApi(__('Order already marked paid and credited.'), Constants::okStatusCode, Constants::successStatus);
        }

        return responseDataApi([
            'message' => __('Order marked as paid and seller wallet credited successfully.'),
            'credited_amount' => $result['credited_amount'],
            'commission_amount' => $result['commission_amount'],
            'balance_after' => $result['balance_after'],
        ]);
    }

    public function getWalletBalanceFromApi($request)
    {
        $userId = $request->login_user_id;
        if (! $userId) {
            return responseMsgApi(__('Login user is required.'), Constants::badRequestStatusCode);
        }

        $walletService = app(WalletService::class);
        $balanceData = $walletService->getWalletBalance($userId);

        return responseDataApi($balanceData);
    }

    public function getWalletTransactionsFromApi($request)
    {
        $userId = $request->login_user_id ?: ($request->user_id ?? $request->user()?->id);
        if (! $userId) {
            return responseMsgApi(__('Login user is required.'), Constants::badRequestStatusCode);
        }

        $limit = (int) ($request->limit ?? 20);
        $offset = (int) ($request->offset ?? 0);

        $walletService = app(WalletService::class);
        $transactionsData = $walletService->getWalletTransactions($userId, $limit, $offset);

        return responseDataApi($transactionsData);
    }

    public function getSellerSalesTransactionsFromApi($request)
    {
        $userId = $request->login_user_id ?: ($request->user_id ?? $request->user()?->id);
        if (! $userId) {
            return responseMsgApi(__('Login user is required.'), Constants::badRequestStatusCode);
        }

        $dateFrom = $request->date_from;
        $dateTo = $request->date_to;
        $limit = (int) ($request->limit ?? 20);
        $offset = (int) ($request->offset ?? 0);

        $walletService = app(WalletService::class);
        $transactionsData = $walletService->getSellerSalesTransactions($userId, $dateFrom, $dateTo, $limit, $offset);

        return responseDataApi($transactionsData);
    }

    public function submitWithdrawRequestFromApi($request)
    {
        $userId = $request->login_user_id;
        if (! $userId) {
            return responseMsgApi(__('Login user is required.'), Constants::badRequestStatusCode);
        }

        $amount = (float) $request->amount;
        $note = $request->note ?? '';

        $walletService = app(WalletService::class);
        $result = $walletService->submitWithdrawRequest($userId, $amount, $note);

        if (! empty($result['error'])) {
            return responseMsgApi($result['error'], Constants::badRequestStatusCode);
        }

        return responseMsgApi($result['message'] ?? __('Withdrawal request submitted successfully.'), Constants::okStatusCode, Constants::successStatus);
    }

    public function calculateDeliveryFeeFromApi($request)
    {
        $yalidineService = app(YalidineService::class);
        $dzshipService = app(\App\Services\DzshipYalidineService::class);

        $itemId = $request->item_id ?? $request->product_id;
        $vendorId = $request->vendor_id;
        $explicitFrom = $request->from_wilaya_id ?? $request->from_wilaya;

        $fromWilaya = $dzshipService->resolveItemFromWilaya(
            $itemId ? (int) $itemId : null,
            $vendorId ? (int) $vendorId : null,
            $explicitFrom
        );

        $toWilaya = $request->to_wilaya_id ?? $request->shipping_city_id ?? $request->shipping_city ?? $request->shipping_state ?? $request->to_wilaya ?? 16;
        $isStopDesk = filter_var($request->is_stop_desk ?? false, FILTER_VALIDATE_BOOLEAN);
        $weight = (float) ($request->weight ?? 1);

        $feeData = $yalidineService->calculateDeliveryFee($fromWilaya, $toWilaya, $isStopDesk, $weight);

        $itemPrice = (float) ($request->item_price ?? $request->sub_total ?? $request->total_price ?? 0);
        $deliveryFee = (float) $feeData['delivery_fee'];
        $totalPrice = $itemPrice + $deliveryFee;

        return response()->json([
            'status' => 'success',
            'delivery_fee' => $deliveryFee,
            'is_stop_desk' => $isStopDesk,
            'from_wilaya_id' => $feeData['from_wilaya_id'],
            'to_wilaya_id' => $feeData['to_wilaya_id'],
            'item_price' => $itemPrice,
            'total_price' => $totalPrice,
            'currency' => 'DA',
            'is_stub' => $feeData['is_stub'] ?? true,
        ]);
    }
}
