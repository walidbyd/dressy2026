<template>
    <Head title="Ads / Publicité" />
    <ps-layout>
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                Ads / Publicité (Story Boost 24h &amp; Article Vitrine Sponsorisé)
            </h1>
            <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                Contrôlez dynamiquement les tarifs, textes promotionnels et l'activation du système Publicité sans modifier l'app mobile.
            </p>
        </div>

        <ps-banner-icon v-if="$page.props.status" theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-secondary-500">Total Boosts</div>
                <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total_boosts }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-emerald-500">Boosts Actifs</div>
                <div class="text-2xl font-bold text-emerald-600 mt-1">{{ stats.active_boosts }}</div>
            </div>
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="text-xs uppercase font-medium text-purple-500">Revenus Publicité (Wallet)</div>
                <div class="text-2xl font-bold text-purple-600 mt-1">{{ formatNumber(stats.total_revenue_dzd) }} DA</div>
            </div>
        </div>

        <!-- Master Switch & Story Boost Config -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-5 mb-6 shadow-sm">
            <h2 class="text-base font-bold text-secondary-800 dark:text-white mb-4">Paramètres Généraux &amp; Story Boost (24h)</h2>
            <form @submit.prevent="saveSettings" class="space-y-4">
                <div class="flex flex-wrap gap-6">
                    <label class="flex items-center gap-2 text-sm font-bold cursor-pointer">
                        <input type="checkbox" v-model="settingsForm.is_enabled" class="w-4 h-4 text-primary-600 rounded" />
                        <span>Activer tout le système Publicité / Boost dans l'App</span>
                    </label>
                    <label class="flex items-center gap-2 text-sm font-semibold cursor-pointer">
                        <input type="checkbox" v-model="settingsForm.story_boost_enabled" class="w-4 h-4 text-primary-600 rounded" />
                        <span>Activer Story Boost (24h)</span>
                    </label>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-xs font-bold uppercase mb-1">Prix Story Boost 24h (DA)</label>
                        <input type="number" step="1" min="0" v-model.number="settingsForm.story_boost_price_dzd" required
                            class="w-full px-3 py-2 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div class="md:col-span-2">
                        <label class="block text-xs font-bold uppercase mb-1">Titre Story Boost</label>
                        <input type="text" v-model="settingsForm.story_boost_title" required
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold uppercase mb-1">Description Promotionnelle Story Boost</label>
                    <textarea v-model="settingsForm.story_boost_description" rows="2"
                        class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white"></textarea>
                </div>

                <button type="submit" class="px-5 py-2 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg">
                    Enregistrer Paramètres Généraux &amp; Story Boost
                </button>
            </form>
        </div>

        <!-- Article / Vitrine Boost Plans (Daily / Weekly / Monthly) -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-5 mb-6 shadow-sm">
            <h2 class="text-base font-bold text-secondary-800 dark:text-white mb-4">Formules Boost Article Vitrine (1 Jour / 1 Semaine / 1 Mois)</h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div v-for="plan in planForms" :key="plan.id"
                    class="p-4 rounded-xl border border-gray-200 dark:border-secondary-700 bg-gray-50/50 dark:bg-secondary-900/50 space-y-3">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-bold uppercase px-2 py-0.5 rounded bg-primary-100 text-primary-700">
                            {{ plan.tier }} ({{ plan.duration_days }}j)
                        </span>
                        <button type="button" @click="togglePlan(plan)"
                            class="px-2.5 py-1 text-xs font-semibold rounded-full"
                            :class="plan.is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-200 text-gray-600'">
                            {{ plan.is_active ? 'Actif' : 'Désactivé' }}
                        </button>
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold uppercase mb-1">Titre</label>
                        <input type="text" v-model="plan.title"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold uppercase mb-1">Prix (DA)</label>
                        <input type="number" step="1" min="0" v-model.number="plan.price_dzd"
                            class="w-full px-3 py-2 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white" />
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold uppercase mb-1">Description</label>
                        <textarea v-model="plan.description" rows="2"
                            class="w-full px-3 py-2 text-xs rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-800 dark:text-white"></textarea>
                    </div>
                    <button type="button" @click="savePlan(plan)"
                        class="w-full py-2 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg">
                        Enregistrer {{ plan.title }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Active Boosts Monitor -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm">
            <div class="p-4 border-b border-gray-100 dark:border-secondary-700">
                <h2 class="text-base font-bold text-secondary-800 dark:text-white">Suivi des Boosts (Stories &amp; Articles)</h2>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Type / Cible</th>
                            <th class="px-5 py-3">Vendeur</th>
                            <th class="px-5 py-3">Formule</th>
                            <th class="px-5 py-3">Montant Payé</th>
                            <th class="px-5 py-3">Début</th>
                            <th class="px-5 py-3">Expiration</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!boosts.data || boosts.data.length === 0">
                            <td colspan="7" class="px-5 py-8 text-center text-secondary-400">Aucun boost enregistré.</td>
                        </tr>
                        <tr v-for="b in boosts.data" :key="b.id">
                            <td class="px-5 py-3 font-semibold">
                                {{ b.target_type === 'story' ? 'Story' : 'Article' }} #{{ b.target_id }}
                            </td>
                            <td class="px-5 py-3 text-xs">
                                {{ b.vendor ? b.vendor.name : (b.user ? b.user.name : ('User #' + b.user_id)) }}
                            </td>
                            <td class="px-5 py-3 text-xs font-mono">{{ b.plan_tier }}</td>
                            <td class="px-5 py-3 font-bold">{{ formatNumber(b.amount_paid_dzd) }} DA</td>
                            <td class="px-5 py-3 text-xs">{{ formatDate(b.starts_at) }}</td>
                            <td class="px-5 py-3 text-xs">{{ formatDate(b.expires_at) }}</td>
                            <td class="px-5 py-3 text-center">
                                <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold"
                                    :class="isBoostActive(b.expires_at) ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-600'">
                                    {{ isBoostActive(b.expires_at) ? 'Actif' : 'Expiré' }}
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
    name: 'AdminAdsIndex',
    components: { Head, PsLayout, PsBannerIcon },
    layout: PsLayout,
    props: {
        settings: Object,
        plans: Array,
        boosts: Object,
        stats: Object,
    },
    setup(props) {
        const settingsForm = ref({
            is_enabled: Boolean(props.settings?.is_enabled ?? true),
            story_boost_enabled: Boolean(props.settings?.story_boost_enabled ?? true),
            story_boost_price_dzd: props.settings?.story_boost_price_dzd ?? 300,
            story_boost_title: props.settings?.story_boost_title || 'Boost Story 24h',
            story_boost_description: props.settings?.story_boost_description || '',
        });
        const planForms = ref((props.plans || []).map((p) => ({ ...p, is_active: Boolean(p.is_active) })));

        const saveSettings = () => {
            router.post(route('admin.ads.settings'), settingsForm.value, { preserveScroll: true });
        };
        const savePlan = (plan) => {
            router.put(route('admin.ads.plans.update', plan.id), plan, { preserveScroll: true });
        };
        const togglePlan = (plan) => {
            router.post(route('admin.ads.plans.toggle', plan.id), {}, {
                preserveScroll: true,
                onSuccess: () => { plan.is_active = !plan.is_active; },
            });
        };
        const isBoostActive = (exp) => exp && new Date(exp).getTime() > Date.now();
        const formatNumber = (n) => Number(n || 0).toLocaleString('fr-FR');
        const formatDate = (d) => d ? new Date(d).toLocaleString('fr-FR') : '';

        return {
            settingsForm, planForms, saveSettings, savePlan, togglePlan,
            isBoostActive, formatNumber, formatDate,
        };
    },
});
</script>
