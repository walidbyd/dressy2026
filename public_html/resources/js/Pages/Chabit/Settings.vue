<template>
    <Head title="Chabit AI Settings" />
    <ps-layout>
        <div class="p-4 sm:p-6 max-w-4xl mx-auto">
            <!-- Header -->
            <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                        <span class="inline-flex items-center justify-center w-9 h-9 rounded-xl bg-purple-600 text-white text-lg">✨</span>
                        Chabit AI Settings
                    </h1>
                    <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        Configure Gemini Vision auto-approval, per-user AI assistant, and Dressy marketplace knowledge base.
                    </p>
                </div>
                <Link
                    :href="route('admin.chabit.messages')"
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gray-900 dark:bg-purple-600 text-white text-sm font-medium hover:opacity-90 transition">
                    Open Unified Message Center →
                </Link>
            </div>

            <!-- Flash Status -->
            <div v-if="$page.props.status?.msg"
                class="mb-5 px-4 py-3 rounded-lg text-sm font-medium bg-emerald-50 border border-emerald-200 text-emerald-800">
                {{ $page.props.status.msg }}
            </div>

            <form @submit.prevent="submit" class="space-y-6 bg-white dark:bg-secondary-800 rounded-2xl shadow-sm border border-gray-200 dark:border-secondary-700 p-6">
                <!-- Gemini API Key & Test Connection -->
                <div>
                    <div class="flex items-center justify-between mb-1.5">
                        <label class="block text-sm font-semibold text-gray-800 dark:text-gray-200">
                            Gemini API Key
                        </label>
                        <span v-if="setting.has_api_key"
                            class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                            ● Saved ({{ setting.masked_api_key }})
                        </span>
                        <span v-else
                            class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
                            ● Not configured
                        </span>
                    </div>
                    <div class="flex flex-col sm:flex-row gap-3">
                        <input
                            v-model="form.gemini_api_key"
                            type="password"
                            autocomplete="new-password"
                            :placeholder="setting.has_api_key ? 'Leave blank to keep saved key, or paste a new key...' : 'Paste your Google AI Studio Gemini API key...'"
                            class="flex-1 rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white px-3.5 py-2.5 text-sm focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
                        />
                        <button
                            type="button"
                            @click="testConnection"
                            :disabled="testing"
                            class="px-4 py-2.5 rounded-lg bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 disabled:opacity-50 transition whitespace-nowrap">
                            {{ testing ? 'Testing...' : 'Test Connection' }}
                        </button>
                    </div>
                    <div v-if="testResult"
                        class="mt-2 text-xs font-medium px-3.5 py-2.5 rounded-lg break-words"
                        :class="testResult.ok ? 'bg-emerald-50 text-emerald-800 border border-emerald-200' : 'bg-rose-50 text-rose-800 border border-rose-200'">
                        <template v-if="testResult.ok">
                            ✅ Connected to <strong>{{ testResult.model }}</strong> (HTTP {{ testResult.http_status || 200 }}) — Reply: {{ testResult.reply }}
                        </template>
                        <template v-else>
                            ❌ Connection failed for <strong>{{ testResult.model }}</strong>
                            <span v-if="testResult.http_status"> (HTTP {{ testResult.http_status }})</span>
                            <span v-else> (Network / cURL Error)</span>:
                            <div class="mt-1 font-mono text-[11px] whitespace-pre-wrap">{{ testResult.error }}</div>
                        </template>
                    </div>
                </div>

                <!-- Gemini Model Selector -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <div>
                        <label class="block text-sm font-semibold text-gray-800 dark:text-gray-200 mb-1.5">
                            Gemini Model
                        </label>
                        <select
                            v-model="form.gemini_model"
                            class="w-full rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white px-3.5 py-2.5 text-sm focus:ring-2 focus:ring-purple-500">
                            <option v-for="m in availableModels" :key="m.id" :value="m.id">
                                {{ m.label }}
                            </option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-semibold text-gray-800 dark:text-gray-200 mb-1.5">
                            Auto-Approve Confidence Threshold (%)
                        </label>
                        <input
                            v-model.number="form.auto_approve_confidence"
                            type="number"
                            min="50"
                            max="100"
                            class="w-full rounded-lg border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white px-3.5 py-2.5 text-sm focus:ring-2 focus:ring-purple-500"
                        />
                        <p class="text-xs text-gray-500 mt-1">
                            Listings with confidence ≥ {{ form.auto_approve_confidence }}% & clean photos publish automatically.
                        </p>
                    </div>
                </div>

                <!-- Feature Toggles -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
                    <label class="flex items-start gap-3 p-4 rounded-xl border border-gray-200 dark:border-secondary-700 cursor-pointer hover:bg-gray-50 dark:hover:bg-secondary-900/40">
                        <input
                            v-model="form.is_enabled"
                            type="checkbox"
                            class="mt-1 h-4 w-4 rounded text-purple-600 focus:ring-purple-500"
                        />
                        <div>
                            <div class="text-sm font-semibold text-gray-900 dark:text-white">Enable Chabit AI Assistant</div>
                            <div class="text-xs text-gray-500 mt-0.5">
                                Allow logged-in buyers & sellers to chat with Chabit (AR / FR / EN) and answer order questions.
                            </div>
                        </div>
                    </label>

                    <label class="flex items-start gap-3 p-4 rounded-xl border border-gray-200 dark:border-secondary-700 cursor-pointer hover:bg-gray-50 dark:hover:bg-secondary-900/40">
                        <input
                            v-model="form.auto_approve_items"
                            type="checkbox"
                            class="mt-1 h-4 w-4 rounded text-purple-600 focus:ring-purple-500"
                        />
                        <div>
                            <div class="text-sm font-semibold text-gray-900 dark:text-white">Auto-Approve Clean Items with Gemini Vision</div>
                            <div class="text-xs text-gray-500 mt-0.5">
                                Automatically inspect up to 4 item photos against selected subcategory & no-phone rules.
                            </div>
                        </div>
                    </label>
                </div>

                <!-- App Knowledge Base -->
                <div>
                    <label class="block text-sm font-semibold text-gray-800 dark:text-gray-200 mb-1.5">
                        Dressy App Knowledge Base (FR / AR / EN)
                    </label>
                    <p class="text-xs text-gray-500 mb-2">
                        Chabit uses these marketplace rules (58 wilayas, DZD, COD, Yalidine Express, Escrow wallet & twice-weekly payouts, no-phone policy) in every assistant reply.
                    </p>
                    <textarea
                        v-model="form.app_knowledge_base"
                        rows="12"
                        class="w-full rounded-xl border border-gray-300 dark:border-secondary-600 dark:bg-secondary-900 dark:text-white p-3.5 text-sm font-mono leading-relaxed focus:ring-2 focus:ring-purple-500"
                    ></textarea>
                </div>

                <!-- Save Button -->
                <div class="flex justify-end pt-2 border-t border-gray-100 dark:border-secondary-700">
                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="px-6 py-2.5 rounded-lg bg-primary-500 text-white text-sm font-semibold hover:bg-primary-600 disabled:opacity-50 transition shadow-sm">
                        {{ form.processing ? 'Saving...' : 'Save Chabit Settings' }}
                    </button>
                </div>
            </form>
        </div>
    </ps-layout>
