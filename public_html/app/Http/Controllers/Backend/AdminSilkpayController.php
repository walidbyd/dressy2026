<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\PsController;
use App\Models\SilkpayPack;
use App\Models\SilkpayTransaction;
use App\Services\SilkpayService;
use Illuminate\Http\Request;

class AdminSilkpayController extends PsController
{
    public function __construct(protected SilkpayService $silkpayService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $settings = $this->silkpayService->getSettings();
        $packs = SilkpayPack::orderBy('sort_order')->orderBy('amount_dzd')->get();

        $txQuery = SilkpayTransaction::with(['user:id,name,email,user_phone', 'pack:id,title,amount_dzd'])
            ->orderByDesc('id');

        if ($request->filled('status') && $request->input('status') !== 'all') {
            $txQuery->where('status', $request->input('status'));
        }

        $transactions = $txQuery->paginate(20)->withQueryString();

        $stats = [
            'total' => SilkpayTransaction::count(),
            'credited' => SilkpayTransaction::where('status', 'credited')->count(),
            'pending' => SilkpayTransaction::where('status', 'pending')->count(),
            'total_credited_dzd' => (float) SilkpayTransaction::where('status', 'credited')->sum('amount_dzd'),
        ];

        return renderView('admin/silkpay/Index', [
            'settings' => $settings,
            'packs' => $packs,
            'transactions' => $transactions,
            'stats' => $stats,
            'webhookUrl' => url('/api/v1/wallet/silkpay/webhook'),
            'filters' => [
                'status' => $request->input('status', 'all'),
            ],
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'webhook_secret' => 'nullable|string|max:255',
            'api_key' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
        ]);

        $settings = $this->silkpayService->getSettings();
        $settings->update([
            'webhook_secret' => $validated['webhook_secret'] ?? '',
            'api_key' => $validated['api_key'] ?? '',
            'is_active' => $request->boolean('is_active', true),
        ]);

        return redirect()->route('admin.silkpay.index')->with('status', [
            'flag' => 'success',
            'msg' => 'Configuration Silk Pay mise à jour.',
        ]);
    }

    public function updatePack(Request $request, int $id)
    {
        $validated = $request->validate([
            'amount_dzd' => 'required|numeric|min:100',
            'title' => 'required|string|max:120',
            'payment_url' => 'nullable|string|max:1000',
            'is_active' => 'nullable|boolean',
        ]);

        $pack = SilkpayPack::findOrFail($id);
        $pack->update([
            'amount_dzd' => (float) $validated['amount_dzd'],
            'title' => trim($validated['title']),
            'payment_url' => trim((string) ($validated['payment_url'] ?? '')),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return redirect()->route('admin.silkpay.index')->with('status', [
            'flag' => 'success',
            'msg' => "Pack {$pack->title} mis à jour.",
        ]);
    }

    public function togglePack(int $id)
    {
        $pack = SilkpayPack::findOrFail($id);
        $pack->is_active = !$pack->is_active;
        $pack->save();

        return redirect()->route('admin.silkpay.index')->with('status', [
            'flag' => 'success',
            'msg' => "Statut du pack {$pack->title} mis à jour.",
        ]);
    }

    public function markCredited(int $id)
    {
        $tx = SilkpayTransaction::findOrFail($id);
        $this->silkpayService->creditTransaction($tx, ['manual_admin' => true, 'admin_id' => auth()->id()]);

        return redirect()->route('admin.silkpay.index')->with('status', [
            'flag' => 'success',
            'msg' => "Transaction {$tx->reference} créditée avec succès.",
        ]);
    }

    public function cancelTransaction(int $id)
    {
        $tx = SilkpayTransaction::findOrFail($id);
        $this->silkpayService->cancelTransaction($tx, ['manual_admin_cancel' => true, 'admin_id' => auth()->id()]);

        return redirect()->route('admin.silkpay.index')->with('status', [
            'flag' => 'success',
            'msg' => "Transaction {$tx->reference} annulée.",
        ]);
    }
}
