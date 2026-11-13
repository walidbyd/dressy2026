<template>
    <Head :title="$t('dressy_wallets_module') || 'Seller Wallets'" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_wallets_title') || 'Seller Wallets & Manual Ledger Adjustment' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    View seller balances, view transaction history, and perform audited credit/debit ledger adjustments.
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
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Total In Seller Wallets</div>
                        <div class="text-2xl font-bold text-primary-600 dark:text-primary-400 mt-1">{{ formatCurrency(stats.total_balance) }}</div>
                    </div>
                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Active platform liability across all seller accounts</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Total Net Earned</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ formatCurrency(stats.total_earned) }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Cumulative payouts credited from settled orders</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-purple-500 dark:text-purple-400">Total Withdrawn</div>
                        <div class="text-2xl font-bold text-purple-600 dark:text-purple-400 mt-1">{{ formatCurrency(stats.total_withdrawn) }}</div>
                    </div>
                    <div class="p-3 bg-purple-50 dark:bg-purple-900/20 text-purple-600 rounded-xl">
                        <ps-icon name="chart-line" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Total funds disbursed to sellers via CCP & BaridiMob</div>
            </div>
        </div>

        <!-- Search Toolbar -->
        <div class="bg-white dark:bg-secondary-800 p-4 rounded-xl border border-gray-100 dark:border-secondary-700 mb-6 flex items-center justify-between gap-4">
            <div class="w-full md:w-96">
                <div class="relative">
                    <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                        placeholder="Search seller by name, email, phone, store..."
                        class="w-full pl-10 pr-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                        <ps-icon name="search" w="18" h="18" />
                    </div>
                </div>
            </div>
            <button @click="handleSearch" class="px-4 py-2 bg-primary-500 hover:bg-primary-600 text-white text-sm font-medium rounded-lg transition-colors">
                Search
            </button>
        </div>

        <!-- Wallets Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="bg-gray-50 dark:bg-secondary-900/50 text-xs uppercase font-semibold text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="py-3 px-4">Seller User</th>
                            <th class="py-3 px-4">Vendor Store</th>
                            <th class="py-3 px-4">Contact</th>
                            <th class="py-3 px-4 text-right font-bold text-secondary-800 dark:text-white">Active Balance</th>
                            <th class="py-3 px-4 text-right">Pending Withdrawals</th>
                            <th class="py-3 px-4 text-right">Total Earned</th>
                            <th class="py-3 px-4 text-right">Total Withdrawn</th>
                            <th class="py-3 px-4 text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-for="user in users.data" :key="user.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-750 transition-colors">
                            <td class="py-3 px-4">
                                <div class="font-medium text-secondary-800 dark:text-white">{{ user.name }}</div>
                                <div class="text-xs text-secondary-400">ID: #{{ user.id }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-primary-600 dark:text-primary-400">
                                    {{ user.vendor ? user.vendor.name : 'Personal Account' }}
                                </div>
                                <div class="text-xs text-secondary-400" v-if="user.vendor">
                                    Store ID: #{{ user.vendor.id }}
                                </div>
                            </td>
                            <td class="py-3 px-4 text-xs">
                                <div>{{ user.email }}</div>
                                <div class="text-secondary-400">{{ user.user_phone || 'No phone' }}</div>
                            </td>
                            <td class="py-3 px-4 text-right font-bold text-base text-primary-600 dark:text-primary-400">
                                {{ formatCurrency(user.wallet ? user.wallet.balance : 0) }}
                            </td>
                            <td class="py-3 px-4 text-right font-medium text-amber-600 dark:text-amber-400">
                                {{ formatCurrency(user.pending_withdrawals) }}
                            </td>
                            <td class="py-3 px-4 text-right font-medium text-emerald-600 dark:text-emerald-400">
                                {{ formatCurrency(user.total_earned) }}
                            </td>
                            <td class="py-3 px-4 text-right font-medium text-purple-600 dark:text-purple-400">
                                {{ formatCurrency(user.total_withdrawn) }}
                            </td>
                            <td class="py-3 px-4 text-center">
                                <div class="flex items-center justify-center gap-2">
                                    <button @click="openAdjustModal(user)"
                                        class="px-2.5 py-1 bg-primary-50 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 hover:bg-primary-100 rounded-md text-xs font-semibold transition-colors flex items-center gap-1">
                                        <ps-icon name="cash" w="14" h="14" />
                                        Change Wallet
                                    </button>
                                    <Link :href="route('admin.wallets.history', user.id)"
                                        class="px-2.5 py-1 bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200 rounded-md text-xs font-semibold transition-colors flex items-center gap-1">
                                        <ps-icon name="chart-line" w="14" h="14" />
                                        History
                                    </Link>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="users.data.length === 0">
                            <td colspan="8" class="py-8 text-center text-secondary-400">
                                No seller wallets found matching search.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="p-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between text-xs text-secondary-500">
                <div>
                    Showing {{ users.from || 0 }} to {{ users.to || 0 }} of {{ users.total }} sellers
                </div>
                <div class="flex items-center gap-1" v-if="users.links && users.links.length > 3">
                    <template v-for="(link, i) in users.links" :key="i">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1 rounded border border-gray-200 dark:border-secondary-700 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                            :class="{ 'bg-primary-500 text-white font-semibold border-primary-500': link.active }"
                            v-html="link.label" />
                        <span v-else class="px-2 py-1 text-gray-300 dark:text-secondary-600" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>

        <!-- "Change Wallet" Adjustment Modal -->
        <jet-dialog-modal :show="showAdjustModal" @close="showAdjustModal = false">
            <template #title>
                <div class="flex items-center gap-2 text-primary-600 dark:text-primary-400">
                    <ps-icon name="cash" w="22" h="22" />
                    Manual Wallet Ledger Adjustment ("Change Wallet")
                </div>
            </template>

            <template #content>
                <div v-if="selectedUser" class="space-y-4">
                    <div class="p-3 bg-gray-50 dark:bg-secondary-900 rounded-lg flex justify-between items-center text-sm border border-gray-200 dark:border-secondary-700">
                        <div>
                            <div class="font-semibold text-secondary-800 dark:text-white">{{ selectedUser.name }}</div>
                            <div class="text-xs text-secondary-500">User #{{ selectedUser.id }} &bull; {{ selectedUser.email }}</div>
                        </div>
                        <div class="text-right">
                            <div class="text-xs text-secondary-500">Current Balance</div>
                            <div class="text-lg font-bold text-primary-600 dark:text-primary-400">
                                {{ formatCurrency(selectedUser.wallet ? selectedUser.wallet.balance : 0) }}
                            </div>
                        </div>
                    </div>

                    <!-- Type Selection -->
                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-2">
                            Adjustment Type
                        </label>
                        <div class="grid grid-cols-2 gap-3">
                            <button type="button" @click="adjustForm.type = 'credit'"
                                class="py-2.5 px-4 rounded-lg border text-sm font-semibold flex items-center justify-center gap-2 transition-colors"
                                :class="adjustForm.type === 'credit' ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' : 'border-gray-200 dark:border-secondary-700 hover:bg-gray-50'">
                                <span class="text-base font-bold">+</span> Credit (Add Funds)
                            </button>
                            <button type="button" @click="adjustForm.type = 'debit'"
                                class="py-2.5 px-4 rounded-lg border text-sm font-semibold flex items-center justify-center gap-2 transition-colors"
                                :class="adjustForm.type === 'debit' ? 'border-red-500 bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300' : 'border-gray-200 dark:border-secondary-700 hover:bg-gray-50'">
                                <span class="text-base font-bold">-</span> Debit (Deduct Funds)
                            </button>
                        </div>
                    </div>

                    <!-- Amount -->
                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Amount (DZD) *
                        </label>
                        <input type="number" step="0.01" min="1" v-model="adjustForm.amount"
                            placeholder="e.g. 500.00"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    </div>

                    <!-- Note -->
                    <div>
                        <label class="block text-xs font-semibold uppercase text-secondary-600 dark:text-secondary-400 mb-1">
                            Audited Reason / Reference Note *
                        </label>
                        <textarea v-model="adjustForm.note" rows="3"
                            placeholder="Mandatory administrative justification (e.g. Dispute refund resolution, Manual CCP deposit correction...)"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"></textarea>
                    </div>

                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 text-xs rounded-lg">
                        <strong>Audited Ledger:</strong> This operation writes directly to the immutable <code>psx_wallet_transactions</code> ledger with your Super Admin ID recorded as the author.
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex justify-end gap-3">
                    <button @click="showAdjustModal = false"
                        class="px-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 text-sm font-medium text-secondary-700 dark:text-secondary-200 hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors">
                        Cancel
                    </button>
                    <button @click="submitAdjust" :disabled="submitting"
                        class="px-5 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg text-sm font-bold shadow-md transition-colors disabled:opacity-50 flex items-center gap-2">
                        <ps-icon v-if="!submitting" name="check" w="16" h="16" />
                        <span v-if="submitting">Processing...</span>
                        <span v-else>Apply Adjustment</span>
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
    name: "AdminWalletIndex",
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
        users: Object,
        filters: Object,
        stats: Object,
    },
    setup(props) {
        const searchQuery = ref(props.filters.search || '');
        const showAdjustModal = ref(false);
        const selectedUser = ref(null);
        const submitting = ref(false);

        const adjustForm = reactive({
            type: 'credit',
            amount: '',
            note: '',
        });

        const formatCurrency = (val) => {
            const num = parseFloat(val) || 0;
            return num.toLocaleString('fr-DZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' DZD';
        };

        const handleSearch = () => {
            router.get(route('admin.wallets.index'), {
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const openAdjustModal = (user) => {
            selectedUser.value = user;
            adjustForm.type = 'credit';
            adjustForm.amount = '';
            adjustForm.note = '';
            showAdjustModal.value = true;
        };

        const submitAdjust = () => {
            if (!selectedUser.value || submitting.value) return;
            if (!adjustForm.amount || parseFloat(adjustForm.amount) <= 0) {
                alert('Please enter a valid amount.');
                return;
            }
            if (!adjustForm.note || adjustForm.note.trim().length === 0) {
                alert('Please provide an audited reason/note for this adjustment.');
                return;
            }

            submitting.value = true;
            router.post(route('admin.wallets.adjust'), {
                user_id: selectedUser.value.id,
                type: adjustForm.type,
                amount: adjustForm.amount,
                note: adjustForm.note,
            }, {
                onSuccess: () => {
                    showAdjustModal.value = false;
                    selectedUser.value = null;
                },
                onFinish: () => {
                    submitting.value = false;
                }
            });
        };

        return {
            searchQuery,
            showAdjustModal,
            selectedUser,
            adjustForm,
            submitting,
            formatCurrency,
            handleSearch,
            openAdjustModal,
            submitAdjust,
        };
    }
});
</script>