</template>

<script setup>
import { ref } from 'vue';
import axios from 'axios';
import { Head, Link, useForm } from '@inertiajs/vue3';
import PsLayout from '@/Components/PsLayout.vue';

const props = defineProps({
    setting: Object,
    availableModels: Array,
});

const form = useForm({
    gemini_api_key: '',
    gemini_model: props.setting.gemini_model || 'gemini-3.6-flash',
    is_enabled: !!props.setting.is_enabled,
    auto_approve_items: !!props.setting.auto_approve_items,
    auto_approve_confidence: props.setting.auto_approve_confidence ?? 85,
    app_knowledge_base: props.setting.app_knowledge_base || '',
});

const testing = ref(false);
const testResult = ref(null);

function submit() {
    form.post(route('admin.chabit.settings.update'), {
        preserveScroll: true,
        onSuccess: () => {
            form.gemini_api_key = '';
        },
    });
}

async function testConnection() {
    testing.value = true;
    testResult.value = null;
    try {
        const res = await axios.post(route('admin.chabit.settings.test'), {
            gemini_api_key: form.gemini_api_key || null,
            gemini_model: form.gemini_model,
        });
        testResult.value = res.data;
    } catch (err) {
        const data = err.response?.data;
        if (data && typeof data === 'object' && ('error' in data || 'message' in data)) {
            testResult.value = {
                ok: false,
                model: data.model || form.gemini_model,
                http_status: data.http_status ?? err.response?.status ?? 0,
                error: data.error || data.message || 'Request failed',
            };
        } else {
            testResult.value = {
                ok: false,
                model: form.gemini_model,
                http_status: err.response?.status ?? 0,
                error: err.message || 'Request failed',
            };
        }
    } finally {
        testing.value = false;
    }
}
</script>
