<template>
    <Head :title="$t('dressy_coupons_module') || 'Coupons & Remises'" />
    <ps-layout>
        <!-- Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white">
                    {{ $t('dressy_coupons_title') || 'Gestion des Coupons & Roue de la Fortune' }}
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Créez des codes promo personnalisés, configurez les remises (5%, 10% ou montant fixe DA) et suivez les récompenses de la Roulette 24h.
                </p>
            </div>
            <div class="flex items-center gap-3">
                <button type="button" @click="openCreateModal"
                    class="inline-flex items-center gap-2 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-sm font-semibold rounded-lg shadow-sm transition-colors">
                    <ps-icon name="plus" w="18" h="18" />
                    <span>Créer un Coupon</span>
                </button>
            </div>
        </div>

        <!-- Banner alerts -->
        <ps-banner-icon v-if="$page.props.errors && Object.keys($page.props.errors).length > 0"
            theme="bg-red-500" iconName="close-circle" class="text-white mb-5">
            <div v-for="(err, key) in $page.props.errors" :key="key">{{ err }}</div>
        </ps-banner-icon>

        <ps-banner-icon v-if="$page.props.status"
            theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ typeof $page.props.status === 'object' && $page.props.status !== null ? $page.props.status.msg : $page.props.status }}
        </ps-banner-icon>

        <!-- Stats Overview Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Total Coupons</div>
                        <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total }}</div>
                    </div>
                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-xl">
                        <ps-icon name="cash" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Créés sur la plateforme</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Coupons Actifs</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ stats.active }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Prêts pour le paiement</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-purple-500 dark:text-purple-400">Total Utilisations</div>
                        <div class="text-2xl font-bold text-purple-600 dark:text-purple-400 mt-1">{{ stats.total_usages }}</div>
                    </div>
                    <div class="p-3 bg-purple-50 dark:bg-purple-900/20 text-purple-600 rounded-xl">
                        <ps-icon name="chart-line" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Commandes avec réduction</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">Gagnés via Roulette</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ stats.roulette }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="refresh" w="24" h="24" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Attribués aux utilisateurs (24h)</div>
            </div>
        </div>

        <!-- Filter & Search Section -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-4 mb-6 shadow-sm">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div class="flex flex-wrap items-center gap-2">
                    <span class="text-xs font-semibold text-secondary-500 uppercase mr-1">Source :</span>
                    <button type="button" @click="filterBySource('all')"
                        class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
                        :class="filters.source === 'all' ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                        Tous
                    </button>
                    <button type="button" @click="filterBySource('admin')"
                        class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
                        :class="filters.source === 'admin' ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                        Admin Manuel
                    </button>
                    <button type="button" @click="filterBySource('roulette')"
                        class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
                        :class="filters.source === 'roulette' ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'">
                        🎡 Roulette 24h
                    </button>
                </div>

                <div class="flex items-center gap-2">
                    <div class="relative w-64">
                        <input type="text" v-model="searchQuery" @keyup.enter="handleSearch"
                            placeholder="Rechercher par code..."
                            class="w-full pl-9 pr-3 py-2 text-xs rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                            <ps-icon name="search" w="14" h="14" />
                        </div>
                    </div>
                    <button type="button" @click="handleSearch"
                        class="px-3 py-2 bg-secondary-800 dark:bg-secondary-700 hover:bg-secondary-900 text-white text-xs font-medium rounded-lg transition-colors">
                        Filtrer
                    </button>
                </div>
            </div>
        </div>

        <!-- Coupons Table -->
        <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 overflow-hidden shadow-sm mb-6">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-secondary-600 dark:text-secondary-300">
                    <thead class="text-xs uppercase bg-gray-50 dark:bg-secondary-900 text-secondary-500 dark:text-secondary-400 border-b border-gray-100 dark:border-secondary-700">
                        <tr>
                            <th class="px-5 py-3">Code Coupon</th>
                            <th class="px-5 py-3">Réduction</th>
                            <th class="px-5 py-3">Commande Min</th>
                            <th class="px-5 py-3">Utilisations</th>
                            <th class="px-5 py-3">Source</th>
                            <th class="px-5 py-3">Validité</th>
                            <th class="px-5 py-3 text-center">Statut</th>
                            <th class="px-5 py-3 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                        <tr v-if="!coupons.data || coupons.data.length === 0">
                            <td colspan="8" class="px-5 py-8 text-center text-secondary-400">
                                Aucun coupon trouvé. Cliquez sur "Créer un Coupon" pour en ajouter un.
                            </td>
                        </tr>
                        <tr v-for="coupon in coupons.data" :key="coupon.id" class="hover:bg-gray-50/50 dark:hover:bg-secondary-900/50 transition-colors">
                            <!-- Code -->
                            <td class="px-5 py-3 font-medium text-secondary-900 dark:text-white">
                                <div class="flex items-center gap-2">
                                    <span class="font-mono font-bold tracking-wider text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/30 px-2.5 py-1 rounded border border-primary-200 dark:border-primary-800">
                                        {{ coupon.code }}
                                    </span>
                                    <button type="button" @click="copyCode(coupon.code)" title="Copier le code"
                                        class="p-1 text-gray-400 hover:text-primary-600 rounded transition-colors">
                                        <ps-icon name="copy" w="14" h="14" />
                                    </button>
                                </div>
                            </td>

                            <!-- Discount -->
                            <td class="px-5 py-3 font-semibold text-secondary-800 dark:text-white">
                                <span v-if="coupon.discount_type === 'percentage'" class="text-emerald-600 dark:text-emerald-400 font-bold">
                                    -{{ coupon.discount_value }}%
                                </span>
                                <span v-else class="text-blue-600 dark:text-blue-400 font-bold">
                                    -{{ formatNumber(coupon.discount_value) }} DA
                                </span>
                            </td>

                            <!-- Min Order -->
                            <td class="px-5 py-3">
                                <span v-if="coupon.min_order_amount && coupon.min_order_amount > 0">
                                    {{ formatNumber(coupon.min_order_amount) }} DA
                                </span>
                                <span v-else class="text-secondary-400 text-xs">Aucun minimum</span>
                            </td>

                            <!-- Usages -->
                            <td class="px-5 py-3">
                                <div class="flex items-center gap-1.5">
                                    <span class="font-bold text-secondary-800 dark:text-white">{{ coupon.usages_count || 0 }}</span>
                                    <span class="text-secondary-400 text-xs">/ {{ coupon.max_uses ? coupon.max_uses : '∞' }}</span>
                                </div>
                                <div v-if="coupon.max_uses" class="w-20 bg-gray-200 dark:bg-secondary-700 h-1.5 rounded-full mt-1 overflow-hidden">
                                    <div class="bg-primary-500 h-full rounded-full"
                                        :style="{ width: Math.min(100, Math.round(((coupon.usages_count || 0) / coupon.max_uses) * 100)) + '%' }">
                                    </div>
                                </div>
                            </td>

                            <!-- Source -->
                            <td class="px-5 py-3">
                                <span v-if="coupon.source === 'roulette'" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                                    🎡 Roulette 24h
                                </span>
                                <span v-else class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                                    Admin
                                </span>
                            </td>

                            <!-- Expiry -->
                            <td class="px-5 py-3 text-xs">
                                <div v-if="coupon.expires_at">
                                    <span :class="isExpired(coupon.expires_at) ? 'text-red-500 font-semibold' : 'text-secondary-600 dark:text-secondary-300'">
                                        {{ formatDate(coupon.expires_at) }}
                                    </span>
                                    <div v-if="isExpired(coupon.expires_at)" class="text-red-500 text-[10px] font-bold uppercase mt-0.5">Expiré</div>
                                </div>
                                <span v-else class="text-secondary-400">Illimité</span>
                            </td>

                            <!-- Status Toggle -->
                            <td class="px-5 py-3 text-center">
                                <button type="button" @click="toggleStatus(coupon)"
                                    class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold transition-colors"
                                    :class="coupon.is_active ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400 hover:bg-emerald-200' : 'bg-gray-100 text-gray-600 dark:bg-secondary-700 dark:text-gray-400 hover:bg-gray-200'">
                                    <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="coupon.is_active ? 'bg-emerald-500' : 'bg-gray-400'"></span>
                                    {{ coupon.is_active ? 'Actif' : 'Inactif' }}
                                </button>
                            </td>

                            <!-- Actions -->
                            <td class="px-5 py-3 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <button type="button" @click="openEditModal(coupon)"
                                        class="p-1.5 text-gray-500 hover:text-blue-600 dark:hover:text-blue-400 rounded-lg hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                                        title="Modifier">
                                        <ps-icon name="edit" w="16" h="16" />
                                    </button>
                                    <button type="button" @click="deleteCoupon(coupon)"
                                        class="p-1.5 text-gray-500 hover:text-red-600 dark:hover:text-red-400 rounded-lg hover:bg-gray-100 dark:hover:bg-secondary-700 transition-colors"
                                        title="Supprimer">
                                        <ps-icon name="trash" w="16" h="16" />
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div v-if="coupons.links && coupons.links.length > 3" class="px-5 py-4 border-t border-gray-100 dark:border-secondary-700 flex items-center justify-between">
                <div class="text-xs text-secondary-500">
                    Affichage de {{ coupons.from || 0 }} à {{ coupons.to || 0 }} sur {{ coupons.total || 0 }} coupons
                </div>
                <div class="flex items-center gap-1">
                    <template v-for="(link, key) in coupons.links" :key="key">
                        <Link v-if="link.url" :href="link.url"
                            class="px-3 py-1 text-xs rounded-md transition-colors"
                            :class="link.active ? 'bg-primary-600 text-white font-bold' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 hover:bg-gray-200'"
                            v-html="link.label" />
                        <span v-else class="px-3 py-1 text-xs text-secondary-400" v-html="link.label" />
                    </template>
                </div>
            </div>
        </div>

        <!-- Create / Edit Modal -->
        <jet-dialog-modal :show="showModal" @close="closeModal">
            <template #title>
                <div class="font-bold text-lg text-secondary-800 dark:text-white">
                    {{ isEditing ? 'Modifier le Coupon #' + editingCouponId : 'Créer un Nouveau Coupon' }}
                </div>
            </template>

            <template #content>
                <form @submit.prevent="submitForm" class="space-y-4">
                    <!-- Code & Generate Button -->
                    <div>
                        <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                            Code Promo *
                        </label>
                        <div class="flex items-center gap-2">
                            <input type="text" v-model="form.code" required uppercase
                                placeholder="EX: DRESSY10"
                                class="flex-1 px-3 py-2 text-sm uppercase font-mono font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                            <button type="button" @click="generateNewCode"
                                class="px-3 py-2 bg-gray-100 dark:bg-secondary-700 hover:bg-gray-200 dark:hover:bg-secondary-600 text-secondary-700 dark:text-secondary-200 text-xs font-semibold rounded-lg transition-colors whitespace-nowrap">
                                🎲 Générer un code
                            </button>
                        </div>
                    </div>

                    <!-- Discount Type & Presets -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                                Type de Remise *
                            </label>
                            <select v-model="form.discount_type" required
                                class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500">
                                <option value="percentage">Pourcentage (%)</option>
                                <option value="fixed_amount">Montant fixe (DA)</option>
                            </select>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                                Valeur de Remise *
                            </label>
                            <div class="relative">
                                <input type="number" step="0.01" min="0.01" v-model.number="form.discount_value" required
                                    class="w-full px-3 py-2 pr-10 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                                <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-xs font-bold text-gray-500">
                                    {{ form.discount_type === 'percentage' ? '%' : 'DA' }}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Percentage Presets -->
                    <div v-if="form.discount_type === 'percentage'" class="flex items-center gap-2 pt-1">
                        <span class="text-xs text-secondary-400">Préréglages rapides :</span>
                        <button type="button" @click="form.discount_value = 5"
                            class="px-2.5 py-1 text-xs rounded font-semibold transition-colors"
                            :class="form.discount_value == 5 ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-600 hover:bg-gray-200'">
                            5%
                        </button>
                        <button type="button" @click="form.discount_value = 10"
                            class="px-2.5 py-1 text-xs rounded font-semibold transition-colors"
                            :class="form.discount_value == 10 ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-600 hover:bg-gray-200'">
                            10%
                        </button>
                        <button type="button" @click="form.discount_value = 15"
                            class="px-2.5 py-1 text-xs rounded font-semibold transition-colors"
                            :class="form.discount_value == 15 ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-600 hover:bg-gray-200'">
                            15%
                        </button>
                        <button type="button" @click="form.discount_value = 20"
                            class="px-2.5 py-1 text-xs rounded font-semibold transition-colors"
                            :class="form.discount_value == 20 ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-secondary-700 text-secondary-600 hover:bg-gray-200'">
                            20%
                        </button>
                    </div>

                    <!-- Min Order Amount -->
                    <div>
                        <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                            Montant Minimum de Commande (Optionnel)
                        </label>
                        <div class="relative">
                            <input type="number" step="1" min="0" v-model.number="form.min_order_amount"
                                placeholder="0 = Pas de minimum requis"
                                class="w-full px-3 py-2 pr-10 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                            <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-xs font-bold text-gray-500">
                                DA
                            </div>
                        </div>
                    </div>

                    <!-- Usage Limits -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                                Limite Totale d'Utilisations
                            </label>
                            <input type="number" min="1" v-model.number="form.max_uses"
                                placeholder="Vide = Illimité"
                                class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        </div>
                        <div>
                            <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                                Limite par Utilisateur
                            </label>
                            <input type="number" min="1" v-model.number="form.max_uses_per_user"
                                placeholder="1 par défaut"
                                class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        </div>
                    </div>

                    <!-- Expiration Date -->
                    <div>
                        <label class="block text-xs font-bold text-secondary-700 dark:text-secondary-200 uppercase mb-1">
                            Date & Heure d'Expiration (Optionnel)
                        </label>
                        <input type="datetime-local" v-model="form.expires_at"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <p class="text-[11px] text-secondary-400 mt-1">Laissez vide pour un coupon sans date d'expiration.</p>
                    </div>

                    <!-- Active Toggle -->
                    <div class="flex items-center gap-2 pt-2">
                        <input type="checkbox" id="coupon_active" v-model="form.is_active"
                            class="w-4 h-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500" />
                        <label for="coupon_active" class="text-sm font-semibold text-secondary-700 dark:text-secondary-300 cursor-pointer">
                            Activer ce coupon immédiatement
                        </label>
                    </div>
                </form>
            </template>

            <template #footer>
                <div class="flex items-center justify-end gap-3">
                    <button type="button" @click="closeModal"
                        class="px-4 py-2 bg-gray-200 dark:bg-secondary-700 hover:bg-gray-300 dark:hover:bg-secondary-600 text-secondary-800 dark:text-white text-xs font-semibold rounded-lg transition-colors">
                        Annuler
                    </button>
                    <button type="button" @click="submitForm" :disabled="submitting"
                        class="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-xs font-semibold rounded-lg shadow-sm transition-colors disabled:opacity-50">
                        {{ submitting ? 'Enregistrement...' : (isEditing ? 'Mettre à jour' : 'Créer le Coupon') }}
                    </button>
                </div>
            </template>
        </jet-dialog-modal>
    </ps-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import axios from 'axios';
