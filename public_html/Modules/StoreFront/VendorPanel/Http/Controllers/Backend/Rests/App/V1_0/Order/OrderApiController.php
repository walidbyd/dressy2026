<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Rests\App\V1_0\Order;

use Illuminate\Contracts\Translation\Translator;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Validator;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Http\Services\OrderService;

class OrderApiController extends Controller
{
    protected $translator;

    protected $orderService;

    public function __construct(Translator $translator, OrderService $orderService)
    {
        $this->translator = $translator;
        $this->orderService = $orderService;
    }

    public function getOrderSummary(Request $request)
    {
        // prepare validation
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }
        // / validation end

        return $this->orderService->getOrderSummaryFromApi($request);
    }

    public function getOrderHistory(Request $request)
    {
        return $this->orderService->searchFromApi($request);
    }

    public function downloadPDF(Request $request)
    {
        return $this->orderService->downloadOrderPDF($request);
    }

    public function getSellerOrders(Request $request)
    {
        return $this->orderService->getSellerOrdersFromApi($request);
    }

    public function getSellerOrderDetail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->getSellerOrderDetailFromApi($request);
    }

    public function acceptOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->acceptOrderFromApi($request);
    }

    public function dispatchOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->dispatchOrderFromApi($request);
    }

    public function sendToDelivery(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->sendToDeliveryOrderFromApi($request);
    }

    public function cancelOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
            'cancel_reason' => 'required_without_all:status_reason,reason|string|min:3',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->cancelOrderFromApi($request);
    }

    public function sellerAction(Request $request, $order_id = null)
    {
        $orderId = $order_id ?: $request->order_id;
        $validator = Validator::make(array_merge($request->all(), ['order_id' => $orderId]), [
            'order_id' => 'required|exists:psx_orders,id',
            'action' => 'required|in:confirm,accept,cancel,reject',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->sellerActionFromApi($request, $orderId);
    }

    public function markOrderPaid(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|exists:psx_orders,id',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->markOrderPaidFromApi($request);
    }

    public function getWalletBalance(Request $request)
    {
        return $this->orderService->getWalletBalanceFromApi($request);
    }

    public function getWalletTransactions(Request $request)
    {
        return $this->orderService->getWalletTransactionsFromApi($request);
    }

    public function getSellerSalesTransactions(Request $request)
    {
        return $this->orderService->getSellerSalesTransactionsFromApi($request);
    }

    public function submitWithdrawRequest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1',
        ]);

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        return $this->orderService->submitWithdrawRequestFromApi($request);
    }

    public function calculateDeliveryFee(Request $request)
    {
        return $this->orderService->calculateDeliveryFeeFromApi($request);
    }

    public function submitReview(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|exists:psx_orders,id',
            'from_user_id' => 'required|exists:users,id',
            'rating' => 'required|numeric|min:1|max:5',
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }

        $order = \Modules\StoreFront\VendorPanel\Entities\Order::with(['orderStatus', 'vendor'])->find($request->order_id);
        if (!$order) {
            return responseMsgApi(__('Commande introuvable.'), Constants::notFoundStatusCode);
        }

        // Verify that the order belongs to the buyer
        if ((int) $order->user_id !== (int) $request->from_user_id) {
            return responseMsgApi(__('Cette commande n\'appartient pas à cet acheteur.'), Constants::badRequestStatusCode);
        }

        // Verify order is Delivered
        $isDelivered = ((int) $order->order_status_id === (int) Constants::orderDeliveredStatus)
            || in_array(strtolower($order->orderStatus?->name ?? ''), ['delivered', 'livrée', 'livree', 'livré'])
            || in_array(strtolower($order->yalidine_status ?? ''), ['livré', 'livre', 'delivered']);

        if (!$isDelivered) {
            return responseMsgApi(__('L\'avis ne peut être déposé qu\'après la livraison de la commande.'), Constants::badRequestStatusCode);
        }

        // Verify not already reviewed
        if ((int) ($order->is_reviewed ?? 0) === 1) {
            return responseMsgApi(__('Cette commande a déjà été évaluée.'), Constants::badRequestStatusCode);
        }

        // Determine seller user ID
        $toUserId = $request->to_user_id ?: ($order->vendor?->owner_user_id ?: $order->vendor_id);

        \Illuminate\Support\Facades\DB::beginTransaction();
        try {
            // Save review in psx_ratings
            $rating = new \Modules\Core\Entities\User\Rating();
            $rating->from_user_id = $request->from_user_id;
            $rating->to_user_id = $toUserId;
            $rating->rating = (float) $request->rating;
            $rating->title = $request->title ?: ('Avis commande #' . ($order->order_code ?? $order->id));
            $rating->description = $request->description ?: '';
            $rating->type = Constants::ratingUserType;
            $rating->transaction_header_id = $order->id;
            if ($order->order_items && $order->order_items->isNotEmpty()) {
                $rating->item_id = $order->order_items->first()->item_id;
            }
            $rating->added_date = \Carbon\Carbon::now();
            $rating->added_user_id = $request->from_user_id;
            $rating->save();

            // Update order record if review columns exist
            $orderFieldsToSave = false;
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'is_reviewed')) {
                $order->is_reviewed = 1;
                $orderFieldsToSave = true;
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'review_rating')) {
                $order->review_rating = (float) $request->rating;
                $orderFieldsToSave = true;
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn('psx_orders', 'review_id')) {
                $order->review_id = $rating->id;
                $orderFieldsToSave = true;
            }
            if ($orderFieldsToSave) {
                $order->save();
            }

            // Automatically recalculate the seller's rating note & count
            $allSellerRatings = \Modules\Core\Entities\User\Rating::where('to_user_id', $toUserId)->get();
            $totalCount = $allSellerRatings->count();
            $sumRating = $allSellerRatings->sum('rating');
            $avgRating = $totalCount > 0 ? number_format((float) ($sumRating / $totalCount), 1, '.', '') : '0.0';

            $sellerUser = \App\Models\User::find($toUserId);
            if ($sellerUser) {
                if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'overall_rating')) {
                    $sellerUser->overall_rating = $avgRating;
                }
                if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'rating_count')) {
                    $sellerUser->rating_count = $totalCount;
                }
                $sellerUser->save();
            }

            if ($order->vendor_id) {
                $vendor = \Modules\Core\Entities\Vendor\Vendor::find($order->vendor_id);
                if ($vendor) {
                    if (\Illuminate\Support\Facades\Schema::hasColumn('psx_vendors', 'overall_rating')) {
                        $vendor->overall_rating = $avgRating;
                    }
                    if (\Illuminate\Support\Facades\Schema::hasColumn('psx_vendors', 'rating_count')) {
                        $vendor->rating_count = $totalCount;
                    }
                    $vendor->save();
                }
            }

            \Illuminate\Support\Facades\DB::commit();

            return responseDataApi([
                'status' => 'success',
                'message' => 'Merci pour votre avis !',
                'order_id' => (string) $order->id,
                'is_reviewed' => '1',
                'review_rating' => (string) $rating->rating,
                'overall_rating' => (string) $avgRating,
                'rating_count' => (string) $totalCount,
            ]);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return responseMsgApi($e->getMessage(), Constants::internalServerErrorStatusCode);
        }
    }
}
