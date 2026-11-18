<?php

namespace App\Models\Chabit;

use Illuminate\Database\Eloquent\Model;

class ChabitSetting extends Model
{
    protected $table = 'chabit_settings';

    protected $fillable = [
        'gemini_api_key',
        'gemini_model',
        'is_enabled',
        'auto_approve_items',
        'auto_approve_confidence',
        'app_knowledge_base',
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
        'auto_approve_items' => 'boolean',
        'auto_approve_confidence' => 'integer',
    ];

    public static function current(): self
    {
        $setting = self::first();
        if (! $setting) {
            $setting = self::create([
                'gemini_api_key' => env('GEMINI_API_KEY'),
                'gemini_model' => 'gemini-3.6-flash',
                'is_enabled' => true,
                'auto_approve_items' => true,
                'auto_approve_confidence' => 85,
                'app_knowledge_base' => self::defaultKnowledgeBase(),
            ]);
        }

        if (empty($setting->app_knowledge_base)) {
            $setting->app_knowledge_base = self::defaultKnowledgeBase();
        }

        return $setting;
    }

    public function getEffectiveApiKey(): ?string
    {
        $raw = (string) ($this->gemini_api_key ?: env('GEMINI_API_KEY', ''));
        $key = preg_replace('/\s+/', '', trim($raw));

        return $key !== '' ? $key : null;
    }

    public function getMaskedApiKey(): string
    {
        $key = $this->getEffectiveApiKey();
        if (! $key) {
            return '';
        }
        if (strlen($key) <= 8) {
            return str_repeat('*', strlen($key));
        }

        return substr($key, 0, 4).str_repeat('*', max(8, strlen($key) - 8)).substr($key, -4);
    }

    public static function defaultKnowledgeBase(): string
    {
        return <<<'KB'
=== DRESSY MARKETPLACE RULES (ALGERIA) ===

[FRANÇAIS]
- Couverture : Dressy couvre les 58 wilayas d'Algérie.
- Devise : Dinar Algérien (DZD / DA).
- Paiement : Paiement à la livraison (Cash on Delivery / COD). L'acheteur paie au livreur Yalidine à la réception.
- Livraison : Expédition nationale assurée par Yalidine Express (Stop Desk / bureau Yalidine ou livraison à domicile). Chaque vendeur expédie son propre colis (le panier est réservé aux articles d'un même vendeur).
- Portefeuille Escrow & Retraits : Les fonds des ventes livrées sont sécurisés dans le portefeuille Dressy (Escrow) puis libérés dès confirmation de paiement COD. Les retraits (CCP / BaridiMob) sont traités par l'administration deux fois par semaine.
- Politique stricte anti-contact externe : Il est strictement interdit d'afficher des numéros de téléphone, WhatsApp, Instagram, Facebook ou liens externes dans les photos, titres, descriptions d'annonces ou dans le chat. Toute transaction doit passer par Dressy pour garantir la protection acheteur/vendeur.

[العربية]
- التغطية: يغطي تطبيق Dressy جميع الولايات الـ 58 في الجزائر.
- العملة: الدينار الجزائري (DZD / دج).
- الدفع: الدفع عند الاستلام (COD) مباشرة لعامل توصيل ياليدين.
- التوصيل: الشحن عبر Yalidine Express (توصيل للمنزل أو لمكتب ياليدين Stop Desk). كل بائع يشحن طرده بشكل منفصل (السلة مخصصة لمنتجات بائع واحد فقط).
- المحفظة والضمان (Escrow) والسحب: تُحفظ أموال المبيعات بأمان في محفظة Dressy وتُحرَّر بعد تأكيد الدفع عند الاستلام. تتم معالجة طلبات السحب (CCP / BaridiMob) من طرف الإدارة مرتين في الأسبوع.
- سياسة منع الأرقام الخارجية: يُمنع منعاً باتاً وضع أرقام الهاتف أو واتساب أو حسابات التواصل الاجتماعي في الصور أو العنوان أو الوصف أو المحادثات.

[ENGLISH]
- Coverage: Dressy operates across all 58 wilayas of Algeria.
- Currency: Algerian Dinar (DZD).
- Payment: Cash on Delivery (COD) paid upon parcel arrival with Yalidine Express.
- Delivery: Nationwide shipping via Yalidine Express (Home delivery or Stop Desk). Each seller ships separately (cart holds items from one seller per shipment).
- Escrow Wallet & Payouts: Seller earnings are protected in the Dressy Escrow wallet and released after COD settlement. Payouts (CCP / BaridiMob) are processed manually by Dressy admins twice per week (AI never approves withdrawals).
- Strict No-Phone Policy: Phone numbers, WhatsApp, social handles, or external links are strictly prohibited in listing photos, titles, descriptions, and chat messages.
KB;
    }
}
