<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Controllers\Finance;

use App\Http\Controllers\PsController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Configuration\Setting;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Entities\WithdrawRequest;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class AdminCommissionController extends PsController
{
    public function __construct(protected WalletService $walletService)
    {
        parent::__construct();
    }

    public function index()
    {
        $commissionPercent = WalletService::getCommissionPercent();
        $minWithdrawAmount = WalletService::getMinWithdrawAmount();
        $yalidineStubMode = WalletService::isYalidineStubMode();

        // Platform Escrow & Finance aggregates
        $totalEscrowOrders = Order::where('is_wallet_credited', 1)->count();
        $totalSellerWallets = Wallet::count();
        $totalSellerBalance = (float) Wallet::sum('balance');
        $totalPendingWithdrawals = (float) WithdrawRequest::where('status', 'pending')->sum('amount');
        $totalPaidWithdrawals = (float) WithdrawRequest::where('status', 'approved')->sum('amount');

        // Estimate commission collected
        $creditedOrders = Order::where('is_wallet_credited', 1)->get(['total_price', 'delivery_fee']);
        $totalCommissionEarned = 0.0;
        $totalEscrowTurnover = 0.0;
        foreach ($creditedOrders as $ord) {
            $base = max(0, (float) ($ord->total_price - ($ord->delivery_fee ?? 0)));
            if ($base <= 0) {
                $base = (float) $ord->total_price;
            }
            $totalEscrowTurnover += $base;
            $totalCommissionEarned += round(($base * $commissionPercent) / 100, 2);
        }

        return renderView('admin/commission/Index', [
            'settings' => [
                'commission_percent' => $commissionPercent,
                'min_withdraw_amount' => $minWithdrawAmount,
                'yalidine_stub_mode' => $yalidineStubMode,
            ],
            'stats' => [
                'total_escrow_orders' => $totalEscrowOrders,
                'total_escrow_turnover' => round($totalEscrowTurnover, 2),
                'total_commission_earned' => round($totalCommissionEarned, 2),
                'total_seller_wallets' => $totalSellerWallets,
                'total_seller_balance' => round($totalSellerBalance, 2),
                'total_pending_withdrawals' => round($totalPendingWithdrawals, 2),
                'total_paid_withdrawals' => round($totalPaidWithdrawals, 2),
            ],
        ]);
    }

    public function update(Request $request)
    {
        if (Auth::user()?->role_id != Constants::superAdminRoleId) {
            abort(403, 'Unauthorized. Super Admin access required.');
        }

        $request->validate([
            'commission_percent' => 'required|numeric|min:0|max:100',
            'min_withdraw_amount' => 'required|numeric|min:0',
            'yalidine_stub_mode' => 'required',
        ]);

        $payload = [
            'commission_percent' => round((float) $request->commission_percent, 2),
            'min_withdraw_amount' => round((float) $request->min_withdraw_amount, 2),
            'yalidine_stub_mode' => filter_var($request->yalidine_stub_mode, FILTER_VALIDATE_BOOLEAN),
        ];

        Setting::updateOrCreate(
            ['setting_env' => 'c2c_finance_setting'],
            [
                'setting' => json_encode($payload),
                'ref_selection' => 'c2c_finance',
            ]
        );

        return redirect()->back()->with('success', 'Platform C2C finance and commission settings updated successfully.');
    }
}
