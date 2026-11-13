<template>
    <Head :title="$t('dressy_escrow_module') || 'COD Escrow / Mark Paid'" />
    <ps-layout>
        <!-- Breadcrumb -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_escrow_title') || 'Dressy C2C Escrow & COD Settlement' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Manage buyer COD delivery escrow, Yalidine tracking, and credit seller wallets after platform collection.
                </p>
            </div>
            <div class="flex items-center gap-2">
                <span class="px-3 py-1 bg-indigo-100 text-indigo-800 dark:bg-indigo-900/40 dark:text-indigo-300 rounded-full text-xs font-semibold">
                    Platform Commission: {{ commission_percent }}%
                </span>
            </div>
        </div>

        <!-- Alert messages -->
        <ps-banner-icon v-if="$page.props.errors && Object.keys($page.props.errors).length > 0"
            theme="bg-red-500" iconName="close-circle" class="text-white mb-5">
            <div v-for="(err, key) in $page.props.errors" :key="key">{{ err }}</div>
        </ps-banner-icon>

        <ps-banner-icon v-if="$page.props.status"
            theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ $page.props.status }}
        </ps-banner-icon>

        <!-- Stats Overview Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Total Orders</div>
                        <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total_orders }}</div>
                    </div>
                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-xl">
                        <ps-icon name="box" w="24" h="24" />
                    </div>
                </div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">Pending Settlement</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ formatCurrency(stats.pending_escrow_amount) }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">{{ stats.unpaid_orders_count }} orders waiting to be marked paid</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Paid to Sellers</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ formatCurrency(stats.paid_sellers_amount) }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">{{ stats.paid_orders_count }} orders settled in seller wallets</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-purple-500 dark:text-purple-400">Platform Commission</div>
                        <div class="text-2xl font-bold text-purple-600 dark:text-purple-400 mt-1">{{ formatCurrency(stats.platform_commission_amount) }}</div>
                    </div>
                    <div class="p-3 bg-purple-50 dark:bg-purple-900/20 text-purple-600 rounded-xl">
                        <ps-icon name="chart-line" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Earned from settled C2C sales</div>
            </div>
        </div>

        <!-- Filter & Search Toolbar -->
        <div class="bg-white dark:bg-secondary-800 p-4 rounded-xl border border-gray-100 dark:border-secondary-700 mb-6 flex flex-col md:flex-row items-center justify-between gap-4">
            <!-- Status Tabs -->
            <div class="flex items-center gap-2 w-full md:w-auto">
                <button @click="applyStatusFilter('all')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'all' ? 'bg-primary-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    All Orders
                </button>
                <button @click="applyStatusFilter('unpaid')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'unpaid' ? 'bg-amber-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    Unpaid (COD Pending)
                </button>
                <button @click="applyStatusFilter('paid')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'paid' ? 'bg-emerald-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    Paid / Credited
                </button>
            </div>

            <!-- Search input -->
            <div class="w-full md:w-80">
                <div class="relative">
                    <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                        placeholder="Search order code, seller, buyer, tracking..."
                        class="w-full pl-10 pr-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                        <ps-icon name="search" w="18" h="18" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Orders Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="bg-gray-50 dark:bg-secondary-900/50 text-xs uppercase font-semibold text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="py-3 px-4">Order Code / Date</th>
                            <th class="py-3 px-4">Buyer Info</th>
                            <th class="py-3 px-4">Seller / Store</th>
                            <th class="py-3 px-4">Yalidine Tracking</th>
                            <th class="py-3 px-4 text-right">Order Subtotal</th>
                            <th class="py-3 px-4 text-right">Comm. ({{ commission_percent }}%)</th>
                            <th class="py-3 px-4 text-right font-bold text-secondary-800 dark:text-white">Net Seller Payout</th>
                            <th class="py-3 px-4 text-center">Escrow Status</th>
                            <th class="py-3 px-4 text-center">Action</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-for="order in orders.data" :key="order.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-750 transition-colors">
                            <td class="py-3 px-4 font-mono font-medium text-secondary-800 dark:text-white">
                                <div>{{ order.order_code || '#' + order.id }}</div>
                                <div class="text-xs text-secondary-400">{{ formatDate(order.created_at) }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-secondary-800 dark:text-white">{{ order.buyer_name }}</div>
                                <div class="text-xs text-secondary-400">{{ order.buyer_phone || 'No phone' }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-primary-600 dark:text-primary-400">{{ order.seller_name }}</div>
                                <div class="text-xs text-secondary-400">Store: {{ order.vendor_name }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div v-if="order.yalidine_tracking" class="flex flex-col gap-1">
                                    <span class="inline-flex items-center gap-1 font-mono text-xs px-2 py-0.5 rounded bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300">
                                        {{ order.yalidine_tracking }}
                                    </span>
                                    <span class="text-xs text-secondary-400 capitalize">
                                        Status: {{ order.yalidine_status || 'dispatched' }}
                                    </span>
                                </div>
                                <span v-else class="text-xs text-secondary-400 italic">No tracking yet</span>
                            </td>
                            <td class="py-3 px-4 text-right font-medium text-secondary-800 dark:text-white">
                                {{ formatCurrency(order.order_sub_total) }}
                            </td>
                            <td class="py-3 px-4 text-right text-purple-600 dark:text-purple-400 font-medium">
                                -{{ formatCurrency(order.commission_amount) }}
                            </td>
                            <td class="py-3 px-4 text-right font-bold text-emerald-600 dark:text-emerald-400">
                                {{ formatCurrency(order.seller_payout) }}
                            </td>
                            <td class="py-3 px-4 text-center">
                                <span v-if="order.is_wallet_credited == 1"
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300">
                                    <ps-icon name="check" w="12" h="12" />
                                    Paid & Credited
                                </span>
                                <span v-else
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
                                    Unpaid (Escrow)
                                </span>
                            </td>
                            <td class="py-3 px-4 text-center">
                                <button v-if="order.is_wallet_credited != 1"
                                    @click="openMarkPaidModal(order)"
                                    class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-sm transition-colors flex items-center gap-1 mx-auto">
                                    <ps-icon name="cash" w="14" h="14" />
                                    Mark Paid & Credit
                                </button>
                                <span v-else class="text-xs text-secondary-400">
                                    Settled on {{ formatDate(order.wallet_credited_at) }}
                                </span>
                            </td>
                        </tr>
                        <tr v-if="orders.data.length === 0">
                            <td colspan="9" class="py-8 text-center text-secondary-400">
                                No escrow orders found matching criteria.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="p-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between text-xs text-secondary-500">
                <div>
                    Showing {{ orders.from || 0 }} to {{ orders.to || 0 }} of {{ orders.total }} orders
                </div>
                <div class="flex items-center gap-1" v-if="orders.links && orders.links.length > 3">
                    <template v-for="(link, i) in orders.links" :key="i">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1 rounded border border-gray-200 dark:border-secondary-700 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                            :class="{ 'bg-primary-500 text-white font-semibold border-primary-500': link.active }"
                            v-html="link.label" />
                        <span v-else class="px-2 py-1 text-gray-300 dark:text-secondary-600" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>

        <!-- Mark Paid Confirmation Modal -->
        <jet-dialog-modal :show="showMarkPaidModal" @close="showMarkPaidModal = false">
            <template #title>
                <div class="flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
                    <ps-icon name="checkCircle" w="22" h="22" />
                    Confirm COD Escrow Payout to Seller
                </div>
            </template>

            <template #content>
                <div v-if="selectedOrder" class="space-y-4">
                    <p class="text-sm text-secondary-600 dark:text-secondary-300">
                        You are about to settle the Cash On Delivery payout for order <strong>{{ selectedOrder.order_code || '#' + selectedOrder.id }}</strong>.
                    </p>

                    <div class="p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl space-y-2 text-sm border border-gray-200 dark:border-secondary-700">
                        <div class="flex justify-between">
                            <span class="text-secondary-500">Seller / Vendor:</span>
                            <span class="font-medium text-secondary-800 dark:text-white">{{ selectedOrder.seller_name }} ({{ selectedOrder.vendor_name }})</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-secondary-500">Collected Order Subtotal:</span>
                            <span class="font-semibold text-secondary-800 dark:text-white">{{ formatCurrency(selectedOrder.order_sub_total) }}</span>
                        </div>
                        <div class="flex justify-between text-purple-600 dark:text-purple-400">
                            <span>Platform Commission ({{ commission_percent }}%):</span>
                            <span>-{{ formatCurrency(selectedOrder.commission_amount) }}</span>
                        </div>
                        <div class="flex justify-between pt-2 border-t border-gray-200 dark:border-secondary-700 font-bold text-base text-emerald-600 dark:text-emerald-400">
                            <span>Net Wallet Credit to Seller:</span>
                            <span>{{ formatCurrency(selectedOrder.seller_payout) }}</span>
                        </div>
                    </div>

                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-300 text-xs rounded-lg">
                        <strong>Protection Check:</strong> This action is idempotent and protected against double-crediting. Once completed, {{ formatCurrency(selectedOrder.seller_payout) }} will be added to the seller's active wallet balance and an immutable ledger transaction will be recorded.
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex justify-end gap-3">
                    <button @click="showMarkPaidModal = false"
                        class="px-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 text-sm font-medium text-secondary-700 dark:text-secondary-200 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors">
                        Cancel
                    </button>
                    <button @click="submitMarkPaid" :disabled="submitting"
                        class="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-sm font-bold shadow-md transition-colors disabled:opacity-50 flex items-center gap-2">
                        <ps-icon v-if="!submitting" name="check" w="16" h="16" />
                        <span v-if="submitting">Crediting Wallet...</span>
                        <span v-else>Confirm & Credit Wallet</span>
                    </button>
                </div>
            </template>
        </jet-dialog-modal>
    </ps-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import PsLayout from "@/Components/PsLayout.vue";
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsBannerIcon from "@/Components/Core/Banners/PsBannerIcon.vue";
import JetDialogModal from '@/Jetstream/DialogModal.vue';

export default defineComponent({
    name: "AdminEscrowIndex",
    components: {
        Head,
        Link,
        PsLayout,
        PsLabel,
        PsIcon,
        PsBannerIcon,
        JetDialogModal,
    },
    layout: PsLayout,
    props: {
        orders: Object,
        filters: Object,
        stats: Object,
        commission_percent: [Number, String],
    },
    setup(props) {
        const searchQuery = ref(props.filters.search || '');
        const showMarkPaidModal = ref(false);
        const selectedOrder = ref(null);
        const submitting = ref(false);

        const formatCurrency = (val) => {
            const num = parseFloat(val) || 0;
            return num.toLocaleString('fr-DZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' DZD';
        };

        const formatDate = (dateStr) => {
            if (!dateStr) return '';
            const d = new Date(dateStr);
            return d.toLocaleDateString('fr-DZ', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        };

        const applyStatusFilter = (status) => {
            router.get(route('admin.escrow.index'), {
                status: status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const handleSearch = () => {
            router.get(route('admin.escrow.index'), {
                status: props.filters.status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const openMarkPaidModal = (order) => {
            selectedOrder.value = order;
            showMarkPaidModal.value = true;
        };

        const submitMarkPaid = () => {
            if (!selectedOrder.value || submitting.value) return;
            submitting.value = true;
            router.post(route('admin.escrow.markPaid', selectedOrder.value.id), {}, {
                onSuccess: () => {
                    showMarkPaidModal.value = false;
                    selectedOrder.value = null;
                },
                onFinish: () => {
                    submitting.value = false;
                }
            });
        };

        return {
            searchQuery,
            showMarkPaidModal,
            selectedOrder,
            submitting,
            formatCurrency,
            formatDate,
            applyStatusFilter,
            handleSearch,
            openMarkPaidModal,
            submitMarkPaid,
        };
    }
});
</script>
