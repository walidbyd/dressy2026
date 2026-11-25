<?php

namespace App\Http\Controllers\Backend;

use App\Http\Controllers\PsController;
use App\Models\OrderDispute;
use App\Services\DisputeService;
use Illuminate\Http\Request;
use Modules\Core\Entities\Notification\ChatHistory;

class AdminDisputeController extends PsController
{
    public function __construct(protected DisputeService $disputeService)
    {
        parent::__construct();
    }

    public function index(Request $request)
    {
        $query = OrderDispute::with([
            'buyer:id,name,email,user_phone',
            'seller:id,name,email,user_phone',
            'vendor:id,name',
            'order:id,order_code,total_price,order_status_id,yalidine_parcel_status',
        ])->orderByDesc('id');

        if ($request->filled('status') && $request->input('status') !== 'all') {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('search')) {
            $s = trim((string) $request->input('search'));
            $query->where(function ($q) use ($s) {
                $q->where('order_code', 'like', "%{$s}%")
                  ->orWhere('description', 'like', "%{$s}%");
            });
        }

        $disputes = $query->paginate(20)->withQueryString();

        // Attach latest chat message context per order
        $orderIds = $disputes->getCollection()->pluck('order_id')->filter()->unique()->values()->all();
        $chats = !empty($orderIds)
            ? ChatHistory::whereIn('order_id', $orderIds)->get()->keyBy('order_id')
            : collect();

        $disputes->getCollection()->transform(function ($d) use ($chats) {
            $d->latest_chat_message = $chats->get($d->order_id)?->latest_chat_message ?? null;
            return $d;
        });

        $stats = [
            'total' => OrderDispute::count(),
            'open' => OrderDispute::whereIn('status', ['open', 'under_review'])->count(),
            'resolved' => OrderDispute::whereIn('status', ['resolved_buyer', 'resolved_vendor', 'closed'])->count(),
        ];

        return renderView('admin/disputes/Index', [
            'disputes' => $disputes,
            'stats' => $stats,
            'filters' => [
                'status' => $request->input('status', 'all'),
                'search' => $request->input('search', ''),
            ],
        ]);
    }

    public function updateStatus(Request $request, int $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:open,under_review,resolved_buyer,resolved_vendor,closed',
            'admin_note' => 'nullable|string|max:2000',
        ]);

        $dispute = OrderDispute::with('order')->findOrFail($id);
        $this->disputeService->resolveDispute(
            $dispute,
            $validated['status'],
            $validated['admin_note'] ?? null,
            auth()->id()
        );

        return redirect()->route('admin.disputes.index')->with('status', [
            'flag' => 'success',
            'msg' => "Litige #{$dispute->id} mis à jour avec succès.",
        ]);
    }
}
