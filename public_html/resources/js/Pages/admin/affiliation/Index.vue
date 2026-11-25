<template>
    <Head :title="$t('dressy_affiliation_module') || 'Affiliation & Parrainage'" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    Affiliation &amp; Parrainage (Invite a Friend)
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Configurez les pourcentages de récompense (émetteur &amp; filleul) et gérez les codes de parrainage.
                </p>
            </div>
        </div>

        <!-- Alerts -->
        <ps-banner-icon v-if="$page.props.errors && Object.keys($page.props.errors).length > 0"
            theme="bg-red-500" iconName="close-circle" class="text-white mb-5">
            <div v-for="(err, key) in $page.props.errors" :key="key">{{ err }}</div>
        </ps-banner-icon>

        <ps-banner-icon v-if="$page.props.status"
            theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Codes Générés</div>
                <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total_codes }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-emerald-500">Codes Actifs</div>
                <div class="text-2xl font-bold text-emerald-600 mt-1">{{ stats.active_codes }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-blue-500">Total Parrainages</div>
                <div class="text-2xl font-bold text-blue-600 mt-1">{{ stats.total_referrals }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-purple-500">Commissions Créditées</div>
                <div class="text-2xl font-bold text-purple-600 mt-1">{{ formatNumber(stats.total_credited_dzd) }} DA</div>
            </div>
        </div>

        <!-- Commission Configuration -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-5 mb-6 shadow-sm">
            <h2 class="text-base font-bold text-secondary-800 dark:text-white mb-4">Configuration des Commissions (%)</h2>
            <form @submit.prevent="saveSettings" class="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
                <div>
                    <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                        Commission Émetteur (Wallet à la livraison) %
                    </label>
                    <input type="number" step="0.5" min="0" max="50" v-model.number="settingsForm.issuer_percentage" required
                        class="w-full px-3 py-2 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                        Réduction Filleul (À la commande) %
                    </label>
                    <input type="number" step="0.5" min="0" max="50" v-model.number="settingsForm.receiver_percentage" required
                        class="w-full px-3 py-2 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                </div>
                <div>
                    <button type="submit" :disabled="savingSettings"
                        class="w-full md:w-auto px-5 py-2.5 bg-primary-600 hover:bg-primary-700 text-white text-sm font-semibold rounded-lg shadow-sm transition-colors disabled:opacity-50">
                        {{ savingSettings ? 'Enregistrement...' : 'Enregistrer la Configuration' }}
                    </button>
                </div>
            </form>
        </div>

        <!-- Codes Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm mb-6">
            <div class="p-4 border-b border-gray-100 dark:border-secondary-700 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <h2 class="text-base font-bold text-secondary-800 dark:text-white">Codes de Parrainage</h2>
                <div class="flex items-center gap-2">
                    <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                        placeholder="Rechercher par code ou utilisateur..."
                        class="w-64 px-3 py-1.5 text-xs rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    <button type="button" @click="handleSearch"
                        class="px-3 py-1.5 bg-secondary-800 text-white text-xs font-semibold rounded-lg">
                        Rechercher
                    </button>
                </div>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Code</th>
                            <th class="px-5 py-3">Émetteur</th>
                            <th class="px-5 py-3 text-center">Utilisations</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!codes.data || codes.data.length === 0">
                            <td colspan="4" class="px-5 py-8 text-center text-secondary-400">
                                Aucun code de parrainage généré pour le moment.
                            </td>
                        </tr>
                        <tr v-for="c in codes.data" :key="c.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-900/50">
                            <td class="px-5 py-3 font-mono font-bold text-primary-600 dark:text-primary-400">
                                {{ c.code }}
                            </td>
                            <td class="px-5 py-3">
                                <div class="font-semibold text-secondary-800 dark:text-white">
                                    {{ c.issuer ? c.issuer.name : ('User #' + c.user_id) }}
                                </div>
                                <div class="text-xs text-secondary-400">{{ c.issuer ? c.issuer.email : '' }}</div>
                            </td>
                            <td class="px-5 py-3 text-center font-bold">{{ c.referrals_count || 0 }}</td>
                            <td class="px-5 py-3 text-center">
                                <button type="button" @click="toggleCode(c)"
                                    class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold transition-colors"
                                    :class="c.is_active ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'">
                                    {{ c.is_active ? 'Actif (Désactiver)' : 'Désactivé (Activer)' }}
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Referrals & Rewards Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="p-4 border-b border-gray-100 dark:border-secondary-700">
                <h2 class="text-base font-bold text-secondary-800 dark:text-white">Historique des Parrainages &amp; Récompenses</h2>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Code</th>
                            <th class="px-5 py-3">Émetteur</th>
                            <th class="px-5 py-3">Filleul</th>
                            <th class="px-5 py-3">Commande</th>
                            <th class="px-5 py-3">Réduction Filleul</th>
                            <th class="px-5 py-3">Commission Wallet</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!referrals || referrals.length === 0">
                            <td colspan="7" class="px-5 py-8 text-center text-secondary-400">
                                Aucun parrainage enregistré pour le moment.
                            </td>
                        </tr>
                        <tr v-for="ref in referrals" :key="ref.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-900/50">
                            <td class="px-5 py-3 font-mono font-bold text-primary-600">
                                {{ ref.affiliation_code ? ref.affiliation_code.code : '-' }}
                            </td>
                            <td class="px-5 py-3">{{ ref.issuer ? ref.issuer.name : ('#' + ref.issuer_user_id) }}</td>
                            <td class="px-5 py-3">{{ ref.receiver ? ref.receiver.name : ('#' + ref.receiver_user_id) }}</td>
                            <td class="px-5 py-3">
                                <div class="font-semibold">#{{ ref.order_code || ref.order_id }}</div>
                                <div class="text-xs text-secondary-400">{{ ref.order && ref.order.yalidine_parcel_status ? ref.order.yalidine_parcel_status : 'En cours' }}</div>
                            </td>
                            <td class="px-5 py-3">-{{ ref.receiver_discount_percent }}% ({{ formatNumber(ref.receiver_discount_amount) }} DA)</td>
                            <td class="px-5 py-3 font-bold text-emerald-600">
                                {{ ref.is_credited ? ('+' + formatNumber(ref.issuer_commission_amount) + ' DA') : (ref.issuer_commission_percent + '% en attente') }}
                            </td>
                            <td class="px-5 py-3 text-center">
                                <span v-if="ref.is_credited" class="inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                                    Crédité
                                </span>
                                <span v-else class="inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
                                    En attente livraison
                                </span>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </ps-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import PsLayout from '@/Components/PsLayout.vue';
import PsBannerIcon from '@/Components/Core/Banners/PsBannerIcon.vue';

export default defineComponent({
    name: 'AdminAffiliationIndex',
    components: { Head, PsLayout, PsBannerIcon },
    layout: PsLayout,
    props: {
        settings: Object,
        codes: Object,
        referrals: Array,
        stats: Object,
        filters: Object,
    },
    setup(props) {
        const searchQuery = ref(props.filters?.search || '');
        const savingSettings = ref(false);
        const settingsForm = ref({
            issuer_percentage: props.settings?.issuer_percentage ?? 10,
            receiver_percentage: props.settings?.receiver_percentage ?? 10,
        });

        const saveSettings = () => {
            savingSettings.value = true;
            router.post(route('admin.affiliation.settings'), settingsForm.value, {
                preserveScroll: true,
                onFinish: () => {
                    savingSettings.value = false;
                },
            });
        };

        const toggleCode = (codeObj) => {
            router.post(route('admin.affiliation.toggle', codeObj.id), {}, {
                preserveScroll: true,
            });
        };

        const handleSearch = () => {
            router.get(route('admin.affiliation.index'), {
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const formatNumber = (num) => {
            if (num === null || num === undefined) return '0';
            return Number(num).toLocaleString('fr-FR');
        };

        return {
            searchQuery,
            savingSettings,
            settingsForm,
            saveSettings,
            toggleCode,
            handleSearch,
            formatNumber,
        };
    },
});
</script>
