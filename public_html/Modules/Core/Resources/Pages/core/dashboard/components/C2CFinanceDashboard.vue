<template>
  <div class="mb-8 space-y-6">
    <!-- Omni-Search Bar Section -->
    <div class="relative bg-white dark:bg-secondary-900 rounded-xl shadow-sm border border-secondary-200 dark:border-secondary-800 p-4">
      <div class="flex items-center gap-3">
        <div class="text-primary-500">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <div class="relative flex-1">
          <input
            v-model="searchQuery"
            @input="handleOmniSearchInput"
            @focus="showDropdown = true"
            type="text"
            placeholder="Omni-Search Dressy: Rechercher utilisateur, n° commande, suivi Yalidine, transaction..."
            class="w-full bg-secondary-50 dark:bg-secondary-800 border-none rounded-lg px-4 py-2.5 text-sm text-secondary-900 dark:text-white placeholder-secondary-400 focus:ring-2 focus:ring-primary-500 outline-none"
          />
          <button
            v-if="searchQuery"
            @click="clearSearch"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-secondary-400 hover:text-secondary-600 dark:hover:text-secondary-200"
          >
            ✕
          </button>
        </div>
        <div v-if="isSearching" class="text-xs text-primary-500 animate-pulse font-medium">
          Recherche...
        </div>
      </div>

      <!-- Instant Search Dropdown Results -->
      <div
        v-if="showDropdown && (hasResults || isSearching)"
        class="absolute left-0 right-0 top-full mt-2 bg-white dark:bg-secondary-900 rounded-xl shadow-xl border border-secondary-200 dark:border-secondary-800 z-50 max-h-96 overflow-y-auto p-4 space-y-4"
      >
        <!-- Users Results -->
        <div v-if="searchResults.users && searchResults.users.length">
          <h4 class="text-xs font-bold uppercase tracking-wider text-secondary-500 dark:text-secondary-400 mb-2 flex items-center gap-1.5">
            <span>👤</span> Utilisateurs / Vendeurs ({{ searchResults.users.length }})
          </h4>
          <div class="space-y-1">
            <a
              v-for="u in searchResults.users"
              :key="'u-' + u.id"
              :href="'/admin/user?search=' + encodeURIComponent(u.name || u.email)"
              class="flex items-center justify-between p-2 rounded-lg hover:bg-secondary-100 dark:hover:bg-secondary-800 transition"
            >
              <div>
                <p class="text-sm font-semibold text-secondary-900 dark:text-white">{{ u.name }}</p>
                <p class="text-xs text-secondary-500">{{ u.email }} | {{ u.user_phone || 'Sans tél' }}</p>
              </div>
              <span class="text-xs bg-primary-50 text-primary-600 dark:bg-primary-900/30 dark:text-primary-400 px-2 py-0.5 rounded-full font-medium">
                Voir Profil →
              </span>
            </a>
          </div>
        </div>

        <!-- Orders Results -->
        <div v-if="searchResults.orders && searchResults.orders.length">
          <h4 class="text-xs font-bold uppercase tracking-wider text-secondary-500 dark:text-secondary-400 mb-2 flex items-center gap-1.5">
            <span>📦</span> Commandes & Suivis ({{ searchResults.orders.length }})
          </h4>
          <div class="space-y-1">
            <a
              v-for="o in searchResults.orders"
              :key="'o-' + o.id"
              :href="'/admin/escrow?search=' + encodeURIComponent(o.order_code || o.id)"
              class="flex items-center justify-between p-2 rounded-lg hover:bg-secondary-100 dark:hover:bg-secondary-800 transition"
            >
              <div>
                <p class="text-sm font-semibold text-secondary-900 dark:text-white">Commande #{{ o.order_code || o.id }}</p>
                <p class="text-xs text-secondary-500">
                  Total: {{ formatMoney(o.total_price) }} DA
                  <span v-if="o.yalidine_tracking"> | Tracking: {{ o.yalidine_tracking }}</span>
                </p>
              </div>
              <span
                :class="o.is_wallet_credited ? 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400' : 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'"
                class="text-xs px-2 py-0.5 rounded-full font-medium"
              >
                {{ o.is_wallet_credited ? 'Réglé' : 'Escrow en attente' }}
              </span>
            </a>
          </div>
        </div>

        <!-- Transactions Results -->
        <div v-if="searchResults.transactions && searchResults.transactions.length">
          <h4 class="text-xs font-bold uppercase tracking-wider text-secondary-500 dark:text-secondary-400 mb-2 flex items-center gap-1.5">
            <span>💳</span> Transactions Grand Livre ({{ searchResults.transactions.length }})
          </h4>
          <div class="space-y-1">
            <a
              v-for="t in searchResults.transactions"
              :key="'t-' + t.id"
              :href="'/admin/wallets'"
              class="flex items-center justify-between p-2 rounded-lg hover:bg-secondary-100 dark:hover:bg-secondary-800 transition"
            >
              <div>
                <p class="text-sm font-medium text-secondary-900 dark:text-white">
                  <span class="font-bold uppercase text-xs px-1.5 py-0.5 rounded bg-secondary-200 dark:bg-secondary-700 mr-1.5">{{ t.type }}</span>
                  {{ formatMoney(t.amount) }} DA
                </p>
                <p class="text-xs text-secondary-500">{{ t.note || ('Réf: ' + t.reference_id) }}</p>
              </div>
              <span class="text-xs text-secondary-400">Solde après: {{ formatMoney(t.balance_after) }} DA</span>
            </a>
          </div>
        </div>

        <div v-if="!hasResults && !isSearching" class="text-center py-4 text-xs text-secondary-400">
          Aucun résultat trouvé pour « {{ searchQuery }} »
        </div>
      </div>
    </div>

    <!-- C2C Finance KPI Cards (4 High-Visibility Cards) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- 1. Pending Escrow Orders -->
      <div class="relative overflow-hidden bg-white dark:bg-secondary-900 p-5 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 hover:shadow-md transition">
        <div class="flex items-center justify-between mb-3">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 font-bold text-lg">
            🛡️
          </span>
          <span class="text-xs font-bold tracking-wider uppercase px-2.5 py-1 rounded-full bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
            Escrow COD
          </span>
        </div>
        <p class="text-xs font-semibold text-secondary-500 dark:text-secondary-400 uppercase tracking-wider">Commandes en attente</p>
        <h3 class="text-2xl font-black text-secondary-900 dark:text-white mt-1">
          {{ kpis.pending_escrow_orders_count || 0 }} <span class="text-sm font-semibold text-secondary-500">cmd</span>
        </h3>
        <p class="text-sm font-bold text-amber-600 dark:text-amber-400 mt-1">
          {{ formatMoney(kpis.pending_escrow_amount) }} DA
        </p>
        <div class="mt-4 pt-3 border-t border-secondary-100 dark:border-secondary-800">
          <a href="/admin/escrow" class="text-xs font-bold text-primary-600 dark:text-primary-400 hover:underline inline-flex items-center gap-1">
            Gérer les règlements Escrow →
          </a>
        </div>
      </div>

      <!-- 2. Pending Withdrawals -->
      <div class="relative overflow-hidden bg-white dark:bg-secondary-900 p-5 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 hover:shadow-md transition">
        <div class="flex items-center justify-between mb-3">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 font-bold text-lg">
            💸
          </span>
          <span class="text-xs font-bold tracking-wider uppercase px-2.5 py-1 rounded-full bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300">
            Retraits CCP
          </span>
        </div>
        <p class="text-xs font-semibold text-secondary-500 dark:text-secondary-400 uppercase tracking-wider">Demandes en attente</p>
        <h3 class="text-2xl font-black text-secondary-900 dark:text-white mt-1">
          {{ kpis.pending_withdrawals_count || 0 }} <span class="text-sm font-semibold text-secondary-500">req</span>
        </h3>
        <p class="text-sm font-bold text-rose-600 dark:text-rose-400 mt-1">
          {{ formatMoney(kpis.pending_withdrawals_amount) }} DA
        </p>
        <div class="mt-4 pt-3 border-t border-secondary-100 dark:border-secondary-800">
          <a href="/admin/withdrawals" class="text-xs font-bold text-rose-600 dark:text-rose-400 hover:underline inline-flex items-center gap-1">
            Valider les virements CCP / BaridiMob →
          </a>
        </div>
      </div>

      <!-- 3. Active Seller Wallets Balance -->
      <div class="relative overflow-hidden bg-white dark:bg-secondary-900 p-5 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 hover:shadow-md transition">
        <div class="flex items-center justify-between mb-3">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-blue-500/10 text-blue-600 dark:text-blue-400 font-bold text-lg">
            💼
          </span>
          <span class="text-xs font-bold tracking-wider uppercase px-2.5 py-1 rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300">
            Portefeuilles
          </span>
        </div>
        <p class="text-xs font-semibold text-secondary-500 dark:text-secondary-400 uppercase tracking-wider">Total Soldes Vendeurs</p>
        <h3 class="text-2xl font-black text-secondary-900 dark:text-white mt-1">
          {{ formatMoney(kpis.total_seller_wallets_amount) }} <span class="text-sm font-semibold text-secondary-500">DA</span>
        </h3>
        <p class="text-sm font-medium text-secondary-500 dark:text-secondary-400 mt-1">
          {{ kpis.total_active_wallets_count || 0 }} portefeuilles actifs
        </p>
        <div class="mt-4 pt-3 border-t border-secondary-100 dark:border-secondary-800">
          <a href="/admin/wallets" class="text-xs font-bold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center gap-1">
            Voir soldes & historiques →
          </a>
        </div>
      </div>

      <!-- 4. Platform Commission -->
      <div class="relative overflow-hidden bg-white dark:bg-secondary-900 p-5 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 hover:shadow-md transition">
        <div class="flex items-center justify-between mb-3">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 font-bold text-lg">
            💎
          </span>
          <span class="text-xs font-bold tracking-wider uppercase px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300">
            Taux: {{ kpis.commission_percent || 0 }}%
          </span>
        </div>
        <p class="text-xs font-semibold text-secondary-500 dark:text-secondary-400 uppercase tracking-wider">Commissions Encaissées</p>
        <h3 class="text-2xl font-black text-secondary-900 dark:text-white mt-1">
          {{ formatMoney(kpis.total_commission_earned) }} <span class="text-sm font-semibold text-secondary-500">DA</span>
        </h3>
        <p class="text-sm font-medium text-emerald-600 dark:text-emerald-400 mt-1">
          Revenu plateforme Dressy
        </p>
        <div class="mt-4 pt-3 border-t border-secondary-100 dark:border-secondary-800">
          <a href="/admin/commission" class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline inline-flex items-center gap-1">
            Modifier le % de commission →
          </a>
        </div>
      </div>
    </div>

    <!-- Quick Action Tables -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Table 1: Pending Escrow Orders -->
      <div class="bg-white dark:bg-secondary-900 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 p-5">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="text-base font-bold text-secondary-900 dark:text-white flex items-center gap-2">
              <span>🛡️</span> Commandes en attente de règlement
            </h3>
            <p class="text-xs text-secondary-500">Colis livrés / COD collectés à créditer au vendeur</p>
          </div>
          <a href="/admin/escrow" class="text-xs font-bold text-primary-600 dark:text-primary-400 hover:underline">
            Tout voir ({{ kpis.pending_escrow_orders_count || 0 }}) →
          </a>
        </div>

        <div v-if="pendingEscrowOrders && pendingEscrowOrders.length" class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead>
              <tr class="border-b border-secondary-100 dark:border-secondary-800 text-secondary-500 uppercase tracking-wider">
                <th class="py-2">Commande</th>
                <th class="py-2">Vendeur</th>
                <th class="py-2">Total</th>
                <th class="py-2">Net Vendeur</th>
                <th class="py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-secondary-100 dark:divide-secondary-800">
              <tr v-for="order in pendingEscrowOrders" :key="'esc-' + order.id" class="hover:bg-secondary-50 dark:hover:bg-secondary-800/50">
                <td class="py-2.5 font-bold text-secondary-900 dark:text-white">
                  #{{ order.order_code }}
                  <span v-if="order.yalidine_tracking" class="block font-mono text-[10px] text-primary-500">{{ order.yalidine_tracking }}</span>
                </td>
                <td class="py-2.5 text-secondary-700 dark:text-secondary-300">{{ order.seller_name }}</td>
                <td class="py-2.5 font-semibold text-secondary-900 dark:text-white">{{ formatMoney(order.total_price) }} DA</td>
                <td class="py-2.5 font-bold text-emerald-600 dark:text-emerald-400">{{ formatMoney(order.seller_payout) }} DA</td>
                <td class="py-2.5 text-right">
                  <a
                    :href="'/admin/escrow?search=' + encodeURIComponent(order.order_code)"
                    class="inline-block px-2.5 py-1 text-xs font-bold text-white bg-primary-600 hover:bg-primary-700 rounded-lg transition"
                  >
                    Régler
                  </a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="text-center py-8 text-xs text-secondary-400">
          Toutes les commandes COD livrées ont été créditées aux vendeurs.
        </div>
      </div>

      <!-- Table 2: Pending Withdrawal Requests -->
      <div class="bg-white dark:bg-secondary-900 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 p-5">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="text-base font-bold text-secondary-900 dark:text-white flex items-center gap-2">
              <span>💸</span> Demandes de Retrait CCP / BaridiMob
            </h3>
            <p class="text-xs text-secondary-500">Demandes de paiement vendeurs à traiter</p>
          </div>
          <a href="/admin/withdrawals" class="text-xs font-bold text-rose-600 dark:text-rose-400 hover:underline">
            Tout voir ({{ kpis.pending_withdrawals_count || 0 }}) →
          </a>
        </div>

        <div v-if="pendingWithdrawals && pendingWithdrawals.length" class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead>
              <tr class="border-b border-secondary-100 dark:border-secondary-800 text-secondary-500 uppercase tracking-wider">
                <th class="py-2">Vendeur</th>
                <th class="py-2">Montant</th>
                <th class="py-2">Solde Actuel</th>
                <th class="py-2">Note / CCP</th>
                <th class="py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-secondary-100 dark:divide-secondary-800">
              <tr v-for="req in pendingWithdrawals" :key="'wdr-' + req.id" class="hover:bg-secondary-50 dark:hover:bg-secondary-800/50">
                <td class="py-2.5 font-bold text-secondary-900 dark:text-white">
                  {{ req.user_name }}
                  <span class="block text-[10px] text-secondary-400 font-normal">{{ req.user_email }}</span>
                </td>
                <td class="py-2.5 font-bold text-rose-600 dark:text-rose-400">{{ formatMoney(req.amount) }} DA</td>
                <td class="py-2.5 font-semibold text-secondary-700 dark:text-secondary-300">{{ formatMoney(req.wallet_balance) }} DA</td>
                <td class="py-2.5 text-secondary-600 dark:text-secondary-400 max-w-[150px] truncate" :title="req.note">
                  {{ req.note || '—' }}
                </td>
                <td class="py-2.5 text-right">
                  <a
                    href="/admin/withdrawals"
                    class="inline-block px-2.5 py-1 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-lg transition"
                  >
                    Examiner
                  </a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="text-center py-8 text-xs text-secondary-400">
          Aucune demande de retrait en attente.
        </div>
      </div>
    </div>

    <!-- Table 3: Recent Ledger Movements -->
    <div class="bg-white dark:bg-secondary-900 rounded-2xl shadow-sm border border-secondary-200 dark:border-secondary-800 p-5">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-base font-bold text-secondary-900 dark:text-white flex items-center gap-2">
            <span>📜</span> Derniers Mouvements du Grand Livre (Ledger)
          </h3>
          <p class="text-xs text-secondary-500">Flux financiers en direct: crédits ventes, commissions, retraits</p>
        </div>
        <a href="/admin/wallets" class="text-xs font-bold text-primary-600 dark:text-primary-400 hover:underline">
          Historique Complet →
        </a>
      </div>

      <div v-if="recentTransactions && recentTransactions.length" class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead>
            <tr class="border-b border-secondary-100 dark:border-secondary-800 text-secondary-500 uppercase tracking-wider">
              <th class="py-2">Date</th>
              <th class="py-2">Utilisateur</th>
              <th class="py-2">Type</th>
              <th class="py-2">Montant</th>
              <th class="py-2">Solde Après</th>
              <th class="py-2">Détails / Note</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-secondary-100 dark:divide-secondary-800">
            <tr v-for="tx in recentTransactions" :key="'tx-' + tx.id" class="hover:bg-secondary-50 dark:hover:bg-secondary-800/50">
              <td class="py-2 text-secondary-500 whitespace-nowrap">{{ tx.created_at || '—' }}</td>
              <td class="py-2 font-bold text-secondary-900 dark:text-white">{{ tx.user_name }}</td>
              <td class="py-2">
                <span
                  :class="{
                    'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300': tx.type === 'credit',
                    'bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-300': tx.type === 'debit' || tx.type === 'withdraw',
                    'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300': tx.type === 'commission',
                  }"
                  class="px-2 py-0.5 rounded-full font-bold uppercase text-[10px]"
                >
                  {{ tx.type }}
                </span>
              </td>
              <td
                :class="tx.type === 'credit' ? 'text-green-600 dark:text-green-400 font-bold' : 'text-rose-600 dark:text-rose-400 font-bold'"
                class="py-2"
              >
                {{ tx.type === 'credit' ? '+' : '-' }}{{ formatMoney(tx.amount) }} DA
              </td>
              <td class="py-2 font-semibold text-secondary-700 dark:text-secondary-300">{{ formatMoney(tx.balance_after) }} DA</td>
              <td class="py-2 text-secondary-600 dark:text-secondary-400">{{ tx.note || ('Réf: ' + tx.reference_id) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="text-center py-6 text-xs text-secondary-400">
        Aucune transaction récente enregistrée sur le grand livre.
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, ref } from 'vue';
import axios from 'axios';

export default defineComponent({
  name: 'C2CFinanceDashboard',
  props: {
    kpis: {
      type: Object,
      default: () => ({
        pending_escrow_orders_count: 0,
        pending_escrow_amount: 0,
        pending_withdrawals_count: 0,
        pending_withdrawals_amount: 0,
        total_seller_wallets_amount: 0,
        total_active_wallets_count: 0,
        total_commission_earned: 0,
        commission_percent: 5,
        currency: 'DA',
      }),
    },
    pendingEscrowOrders: {
      type: Array,
      default: () => [],
    },
    pendingWithdrawals: {
      type: Array,
      default: () => [],
    },
    recentTransactions: {
      type: Array,
      default: () => [],
    },
    initialQuery: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const searchQuery = ref(props.initialQuery || '');
    const isSearching = ref(false);
    const showDropdown = ref(false);
    const searchResults = ref({
      users: [],
      orders: [],
      transactions: [],
    });

    let debounceTimeout = null;

    const handleOmniSearchInput = () => {
      clearTimeout(debounceTimeout);
      const query = searchQuery.value.trim();
      if (!query) {
        searchResults.value = { users: [], orders: [], transactions: [] };
        showDropdown.value = false;
        return;
      }

      showDropdown.value = true;
      isSearching.value = true;

      debounceTimeout = setTimeout(async () => {
        try {
          const response = await axios.get('/admin/omni-search', {
            params: { q: query },
          });
          searchResults.value = response.data;
        } catch (e) {
          console.error('Omni-search error:', e);
        } finally {
          isSearching.value = false;
        }
      }, 300);
    };

    const clearSearch = () => {
      searchQuery.value = '';
      searchResults.value = { users: [], orders: [], transactions: [] };
      showDropdown.value = false;
    };

    const formatMoney = (val) => {
      const num = parseFloat(val) || 0;
      return num.toLocaleString('fr-DZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    };

    return {
      searchQuery,
      isSearching,
      showDropdown,
      searchResults,
      handleOmniSearchInput,
      clearSearch,
      formatMoney,
    };
  },
  computed: {
    hasResults() {
      const r = this.searchResults;
      return (
        (r.users && r.users.length > 0) ||
        (r.orders && r.orders.length > 0) ||
        (r.transactions && r.transactions.length > 0)
      );
    },
  },
});
</script>