import PsLayout from "@/Components/PsLayout.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsBannerIcon from "@/Components/Core/Banners/PsBannerIcon.vue";
import JetDialogModal from '@/Jetstream/DialogModal.vue';

export default defineComponent({
    name: "AdminCouponsIndex",
    components: {
        Head,
        Link,
        PsLayout,
        PsIcon,
        PsBannerIcon,
        JetDialogModal,
    },
    layout: PsLayout,
    props: {
        coupons: Object,
        filters: Object,
        stats: Object,
    },
    setup(props) {
        const searchQuery = ref(props.filters.search || '');
        const showModal = ref(false);
        const isEditing = ref(false);
        const editingCouponId = ref(null);
        const submitting = ref(false);

        const form = ref({
            code: '',
            discount_type: 'percentage',
            discount_value: 10,
            min_order_amount: null,
            max_uses: null,
            max_uses_per_user: 1,
            expires_at: '',
            is_active: true,
        });

        const resetForm = () => {
            form.value = {
                code: '',
                discount_type: 'percentage',
                discount_value: 10,
                min_order_amount: null,
                max_uses: null,
                max_uses_per_user: 1,
                expires_at: '',
                is_active: true,
            };
            isEditing.value = false;
            editingCouponId.value = null;
        };

        const openCreateModal = () => {
            resetForm();
            generateNewCode();
            showModal.value = true;
        };

        const openEditModal = (coupon) => {
            isEditing.value = true;
            editingCouponId.value = coupon.id;
            let formattedExpiry = '';
            if (coupon.expires_at) {
                const d = new Date(coupon.expires_at);
                formattedExpiry = d.toISOString().slice(0, 16);
            }
            form.value = {
                code: coupon.code,
                discount_type: coupon.discount_type,
                discount_value: coupon.discount_value,
                min_order_amount: coupon.min_order_amount,
                max_uses: coupon.max_uses,
                max_uses_per_user: coupon.max_uses_per_user || 1,
                expires_at: formattedExpiry,
                is_active: Boolean(coupon.is_active),
            };
            showModal.value = true;
        };

        const closeModal = () => {
            showModal.value = false;
            resetForm();
        };

        const generateNewCode = async () => {
            try {
                const res = await axios.get(route('admin.coupons.generateCode'));
                if (res.data && res.data.code) {
                    form.value.code = res.data.code;
                }
            } catch (e) {
                form.value.code = 'DRESSY' + Math.floor(1000 + Math.random() * 9000);
            }
        };

        const submitForm = () => {
            if (!form.value.code || submitting.value) return;

            submitting.value = true;
            const payload = {
                ...form.value,
                code: form.value.code.toUpperCase().trim(),
            };

            if (isEditing.value && editingCouponId.value) {
                router.put(route('admin.coupons.update', editingCouponId.value), payload, {
                    onSuccess: () => {
                        closeModal();
                    },
                    onFinish: () => {
                        submitting.value = false;
                    }
                });
            } else {
                router.post(route('admin.coupons.store'), payload, {
                    onSuccess: () => {
                        closeModal();
                    },
                    onFinish: () => {
                        submitting.value = false;
                    }
                });
            }
        };

        const toggleStatus = (coupon) => {
            router.post(route('admin.coupons.toggle', coupon.id), {}, {
                preserveScroll: true,
            });
        };

        const deleteCoupon = (coupon) => {
            if (!confirm(`Supprimer définitivement le coupon #${coupon.code} ?`)) return;

            router.delete(route('admin.coupons.destroy', coupon.id), {
                preserveScroll: true,
            });
        };

        const filterBySource = (source) => {
            router.get(route('admin.coupons.index'), {
                source: source,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const handleSearch = () => {
            router.get(route('admin.coupons.index'), {
                source: props.filters.source,
                search: searchQuery.value,
            }, { preserveState: true, replace: true });
        };

        const copyCode = (code) => {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(code);
                alert(`Code "${code}" copié dans le presse-papier !`);
            } else {
                prompt('Copiez le code :', code);
            }
        };

        const formatNumber = (num) => {
            if (num === null || num === undefined) return '0';
            return Number(num).toLocaleString('fr-FR');
        };

        const formatDate = (dateStr) => {
            if (!dateStr) return '';
            const d = new Date(dateStr);
            return d.toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
            });
        };

        const isExpired = (dateStr) => {
            if (!dateStr) return false;
            return new Date(dateStr).getTime() < Date.now();
        };

        return {
            searchQuery,
            showModal,
            isEditing,
            editingCouponId,
            submitting,
            form,
            openCreateModal,
            openEditModal,
            closeModal,
            generateNewCode,
            submitForm,
            toggleStatus,
            deleteCoupon,
            filterBySource,
            handleSearch,
            copyCode,
            formatNumber,
            formatDate,
            isExpired,
        };
    }
});
</script>
