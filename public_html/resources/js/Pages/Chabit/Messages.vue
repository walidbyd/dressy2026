<template>
    <Head title="Chabit Unified Message Center" />
    <ps-layout>
        <div class="p-4 sm:p-6 max-w-7xl mx-auto">
            <!-- Header -->
            <div class="flex flex-wrap items-center justify-between gap-4 mb-5">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                        <span class="inline-flex items-center justify-center w-9 h-9 rounded-xl bg-purple-600 text-white text-lg">💬</span>
                        Chabit Unified Message Center
                    </h1>
                    <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        Monitor AI Assistant threads, COD Order Confirmations, and Buyer ↔ Seller marketplace safety.
                    </p>
                </div>
                <Link
                    :href="route('admin.chabit.settings')"
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 dark:border-secondary-600 text-gray-700 dark:text-gray-200 text-sm font-medium hover:bg-gray-50 dark:hover:bg-secondary-800 transition">
                    ⚙ Chabit Settings
                </Link>
            </div>

            <!-- 3 Tabs -->
            <div class="flex flex-wrap gap-2 mb-5 border-b border-gray-200 dark:border-secondary-700 pb-3">
                <button
                    type="button"
                    @click="activeTab = 'assistant'; selectedThread = null"
                    class="px-4 py-2 rounded-lg text-sm font-semibold transition"
                    :class="activeTab === 'assistant' ? 'bg-purple-600 text-white shadow-sm' : 'bg-white dark:bg-secondary-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-secondary-700'">
                    ✨ AI Assistant Chats ({{ assistantList.length }})
                </button>
                <button
                    type="button"
                    @click="activeTab = 'orders'; selectedThread = null"
                    class="px-4 py-2 rounded-lg text-sm font-semibold transition"
                    :class="activeTab === 'orders' ? 'bg-purple-600 text-white shadow-sm' : 'bg-white dark:bg-secondary-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-secondary-700'">
                    📦 Order Confirmations ({{ orderList.length }})
                </button>
                <button
                    type="button"
                    @click="activeTab = 'marketplace'; selectedThread = null"
                    class="px-4 py-2 rounded-lg text-sm font-semibold transition"
                    :class="activeTab === 'marketplace' ? 'bg-purple-600 text-white shadow-sm' : 'bg-white dark:bg-secondary-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-secondary-700'">
                    🛡️ Buyer ↔ Seller Chats (Read-Only • {{ marketplaceChats.length }})
                </button>
            </div>

            <!-- TAB 1 & 2: Interactive Chabit Thread Viewer + Admin Takeover -->
            <div v-if="activeTab === 'assistant' || activeTab === 'orders'"
                class="grid grid-cols-1 lg:grid-cols-12 gap-5 bg-white dark:bg-secondary-800 rounded-2xl border border-gray-200 dark:border-secondary-700 overflow-hidden shadow-sm min-h-[580px]">
                <!-- Left Thread List -->
                <div class="lg:col-span-4 border-r border-gray-200 dark:border-secondary-700 overflow-y-auto max-h-[650px]">
                    <div v-if="currentThreads.length === 0" class="p-8 text-center text-sm text-gray-500">
                        No threads yet in this category.
                    </div>
                    <button
                        v-for="t in currentThreads"
                        :key="t.id"
                        type="button"
                        @click="openThread(t.id)"
                        class="w-full text-left p-4 border-b border-gray-100 dark:border-secondary-700 hover:bg-purple-50/50 dark:hover:bg-secondary-900/50 transition"
                        :class="{ 'bg-purple-50 dark:bg-secondary-900': selectedThread?.id === t.id }">
                        <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-sm text-gray-900 dark:text-white truncate">
                                {{ t.user?.name || ('User #' + t.user_id) }}
                            </span>
                            <div class="flex items-center gap-1.5">
                                <span v-if="t.language" class="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-secondary-700 text-[10px] font-bold uppercase text-gray-600 dark:text-gray-300">
                                    {{ t.language }}
                                </span>
                                <span v-if="t.ai_paused" class="px-1.5 py-0.5 rounded bg-amber-100 text-amber-800 text-[10px] font-bold">
                                    PAUSED
                                </span>
                                <span v-if="t.unread_admin_count > 0" class="px-1.5 py-0.5 rounded-full bg-rose-500 text-white text-[10px] font-bold">
                                    {{ t.unread_admin_count }}
                                </span>
                            </div>
                        </div>
                        <div v-if="t.order" class="text-xs text-purple-700 dark:text-purple-400 font-medium mt-0.5">
                            {{ t.thread_type === 'order_buyer' ? 'Buyer' : 'Seller' }} • Order {{ t.order.order_code || ('#' + t.order.id) }}
                        </div>
                        <p class="text-xs text-gray-500 dark:text-gray-400 truncate mt-1">
                            {{ t.latest_message?.body || 'No messages yet' }}
                        </p>
                    </button>
                </div>

                <!-- Right Active Conversation -->
                <div class="lg:col-span-8 flex flex-col max-h-[650px]">
                    <div v-if="!selectedThread" class="flex-1 flex items-center justify-center text-sm text-gray-400 p-8">
                        Select a thread on the left to inspect messages or reply directly.
                    </div>

                    <template v-else>
                        <!-- Thread Header -->
                        <div class="p-4 border-b border-gray-200 dark:border-secondary-700 flex flex-wrap items-center justify-between gap-3 bg-gray-50 dark:bg-secondary-900/60">
                            <div>
                                <div class="font-bold text-gray-900 dark:text-white text-sm">
                                    {{ selectedThread.user?.name || ('User #' + selectedThread.user_id) }}
                                    <span class="text-xs font-normal text-gray-500 ms-1">({{ selectedThread.user?.email }})</span>
                                </div>
                                <div class="text-xs text-gray-500 mt-0.5 flex items-center gap-2">
                                    <span>Type: <strong>{{ selectedThread.thread_type }}</strong></span>
                                    <span v-if="selectedThread.order">• Order: <strong>{{ selectedThread.order.order_code || ('#' + selectedThread.order.id) }}</strong></span>
                                    <span>• Lang: <strong class="uppercase">{{ selectedThread.language || 'unset' }}</strong></span>
                                </div>
                            </div>
                            <button
                                type="button"
                                @click="togglePause"
                                :disabled="togglingPause"
                                class="px-3.5 py-1.5 rounded-lg text-xs font-semibold transition"
                                :class="selectedThread.ai_paused ? 'bg-amber-500 text-white hover:bg-amber-600' : 'bg-gray-200 dark:bg-secondary-700 text-gray-800 dark:text-white hover:bg-gray-300'">
                                {{ selectedThread.ai_paused ? '⏸ AI Paused (Admin Takeover Active)' : '▶ Pause AI (Admin Reply)' }}
                            </button>
                        </div>

                        <!-- Messages List -->
                        <div ref="messagesContainer" class="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50/40 dark:bg-secondary-900/30">
                            <div v-if="loadingThread" class="text-center py-8 text-xs text-gray-400">
                                Loading conversation...
                            </div>
                            <div
                                v-for="msg in selectedThread.messages"
                                :key="msg.id"
                                class="flex flex-col"
                                :class="msg.sender_type === 'user' ? 'items-start' : 'items-end'">
                                <div class="max-w-[82%] rounded-2xl px-4 py-2.5 text-sm shadow-sm whitespace-pre-line"
                                    :dir="selectedThread.language === 'ar' ? 'rtl' : 'ltr'"
                                    :class="{
                                        'bg-white dark:bg-secondary-700 text-gray-900 dark:text-white border border-gray-200 dark:border-secondary-600': msg.sender_type === 'user',
                                        'bg-purple-600 text-white': msg.sender_type === 'ai',
                                        'bg-emerald-600 text-white': msg.sender_type === 'admin',
                                        'bg-slate-700 text-white': msg.sender_type === 'system'
                                    }">
                                    <div class="text-[10px] font-bold uppercase tracking-wider opacity-80 mb-1">
                                        {{ msg.sender_type === 'user' ? 'User' : (msg.sender_type === 'ai' ? '✨ Chabit AI' : (msg.sender_type === 'admin' ? '👤 Admin Reply' : '🔔 System')) }}
                                    </div>
                                    <div>{{ msg.body }}</div>
                                    <div v-if="msg.quick_replies && msg.quick_replies.length" class="flex flex-wrap gap-1.5 mt-2">
                                        <span v-for="qr in msg.quick_replies" :key="qr.id"
                                            class="px-2 py-0.5 rounded-full text-[11px] bg-white/20 border border-white/30">
                                            {{ qr.label }}
                                        </span>
                                    </div>
                                </div>
                                <span class="text-[10px] text-gray-400 mt-1 px-1">
                                    {{ formatDate(msg.created_at) }}
                                </span>
                            </div>
                        </div>

                        <!-- Direct Admin Reply Input -->
                        <form @submit.prevent="sendAdminReply" class="p-3.5 border-t border-gray-200 dark:border-secondary-700 bg-white dark:bg-secondary-800 flex gap-2">
                            <input
                                v-model="replyText"
                                type="text"
                                placeholder="Write a direct Admin reply (sends instant FCM push notification)..."
                                class="flex-1 rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white px-3.5 py-2 text-sm focus:ring-2 focus:ring-emerald-500"
                            />
                            <button
                                type="submit"
                                :disabled="sendingReply || !replyText.trim()"
                                class="px-5 py-2 rounded-lg bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 disabled:opacity-50 transition">
                                {{ sendingReply ? 'Sending...' : 'Send Reply' }}
                            </button>
                        </form>
                    </template>
                </div>
            </div>

            <!-- TAB 3: Buyer <-> Seller Marketplace Chats (Read-Only Safety Monitor) -->
            <div v-else class="bg-white dark:bg-secondary-800 rounded-2xl border border-gray-200 dark:border-secondary-700 shadow-sm overflow-hidden">
                <div class="p-4 border-b border-gray-200 dark:border-secondary-700 bg-gray-50 dark:bg-secondary-900/50 flex items-center justify-between">
                    <span class="text-sm font-semibold text-gray-700 dark:text-gray-200">
                        Read-only safety log of recent Buyer ↔ Seller conversations
                    </span>
                    <input
                        v-model="chatSearch"
                        type="text"
                        placeholder="Search buyer, seller, item or message..."
                        class="rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white px-3 py-1.5 text-xs w-64"
                    />
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200 dark:divide-secondary-700 text-sm">
                        <thead class="bg-gray-50 dark:bg-secondary-900/40 text-xs uppercase text-gray-500">
                            <tr>
                                <th class="px-4 py-3 text-left">Listing</th>
                                <th class="px-4 py-3 text-left">Buyer</th>
                                <th class="px-4 py-3 text-left">Seller</th>
                                <th class="px-4 py-3 text-left">Latest Message</th>
                                <th class="px-4 py-3 text-left">Updated</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 dark:divide-secondary-700">
                            <tr v-for="c in filteredMarketplaceChats" :key="c.id" class="hover:bg-gray-50 dark:hover:bg-secondary-900/40">
                                <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">{{ c.item_title }}</td>
                                <td class="px-4 py-3 text-gray-700 dark:text-gray-300">
                                    <div>{{ c.buyer_name }}</div>
                                    <div class="text-xs text-gray-400">{{ c.buyer_email }}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-700 dark:text-gray-300">
                                    <div>{{ c.seller_name }}</div>
                                    <div class="text-xs text-gray-400">{{ c.seller_email }}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-700 dark:text-gray-200 max-w-md">
                                    <span class="block truncate" :title="c.latest_chat_message">{{ c.latest_chat_message || '—' }}</span>
                                </td>
                                <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{{ c.updated_date }}</td>
                            </tr>
                            <tr v-if="filteredMarketplaceChats.length === 0">
                                <td colspan="5" class="px-4 py-8 text-center text-gray-400">No marketplace chats found.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </ps-layout>
