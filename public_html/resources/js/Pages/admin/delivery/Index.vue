<template>
    <Head :title="($t('dressy_delivery_settings_title') && $t('dressy_delivery_settings_title') !== 'dressy_delivery_settings_title') ? $t('dressy_delivery_settings_title') : 'Paramètres de livraison (Yalidine)'" />
    <ps-layout>
        <!-- Page Header -->
        <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-secondary-800 dark:text-white flex items-center gap-2.5">
                    <span>{{ ($t('dressy_delivery_title') && $t('dressy_delivery_title') !== 'dressy_delivery_title') ? $t('dressy_delivery_title') : 'Paramètres de Livraison Yalidine' }}</span>
                    <span v-if="form.environment === 'sandbox'"
                        class="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300">
                        Sandbox / Simulation
                    </span>
                    <span v-else-if="form.is_enabled"
                        class="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300">
                        Production Active
                    </span>
                    <span v-else
                        class="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300">
                        Désactivé
                    </span>
                </h1>
                <p class="text-sm text-secondary-500 dark:text-secondary-400 mt-1">
                    Gérez les identifiants d'API Yalidine, l'automatisation de création de colis, l'origine de ramassage par défaut et la synchronisation des statuts de livraison.
                </p>
            </div>
            <div class="flex items-center gap-2">
                <button type="button" @click="syncFees" :disabled="syncingFees"
                    class="px-4 py-2 bg-white dark:bg-secondary-800 border border-gray-200 dark:border-secondary-700 hover:bg-gray-50 dark:hover:bg-secondary-700 text-secondary-700 dark:text-secondary-200 text-sm font-medium rounded-lg shadow-sm flex items-center gap-2 transition-colors disabled:opacity-50">
                    <ps-icon v-if="!syncingFees" name="refresh" w="16" h="16" />
                    <svg v-else class="animate-spin h-4 w-4 text-secondary-600" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                    </svg>
                    <span>{{ syncingFees ? 'Synchronisation...' : 'Actualiser Wilayas & Tarifs' }}</span>
                </button>
            </div>
        </div>

        <!-- Banner Alerts -->
        <ps-banner-icon v-if="$page.props.errors && Object.keys($page.props.errors).length > 0"
            theme="bg-red-500" iconName="close-circle" class="text-white mb-5">
            <div v-for="(err, key) in $page.props.errors" :key="key">{{ err }}</div>
        </ps-banner-icon>

        <ps-banner-icon v-if="$page.props.status"
            theme="bg-green-500" iconName="rightalert" class="text-white mb-5">
            {{ $page.props.status }}
        </ps-banner-icon>

        <!-- Logistics Stats KPI Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-secondary-500 dark:text-secondary-400">Total Colis Générés</div>
                        <div class="text-2xl font-bold text-secondary-800 dark:text-white mt-1">{{ stats.total_shipments }}</div>
                    </div>
                    <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-xl">
                        <ps-icon name="list" w="22" h="22" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Expéditions avec code de suivi Yalidine</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-amber-500 dark:text-amber-400">En cours d'acheminement</div>
                        <div class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ stats.in_transit }}</div>
                    </div>
                    <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-xl">
                        <ps-icon name="refresh" w="22" h="22" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">En transit dans les centres Yalidine</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-emerald-500 dark:text-emerald-400">Livrés & Réglés</div>
                        <div class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ stats.delivered }}</div>
                    </div>
                    <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-xl">
                        <ps-icon name="checkCircle" w="22" h="22" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Crédit vendeur automatique libéré</div>
            </div>

            <div class="bg-white dark:bg-secondary-800 rounded-xl p-5 border border-gray-100 dark:border-secondary-700 shadow-sm">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-xs uppercase font-medium text-red-500 dark:text-red-400">Retournés / Annulés</div>
                        <div class="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">{{ stats.returned_or_cancelled }}</div>
                    </div>
                    <div class="p-3 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-xl">
                        <ps-icon name="bell" w="22" h="22" />
                    </div>
                </div>
                <div class="text-xs text-secondary-500 mt-2">Déduction automatique du solde vendeur</div>
            </div>
        </div>

        <!-- Main Settings Form -->
        <form @submit.prevent="saveSettings" class="space-y-8">
            <!-- SECTION 1: API Connection & Credentials -->
            <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-6 shadow-sm">
                <div class="flex items-center justify-between pb-4 mb-6 border-b border-gray-100 dark:border-secondary-700">
                    <div>
                        <h2 class="text-lg font-bold text-secondary-800 dark:text-white flex items-center gap-2">
                            <span>1. Connexion & Identifiants API Yalidine</span>
                        </h2>
                        <p class="text-xs text-secondary-500 dark:text-secondary-400 mt-0.5">
                            Connectez votre compte Yalidine Pro officiel pour automatiser les créations de colis et le suivi en direct.
                        </p>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="form.is_enabled" class="sr-only peer">
                        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-500"></div>
                        <span class="ml-3 text-sm font-semibold text-secondary-800 dark:text-white">
                            {{ form.is_enabled ? 'Activé' : 'Désactivé' }}
                        </span>
                    </label>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <!-- Environment Mode -->
                    <div class="md:col-span-2">
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-2">
                            Mode d'Environnement
                        </label>
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 max-w-lg">
                            <label :class="[
                                'flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition-all',
                                form.environment === 'production'
                                    ? 'border-primary-500 bg-primary-50/50 dark:bg-primary-950/20 text-primary-900 dark:text-primary-100'
                                    : 'border-gray-200 dark:border-secondary-700 hover:bg-gray-50 dark:hover:bg-secondary-700'
                            ]">
                                <input type="radio" value="production" v-model="form.environment" class="text-primary-600 focus:ring-primary-500">
                                <div>
                                    <div class="text-sm font-bold">Production (Yalidine Réel)</div>
                                    <div class="text-xs text-secondary-500">Génère des vrais bordereaux et notifie les livreurs</div>
                                </div>
                            </label>

                            <label :class="[
                                'flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition-all',
                                form.environment === 'sandbox'
                                    ? 'border-amber-500 bg-amber-50/50 dark:bg-amber-950/20 text-amber-900 dark:text-amber-100'
                                    : 'border-gray-200 dark:border-secondary-700 hover:bg-gray-50 dark:hover:bg-secondary-700'
                            ]">
                                <input type="radio" value="sandbox" v-model="form.environment" class="text-amber-600 focus:ring-amber-500">
                                <div>
                                    <div class="text-sm font-bold">Sandbox (Simulation DZBuild)</div>
                                    <div class="text-xs text-secondary-500">Mode test sécurisé sans impact sur votre compte Yalidine</div>
                                </div>
                            </label>
                        </div>
                    </div>

                    <!-- API Base URL -->
                    <div class="md:col-span-2">
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            URL de Base de l'API Yalidine
                        </label>
                        <input type="url" v-model="form.api_base_url" required
                            class="w-full max-w-lg px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-mono focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <p class="text-xs text-secondary-500 mt-1">Par défaut : <code>https://api.yalidine.app/v1</code></p>
                    </div>

                    <!-- API ID -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Yalidine API ID (<span class="font-mono text-xs">X-API-ID</span>) *
                        </label>
                        <input type="text" v-model="form.api_id" placeholder="Ex: 8492048591"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-mono focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <p class="text-xs text-secondary-500 mt-1">Trouvez cet identifiant dans votre dashboard Yalidine Pro &gt; Développeur.</p>
                    </div>

                    <!-- API Token -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Yalidine API Token (<span class="font-mono text-xs">X-API-TOKEN</span>) *
                        </label>
                        <div class="relative">
                            <input :type="showToken ? 'text' : 'password'" v-model="form.api_token"
                                placeholder="Collez votre clé secrète Yalidine"
                                class="w-full px-3 py-2 pr-20 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-mono focus:outline-none focus:ring-2 focus:ring-primary-500" />
                            <button type="button" @click="showToken = !showToken"
                                class="absolute inset-y-0 right-0 pr-3 flex items-center text-xs font-semibold text-secondary-500 hover:text-secondary-800">
                                {{ showToken ? 'Masquer' : 'Afficher' }}
                            </button>
                        </div>
                        <p class="text-xs text-secondary-500 mt-1">
                            Chiffré de bout en bout dans la base de données. Ne sera jamais exposé en clair.
                        </p>
                    </div>

                    <!-- Test Connection Button & Result Alert -->
                    <div class="md:col-span-2 pt-2">
                        <div class="flex flex-wrap items-center gap-3">
                            <button type="button" @click="testConnection" :disabled="testingConnection"
                                class="px-5 py-2.5 bg-secondary-800 hover:bg-secondary-900 text-white rounded-lg text-sm font-bold shadow-sm transition-colors disabled:opacity-50 flex items-center gap-2">
                                <ps-icon v-if="!testingConnection" name="checkCircle" w="18" h="18" />
                                <svg v-else class="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                                </svg>
                                <span>{{ testingConnection ? 'Test en cours...' : 'Tester la Connexion Yalidine' }}</span>
                            </button>
                        </div>

                        <!-- Connection Test Feedback -->
                        <div v-if="testResult" class="mt-4 p-4 rounded-xl border text-sm"
                            :class="testResult.success
                                ? 'bg-emerald-50 dark:bg-emerald-950/30 border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200'
                                : 'bg-red-50 dark:bg-red-950/30 border-red-200 dark:border-red-800 text-red-800 dark:text-red-200'">
                            <div class="flex items-start gap-3">
                                <ps-icon :name="testResult.success ? 'checkCircle' : 'close-circle'" w="20" h="20" class="shrink-0 mt-0.5" />
                                <div>
                                    <div class="font-bold">{{ testResult.success ? 'Connexion Réussie !' : 'Erreur de Connexion' }}</div>
                                    <div class="mt-1">{{ testResult.message }}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- SECTION 2: Automatic Order Matching & Parcel Creation Rules -->
            <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-6 shadow-sm">
                <div class="pb-4 mb-6 border-b border-gray-100 dark:border-secondary-700">
                    <h2 class="text-lg font-bold text-secondary-800 dark:text-white">
                        2. Règles d'Automatisation & Création de Colis
                    </h2>
                    <p class="text-xs text-secondary-500 dark:text-secondary-400 mt-0.5">
                        Configurez quand les commandes génèrent automatiquement un bordereau Yalidine et comment les statuts sont synchronisés.
                    </p>
                </div>

                <div class="space-y-6">
                    <!-- Auto-create toggle -->
                    <div class="flex items-center justify-between max-w-2xl p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700">
                        <div>
                            <div class="text-sm font-bold text-secondary-800 dark:text-white">Création Automatique de Colis</div>
                            <div class="text-xs text-secondary-500">Transmettre automatiquement la commande à Yalidine pour obtenir le code de suivi et le bordereau PDF.</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" v-model="form.auto_create_parcel" class="sr-only peer">
                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-500"></div>
                        </label>
                    </div>

                    <!-- Trigger Event -->
                    <div class="max-w-xl">
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Événement Déclencheur de l'Expédition
                        </label>
                        <select v-model="form.auto_sync_trigger"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500">
                            <option value="on_seller_confirmed">Dès Confirmation par le Vendeur (Recommandé)</option>
                            <option value="on_order_placed">Instantané dès la commande client (On Order Placed)</option>
                            <option value="manual_only">Création Manuelle Uniquement (Bouton Admin / Vendeur)</option>
                        </select>
                        <p class="text-xs text-secondary-500 mt-1">
                            En mode "Confirmation Vendeur", le bordereau Yalidine est généré au moment où le vendeur accepte la commande.
                        </p>
                    </div>

                    <!-- Auto-sync status toggle -->
                    <div class="flex items-center justify-between max-w-2xl p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700">
                        <div>
                            <div class="text-sm font-bold text-secondary-800 dark:text-white">Synchronisation Automatique des Statuts de Livraison</div>
                            <div class="text-xs text-secondary-500">Met à jour les commandes en "Livré et payé" ou "Retourné" et déclenche les flux financiers correspondants.</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" v-model="form.auto_sync_status" class="sr-only peer">
                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-500"></div>
                        </label>
                    </div>

                    <!-- Webhook Callback URL Card -->
                    <div class="p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700 max-w-2xl">
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            URL de Callback Webhook Yalidine (Live Tracking)
                        </label>
                        <div class="flex items-center gap-2 mt-2">
                            <input type="text" readonly :value="form.webhook_url"
                                class="w-full px-3 py-2 text-xs font-mono rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-800 text-secondary-700 dark:text-secondary-300 select-all" />
                            <button type="button" @click="copyWebhookUrl"
                                class="px-3 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg text-xs font-bold shrink-0 transition-colors">
                                {{ webhookCopied ? 'Copié !' : 'Copier l\'URL' }}
                            </button>
                        </div>
                        <p class="text-xs text-secondary-500 mt-2">
                            Copiez cette URL dans votre portail Yalidine Pro &gt; Webhooks pour recevoir les notifications de livraison en temps réel.
                        </p>
                    </div>

                    <!-- Cron Command Helper -->
                    <div class="p-4 bg-blue-50/70 dark:bg-blue-950/20 rounded-xl border border-blue-100 dark:border-blue-900/40 text-xs text-blue-900 dark:text-blue-200 max-w-2xl">
                        <div class="font-bold mb-1 flex items-center gap-1.5">
                            <ps-icon name="chart-line" w="14" h="14" />
                            <span>Tâche Planifiée Cron pour la Synchronisation Automatique :</span>
                        </div>
                        <code class="block p-2 mt-1 rounded bg-white dark:bg-secondary-900 text-secondary-800 dark:text-secondary-100 font-mono text-[11px] border border-blue-200 dark:border-blue-800">
                            * * * * * cd /home/u348824147/domains/dressydz.com/public_html &amp;&amp; php artisan yalidine:sync-statuses &gt;&gt; /dev/null 2&gt;&amp;1
                        </code>
                    </div>
                </div>
            </div>

            <!-- SECTION 3: Default Sender & Shipping Preferences -->
            <div class="bg-white dark:bg-secondary-800 rounded-xl border border-gray-100 dark:border-secondary-700 p-6 shadow-sm">
                <div class="pb-4 mb-6 border-b border-gray-100 dark:border-secondary-700">
                    <h2 class="text-lg font-bold text-secondary-800 dark:text-white">
                        3. Coordonnées Expéditeur & Préférences d'Expédition par Défaut
                    </h2>
                    <p class="text-xs text-secondary-500 dark:text-secondary-400 mt-0.5">
                        Définit l'expéditeur de référence qui apparaît sur le bordereau Yalidine et les options de livraison pour les acheteurs.
                    </p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <!-- Sender Name -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Nom de l'Expéditeur *
                        </label>
                        <input type="text" v-model="form.sender_name" required
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <p class="text-xs text-secondary-500 mt-1">Ex: Dressy DZ</p>
                    </div>

                    <!-- Sender Phone -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Téléphone Expéditeur *
                        </label>
                        <input type="text" v-model="form.sender_phone" required
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-mono focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        <p class="text-xs text-secondary-500 mt-1">Format algérien : 0550000000</p>
                    </div>

                    <!-- Origin Wilaya -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Wilaya d'Origine / Ramassage par Défaut *
                        </label>
                        <select v-model="form.from_wilaya_id" required
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500">
                            <option v-for="w in wilayas" :key="w.id" :value="w.id">
                                {{ w.name }}
                            </option>
                        </select>
                    </div>

                    <!-- Origin Commune -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Commune d'Origine par Défaut
                        </label>
                        <input type="text" v-model="form.from_commune_name" placeholder="Ex: Alger Centre / Bab Ezzouar"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    </div>

                    <!-- Default Delivery Type -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Type de Livraison Présélectionné *
                        </label>
                        <select v-model="form.default_delivery_type" required
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500">
                            <option value="home">Livraison à Domicile (Home Delivery)</option>
                            <option value="stop_desk">Point Relais / Bureau Yalidine (Stop-Desk)</option>
                        </select>
                    </div>

                    <!-- Description Prefix -->
                    <div>
                        <label class="block text-sm font-bold text-secondary-800 dark:text-white mb-1">
                            Préfixe Libellé Colis
                        </label>
                        <input type="text" v-model="form.description_prefix" placeholder="Ex: Article Mode Dressy"
                            class="w-full px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900 text-secondary-800 dark:text-white font-medium focus:outline-none focus:ring-2 focus:ring-primary-500" />
                    </div>

                    <!-- Checkboxes: Open Parcel & Insurance -->
                    <div class="md:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                        <label class="flex items-start gap-3 p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700 cursor-pointer">
                            <input type="checkbox" v-model="form.open_parcel" class="mt-1 rounded text-primary-600 focus:ring-primary-500">
                            <div>
                                <div class="text-sm font-bold text-secondary-800 dark:text-white">Autoriser l'Ouverture du Colis (open_parcel)</div>
                                <div class="text-xs text-secondary-500">Permet au client de vérifier l'article avant encaissement (recommandé pour la confiance acheteur).</div>
                            </div>
                        </label>

                        <label class="flex items-start gap-3 p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700 cursor-pointer">
                            <input type="checkbox" v-model="form.has_insurance" class="mt-1 rounded text-primary-600 focus:ring-primary-500">
                            <div>
                                <div class="text-sm font-bold text-secondary-800 dark:text-white">Assurance Transport Yalidine (has_insurance)</div>
                                <div class="text-xs text-secondary-500">Active la couverture assurance marchandise auprès de Yalidine.</div>
                            </div>
                        </label>
                    </div>

                    <!-- Free shipping option -->
                    <div class="md:col-span-2 p-4 bg-gray-50 dark:bg-secondary-900 rounded-xl border border-gray-100 dark:border-secondary-700">
                        <div class="flex items-center justify-between mb-3">
                            <div>
                                <div class="text-sm font-bold text-secondary-800 dark:text-white">Livraison Gratuite Promotionnelle</div>
                                <div class="text-xs text-secondary-500">Prendre en charge les frais de livraison pour le compte des acheteurs au-delà d'un montant d'achat.</div>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer">
                                <input type="checkbox" v-model="form.is_free_shipping" class="sr-only peer">
                                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-500"></div>
                            </label>
                        </div>
                        <div v-if="form.is_free_shipping" class="mt-3 pt-3 border-t border-gray-200 dark:border-secondary-700 flex items-center gap-3">
                            <label class="text-xs font-semibold text-secondary-700 dark:text-secondary-300">
                                Montant minimum du panier pour livraison offerte (DZD) :
                            </label>
                            <input type="number" min="0" step="100" v-model="form.free_shipping_min_amount"
                                class="w-36 px-3 py-1.5 text-sm font-bold rounded-lg border border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-800 text-secondary-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- SECTION 4: Submit Button -->
            <div class="flex items-center justify-end gap-4 pt-4">
                <button type="submit" :disabled="saving"
                    class="px-8 py-3 bg-primary-500 hover:bg-primary-600 text-white rounded-xl text-sm font-bold shadow-md transition-all disabled:opacity-50 flex items-center gap-2">
                    <ps-icon v-if="!saving" name="check" w="18" h="18" />
                    <svg v-else class="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                    </svg>
                    <span>{{ saving ? 'Enregistrement...' : 'Enregistrer Tous les Paramètres' }}</span>
                </button>
            </div>
        </form>
    </ps-layout>
