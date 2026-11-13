<template>
    <Head :title="`Wallet History - ${user.name}`" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <div class="flex items-center gap-2 text-sm text-secondary-500 mb-1">
                    <Link :href="route('admin.wallets.index')" class="hover:text-primary-600 transition-colors flex items-center gap-1">
                        &larr; Back to Seller Wallets
                    </Link>
                </div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    Ledger History: {{ user.name }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Complete immutable chronological audit log for User #{{ user.id }} &bull; {{ user.email }}
                </p>
            </div>
            <div>
                <Link :href="route('admin.wallets.index')"
                    class="px-4 py-2 bg-gray-100 dark:bg-secondary-700 hover:bg-gray-200 text-secondary-700 dark:text-secondary-300 rounded-lg text-sm font-medium transition-colors">
                    Back to Wallets
                </Link>
            </div>
        </div>

        <!-- Account Summary Card -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-primary-100 dark:bg-primary-900/40 text-primary-600 dark:text-primary-400 flex items-center justify-center font-bold text-lg">
                    {{ user.name.charAt(0).toUpperCase() }}
                </div>
                <div>
                    <div class="text-base font-bold text-secondary-800 dark:text-white">{{ user.name }}</div>
                    <div class="text-xs text-secondary-500">
                        Store: <span class="font-medium text-primary-600 dark:text-primary-400">{{ user.vendor_name || 'Personal Account' }}</span>
                        &bull; Contact: {{ user.phone || user.email }}
                    </div>
                </div>
            </div>
            <div class="text-right">
                <div class="text-xs uppercase font-medium text-secondary-500">Current Balance</div>
                <div class="text-2xl font-black text-primary-600 dark:text-primary-400">
                    {{ formatCurrency(user.wallet_balance) }}
                </div>
            </div>
        </div>

        <!-- Ledger Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="bg-gray-50 dark:bg-secondary-900/50 text-xs uppercase font-semibold text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="py-3 px-4">Tx ID / Date</th>
                            <th class="py-3 px-4">Type</th>
                            <th class="py-3 px-4 text-right">Amount</th>
                            <th class="py-3 px-4 text-right font-bold text-secondary-800 dark:text-white">Balance After</th>
                            <th class="py-3 px-4">Reference</th>
                            <th class="py-3 px-4">Audited Note / Details</th>
                            <th class="py-3 px-4 text-center">Author ID</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-for="tx in transactions.data" :key="tx.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-750 transition-colors">
                            <td class="py-3 px-4 font-mono text-xs">
                                <div class="font-bold text-secondary-800 dark:text-white">#{{ tx.id }}</div>
                                <div class="text-secondary-400">{{ formatDate(tx.created_at) }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <span v-if="tx.type === 'credit'"
                                    class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300">
                                    + Credit
                                </span>
                                <span v-else
                                    class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300">
                                    - Debit
                                </span>
                            </td>
                            <td class="py-3 px-4 text-right font-bold"
                                :class="tx.type === 'credit' ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'">
                                {{ tx.type === 'credit' ? '+' : '-' }}{{ formatCurrency(tx.amount) }}
                            </td>
                            <td class="py-3 px-4 text-right font-bold text-secondary-800 dark:text-white">
                                {{ formatCurrency(tx.balance_after) }}
                            </td>
                            <td class="py-3 px-4 font-mono text-xs">
                                <span v-if="tx.reference_type" class="px-2 py-0.5 rounded bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 capitalize">
                                    {{ tx.reference_type }}: {{ tx.reference_id || 'N/A' }}
                                </span>
                                <span v-else class="text-secondary-400">Manual</span>
                            </td>
                            <td class="py-3 px-4 text-xs text-secondary-700 dark:text-secondary-300">
                                {{ tx.note || 'No note provided' }}
                            </td>
                            <td class="py-3 px-4 text-center text-xs font-mono text-secondary-400">
                                {{ tx.added_user_id ? 'Admin #' + tx.added_user_id : 'System' }}
                            </td>
                        </tr>
                        <tr v-if="transactions.data.length === 0">
                            <td colspan="7" class="py-8 text-center text-secondary-400">
                                No ledger transactions found for this user.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="p-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between text-xs text-secondary-500">
                <div>
                    Showing {{ transactions.from || 0 }} to {{ transactions.to || 0 }} of {{ transactions.total }} transactions
                </div>
                <div class="flex items-center gap-1" v-if="transactions.links && transactions.links.length > 3">
                    <template v-for="(link, i) in transactions.links" :key="i">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1 rounded border border-gray-200 dark:border-secondary-700 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                            :class="{ 'bg-primary-500 text-white font-semibold border-primary-500': link.active }"
                            v-html="link.label" />
                        <span v-else class="px-2 py-1 text-gray-300 dark:text-secondary-600" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>
    </ps-layout>
</template>

<script>
import { defineComponent } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import PsLayout from "@/Components/PsLayout.vue";
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";

export default defineComponent({
    name: "AdminWalletHistory",
    components: {
        Head,
        Link,
        PsLayout,
        PsLabel,
        PsIcon,
    },
    layout: PsLayout,
    props: {
        user: Object,
        transactions: Object,
    },
    setup() {
        const formatCurrency = (val) => {
            const num = parseFloat(val) || 0;
            return num.toLocaleString('fr-DZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' DZD';
        };

        const formatDate = (dateStr) => {
            if (!dateStr) return '';
            const d = new Date(dateStr);
            return d.toLocaleDateString('fr-DZ', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        };

        return {
            formatCurrency,
            formatDate,
        };
    }
});
</script>