</template>

<script setup>
import { computed, nextTick, ref } from 'vue';
import axios from 'axios';
import { Head, Link } from '@inertiajs/vue3';
import PsLayout from '@/Components/PsLayout.vue';

const props = defineProps({
    assistantThreads: Array,
    orderThreads: Array,
    marketplaceChats: Array,
});

const activeTab = ref('assistant');
const assistantList = ref([...(props.assistantThreads || [])]);
const orderList = ref([...(props.orderThreads || [])]);
const selectedThread = ref(null);
const loadingThread = ref(false);
const togglingPause = ref(false);
const sendingReply = ref(false);
const replyText = ref('');
const chatSearch = ref('');
const messagesContainer = ref(null);

const currentThreads = computed(() =>
    activeTab.value === 'assistant' ? assistantList.value : orderList.value
);

const filteredMarketplaceChats = computed(() => {
    const q = chatSearch.value.trim().toLowerCase();
    if (!q) return props.marketplaceChats || [];
    return (props.marketplaceChats || []).filter((c) =>
        [c.item_title, c.buyer_name, c.buyer_email, c.seller_name, c.seller_email, c.latest_chat_message]
            .some((v) => String(v || '').toLowerCase().includes(q))
    );
});

async function openThread(id) {
    loadingThread.value = true;
    try {
        const res = await axios.get(route('admin.chabit.threads.show', id));
        selectedThread.value = res.data.thread;
        // Clear unread badge locally
        const list = activeTab.value === 'assistant' ? assistantList.value : orderList.value;
        const found = list.find((t) => t.id === id);
        if (found) found.unread_admin_count = 0;
        await nextTick();
        scrollToBottom();
    } finally {
        loadingThread.value = false;
    }
}

