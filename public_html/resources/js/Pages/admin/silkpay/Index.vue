<template>
    <Head title="Paiement Silk Pay (CIB / Edahabia)" />
    <ps-layout>
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                Paiement Silk Pay — Rechargement Wallet (CIB / Edahabia)
            </h1>
            <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                Configurez les packs de rechargement (1 000 à 6 000 DA), les liens Silk Pay et suivez les transactions.
            </p>
        </div>

        <ps-banner-icon v-if="$page.props.status" theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-secondary-500">Total Transactions</div>
                <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-emerald-500">Créditées</div>
                <div class="text-2xl font-bold text-emerald-600 mt-1">{{ stats.credited }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-amber-500">En attente</div>
                <div class="text-2xl font-bold text-amber-600 mt-1">{{ stats.pending }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-blue-500">Total Crédité</div>
                <div class="text-2xl font-bold text-blue-600 mt-1">{{ formatNumber(stats.total_credited_dzd) }} DA</div>
            </div>
        </div>

        <!-- Webhook & API Config -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-5 mb-6 shadow-sm">
            <h2 class="text-base font-bold text-secondary-800 dark:text-white mb-3">Configuration Webhook &amp; API Silk Pay</h2>
            <div class="mb-4 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                <div class="text-xs text-blue-900 dark:text-blue-200">
                    <strong>Webhook Callback URL (POST) :</strong>
                    <span class="font-mono ml-1">{{ webhookUrl }}</span>
                </div>
                <button type="button" @click="copyWebhook"
                    class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg">
                    Copier l'URL
                </button>
            </div>
            <form @submit.prevent="saveSettings" class="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
                <div>
                    <label class="block text-xs font-bold uppercase mb-1">Webhook Secret</label>
                    <input type="text" v-model="settingsForm.webhook_secret" placeholder="Secret HMAC Silk Pay"
                        class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                </div>
                <div>
                    <label class="block text-xs font-bold uppercase mb-1">Clé API Silk Pay</label>
                    <input type="text" v-model="settingsForm.api_key" placeholder="Clé API optionnelle"
                        class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                </div>
                <div class="flex items-center justify-between gap-3">
                    <label class="flex items-center gap-2 text-sm font-semibold cursor-pointer">
                        <input type="checkbox" v-model="settingsForm.is_active" class="w-4 h-4 text-primary-600 rounded" />
                        <span>Actif</span>
                    </label>
                    <button type="submit" class="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg">
                        Enregistrer
                    </button>
                </div>
            </form>
        </div>

        <!-- Top-Up Packs -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-5 mb-6 shadow-sm">
            <h2 class="text-base font-bold text-secondary-800 dark:text-white mb-4">Packs de Rechargement &amp; Liens Silk Pay</h2>
            <div class="space-y-4">
                <div v-for="pack in packForms" :key="pack.id"
                    class="p-4 rounded-xl border border-gray-200 dark:border-secondary-700 bg-gray-50/50 dark:bg-secondary-900/50 grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
                    <div class="md:col-span-2">
                        <label class="block text-[11px] font-bold uppercase mb-1">Montant (DA)</label>
                        <input type="number" step="1" min="100" v-model.number="pack.amount_dzd"
                            class="w-full px-3 py-2 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div class="md:col-span-3">
                        <label class="block text-[11px] font-bold uppercase mb-1">Titre du Pack</label>
                        <input type="text" v-model="pack.title"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div class="md:col-span-5">
                        <label class="block text-[11px] font-bold uppercase mb-1">Lien de Paiement Silk Pay (URL)</label>
                        <input type="url" v-model="pack.payment_url" placeholder="https://silkpay.dz/pay/..."
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div class="md:col-span-2 flex items-center justify-end gap-2">
                        <button type="button" @click="togglePack(pack)"
                            class="px-2.5 py-2 text-xs font-semibold rounded-lg"
                            :class="pack.is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-200 text-gray-600'">
                            {{ pack.is_active ? 'Actif' : 'Inactif' }}
                        </button>
                        <button type="button" @click="savePack(pack)"
                            class="px-3 py-2 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg">
                            Sauver
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Transactions Log -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="p-4 border-b border-gray-100 dark:border-secondary-700 flex flex-wrap items-center justify-between gap-3">
                <h2 class="text-base font-bold text-secondary-800 dark:text-white">Journal des Transactions Silk Pay</h2>
                <div class="flex items-center gap-2">
                    <button v-for="st in ['all', 'pending', 'credited', 'canceled']" :key="st" type="button"
                        @click="filterStatus(st)"
                        class="px-3 py-1 text-xs font-semibold rounded-lg"
                        :class="filters.status === st ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-200'">
                        {{ st === 'all' ? 'Toutes' : st }}
                    </button>
                </div>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Référence</th>
                            <th class="px-5 py-3">Utilisateur</th>
                            <th class="px-5 py-3">Pack</th>
                            <th class="px-5 py-3">Montant</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                            <th class="px-5 py-3">Date</th>
                            <th class="px-5 py-3 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!transactions.data || transactions.data.length === 0">
                            <td colspan="7" class="px-5 py-8 text-center text-secondary-400">Aucune transaction enregistrée.</td>
                        </tr>
                        <tr v-for="tx in transactions.data" :key="tx.id">
                            <td class="px-5 py-3 font-mono font-bold text-xs text-primary-600">#{{ tx.id }} • {{ tx.reference }}</td>
                            <td class="px-5 py-3 text-xs">{{ tx.user ? tx.user.name : ('User #' + tx.user_id) }}</td>
                            <td class="px-5 py-3 text-xs">{{ tx.pack ? tx.pack.title : '-' }}</td>
                            <td class="px-5 py-3 font-bold">{{ formatNumber(tx.amount_dzd) }} DA</td>
                            <td class="px-5 py-3 text-center">
                                <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold"
                                    :class="tx.status === 'credited' ? 'bg-emerald-100 text-emerald-800' : (tx.status === 'canceled' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-800')">
                                    {{ tx.status }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-xs">{{ formatDate(tx.created_at) }}</td>
                            <td class="px-5 py-3 text-right">
                                <div v-if="tx.status === 'pending'" class="flex items-center justify-end gap-2">
                                    <button type="button" @click="markCredited(tx.id)"
                                        class="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded">
                                        Créditer
                                    </button>
                                    <button type="button" @click="cancelTx(tx.id)"
                                        class="px-2.5 py-1 bg-red-600 hover:bg-red-700 text-white text-xs font-semibold rounded">
                                        Annuler
                                    </button>
                                </div>
                                <span v-else class="text-xs text-secondary-400">-</span>
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
    name: 'AdminSilkpayIndex',
    components: { Head, PsLayout, PsBannerIcon },
    layout: PsLayout,
    props: {
        settings: Object,
        packs: Array,
        transactions: Object,
        stats: Object,
        webhookUrl: String,
        filters: Object,
    },
    setup(props) {
        const settingsForm = ref({
            webhook_secret: props.settings?.webhook_secret || '',
            api_key: props.settings?.api_key || '',
            is_active: Boolean(props.settings?.is_active ?? true),
        });
        const packForms = ref((props.packs || []).map((p) => ({ ...p, is_active: Boolean(p.is_active) })));

        const copyWebhook = () => {
            if (navigator.clipboard) {
                navigator.clipboard.writeText(props.webhookUrl);
                alert('Webhook URL copiée !');
            }
        };
        const saveSettings = () => {
            router.post(route('admin.silkpay.settings'), settingsForm.value, { preserveScroll: true });
        };
        const savePack = (pack) => {
            router.put(route('admin.silkpay.packs.update', pack.id), pack, { preserveScroll: true });
        };
        const togglePack = (pack) => {
            router.post(route('admin.silkpay.packs.toggle', pack.id), {}, {
                preserveScroll: true,
                onSuccess: () => { pack.is_active = !pack.is_active; },
            });
        };
        const markCredited = (id) => {
            if (confirm('Créditer manuellement cette transaction ?')) {
                router.post(route('admin.silkpay.tx.credit', id), {}, { preserveScroll: true });
            }
        };
        const cancelTx = (id) => {
            if (confirm('Annuler cette transaction ?')) {
                router.post(route('admin.silkpay.tx.cancel', id), {}, { preserveScroll: true });
            }
        };
        const filterStatus = (st) => {
            router.get(route('admin.silkpay.index'), { status: st }, { preserveState: true, replace: true });
        };
        const formatNumber = (n) => Number(n || 0).toLocaleString('fr-FR');
        const formatDate = (d) => d ? new Date(d).toLocaleString('fr-FR') : '';

        return {
            settingsForm, packForms, copyWebhook, saveSettings, savePack, togglePack,
            markCredited, cancelTx, filterStatus, formatNumber, formatDate,
        };
    },
});
</script>
