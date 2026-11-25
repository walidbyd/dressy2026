<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\PsController;
use App\Models\AffiliationCode;
use App\Models\AffiliationReferral;
use App\Services\AffiliationService;
use Illuminate\Http\Request;

class AdminAffiliationController extends PsController
{
    public function __construct(protected AffiliationService $affiliationService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $settings = $this->affiliationService->getSettings();

        $codesQuery = AffiliationCode::with(['issuer:id,name,email', 'referrals.receiver:id,name,email', 'referrals.order:id,order_code,order_status_id,yalidine_parcel_status'])
            ->withCount('referrals')
            ->orderByDesc('id');

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $codesQuery->where(function ($q) use ($search) {
                $q->where('code', 'like', "%{$search}%")
                  ->orWhereHas('issuer', function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%")
                         ->orWhere('email', 'like', "%{$search}%");
                  });
            });
        }

        $codes = $codesQuery->paginate(20)->withQueryString();

        $referrals = AffiliationReferral::with([
            'affiliationCode:id,code,is_active',
            'issuer:id,name,email',
            'receiver:id,name,email',
            'order:id,order_code,order_status_id,yalidine_parcel_status',
        ])->orderByDesc('id')->limit(50)->get();

        $stats = [
            'total_codes' => AffiliationCode::count(),
            'active_codes' => AffiliationCode::where('is_active', true)->count(),
            'total_referrals' => AffiliationReferral::count(),
            'total_credited_dzd' => (float) AffiliationReferral::where('is_credited', true)->sum('issuer_commission_amount'),
        ];

        return renderView('admin/affiliation/Index', [
            'settings' => [
                'issuer_percentage' => (float) $settings->issuer_percentage,
                'receiver_percentage' => (float) $settings->receiver_percentage,
            ],
            'codes' => $codes,
            'referrals' => $referrals,
            'stats' => $stats,
            'filters' => [
                'search' => $request->input('search', ''),
            ],
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'issuer_percentage' => 'required|numeric|min:0|max:50',
            'receiver_percentage' => 'required|numeric|min:0|max:50',
        ]);

        $settings = $this->affiliationService->getSettings();
        $settings->update([
            'issuer_percentage' => (float) $validated['issuer_percentage'],
            'receiver_percentage' => (float) $validated['receiver_percentage'],
        ]);

        return redirect()->route('admin.affiliation.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Paramètres d\'affiliation mis à jour avec succès.',
        ]);
    }

    public function toggleCode(int $id)
    {
        $code = AffiliationCode::findOrFail($id);
        $code->is_active = !$code->is_active;
        $code->save();

        return redirect()->route('admin.affiliation.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Statut du code de parrainage mis à jour.',
        ]);
    }
}
