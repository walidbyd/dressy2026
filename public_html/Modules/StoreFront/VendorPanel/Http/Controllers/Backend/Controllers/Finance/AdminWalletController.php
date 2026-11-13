<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Controllers\Finance;

use App\Http\Controllers\PsController;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Entities\WithdrawRequest;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class AdminWalletController extends PsController
{
    public function __construct(protected WalletService $walletService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $search = $request->input('search', '');

        $query = User::with(['wallet', 'vendor'])->where('status', 1)->latest('id');

        if (! empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('user_phone', 'like', "%{$search}%")
                    ->orWhereHas('vendor', function ($vq) use ($search) {
                        $vq->where('name', 'like', "%{$search}%");
                    });
            });
        }

        $users = $query->paginate(15)->withQueryString();

        // Calculate pending withdrawal and total earned for each user
        $users->getCollection()->transform(function ($u) {
            $wallet = $u->wallet;
            $balance = $wallet ? (float) $wallet->balance : 0.0;
            $pendingWithdrawals = (float) WithdrawRequest::where('user_id', $u->id)
                ->where('status', 'pending')
                ->sum('amount');
            $totalEarned = (float) WalletTransaction::where('user_id', $u->id)
                ->where('type', 'credit')
                ->where('reference_type', 'order')
                ->sum('amount');
            $totalWithdrawn = (float) WalletTransaction::where('user_id', $u->id)
                ->where('type', 'debit')
                ->where('reference_type', 'withdraw')
                ->sum('amount');

            $u->wallet_balance = $balance;
            $u->pending_withdrawals = $pendingWithdrawals;
            $u->total_earned = $totalEarned;
            $u->total_withdrawn = $totalWithdrawn;
            $u->vendor_name = $u->vendor?->name ?? 'N/A';

            return $u;
        });

        $totalBalanceAll = (float) Wallet::sum('balance');
        $totalEarnedAll = (float) WalletTransaction::where('type', 'credit')->where('reference_type', 'order')->sum('amount');
        $totalWithdrawnAll = (float) WalletTransaction::where('type', 'debit')->where('reference_type', 'withdraw')->sum('amount');

        return renderView('admin/wallets/Index', [
            'users' => $users,
            'filters' => [
                'search' => $search,
            ],
            'stats' => [
                'total_balance' => $totalBalanceAll,
                'total_earned' => $totalEarnedAll,
                'total_withdrawn' => $totalWithdrawnAll,
            ],
        ]);
    }

    public function adjust(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'type' => 'required|in:credit,debit',
            'amount' => 'required|numeric|min:1',
            'note' => 'required|string|max:500',
        ]);

        $userId = $request->input('user_id');
        $type = $request->input('type');
        $amount = round((float) $request->input('amount'), 2);
        $note = $request->input('note');
        $adminId = Auth::id();

        try {
            DB::beginTransaction();

            $wallet = $this->walletService->getOrCreateWalletForUser($userId);
            $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

            if ($type === 'debit') {
                if ((float) $lockedWallet->balance < $amount) {
                    DB::rollBack();

                    return redirect()->back()->with('status', [
                        'flag' => Constants::danger,
                        'msg' => "Insufficient wallet balance ({$lockedWallet->balance} DZD) for debit of {$amount} DZD.",
                    ]);
                }
                $newBalance = round((float) $lockedWallet->balance - $amount, 2);
            } else {
                $newBalance = round((float) $lockedWallet->balance + $amount, 2);
            }

            $lockedWallet->balance = $newBalance;
            $lockedWallet->save();

            WalletTransaction::create([
                'wallet_id' => $lockedWallet->id,
                'user_id' => $userId,
                'type' => $type,
                'amount' => $amount,
                'balance_after' => $newBalance,
                'reference_type' => 'manual',
                'reference_id' => (string) $adminId,
                'note' => "Admin manual {$type}: {$note}",
                'added_user_id' => $adminId,
            ]);

            DB::commit();

            return redirect()->back()->with('status', [
                'flag' => Constants::success,
                'msg' => "Wallet successfully updated ({$type}ed {$amount} DZD). New balance: {$newBalance} DZD.",
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();

            return redirect()->back()->with('status', [
                'flag' => Constants::danger,
                'msg' => $e->getMessage(),
            ]);
        }
    }

    public function history(Request $request, $userId)
    {
        $user = User::with(['wallet', 'vendor'])->findOrFail($userId);

        $typeFilter = $request->input('type', 'all');

        $query = WalletTransaction::where('user_id', $userId)->latest('id');

        if ($typeFilter === 'credit') {
            $query->where('type', 'credit');
        } elseif ($typeFilter === 'debit') {
            $query->where('type', 'debit');
        }

        $transactions = $query->paginate(20)->withQueryString();

        $wallet = $user->wallet;
        $balance = $wallet ? (float) $wallet->balance : 0.0;
        $totalCredited = (float) WalletTransaction::where('user_id', $userId)->where('type', 'credit')->sum('amount');
        $totalDebited = (float) WalletTransaction::where('user_id', $userId)->where('type', 'debit')->sum('amount');

        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->user_phone ?? 'N/A',
            'vendor_name' => $user->vendor?->name ?? 'Personal Account',
            'wallet_balance' => $balance,
            'balance' => $balance,
            'currency' => $wallet ? $wallet->currency_code : 'DZD',
            'total_credited' => $totalCredited,
            'total_debited' => $totalDebited,
        ];

        return renderView('admin/wallets/History', [
            'user' => $userData,
            'targetUser' => $userData,
            'transactions' => $transactions,
            'filters' => [
                'type' => $typeFilter,
            ],
        ]);
    }
}
