<template>
    <Head :title="$t('dressy_commission_module') || 'Commission & Settings'" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_commission_title') || 'Dressy C2C Finance & Commission Configuration' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Manage marketplace sales commission percentages, minimum seller withdrawal limits, and Yalidine logistics integration mode.
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

        <!-- Platform Financial Performance Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Total Escrow Turnover</div>
                        <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ formatCurrency(stats.total_escrow_turnover) }}</div>
                    </div>
                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">{{ stats.total_escrow_orders }} settled C2C transactions</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-purple-500 dark:text-purple-400">Platform Revenue (Commission)</div>
                        <div class="text-2xl font-bold text-purple-600 dark:text-purple-400 mt-1">{{ formatCurrency(stats.total_commission_earned) }}</div>
                    </div>
                    <div class="p-3 bg-purple-50 dark:bg-purple-900/20 text-purple-600 rounded-xl">
                        <ps-icon name="chart-line" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Earned from completed seller sales</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">Active Seller Balances</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ formatCurrency(stats.total_seller_balance) }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Held across {{ stats.total_seller_wallets }} seller wallets</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Total Payouts Disbursed</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ formatCurrency(stats.total_paid_withdrawals) }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Sent to sellers via CCP & BaridiMob</div>
            </div>
        </div>

        <!-- Configuration Form -->
        <div class="max-w-3xl bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-6 shadow-sm">
            <h2 class="text-lg font-bold text-secondary-800 dark:text-white mb-6 pb-3 border-b border-gray-100 dark:border-secondary-700">
                Marketplace Commission & Finance Parameters
            </h2>

            <form @submit.prevent="saveSettings" class="space-y-6">
                <!-- Commission Percent -->
                <div>
                    <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                        Platform Commission Rate (%) *
                    </label>
                    <p class="text-xs text-secondary-500 dark:text-secondary-400 mb-2">
                        Percentage retained by Dressy on every order. When marked paid, this fee is deducted from the order subtotal before crediting the seller's wallet.
                    </p>
                    <div class="relative w-48">
                        <input type="number" step="0.1" min="0" max="100" v-model="form.commission_percent" required
                            class="w-full px-3 py-2 pr-8 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-bold focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-500 font-bold">
                            %
                        </div>
                    </div>
                </div>

                <!-- Minimum Withdrawal -->
                <div>
                    <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                        Minimum Withdrawal Threshold (DZD) *
                    </label>
                    <p class="text-xs text-secondary-500 dark:text-secondary-400 mb-2">
                        The minimum wallet balance required for sellers to submit a withdrawal request.
                    </p>
                    <div class="relative w-64">
                        <input type="number" step="10" min="0" v-model="form.min_withdraw_amount" required
                            class="w-full px-3 py-2 pr-14 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-bold focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-500 font-semibold text-xs">
                            DZD
                        </div>
                    </div>
                </div>

                <!-- Yalidine Mode -->
                <div>
                    <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                        Yalidine Logistics API Mode
                    </label>
                    <p class="text-xs text-secondary-500 dark:text-secondary-400 mb-3">
                        Choose whether order dispatch generates simulated tracking numbers or calls live Yalidine shipping APIs.
                    </p>
                    <div class="space-y-3">
                        <label class="flex items-start gap-3 p-3.5 rounded-xl border cursor-pointer transition-colors"
                            :class="form.yalidine_stub_mode ? 'border-primary-500 bg-primary-50/50 dark:bg-primary-900/20' : 'border-gray-200 dark:border-secondary-700'">
                            <input type="radio" :value="true" v-model="form.yalidine_stub_mode" class="mt-1 text-primary-600 focus:ring-primary-500" />
                            <div>
                                <div class="font-bold text-sm text-secondary-800 dark:text-white">Stub Mode (Simulation / Test)</div>
                                <div class="text-xs text-secondary-500 dark:text-secondary-400 mt-0.5">
                                    Generates realistic mock tracking numbers (<code>YAL-SIM-XXXXXX</code>) instantly upon seller dispatch without making external HTTP requests. Ideal for development and testing.
                                </div>
                            </div>
                        </label>

                        <label class="flex items-start gap-3 p-3.5 rounded-xl border cursor-pointer transition-colors"
                            :class="!form.yalidine_stub_mode ? 'border-primary-500 bg-primary-50/50 dark:bg-primary-900/20' : 'border-gray-200 dark:border-secondary-700'">
                            <input type="radio" :value="false" v-model="form.yalidine_stub_mode" class="mt-1 text-primary-600 focus:ring-primary-500" />
                            <div>
                                <div class="font-bold text-sm text-secondary-800 dark:text-white">Live Production Mode</div>
                                <div class="text-xs text-secondary-500 dark:text-secondary-400 mt-0.5">
                                    Calls the official Yalidine API with credentials defined in your server environment (<code>YALIDINE_API_TOKEN</code>) to generate real shipping parcels.
                                </div>
                            </div>
                        </label>
                    </div>
                </div>

                <!-- Submit Button -->
                <div class="pt-4 border-t border-gray-100 dark:border-secondary-700 flex justify-end">
                    <button type="submit" :disabled="saving"
                        class="px-6 py-2.5 bg-primary-500 hover:bg-primary-600 text-white rounded-lg text-sm font-bold shadow-md transition-colors disabled:opacity-50 flex items-center gap-2">
                        <ps-icon v-if="!saving" name="check" w="18" h="18" />
                        <span v-if="saving">Saving Changes...</span>
                        <span v-else>Save Platform Settings</span>
                    </button>
                </div>
            </form>
        </div>
    </ps-layout>
</template>

<script>
import { defineComponent, ref, reactive } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import PsLayout from "@/Components/PsLayout.vue";
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsBannerIcon from "@/Components/Core/Banners/PsBannerIcon.vue";

export default defineComponent({
    name: "AdminCommissionIndex",
    components: {
        Head,
        PsLayout,
        PsLabel,
        PsIcon,
        PsBannerIcon,
    },
    layout: PsLayout,
    props: {
        settings: Object,
        stats: Object,
    },
    setup(props) {
        const saving = ref(false);

        const form = reactive({
            commission_percent: props.settings.commission_percent ?? 10,
            min_withdraw_amount: props.settings.min_withdraw_amount ?? 1000,
            yalidine_stub_mode: props.settings.yalidine_stub_mode ?? true,
        });

        const formatCurrency = (val) => {
            const num = parseFloat(val) || 0;
            return num.toLocaleString('fr-DZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' DZD';
        };

        const saveSettings = () => {
            saving.value = true;
            router.post(route('admin.commission.update'), {
                commission_percent: form.commission_percent,
                min_withdraw_amount: form.min_withdraw_amount,
                yalidine_stub_mode: form.yalidine_stub_mode,
            }, {
                onFinish: () => {
                    saving.value = false;
                }
            });
        };

        return {
            form,
            saving,
            formatCurrency,
            saveSettings,
        };
    }
});
</script>
