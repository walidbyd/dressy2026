<template>
    <Head :title="$t('dressy_disputes_module') || 'Gestion des Litiges'" />
    <ps-layout>
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    Gestion des Litiges (Disputes)
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Litiges ouverts par les acheteurs dans les 7 jours suivant la livraison.
                </p>
            </div>
        </div>

        <ps-banner-icon v-if="$page.props.status"
            theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-secondary-500">Total Litiges</div>
                <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-amber-500">Ouverts / En examen</div>
                <div class="text-2xl font-bold text-amber-600 mt-1">{{ stats.open }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-emerald-500">Résolus / Clôturés</div>
                <div class="text-2xl font-bold text-emerald-600 mt-1">{{ stats.resolved }}</div>
            </div>
        </div>

        <!-- Filters -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-4 mb-6 shadow-sm flex flex-wrap items-center justify-between gap-3">
            <div class="flex flex-wrap items-center gap-2">
                <button v-for="st in ['all', 'open', 'under_review', 'resolved_buyer', 'resolved_vendor', 'closed']" :key="st"
                    type="button" @click="filterStatus(st)"
                    class="px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors"
                    :class="filters.status === st ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-200'">
                    {{ statusLabel(st) }}
                </button>
            </div>
            <div class="flex items-center gap-2">
                <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                    placeholder="Rechercher #commande ou motif..."
                    class="w-60 px-3 py-1.5 text-xs rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                <button type="button" @click="handleSearch"
                    class="px-3 py-1.5 bg-secondary-800 text-white text-xs font-semibold rounded-lg">
                    Rechercher
                </button>
            </div>
        </div>

        <!-- Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Commande</th>
                            <th class="px-5 py-3">Acheteur</th>
                            <th class="px-5 py-3">Vendeur</th>
                            <th class="px-5 py-3">Motif &amp; Détails</th>
                            <th class="px-5 py-3">Dernier Message Chat</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                            <th class="px-5 py-3 text-right">Décision</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!disputes.data || disputes.data.length === 0">
                            <td colspan="7" class="px-5 py-8 text-center text-secondary-400">
                                Aucun litige trouvé.
                            </td>
                        </tr>
                        <tr v-for="d in disputes.data" :key="d.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-900/50">
                            <td class="px-5 py-3 font-bold text-secondary-900 dark:text-white">
                                #{{ d.order_code || d.order_id }}
                                <div class="text-xs text-secondary-400 font-normal">
                                    {{ d.order ? (Number(d.order.total_price).toLocaleString('fr-FR') + ' DA') : '' }}
                                </div>
                            </td>
                            <td class="px-5 py-3 text-xs">
                                <div class="font-semibold text-secondary-800 dark:text-white">{{ d.buyer ? d.buyer.name : ('#' + d.buyer_user_id) }}</div>
                                <div class="text-secondary-400">{{ d.buyer ? d.buyer.user_phone : '' }}</div>
                            </td>
                            <td class="px-5 py-3 text-xs">
                                <div class="font-semibold text-secondary-800 dark:text-white">{{ d.vendor ? d.vendor.name : (d.seller ? d.seller.name : '-') }}</div>
                                <div class="text-secondary-400">{{ d.seller ? d.seller.user_phone : '' }}</div>
                            </td>
                            <td class="px-5 py-3 max-w-xs">
                                <div class="text-xs font-bold text-red-600">{{ typeLabel(d.dispute_type) }}</div>
                                <div class="text-xs text-secondary-600 dark:text-secondary-300 mt-0.5 line-clamp-3">{{ d.description }}</div>
                                <div v-if="d.admin_note" class="text-[11px] text-primary-600 mt-1">Note: {{ d.admin_note }}</div>
                            </td>
                            <td class="px-5 py-3 text-xs max-w-xs text-secondary-500">
                                {{ d.latest_chat_message || 'Aucun message' }}
                            </td>
                            <td class="px-5 py-3 text-center">
                                <span class="inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold"
                                    :class="statusBadgeClass(d.status)">
                                    {{ statusLabel(d.status) }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-right">
                                <button type="button" @click="openDecisionModal(d)"
                                    class="px-3 py-1.5 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg">
                                    Décider
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Decision Modal -->
        <jet-dialog-modal :show="showModal" @close="showModal = false">
            <template #title>
                <div class="font-bold text-lg text-secondary-800 dark:text-white">
                    Décision Litige #{{ selectedDispute?.id }} (Commande #{{ selectedDispute?.order_code }})
                </div>
            </template>
            <template #content>
                <div class="space-y-4">
                    <div class="p-3 rounded-lg bg-gray-50 dark:bg-secondary-900 text-xs space-y-1">
                        <div><strong>Motif :</strong> {{ typeLabel(selectedDispute?.dispute_type) }}</div>
                        <div><strong>Explication acheteur :</strong> {{ selectedDispute?.description }}</div>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase mb-1">Décision / Statut</label>
                        <select v-model="decisionForm.status"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white">
                            <option value="under_review">En cours d'examen</option>
                            <option value="resolved_buyer">Résolu en faveur de l'acheteur (Retour / Remboursement)</option>
                            <option value="resolved_vendor">Résolu en faveur du vendeur</option>
                            <option value="closed">Clôturé</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase mb-1">Note de l'administration</label>
                        <textarea v-model="decisionForm.admin_note" rows="3"
                            placeholder="Expliquez la décision (visible dans le fil de discussion de la commande)..."
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white"></textarea>
                    </div>
                </div>
            </template>
            <template #footer>
                <div class="flex items-center justify-end gap-2">
                    <button type="button" @click="showModal = false"
                        class="px-4 py-2 bg-gray-200 text-secondary-800 text-xs font-semibold rounded-lg">
                        Annuler
                    </button>
                    <button type="button" @click="submitDecision" :disabled="submitting"
                        class="px-4 py-2 bg-primary-600 text-white text-xs font-semibold rounded-lg disabled:opacity-50">
                        {{ submitting ? 'Enregistrement...' : 'Enregistrer la décision' }}
                    </button>
                </div>
            </template>
        </jet-dialog-modal>
    </ps-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import PsLayout from '@/Components/PsLayout.vue';
import PsBannerIcon from '@/Components/Core/Banners/PsBannerIcon.vue';
import JetDialogModal from '@/Jetstream/DialogModal.vue';

export default defineComponent({
    name: 'AdminDisputesIndex',
    components: { Head, PsLayout, PsBannerIcon, JetDialogModal },
    layout: PsLayout,
    props: {
        disputes: Object,
        stats: Object,
        filters: Object,
    },
    setup(props) {
        const searchQuery = ref(props.filters?.search || '');
        const showModal = ref(false);
        const submitting = ref(false);
        const selectedDispute = ref(null);
        const decisionForm = ref({ status: 'under_review', admin_note: '' });

        const statusLabel = (s) => ({
            all: 'Tous',
            open: 'Ouvert',
            under_review: 'En examen',
            resolved_buyer: 'Faveur Acheteur',
            resolved_vendor: 'Faveur Vendeur',
            closed: 'Clôturé',
        }[s] || s);

        const typeLabel = (t) => ({
            not_as_described: 'Non conforme',
            damaged_defective: 'Endommagé / Défectueux',
            wrong_item: 'Mauvais article',
            missing_item: 'Article manquant',
            return_request: 'Demande de retour',
            other: 'Autre',
        }[t] || t);

        const statusBadgeClass = (s) => {
            if (s === 'open') return 'bg-red-100 text-red-700';
            if (s === 'under_review') return 'bg-amber-100 text-amber-800';
            if (s === 'resolved_buyer' || s === 'resolved_vendor') return 'bg-emerald-100 text-emerald-800';
            return 'bg-gray-100 text-gray-700';
        };

        const filterStatus = (st) => {
            router.get(route('admin.disputes.index'), { status: st, search: searchQuery.value }, { preserveState: true, replace: true });
        };

        const handleSearch = () => {
            router.get(route('admin.disputes.index'), { status: props.filters?.status || 'all', search: searchQuery.value }, { preserveState: true, replace: true });
        };

        const openDecisionModal = (d) => {
            selectedDispute.value = d;
            decisionForm.value = { status: d.status === 'open' ? 'under_review' : d.status, admin_note: d.admin_note || '' };
            showModal.value = true;
        };

        const submitDecision = () => {
            if (!selectedDispute.value || submitting.value) return;
            submitting.value = true;
            router.post(route('admin.disputes.updateStatus', selectedDispute.value.id), decisionForm.value, {
                preserveScroll: true,
                onSuccess: () => { showModal.value = false; },
                onFinish: () => { submitting.value = false; },
            });
        };

        return {
            searchQuery, showModal, submitting, selectedDispute, decisionForm,
            statusLabel, typeLabel, statusBadgeClass, filterStatus, handleSearch,
            openDecisionModal, submitDecision,
        };
    },
});
</script>
