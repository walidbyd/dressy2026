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

class AdminWithdrawalController extends PsController
{
    public function __construct(protected WalletService $walletService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');
        $search = $request->input('search', '');

        $query = WithdrawRequest::with(['user.vendor', 'wallet'])->latest('id');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        if (! empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('note', 'like', "%{$search}%")
                    ->orWhere('id', 'like', "%{$search}%")
                    ->orWhereHas('user', function ($uq) use ($search) {
                        $uq->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('user_phone', 'like', "%{$search}%");
                    });
            });
        }

        $withdrawals = $query->paginate(15)->withQueryString();

        $stats = [
            'pending_count' => WithdrawRequest::where('status', 'pending')->count(),
            'pending_amount' => (float) WithdrawRequest::where('status', 'pending')->sum('amount'),
            'approved_amount' => (float) WithdrawRequest::where('status', 'approved')->sum('amount'),
            'rejected_amount' => (float) WithdrawRequest::where('status', 'rejected')->sum('amount'),
        ];

        return renderView('admin/withdrawals/Index', [
            'withdrawals' => $withdrawals,
            'filters' => [
                'status' => $status,
                'search' => $search,
            ],
            'stats' => $stats,
        ]);
    }

    public function approve(Request $request, $id)
    {
        // Enforce Super Admin only
        if (Auth::user()?->role_id != Constants::superAdminRoleId) {
            abort(403, 'Unauthorized. Super Admin access required.');
        }

        $request->validate([
            'admin_reference' => 'nullable|string|max:255',
            'admin_note' => 'nullable|string|max:500',
        ]);

        $withdraw = WithdrawRequest::findOrFail($id);

        if ($withdraw->status !== 'pending') {
            return redirect()->back()->with('error', 'Only pending requests can be approved.');
        }

        try {
            DB::transaction(function () use ($withdraw, $request) {
                // Lock wallet row for update
                $wallet = Wallet::where('user_id', $withdraw->user_id)->lockForUpdate()->first();

                if (! $wallet || $wallet->balance < $withdraw->amount) {
                    $avail = $wallet ? $wallet->balance : 0;
                    throw new \Exception("Seller has insufficient wallet balance ({$avail} DZD) to approve {$withdraw->amount} DZD.");
                }

                $newBalance = (float) $wallet->balance - (float) $withdraw->amount;
                $wallet->balance = $newBalance;
                $wallet->save();

                $adminRef = $request->input('admin_reference', '');
                $adminNote = $request->input('admin_note', '');

                $txNote = 'Withdrawal Approved';
                if (! empty($adminRef)) {
                    $txNote .= " (Ref: {$adminRef})";
                }
                if (! empty($adminNote)) {
                    $txNote .= " - {$adminNote}";
                }

                // Log immutable ledger row
                WalletTransaction::create([
                    'wallet_id' => $wallet->id,
                    'user_id' => $withdraw->user_id,
                    'type' => 'debit',
                    'amount' => $withdraw->amount,
                    'balance_after' => $newBalance,
                    'reference_type' => 'withdraw',
                    'reference_id' => (string) $withdraw->id,
                    'note' => $txNote,
                    'added_user_id' => Auth::id(),
                ]);

                // Update withdraw request
                $withdraw->status = 'approved';
                if (\Illuminate\Support\Facades\Schema::hasColumn('psx_withdraw_requests', 'admin_reference')) {
                    $withdraw->admin_reference = $adminRef;
                }
                if (\Illuminate\Support\Facades\Schema::hasColumn('psx_withdraw_requests', 'admin_note')) {
                    $withdraw->admin_note = $adminNote;
                }
                $withdraw->save();
            });

            return redirect()->back()->with('success', "Withdrawal request #{$withdraw->id} of {$withdraw->amount} DZD approved successfully.");
        } catch (\Throwable $e) {
            return redirect()->back()->with('error', $e->getMessage());
        }
    }

    public function reject(Request $request, $id)
    {
        // Enforce Super Admin only
        if (Auth::user()?->role_id != Constants::superAdminRoleId) {
            abort(403, 'Unauthorized. Super Admin access required.');
        }

        $request->validate([
            'rejection_reason' => 'required|string|max:500',
        ]);

        $withdraw = WithdrawRequest::findOrFail($id);

        if ($withdraw->status !== 'pending') {
            return redirect()->back()->with('error', 'Only pending requests can be rejected.');
        }

        try {
            DB::transaction(function () use ($withdraw, $request) {
                $withdraw->status = 'rejected';
                $reason = $request->input('rejection_reason');
                
                if (\Illuminate\Support\Facades\Schema::hasColumn('psx_withdraw_requests', 'admin_note')) {
                    $withdraw->admin_note = 'Rejected: ' . $reason;
                } else {
                    $withdraw->note = ($withdraw->note ? $withdraw->note . ' | ' : '') . 'Rejected: ' . $reason;
                }
                
                $withdraw->save();
            });

            return redirect()->back()->with('success', "Withdrawal request #{$withdraw->id} has been rejected. Seller wallet balance remains intact.");
        } catch (\Throwable $e) {
            return redirect()->back()->with('error', $e->getMessage());
        }
    }
}