async function togglePause() {
    if (!selectedThread.value) return;
    togglingPause.value = true;
    try {
        const res = await axios.post(route('admin.chabit.threads.togglePause', selectedThread.value.id));
        selectedThread.value.ai_paused = res.data.ai_paused;
        const list = activeTab.value === 'assistant' ? assistantList.value : orderList.value;
        const found = list.find((t) => t.id === selectedThread.value.id);
        if (found) found.ai_paused = res.data.ai_paused;
    } finally {
        togglingPause.value = false;
    }
}

async function sendAdminReply() {
    if (!selectedThread.value || !replyText.value.trim()) return;
    sendingReply.value = true;
    try {
        const res = await axios.post(route('admin.chabit.threads.reply', selectedThread.value.id), {
            body: replyText.value.trim(),
        });
        selectedThread.value.messages.push(res.data.message);
        const list = activeTab.value === 'assistant' ? assistantList.value : orderList.value;
        const found = list.find((t) => t.id === selectedThread.value.id);
        if (found) found.latest_message = res.data.message;
        replyText.value = '';
        await nextTick();
        scrollToBottom();
    } finally {
        sendingReply.value = false;
    }
}

function scrollToBottom() {
    if (messagesContainer.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
    }
}

function formatDate(d) {
    if (!d) return '';
    try {
        return new Date(d).toLocaleString();
    } catch {
        return String(d);
    }
}
</script>