</template>

<script>
import { defineComponent, ref, reactive } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import axios from 'axios';
import PsLayout from "@/Components/PsLayout.vue";
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsBannerIcon from "@/Components/Core/Banners/PsBannerIcon.vue";

export default defineComponent({
    name: "AdminDeliveryIndex",
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
        wilayas: Array,
        stats: Object,
    },
    setup(props) {
        const saving = ref(false);
        const showToken = ref(false);
        const testingConnection = ref(false);
        const testResult = ref(null);
        const syncingFees = ref(false);
        const webhookCopied = ref(false);

        const form = reactive({
            is_enabled: props.settings.is_enabled ?? true,
            environment: props.settings.environment ?? 'production',
            api_base_url: props.settings.api_base_url ?? 'https://api.yalidine.app/v1',
            api_id: props.settings.api_id ?? '',
            api_token: props.settings.api_token ?? '',
            auto_create_parcel: props.settings.auto_create_parcel ?? true,
            auto_sync_trigger: props.settings.auto_sync_trigger ?? 'on_seller_confirmed',
            auto_sync_status: props.settings.auto_sync_status ?? true,
            webhook_secret: props.settings.webhook_secret ?? '',
            webhook_url: props.settings.webhook_url ?? '',
            sender_name: props.settings.sender_name ?? 'Dressy DZ',
            sender_phone: props.settings.sender_phone ?? '0550000000',
            from_wilaya_id: props.settings.from_wilaya_id ?? 16,
            from_commune_name: props.settings.from_commune_name ?? 'Alger',
            from_stop_desk_id: props.settings.from_stop_desk_id ?? '',
            default_delivery_type: props.settings.default_delivery_type ?? 'home',
            is_free_shipping: props.settings.is_free_shipping ?? false,
            free_shipping_min_amount: props.settings.free_shipping_min_amount ?? 0,
            has_insurance: props.settings.has_insurance ?? false,
            open_parcel: props.settings.open_parcel ?? true,
            description_prefix: props.settings.description_prefix ?? 'Article Mode Dressy',
        });

        const copyWebhookUrl = () => {
            if (navigator && navigator.clipboard) {
                navigator.clipboard.writeText(form.webhook_url).then(() => {
                    webhookCopied.value = true;
                    setTimeout(() => { webhookCopied.value = false; }, 2500);
                });
            }
        };

        const testConnection = async () => {
            testingConnection.value = true;
            testResult.value = null;

            try {
                const response = await axios.post(route('admin.delivery.testConnection'), {
                    api_id: form.api_id,
                    api_token: form.api_token,
                    api_base_url: form.api_base_url,
                });
                testResult.value = {
                    success: true,
                    message: response.data.message || 'Connexion réussie à l\'API Yalidine !',
                };
            } catch (err) {
                const msg = err.response?.data?.message || err.message || 'Échec de connexion à Yalidine';
                testResult.value = {
                    success: false,
                    message: msg,
                };
            } finally {
                testingConnection.value = false;
            }
        };

        const syncFees = async () => {
            syncingFees.value = true;
            try {
                const res = await axios.post(route('admin.delivery.syncFees'));
                alert(res.data.message || 'Synchronisation terminée !');
            } catch (err) {
                alert(err.response?.data?.message || 'Erreur lors de la synchronisation.');
            } finally {
                syncingFees.value = false;
            }
        };

        const saveSettings = () => {
            saving.value = true;
            router.post(route('admin.delivery.update'), {
                is_enabled: form.is_enabled,
                environment: form.environment,
                api_base_url: form.api_base_url,
                api_id: form.api_id,
                api_token: form.api_token,
                auto_create_parcel: form.auto_create_parcel,
                auto_sync_trigger: form.auto_sync_trigger,
                auto_sync_status: form.auto_sync_status,
                webhook_secret: form.webhook_secret,
                sender_name: form.sender_name,
                sender_phone: form.sender_phone,
                from_wilaya_id: form.from_wilaya_id,
                from_commune_name: form.from_commune_name,
                from_stop_desk_id: form.from_stop_desk_id,
                default_delivery_type: form.default_delivery_type,
                is_free_shipping: form.is_free_shipping,
                free_shipping_min_amount: form.free_shipping_min_amount,
                has_insurance: form.has_insurance,
                open_parcel: form.open_parcel,
                description_prefix: form.description_prefix,
            }, {
                onFinish: () => {
                    saving.value = false;
                }
            });
        };

        return {
            form,
            saving,
            showToken,
            testingConnection,
            testResult,
            syncingFees,
            webhookCopied,
            copyWebhookUrl,
            testConnection,
            syncFees,
            saveSettings,
        };
    }
});
</script>
