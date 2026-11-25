<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\PsController;
use App\Models\Coupon;
use App\Models\CouponUsage;
use App\Models\User;
use App\Services\CouponService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AdminCouponController extends PsController
{
    public function __construct(protected CouponService $couponService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $query = Coupon::withCount('usages')->orderByDesc('id');

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where('code', 'like', "%{$search}%");
        }

        if ($request->filled('source') && in_array($request->input('source'), ['admin', 'roulette'], true)) {
            $query->where('source', $request->input('source'));
        }

        if ($request->filled('status')) {
            if ($request->input('status') === 'active') {
                $query->where('is_active', true);
            } elseif ($request->input('status') === 'inactive') {
                $query->where('is_active', false);
            }
        }

        $coupons = $query->paginate(20)->withQueryString();

        $stats = [
            'total' => Coupon::count(),
            'active' => Coupon::where('is_active', true)->count(),
            'total_usages' => CouponUsage::count(),
            'roulette' => Coupon::where('source', 'roulette')->count(),
        ];

        $users = User::select('id', 'name', 'email')
            ->orderBy('name')
            ->limit(500)
            ->get();

        return renderView('admin/coupons/Index', [
            'coupons' => $coupons,
            'users' => $users,
            'filters' => [
                'search' => $request->input('search', ''),
                'source' => $request->input('source', 'all'),
                'status' => $request->input('status', 'all'),
            ],
            'stats' => $stats,
        ]);
    }

    public function generateCode()
    {
        return response()->json([
            'code' => $this->couponService->generateUniqueCode('DRESSY'),
        ]);
    }

    public function store(Request $request)
    {
        $request->merge([
            'code' => strtoupper(trim((string) $request->input('code'))),
        ]);

        $validated = $request->validate([
            'code' => 'required|string|max:64|unique:psx_coupons,code',
            'discount_type' => 'required|in:percentage,fixed_amount',
            'discount_value' => 'required|numeric|min:0.01',
            'min_order_amount' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'max_uses_per_user' => 'nullable|integer|min:1',
            'target_type' => 'nullable|in:none,user,group',
            'user_id' => 'nullable|integer|exists:users,id',
            'target_group' => 'nullable|in:all,buyers,vendors,selected',
            'target_user_ids' => 'nullable|array',
            'target_user_ids.*' => 'integer|exists:users,id',
            'expires_at' => 'nullable|date',
            'is_active' => 'nullable|boolean',
        ]);

        $targetType = $validated['target_type'] ?? 'none';
        $targetUserId = $targetType === 'user' ? ($validated['user_id'] ?? null) : null;
        $targetGroup = $targetType === 'group' ? ($validated['target_group'] ?? 'all') : null;
        $targetUserIds = ($targetType === 'group' && $targetGroup === 'selected')
            ? array_values(array_unique(array_map('intval', $validated['target_user_ids'] ?? [])))
            : null;

        Coupon::create([
            'code' => strtoupper(trim($validated['code'])),
            'discount_type' => $validated['discount_type'],
            'discount_value' => (float) $validated['discount_value'],
            'min_order_amount' => $validated['min_order_amount'] !== null && $validated['min_order_amount'] !== '' ? (float) $validated['min_order_amount'] : null,
            'max_uses' => $validated['max_uses'] ?: null,
            'max_uses_per_user' => $validated['max_uses_per_user'] ?: 1,
            'user_id' => $targetUserId,
            'target_type' => $targetType,
            'target_group' => $targetGroup,
            'target_user_ids' => $targetUserIds,
            'source' => 'admin',
            'is_active' => $request->boolean('is_active', true),
            'expires_at' => !empty($validated['expires_at']) ? Carbon::parse($validated['expires_at']) : null,
        ]);

        return redirect()->route('admin.coupons.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Coupon créé avec succès !',
        ]);
    }

    public function update(Request $request, int $id)
    {
        $coupon = Coupon::findOrFail($id);

        $validated = $request->validate([
            'code' => 'required|string|max:64|unique:psx_coupons,code,' . $coupon->id,
            'discount_type' => 'required|in:percentage,fixed_amount',
            'discount_value' => 'required|numeric|min:0.01',
            'min_order_amount' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'max_uses_per_user' => 'nullable|integer|min:1',
            'target_type' => 'nullable|in:none,user,group',
            'user_id' => 'nullable|integer|exists:users,id',
            'target_group' => 'nullable|in:all,buyers,vendors,selected',
            'target_user_ids' => 'nullable|array',
            'target_user_ids.*' => 'integer|exists:users,id',
            'expires_at' => 'nullable|date',
            'is_active' => 'nullable|boolean',
        ]);

        $targetType = $validated['target_type'] ?? ($coupon->target_type ?? 'none');
        $targetUserId = $targetType === 'user' ? ($validated['user_id'] ?? null) : null;
        $targetGroup = $targetType === 'group' ? ($validated['target_group'] ?? 'all') : null;
        $targetUserIds = ($targetType === 'group' && $targetGroup === 'selected')
            ? array_values(array_unique(array_map('intval', $validated['target_user_ids'] ?? [])))
            : null;

        $coupon->update([
            'code' => strtoupper(trim($validated['code'])),
            'discount_type' => $validated['discount_type'],
            'discount_value' => (float) $validated['discount_value'],
            'min_order_amount' => $validated['min_order_amount'] !== null && $validated['min_order_amount'] !== '' ? (float) $validated['min_order_amount'] : null,
            'max_uses' => $validated['max_uses'] ?: null,
            'max_uses_per_user' => $validated['max_uses_per_user'] ?: 1,
            'user_id' => $targetUserId,
            'target_type' => $targetType,
            'target_group' => $targetGroup,
            'target_user_ids' => $targetUserIds,
            'is_active' => $request->boolean('is_active', false),
            'expires_at' => !empty($validated['expires_at']) ? Carbon::parse($validated['expires_at']) : null,
        ]);

        return redirect()->route('admin.coupons.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Coupon mis à jour avec succès !',
        ]);
    }

    public function toggle(int $id)
    {
        $coupon = Coupon::findOrFail($id);
        $coupon->is_active = !$coupon->is_active;
        $coupon->save();

        return redirect()->route('admin.coupons.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Statut du coupon mis à jour.',
        ]);
    }

    public function destroy(int $id)
    {
        $coupon = Coupon::findOrFail($id);
        $coupon->delete();

        return redirect()->route('admin.coupons.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Coupon supprimé avec succès.',
        ]);
    }
}
