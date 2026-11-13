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
            'order_id' => 'required|exists:psx_orders,id',
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
            'order_id' => 'required|exists:psx_orders,id',
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
            'order_id' => 'required|exists:psx_orders,id',
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
            'order_id' => 'required|exists:psx_orders,id',
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
}
