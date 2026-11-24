<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dressy Admin — Coupons Management</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 min-h-screen">
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div>
            <h1 class="text-2xl font-bold text-gray-900">Coupons Management</h1>
            <p class="text-sm text-gray-500">Create, edit, enable/disable, and track real promo &amp; 24h roulette coupons.</p>
        </div>
        <a href="{{ url('/admin') }}" class="px-4 py-2 rounded-lg bg-white border border-gray-300 text-sm font-medium hover:bg-gray-100">
            ← Back to Dashboard
        </a>
    </div>

    @if(session('success'))
        <div class="mb-4 rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-800">
            {{ session('success') }}
        </div>
    @endif

    @if($errors->any())
        <div class="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-800">
            <ul class="list-disc pl-5">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <!-- Create Coupon Card -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8">
        <h2 class="text-lg font-semibold mb-4">Create New Coupon</h2>
        <form action="{{ route('admin.coupons.store') }}" method="POST" class="grid grid-cols-1 md:grid-cols-4 gap-4">
            @csrf
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Coupon Code *</label>
                <div class="flex gap-2">
                    <input type="text" name="code" id="new_coupon_code" required placeholder="DRESSY10"
                           class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm uppercase">
                    <button type="button" onclick="generateCouponCode()"
                            class="px-3 py-2 rounded-lg bg-gray-800 text-white text-xs font-medium whitespace-nowrap hover:bg-gray-900">
                        Generate
                    </button>
                </div>
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Discount Type *</label>
                <select name="discount_type" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                    <option value="percentage">Percentage (%)</option>
                    <option value="fixed_amount">Fixed Amount (DA)</option>
                </select>
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Discount Value *</label>
                <input type="number" step="0.01" min="0.01" name="discount_value" required placeholder="10"
                       class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Min Order Amount (DA)</label>
                <input type="number" step="0.01" min="0" name="min_order_amount" placeholder="Optional"
                       class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Max Total Uses</label>
                <input type="number" min="1" name="max_uses" placeholder="Unlimited"
                       class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Max Uses Per User</label>
                <input type="number" min="1" name="max_uses_per_user" value="1"
                       class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            </div>
            <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Expires At</label>
                <input type="datetime-local" name="expires_at"
                       class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            </div>
            <div class="flex items-end gap-3">
                <label class="flex items-center gap-2 text-sm">
                    <input type="checkbox" name="is_active" value="1" checked class="rounded border-gray-300">
                    Active
                </label>
                <button type="submit" class="ml-auto px-5 py-2 rounded-lg bg-[#ED7768] text-white text-sm font-semibold hover:opacity-90">
                    Create Coupon
                </button>
            </div>
        </form>
    </div>

    <!-- Filter -->
    <form method="GET" class="flex flex-wrap gap-3 mb-4">
        <input type="text" name="search" value="{{ $search }}" placeholder="Search code..."
               class="rounded-lg border border-gray-300 px-3 py-2 text-sm bg-white">
        <select name="source" class="rounded-lg border border-gray-300 px-3 py-2 text-sm bg-white">
            <option value="">All Sources</option>
            <option value="admin" {{ $sourceFilter === 'admin' ? 'selected' : '' }}>Admin</option>
            <option value="roulette" {{ $sourceFilter === 'roulette' ? 'selected' : '' }}>24h Spin Roulette</option>
        </select>
        <button type="submit" class="px-4 py-2 rounded-lg bg-gray-800 text-white text-sm font-medium">Filter</button>
    </form>

    <!-- Coupons Table -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
                <th class="px-4 py-3 text-left">Code</th>
                <th class="px-4 py-3 text-left">Discount</th>
                <th class="px-4 py-3 text-left">Min Order</th>
                <th class="px-4 py-3 text-left">Usage</th>
                <th class="px-4 py-3 text-left">Source</th>
                <th class="px-4 py-3 text-left">Expires</th>
                <th class="px-4 py-3 text-left">Status</th>
                <th class="px-4 py-3 text-right">Actions</th>
            </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
            @forelse($coupons as $coupon)
                <tr>
                    <td class="px-4 py-3 font-mono font-bold">{{ $coupon->code }}</td>
                    <td class="px-4 py-3">
                        {{ $coupon->discount_type === 'percentage' ? $coupon->discount_value . '%' : number_format($coupon->discount_value, 0) . ' DA' }}
                    </td>
                    <td class="px-4 py-3">{{ $coupon->min_order_amount ? number_format($coupon->min_order_amount, 0) . ' DA' : '—' }}</td>
                    <td class="px-4 py-3">{{ $coupon->used_count }} / {{ $coupon->max_uses ?? '∞' }}</td>
                    <td class="px-4 py-3">
                        <span class="px-2 py-0.5 rounded-full text-xs {{ $coupon->source === 'roulette' ? 'bg-amber-100 text-amber-800' : 'bg-blue-100 text-blue-800' }}">
                            {{ $coupon->source }}
                        </span>
                    </td>
                    <td class="px-4 py-3">{{ $coupon->expires_at ? $coupon->expires_at->format('Y-m-d H:i') : 'Never' }}</td>
                    <td class="px-4 py-3">
                        <span class="px-2 py-0.5 rounded-full text-xs {{ $coupon->is_active ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700' }}">
                            {{ $coupon->is_active ? 'Active' : 'Disabled' }}
                        </span>
                    </td>
                    <td class="px-4 py-3 text-right space-x-2">
                        <form action="{{ route('admin.coupons.toggle', $coupon->id) }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" class="px-2.5 py-1 rounded border text-xs hover:bg-gray-100">
                                {{ $coupon->is_active ? 'Disable' : 'Enable' }}
                            </button>
                        </form>
                        <form action="{{ route('admin.coupons.destroy', $coupon->id) }}" method="POST" class="inline"
                              onsubmit="return confirm('Delete coupon {{ $coupon->code }}?')">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="px-2.5 py-1 rounded bg-red-50 text-red-700 border border-red-200 text-xs hover:bg-red-100">
                                Delete
                            </button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="8" class="px-4 py-8 text-center text-gray-500">No coupons found.</td>
                </tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="mt-4">{{ $coupons->links() }}</div>
</div>

<script>
async function generateCouponCode() {
    const res = await fetch("{{ route('admin.coupons.generateCode') }}");
    const data = await res.json();
    if (data.code) {
        document.getElementById('new_coupon_code').value = data.code;
    }
}
</script>
</body>
</html>
