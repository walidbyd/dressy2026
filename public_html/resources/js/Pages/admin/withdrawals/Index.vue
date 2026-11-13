<template>
    <Head :title="$t('dressy_withdrawals_module') || 'Withdrawal Requests'" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_withdrawals_title') || 'Seller Withdrawal Requests (CCP & BaridiMob)' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Review seller payout requests, execute CCP / BaridiMob transfers, and record approved disbursements.
                </p>
            </div>
        </div>

        <!-- Banner alerts -->
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
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">Pending Requests</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ stats.pending_count }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="bell" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Requires admin payout verification</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">Pending Amount</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ formatCurrency(stats.pending_amount) }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Awaiting wire / transfer execution</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Approved Payouts</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ formatCurrency(stats.approved_amount) }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Disbursed to seller CCP / BaridiMob</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-red-500 dark:text-red-400">Rejected Requests</div>
                        <div class="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">{{ formatCurrency(stats.rejected_amount) }}</div>
                    </div>
                    <div class="p-3 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-xl">
                        <ps-icon name="close-circle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Declined; funds kept in seller wallets</div>
            </div>
        </div>

        <!-- Toolbar & Filter Tabs -->
        <div class="bg-white dark:bg-secondary-800 p-4 rounded-xl border border-gray-100 dark:border-secondary-700 mb-6 flex flex-col md:flex-row items-center justify-between gap-4">
            <div class="flex items-center gap-2 w-full md:w-auto">
                <button @click="applyStatusFilter('pending')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'pending' ? 'bg-amber-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    Pending ({{ stats.pending_count }})
                </button>
                <button @click="applyStatusFilter('approved')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'approved' ? 'bg-emerald-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    Approved
                </button>
                <button @click="applyStatusFilter('rejected')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'rejected' ? 'bg-red-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    Rejected
                </button>
                <button @click="applyStatusFilter('all')"
                    class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    :class="filters.status === 'all' ? 'bg-primary-500 text-white shadow' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                    All Requests
                </button>
            </div>

            <div class="w-full md:w-80">
                <div class="relative">
                    <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                        placeholder="Search seller, phone, note, ID..."
                        class="w-full pl-10 pr-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                        <ps-icon name="search" w="18" h="18" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Requests Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="bg-gray-50 dark:bg-secondary-900/50 text-xs uppercase font-semibold text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="py-3 px-4">Req ID / Date</th>
                            <th class="py-3 px-4">Seller Details</th>
                            <th class="py-3 px-4 text-right">Current Balance</th>
                            <th class="py-3 px-4 text-right font-bold text-secondary-800 dark:text-white">Amount Requested</th>
                            <th class="py-3 px-4">CCP / BaridiMob Info</th>
                            <th class="py-3 px-4 text-center">Status</th>
                            <th class="py-3 px-4">Admin Reference / Note</th>
                            <th class="py-3 px-4 text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-for="req in withdrawals.data" :key="req.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-750 transition-colors">
                            <td class="py-3 px-4 font-mono text-xs">
                                <div class="font-bold text-secondary-800 dark:text-white">#{{ req.id }}</div>
                                <div class="text-secondary-400">{{ formatDate(req.created_at) }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-secondary-800 dark:text-white">{{ req.user ? req.user.name : 'Unknown User' }}</div>
                                <div class="text-xs text-secondary-400">
                                    {{ req.user ? req.user.email : '' }} &bull; {{ req.user?.user_phone || 'No phone' }}
                                </div>
                                <div class="text-xs text-primary-600 dark:text-primary-400 font-medium" v-if="req.user?.vendor">
                                    Store: {{ req.user.vendor.name }}
                                </div>
                            </td>
                            <td class="py-3 px-4 text-right font-medium text-secondary-700 dark:text-secondary-300">
                                {{ formatCurrency(req.wallet ? req.wallet.balance : 0) }}
                            </td>
                            <td class="py-3 px-4 text-right font-black text-base text-secondary-900 dark:text-white">
                                {{ formatCurrency(req.amount) }}
                            </td>
                            <td class="py-3 px-4 text-xs font-mono max-w-xs break-words">
                                <div class="p-2 rounded bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-secondary-200 border border-gray-200 dark:border-secondary-700">
                                    {{ req.note || 'No payment note provided' }}
                                </div>
                            </td>
                            <td class="py-3 px-4 text-center">
                                <span v-if="req.status === 'pending'"
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
                                    Pending
                                </span>
                                <span v-else-if="req.status === 'approved'"
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300">
                                    Approved
                                </span>
                                <span v-else-if="req.status === 'rejected'"
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300">
                                    Rejected
                                </span>
                            </td>
                            <td class="py-3 px-4 text-xs text-secondary-600 dark:text-secondary-400 max-w-xs">
                                <div v-if="req.admin_reference" class="font-mono font-semibold text-emerald-600 dark:text-emerald-400">
                                    Ref: {{ req.admin_reference }}
                                </div>
                                <div v-if="req.admin_note" class="italic mt-0.5">
                                    {{ req.admin_note }}
                                </div>
                                <span v-if="!req.admin_reference && !req.admin_note" class="text-secondary-400">-</span>
                            </td>
                            <td class="py-3 px-4 text-center">
                                <div v-if="req.status === 'pending'" class="flex items-center justify-center gap-2">
                                    <button @click="openApproveModal(req)"
                                        class="px-2.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-sm transition-colors flex items-center gap-1">
                                        <ps-icon name="check" w="14" h="14" />
                                        Approve
                                    </button>
                                    <button @click="openRejectModal(req)"
                                        class="px-2.5 py-1.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-xs font-semibold shadow-sm transition-colors flex items-center gap-1">
                                        <ps-icon name="trash" w="14" h="14" />
                                        Reject
                                    </button>
                                </div>
                                <span v-else class="text-xs text-secondary-400 capitalize">
                                    Finalized
                                </span>
                            </td>
                        </tr>
                        <tr v-if="withdrawals.data.length === 0">
                            <td colspan="8" class="py-8 text-center text-secondary-400">
                                No withdrawal requests found.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="p-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between text-xs text-secondary-500">
                <div>
                    Showing {{ withdrawals.from || 0 }} to {{ withdrawals.to || 0 }} of {{ withdrawals.total }} requests
                </div>
                <div class="flex items-center gap-1" v-if="withdrawals.links && withdrawals.links.length > 3">
                    <template v-for="(link, i) in withdrawals.links" :key="i">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1 rounded border border-gray-200 dark:border-secondary-700 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                            :class="{ 'bg-primary-500 text-white font-semibold border-primary-500': link.active }"
                            v-html="link.label" />
                        <span v-else class="px-2 py-1 text-gray-300 dark:text-secondary-600" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>

        <!-- Approve Modal -->
        <jet-dialog-modal :show="showApproveModal" @close="showApproveModal = false">
            <template #title>
                <div class="flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
                    <ps-icon name="checkCircle" w="22" h="22" />
                    Approve Withdrawal Request & Deduct Balance
                </div>
            </template>

            <template #content>
                <div v-if="selectedRequest" class="space-y-4">
                    <div class="p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl space-y-2 text-sm border border-gray-200 dark:border-secondary-700">
                        <div class="flex justify-between">
                            <span class="text-secondary-500">Seller:</span>
                            <span class="font-bold text-secondary-800 dark:text-white">{{ selectedRequest.user?.name }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-secondary-500">Payment Details:</span>
                            <span class="font-mono text-xs text-secondary-700 dark:text-secondary-300 max-w-xs text-right">{{ selectedRequest.note }}</span>
                        </div>
                        <div class="flex justify-between font-black text-base text-emerald-600 dark:text-emerald-400 pt-2 border-t border-gray-200 dark:border-secondary-700">
                            <span>Amount to Disburse:</span>
                            <span>{{ formatCurrency(selectedRequest.amount) }}</span>
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Disbursement Reference (BaridiMob TX ID / CCP Stamp #)
                        </label>
                        <input type="text" v-model="approveForm.admin_reference"
                            placeholder="e.g. BM-982341908 or CCP-092834"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500" />
                    </div>

                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Internal Administrative Note (Optional)
                        </label>
                        <input type="text" v-model="approveForm.admin_note"
                            placeholder="e.g. Paid via BaridiMob app by Admin"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500" />
                    </div>

                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-300 text-xs rounded-lg">
                        <strong>Ledger Effect:</strong> Approving will atomically deduct <strong>{{ formatCurrency(selectedRequest.amount) }}</strong> from the seller's active wallet balance and create an immutable debit transaction in the ledger.
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex justify-end gap-3">
                    <button @click="showApproveModal = false"
                        class="px-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 text-sm font-medium text-secondary-700 dark:text-secondary-200 hover:bg-gray-100 transition-colors">
                        Cancel
                    </button>
                    <button @click="submitApprove" :disabled="submitting"
                        class="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-sm font-bold shadow-md transition-colors disabled:opacity-50 flex items-center gap-2">
                        <ps-icon v-if="!submitting" name="check" w="16" h="16" />
                        <span v-if="submitting">Approving...</span>
                        <span v-else>Confirm & Deduct Balance</span>
                    </button>
                </div>
            </template>
        </jet-dialog-modal>

        <!-- Reject Modal -->
        <jet-dialog-modal :show="showRejectModal" @close="showRejectModal = false">
            <template #title>
                <div class="flex items-center gap-2 text-red-600 dark:text-red-400">
                    <ps-icon name="trash" w="22" h="22" />
                    Reject Withdrawal Request
                </div>
            </template>

            <template #content>
                <div v-if="selectedRequest" class="space-y-4">
                    <p class="text-sm text-secondary-600 dark:text-secondary-300">
                        Rejecting withdrawal request <strong>#{{ selectedRequest.id }}</strong> for {{ formatCurrency(selectedRequest.amount) }} by {{ selectedRequest.user?.name }}.
                    </p>

                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Rejection Reason *
                        </label>
                        <textarea v-model="rejectForm.rejection_reason" rows="3"
                            placeholder="Reason for declining (e.g. Invalid CCP account number, incorrect BaridiMob RIP, Seller requested cancellation...)"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500"></textarea>
                    </div>

                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-300 text-xs rounded-lg">
                        <strong>Safety Guarantee:</strong> Rejecting does NOT deduct funds from the seller's wallet. Their balance remains 100% available for future withdrawal.
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex justify-end gap-3">
                    <button @click="showRejectModal = false"
                        class="px-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 text-sm font-medium text-secondary-700 dark:text-secondary-200 hover:bg-gray-100 transition-colors">
                        Cancel
                    </button>
                    <button @click="submitReject" :disabled="submitting"
                        class="px-5 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-bold shadow-md transition-colors disabled:opacity-50 flex items-center gap-2">
                        <ps-icon v-if="!submitting" name="trash" w="16" h="16" />
                        <span v-if="submitting">Rejecting...</span>
                        <span v-else>Confirm Rejection</span>
                    </button>
                </div>
            </template>
        </jet-dialog-modal>
    </ps-layout>
</template>

<script>
import { defineComponent, ref, reactive } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import PsLayout from "@/Components/PsLayout.vue";
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsBannerIcon from "@/Components/Core/Banners/PsBannerIcon.vue";
import JetDialogModal from '@/Jetstream/DialogModal.vue';

export default defineComponent({
    name: "AdminWithdrawalIndex",
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
        withdrawals: Object,
        filters: Object,
        stats: Object,
    },
    setup(props) {
        const searchQuery = ref(props.filters.search || '');
        const showApproveModal = ref(false);
        const showRejectModal = ref(false);
        const selectedRequest = ref(null);
        const submitting = ref(false);

        const approveForm = reactive({
            admin_reference: '',
            admin_note: '',
        });

        const rejectForm = reactive({
            rejection_reason: '',
        });

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
            router.get(route('admin.withdrawals.index'), {
                status: status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const handleSearch = () => {
            router.get(route('admin.withdrawals.index'), {
                status: props.filters.status,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const openApproveModal = (req) => {
            selectedRequest.value = req;
            approveForm.admin_reference = '';
            approveForm.admin_note = '';
            showApproveModal.value = true;
        };

        const submitApprove = () => {
            if (!selectedRequest.value || submitting.value) return;
            submitting.value = true;
            router.post(route('admin.withdrawals.approve', selectedRequest.value.id), {
                admin_reference: approveForm.admin_reference,
                admin_note: approveForm.admin_note,
            }, {
                onSuccess: () => {
                    showApproveModal.value = false;
                    selectedRequest.value = null;
                },
                onFinish: () => {
                    submitting.value = false;
                }
            });
        };

        const openRejectModal = (req) => {
            selectedRequest.value = req;
            rejectForm.rejection_reason = '';
            showRejectModal.value = true;
        };

        const submitReject = () => {
            if (!selectedRequest.value || submitting.value) return;
            if (!rejectForm.rejection_reason || rejectForm.rejection_reason.trim().length === 0) {
                alert('Please provide a reason for rejection.');
                return;
            }

            submitting.value = true;
            router.post(route('admin.withdrawals.reject', selectedRequest.value.id), {
                rejection_reason: rejectForm.rejection_reason,
            }, {
                onSuccess: () => {
                    showRejectModal.value = false;
                    selectedRequest.value = null;
                },
                onFinish: () => {
                    submitting.value = false;
                }
            });
        };

        return {
            searchQuery,
            showApproveModal,
            showRejectModal,
            selectedRequest,
            approveForm,
            rejectForm,
            submitting,
            formatCurrency,
            formatDate,
            applyStatusFilter,
            handleSearch,
            openApproveModal,
            submitApprove,
            openRejectModal,
            submitReject,
        };
    }
});
</script>
