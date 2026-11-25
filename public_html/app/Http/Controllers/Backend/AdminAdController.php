<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\PsController;
use App\Models\AdBoost;
use App\Models\AdPlan;
use App\Models\AdSetting;
use App\Services\AdBoostService;
use Illuminate\Http\Request;

class AdminAdController extends PsController
{
    public function __construct(protected AdBoostService $adBoostService)
    {
        parent::__construct();
    }

    public function index()
    {
        $settings = $this->adBoostService->getSettings();
        $plans = AdPlan::orderBy('sort_order')->get();
        $boosts = AdBoost::with(['user:id,name,email', 'vendor:id,name'])
            ->orderByDesc('id')
            ->paginate(20);

        $stats = [
            'total_boosts' => AdBoost::count(),
            'active_boosts' => AdBoost::where('expires_at', '>', now())->count(),
            'total_revenue_dzd' => (float) AdBoost::sum('amount_paid_dzd'),
        ];

        return renderView('admin/ads/Index', [
            'settings' => $settings,
            'plans' => $plans,
            'boosts' => $boosts,
            'stats' => $stats,
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'is_enabled' => 'nullable|boolean',
            'story_boost_enabled' => 'nullable|boolean',
            'story_boost_price_dzd' => 'required|numeric|min:0',
            'story_boost_title' => 'required|string|max:160',
            'story_boost_description' => 'nullable|string|max:1000',
        ]);

        $settings = $this->adBoostService->getSettings();
        $settings->update([
            'is_enabled' => $request->boolean('is_enabled', false),
            'story_boost_enabled' => $request->boolean('story_boost_enabled', false),
            'story_boost_price_dzd' => (float) $validated['story_boost_price_dzd'],
            'story_boost_title' => trim($validated['story_boost_title']),
            'story_boost_description' => trim((string) ($validated['story_boost_description'] ?? '')),
        ]);

        return redirect()->route('admin.ads.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Paramètres Publicité & Story Boost mis à jour.',
        ]);
    }

    public function updatePlan(Request $request, int $id)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:160',
            'description' => 'nullable|string|max:1000',
            'price_dzd' => 'required|numeric|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        $plan = AdPlan::findOrFail($id);
        $plan->update([
            'title' => trim($validated['title']),
            'description' => trim((string) ($validated['description'] ?? '')),
            'price_dzd' => (float) $validated['price_dzd'],
            'is_active' => $request->boolean('is_active', false),
        ]);

        return redirect()->route('admin.ads.index')->with('status', [
            'flag' => 'success',
            'msg' => "Formule {$plan->title} mise à jour.",
        ]);
    }

    public function togglePlan(int $id)
    {
        $plan = AdPlan::findOrFail($id);
        $plan->is_active = !$plan->is_active;
        $plan->save();

        return redirect()->route('admin.ads.index')->with('status', [
            'flag' => 'success',
            'msg' => "Statut de la formule {$plan->title} mis à jour.",
        ]);
    }
}
