<template>
    <Head :title="$t('dressy_orders_module') || 'Orders Management'" />
    <ps-layout>
        <!-- Breadcrumb / Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_orders_title') || 'Marketplace Orders Management' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Monitor orders, track Yalidine delivery, manage seller fulfillments, and record return/cancellation reasons.
                </p>
            </div>
            <div class="flex items-center gap-2">
                <span class="px-3 py-1 bg-primary-100 text-primary-800 dark:bg-primary-900/40 dark:text-primary-300 rounded-full text-xs font-semibold">
                    Total Marketplace Orders: {{ stats.total }}
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
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats Overview Cards -->
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-primary-500 transition-colors"
                @click="applyStatusFilter('all')" :class="{ 'ring-2 ring-primary-500': filters.status === 'all' }">
                <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">All Orders</div>
                <div class="text-xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total }}</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-amber-500 transition-colors"
                @click="applyStatusFilter('pending')" :class="{ 'ring-2 ring-amber-500': filters.status === 'pending' }">
                <div class="text-xs uppercase font-medium text-amber-600 dark:text-amber-400">Pending</div>
                <div class="text-xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ stats.pending }}</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-blue-500 transition-colors"
                @click="applyStatusFilter('delivering')" :class="{ 'ring-2 ring-blue-500': filters.status === 'delivering' }">
                <div class="text-xs uppercase font-medium text-blue-600 dark:text-blue-400">Delivering</div>
                <div class="text-xl font-bold text-blue-600 dark:text-blue-400 mt-1">{{ stats.delivering }}</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-emerald-500 transition-colors"
                @click="applyStatusFilter('delivered')" :class="{ 'ring-2 ring-emerald-500': filters.status === 'delivered' }">
                <div class="text-xs uppercase font-medium text-emerald-600 dark:text-emerald-400">Delivered</div>
                <div class="text-xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ stats.delivered }}</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-red-500 transition-colors"
                @click="applyStatusFilter('cancelled')" :class="{ 'ring-2 ring-red-500': filters.status === 'cancelled' }">
                <div class="text-xs uppercase font-medium text-red-600 dark:text-red-400">Cancelled</div>
                <div class="text-xl font-bold text-red-600 dark:text-red-400 mt-1">{{ stats.cancelled }}</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-4 border border-gray-100 dark:border-secondary-700 shadow-sm cursor-pointer hover:border-gray-500 transition-colors"
                @click="applyStatusFilter('returned')" :class="{ 'ring-2 ring-gray-500': filters.status === 'returned' }">
                <div class="text-xs uppercase font-medium text-gray-600 dark:text-gray-400">Returned</div>
                <div class="text-xl font-bold text-gray-600 dark:text-gray-400 mt-1">{{ stats.returned }}</div>
            </div>
        </div>

        <!-- Filter & Search Toolbar -->
        <div class="bg-white dark:bg-secondary-800 p-4 rounded-xl border border-gray-100 dark:border-secondary-700 mb-6 flex flex-col md:flex-row items-center justify-between gap-4">
            <!-- Search input -->
            <div class="flex items-center gap-2 w-full md:w-96">
                <div class="relative w-full">
                    <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                        placeholder="Search by code, tracking, buyer, seller..."
                        class="w-full pl-9 pr-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    <span class="absolute left-3 top-2.5 text-gray-400">
                        <ps-icon name="search" w="16" h="16" />
                    </span>
                </div>
                <button @click="handleSearch" class="px-4 py-2 bg-primary-500 text-white rounded-lg text-sm font-medium hover:bg-primary-600">
                    Search
                </button>
            </div>

            <!-- Active filter indicator -->
            <div class="text-xs text-secondary-500 dark:text-secondary-400">
                Showing: <span class="font-semibold text-secondary-800 dark:text-white capitalize">{{ filters.status }}</span> ({{ orders.total }} orders)
            </div>
        </div>

        <!-- Orders Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="bg-gray-50 dark:bg-secondary-900/50 text-xs uppercase text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-4 font-semibold">Order</th>
                            <th class="px-5 py-4 font-semibold">Buyer</th>
                            <th class="px-5 py-4 font-semibold">Seller</th>
                            <th class="px-5 py-4 font-semibold">Amounts</th>
                            <th class="px-5 py-4 font-semibold">Yalidine Delivery</th>
                            <th class="px-5 py-4 font-semibold">Status</th>
                            <th class="px-5 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-for="order in orders.data" :key="order.id" class="hover:bg-gray-50/60 dark:hover:bg-secondary-700/30 transition-colors">
                            <!-- Order Code & Date -->
                            <td class="px-5 py-4">
                                <div class="font-bold text-secondary-800 dark:text-white">
                                    #{{ order.order_code || order.id }}
                                </div>
                                <div class="text-xs text-secondary-400 mt-0.5">
                                    {{ order.created_at }}
                                </div>
                                <div class="text-xs text-secondary-500 mt-1">
                                    {{ order.order_items ? order.order_items.length : 0 }} item(s)
                                </div>
                            </td>

                            <!-- Buyer Info -->
                            <td class="px-5 py-4">
                                <div class="font-medium text-secondary-800 dark:text-white">
                                    {{ order.buyer_name }}
                                </div>
                                <div class="text-xs text-secondary-400 mt-0.5">
                                    📞 {{ order.buyer_phone }}
                                </div>
                                <div v-if="order.shipping_and_billing?.shipping_city" class="text-xs text-secondary-500 mt-0.5">
                                    📍 {{ order.shipping_and_billing.shipping_city }}
                                </div>
                            </td>

                            <!-- Seller Info -->
                            <td class="px-5 py-4">
                                <div class="font-medium text-secondary-800 dark:text-white">
                                    {{ order.seller_name }}
                                </div>
                                <div class="text-xs text-secondary-400 mt-0.5">
                                    📞 {{ order.seller_phone }}
                                </div>
                            </td>

                            <!-- Amounts -->
                            <td class="px-5 py-4">
                                <div class="font-bold text-secondary-800 dark:text-white">
                                    {{ order.total_price_formatted }} DZD
                                </div>
                                <div class="text-xs text-secondary-400 mt-0.5">
                                    Delivery: {{ order.delivery_fee_formatted }} DZD
                                </div>
                            </td>

                            <!-- Yalidine Tracking & Mode -->
                            <td class="px-5 py-4">
                                <div class="flex flex-col gap-1.5 items-start">
                                    <!-- Delivery Mode Badge -->
                                    <span class="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full"
                                        :class="order.delivery_type === 'stop_desk' ? 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 border border-amber-200 dark:border-amber-900' : 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300 border border-blue-200 dark:border-blue-900'">
                                        <span v-if="order.delivery_type === 'stop_desk'">🏢 Stop Desk (Relais)</span>
                                        <span v-else>🏠 Domicile (Home)</span>
                                    </span>

                                    <!-- Tracking Info or Generate Button -->
                                    <div v-if="order.yalidine_tracking" class="flex flex-col gap-1 w-full">
                                        <div class="flex items-center gap-1.5">
                                            <span class="inline-flex items-center gap-1 font-mono font-bold text-xs text-indigo-700 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-900/30 px-2 py-1 rounded">
                                                📦 {{ order.yalidine_tracking }}
                                            </span>
                                            <a v-if="order.yalidine_label_url" :href="order.yalidine_label_url" target="_blank"
                                                title="Print Shipping Label (PDF)"
                                                class="p-1 text-gray-500 hover:text-primary-600 bg-gray-100 dark:bg-secondary-700 rounded transition-colors">
                                                🖨️
                                            </a>
                                        </div>
                                        <span v-if="order.yalidine_status" class="text-[11px] text-secondary-500 capitalize">
                                            Status: {{ order.yalidine_status }}
                                        </span>
                                    </div>
                                    <div v-else class="flex flex-col gap-1">
                                        <span class="text-xs text-secondary-400 italic">Not dispatched yet</span>
                                        <button @click="generateYalidineParcel(order)" :disabled="generatingOrder === order.id"
                                            class="inline-flex items-center gap-1 px-2 py-1 bg-primary-50 hover:bg-primary-100 text-primary-700 border border-primary-200 dark:bg-primary-950/40 dark:text-primary-300 dark:border-primary-800 rounded text-[11px] font-semibold transition-colors disabled:opacity-50">
                                            <span>{{ generatingOrder === order.id ? 'Generating...' : '+ Generate Yalidine' }}</span>
                                        </button>
                                    </div>
                                </div>
                            </td>

                            <!-- Status Badge & Reason -->
                            <td class="px-5 py-4">
                                <div class="flex flex-col gap-1.5 items-start">
                                    <span class="px-2.5 py-1 rounded-full text-xs font-semibold" :class="order.status_badge_color">
                                        {{ order.status_label }}
                                    </span>
                                    <!-- 72h Countdown / Remaining Hours -->
                                    <div v-if="order.remaining_hours !== null && [1, 2, 3].includes(Number(order.order_status_id))"
                                        class="text-[11px] font-medium px-2 py-0.5 rounded border"
                                        :class="order.remaining_hours <= 12 ? 'bg-red-50 text-red-700 border-red-200 dark:bg-red-950/40 dark:text-red-300' : 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300'">
                                        ⏱️ {{ order.remaining_hours }}h left ({{ order.fulfillment_deadline_formatted }})
                                    </div>
                                    <!-- Reason pill if Cancelled or Returned -->
                                    <div v-if="order.status_reason" class="text-xs text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 px-2 py-1 rounded max-w-xs break-words">
                                        <span class="font-semibold">Reason:</span> {{ order.status_reason }}
                                    </div>
                                </div>
                            </td>

                            <!-- Actions -->
                            <td class="px-5 py-4 text-right">
                                <div class="flex items-center justify-end gap-1.5 flex-wrap">
                                    <button v-if="[1, 2, 3].includes(Number(order.order_status_id))"
                                        @click="extendOrderDeadline(order)"
                                        title="Add / Extend Hours on 72h Deadline"
                                        class="px-2.5 py-1.5 bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800 rounded-lg text-xs font-semibold transition-colors">
                                        ⏱️ +Hours
                                    </button>
                                    <a v-if="order.yalidine_label_url" :href="order.yalidine_label_url" target="_blank"
                                        class="px-2.5 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 dark:bg-blue-950/40 dark:text-blue-300 dark:border-blue-800 rounded-lg text-xs font-semibold transition-colors flex items-center gap-1">
                                        <span>🖨️ Label</span>
                                    </a>
                                    <button @click="openStatusModal(order)"
                                        class="px-3 py-1.5 bg-secondary-100 hover:bg-secondary-200 dark:bg-secondary-700 dark:hover:bg-secondary-600 text-secondary-800 dark:text-white rounded-lg text-xs font-semibold transition-colors">
                                        Update Status
                                    </button>
                                </div>
                            </td>
                        </tr>

                        <!-- Empty State -->
                        <tr v-if="orders.data.length === 0">
                            <td colspan="7" class="px-5 py-12 text-center text-secondary-400">
                                <div class="flex flex-col items-center justify-center">
                                    <ps-icon name="box" w="40" h="40" class="text-secondary-300 mb-2" />
                                    <div class="text-base font-semibold text-secondary-600 dark:text-secondary-300">No Orders Found</div>
                                    <div class="text-xs text-secondary-400 mt-1">There are no orders matching your current filter.</div>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div v-if="orders.links && orders.links.length > 3" class="px-5 py-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between">
                <div class="text-xs text-secondary-500">
                    Showing {{ orders.from || 0 }} to {{ orders.to || 0 }} of {{ orders.total }} orders
                </div>
                <div class="flex items-center gap-1">
                    <template v-for="(link, i) in orders.links" :key="i">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1.5 text-xs rounded-lg transition-colors"
                            :class="link.active ? 'bg-primary-500 text-white font-semibold' : 'text-secondary-600 dark:text-secondary-300 hover:bg-gray-100 dark:hover:bg-secondary-700'"
                            v-html="link.label" />
                        <span v-else class="px-3 py-1.5 text-xs text-secondary-400" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>

        <!-- Status Change Modal -->
        <jet-dialog-modal :show="showModal" @close="showModal = false">
            <template #title>
                <div class="flex items-center gap-2">
                    <span class="font-bold text-lg text-secondary-800 dark:text-white">
                        Update Status: #{{ selectedOrder?.order_code || selectedOrder?.id }}
                    </span>
                </div>
            </template>

            <template #content>
                <div class="space-y-4 py-2">
                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Order Status
                        </label>
                        <select v-model="form.order_status_id"
                            class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500">
                            <option value="1">Pending</option>
                            <option value="2">Approved</option>
                            <option value="3">Delivering (Sent to Delivery Company)</option>
                            <option value="4">Delivered</option>
                            <option value="5">Cancelled</option>
                            <option value="6">Returned</option>
                        </select>
                    </div>

                    <!-- Reason section if status is Cancelled (5) or Returned (6) -->
                    <div v-if="form.order_status_id == 5 || form.order_status_id == 6" class="space-y-2 pt-2 border-t border-gray-100 dark:border-secondary-700">
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400">
                            Reason for {{ form.order_status_id == 5 ? 'Cancellation' : 'Return' }} <span class="text-red-500">*</span>
                        </label>

                        <!-- Preset Reason Quick Select -->
                        <div class="flex flex-wrap gap-1.5 mb-2">
                            <button v-for="preset in reasonPresets" :key="preset" type="button"
                                @click="form.status_reason = preset"
                                class="px-2.5 py-1 text-xs rounded-full border border-gray-200 dark:border-secondary-600 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                                :class="{ 'bg-primary-100 border-primary-500 text-primary-800 dark:bg-primary-900/40 dark:text-primary-300 font-semibold': form.status_reason === preset }">
                                {{ preset }}
                            </button>
                        </div>

                        <textarea v-model="form.status_reason" rows="3"
                            placeholder="Enter the reason or details..."
                            class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"></textarea>
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex items-center justify-end gap-2">
                    <button @click="showModal = false" type="button"
                        class="px-4 py-2 bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 rounded-lg text-sm font-medium hover:bg-gray-200">
                        Cancel
                    </button>
                    <button @click="submitStatusUpdate" :disabled="submitting" type="button"
                        class="px-4 py-2 bg-primary-500 text-white rounded-lg text-sm font-medium hover:bg-primary-600 disabled:opacity-50">
                        {{ submitting ? 'Updating...' : 'Save Status' }}
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
    name: "AdminOrdersIndex",
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
    },
    setup(props) {
        const searchQuery = ref(props.filters.search || '');
        const showModal = ref(false);
        const selectedOrder = ref(null);
        const submitting = ref(false);
        const generatingOrder = ref(null);

        const form = ref({
            order_status_id: 1,
            status_reason: '',
        });

        const reasonPresets = [
            'No answer from buyer',
            'Cancelled by the buyer',
            'Damaged during delivery',
            'Wrong delivery address',
            'Item defective / not as described',
            'Buyer refused package',
        ];

        const generateYalidineParcel = (order) => {
            if (!order || generatingOrder.value) return;
            const code = order.order_code || order.id;
            if (!confirm(`Générer l'expédition officielle Yalidine pour la commande #${code} ?`)) {
                return;
            }
            generatingOrder.value = order.id;
            router.post(route('admin.orders.generateParcel', order.id), {}, {
                preserveScroll: true,
                onSuccess: (page) => {
                    const status = page.props.status;
                    const msg = (typeof status === 'object' && status !== null) ? status.msg : status;
                    if (msg) {
                        alert(`✅ ${msg}`);
                    } else {
                        alert('✅ Bordereau et colis Yalidine générés avec succès !');
                    }
                },
                onError: (errors) => {
                    const err = errors.msg || Object.values(errors).join('\n') || 'Échec de la génération du colis Yalidine.';
                    alert(`❌ Erreur Yalidine : ${err}`);
                },
                onFinish: () => {
                    generatingOrder.value = null;
                }
            });
        };

        const extendOrderDeadline = (order) => {
            if (!order) return;
            const code = order.order_code || order.id;
            const input = prompt(`Nombre d'heures à ajouter au délai de la commande #${code} (ex: 24, 48, 72) :`, '24');
            if (input === null) return;
            const hours = parseInt(input, 10);
            if (!hours || hours < 1 || hours > 720) {
                alert('❌ Veuillez saisir un nombre d\'heures valide entre 1 et 720.');
                return;
            }
            router.post(route('admin.orders.extendDeadline', order.id), { hours }, {
                preserveScroll: true,
                onSuccess: (page) => {
                    const status = page.props.status;
                    const msg = (typeof status === 'object' && status !== null) ? status.msg : status;
                    alert(`✅ ${msg || `Délai prolongé de +${hours}h !`}`);
                },
                onError: (errors) => {
                    const err = errors.msg || Object.values(errors).join('\n') || 'Échec de prolongation du délai.';
                    alert(`❌ Erreur : ${err}`);
                }
            });
        };

        const applyStatusFilter = (status) => {
            router.get(route('admin.orders.index'), {
                status: status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const handleSearch = () => {
            router.get(route('admin.orders.index'), {
                status: props.filters.status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const openStatusModal = (order) => {
            selectedOrder.value = order;
            form.value.order_status_id = order.order_status_id || 1;
            form.value.status_reason = order.status_reason || '';
            showModal.value = true;
        };

        const submitStatusUpdate = () => {
            if (!selectedOrder.value || submitting.value) return;

            // Validate reason if Cancelled or Returned
            if ((form.value.order_status_id == 5 || form.value.order_status_id == 6) && !form.value.status_reason.trim()) {
                alert('Please provide or select a reason for this status change.');
                return;
            }

            submitting.value = true;
            router.post(route('admin.orders.updateStatus', selectedOrder.value.id), form.value, {
                onSuccess: () => {
                    showModal.value = false;
                    selectedOrder.value = null;
                },
                onFinish: () => {
                    submitting.value = false;
                }
            });
        };

        return {
            searchQuery,
            showModal,
            selectedOrder,
            submitting,
            generatingOrder,
            generateYalidineParcel,
            extendOrderDeadline,
            form,
            reasonPresets,
            applyStatusFilter,
            handleSearch,
            openStatusModal,
            submitStatusUpdate,
        };
    }
});
</script>
