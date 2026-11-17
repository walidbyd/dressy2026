<!DOCTYPE html>
<html lang="fr" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dressy — Mode & Seconde Main en Algérie | Télécharger l'Application</title>
    <meta name="description" content="Dressy est l'application n°1 d'achat et vente de vêtements, chaussures et accessoires de mode en Algérie. Vendez en 30s, livraison sécurisée Yalidine Express sur les 58 Wilayas.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,600;0,700;1,500&family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-warm: #FAF7F2;
            --burgundy: #5C1A2B;
            --burgundy-dark: #43121F;
            --burgundy-light: #F7EFF1;
            --coral: #E07A7A;
            --charcoal: #232328;
            --text-dark: #1F1C1B;
            --text-muted: #6B635B;
            --border: #EADBCC;
            --border-light: #F2EBE1;
            --card-bg: #FFFFFF;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-warm);
            color: var(--text-dark);
            line-height: 1.6;
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
        }

        html[dir="rtl"] body {
            font-family: 'Noto Sans Arabic', 'Plus Jakarta Sans', sans-serif;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
        }

        /* Header */
        header {
            padding: 24px 0;
            border-bottom: 1px solid var(--border-light);
            background: rgba(250, 247, 242, 0.95);
            position: sticky;
            top: 0;
            z-index: 50;
            backdrop-filter: blur(10px);
        }

        .nav-wrap {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .logo-wrap {
            display: flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
        }

        .logo-badge {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: var(--burgundy);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Playfair Display', serif;
            font-size: 22px;
            font-weight: 700;
            box-shadow: 0 4px 14px rgba(92, 26, 43, 0.25);
        }

        .logo-text {
            font-family: 'Playfair Display', serif;
            font-size: 28px;
            font-weight: 700;
            color: var(--burgundy);
            letter-spacing: -0.5px;
        }

        .lang-switch {
            display: flex;
            background: #EFE8DE;
            padding: 4px;
            border-radius: 20px;
            gap: 2px;
        }

        .lang-btn {
            border: none;
            background: transparent;
            padding: 6px 14px;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-muted);
            border-radius: 16px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .lang-btn.active {
            background: #fff;
            color: var(--burgundy);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
        }

        /* Hero */
        .hero {
            padding: 70px 0 80px;
        }

        .hero-grid {
            display: grid;
            grid-template-columns: 1.15fr 0.85fr;
            align-items: center;
            gap: 60px;
        }

        .badge-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--burgundy-light);
            border: 1px solid rgba(92, 26, 43, 0.15);
            color: var(--burgundy);
            padding: 8px 16px;
            border-radius: 30px;
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 24px;
        }

        .badge-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--coral);
        }

        .hero h1 {
            font-family: 'Playfair Display', serif;
            font-size: 52px;
            font-weight: 700;
            line-height: 1.15;
            color: var(--burgundy);
            margin-bottom: 22px;
            letter-spacing: -1px;
        }

        .hero p.lead {
            font-size: 18px;
            color: var(--text-muted);
            line-height: 1.65;
            margin-bottom: 36px;
            max-width: 540px;
        }

        /* Download CTAs */
        .download-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            align-items: center;
            margin-bottom: 24px;
        }

        .store-btn {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            background: var(--charcoal);
            color: #fff;
            padding: 12px 22px;
            border-radius: 14px;
            text-decoration: none;
            transition: all 0.25s ease;
            box-shadow: 0 6px 20px rgba(35, 35, 40, 0.18);
        }

        .store-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(35, 35, 40, 0.28);
            background: #17171a;
        }

        .store-btn svg {
            width: 26px;
            height: 26px;
            fill: currentColor;
            flex-shrink: 0;
        }

        .store-btn .sub {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            opacity: 0.75;
            display: block;
            line-height: 1.2;
        }

        .store-btn .main {
            font-size: 16px;
            font-weight: 700;
            letter-spacing: -0.3px;
            line-height: 1.2;
        }

        .apk-fallback {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: var(--burgundy);
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            padding: 10px 16px;
            border-radius: 12px;
            border: 1px dashed rgba(92, 26, 43, 0.35);
            background: rgba(92, 26, 43, 0.03);
            transition: all 0.2s ease;
        }

        .apk-fallback:hover {
            background: rgba(92, 26, 43, 0.08);
            border-color: var(--burgundy);
        }

        /* Mockup */
        .mockup-wrap {
            position: relative;
            display: flex;
            justify-content: center;
        }

        .phone-frame {
            width: 310px;
            height: 620px;
            background: #111;
            border-radius: 46px;
            padding: 12px;
            box-shadow: 0 25px 60px rgba(92, 26, 43, 0.22), 0 10px 25px rgba(0, 0, 0, 0.15);
            position: relative;
            border: 4px solid #333;
        }

        .phone-screen {
            width: 100%;
            height: 100%;
            background: #FAF7F2;
            border-radius: 36px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            position: relative;
        }

        .screen-notch {
            width: 120px;
            height: 20px;
            background: #111;
            border-radius: 0 0 14px 14px;
            margin: 0 auto;
        }

        .app-header {
            padding: 12px 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #EFE8DE;
        }

        .app-brand {
            font-family: 'Playfair Display', serif;
            font-weight: 700;
            color: var(--burgundy);
            font-size: 20px;
        }

        .seller-stories {
            display: flex;
            gap: 10px;
            padding: 14px 14px 10px;
            overflow: hidden;
        }

        .seller-avatar {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            padding: 2px;
            background: linear-gradient(135deg, var(--burgundy), var(--coral));
            flex-shrink: 0;
        }

        .seller-avatar-inner {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            background: #E8DFD3;
            border: 2px solid #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 700;
            color: var(--burgundy);
        }

        .product-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            padding: 8px 14px;
            flex: 1;
        }

        .product-card {
            background: #fff;
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid #EFE8DE;
            display: flex;
            flex-direction: column;
        }

        .product-img {
            height: 115px;
            background: #EDE6DC;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
            font-size: 12px;
            position: relative;
        }

        .product-tag {
            position: absolute;
            bottom: 6px;
            left: 6px;
            background: rgba(92, 26, 43, 0.9);
            color: #fff;
            font-size: 9px;
            font-weight: 700;
            padding: 2px 6px;
            border-radius: 6px;
        }

        .product-body {
            padding: 8px 10px;
        }

        .product-title {
            font-size: 11px;
            font-weight: 600;
            color: var(--text-dark);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .product-price {
            font-size: 13px;
            font-weight: 700;
            color: var(--burgundy);
            margin-top: 2px;
        }

        /* Floating Nav in Mockup */
        .mockup-nav {
            position: absolute;
            bottom: 12px;
            left: 14px;
            right: 14px;
            height: 50px;
            background: #232328;
            border-radius: 26px;
            display: flex;
            align-items: center;
            justify-content: space-around;
            padding: 0 10px;
            box-shadow: 0 6px 18px rgba(0, 0, 0, 0.35);
        }

        .mockup-nav-icon {
            width: 20px;
            height: 20px;
            color: #9CA3AF;
        }

        .mockup-nav-center {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: #E07A7A;
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            font-weight: bold;
        }

        /* Features Section */
        .features {
            padding: 80px 0;
            background: #FAF7F2;
            border-top: 1px solid var(--border-light);
        }

        .section-header {
            text-align: center;
            max-width: 650px;
            margin: 0 auto 50px;
        }

        .section-header h2 {
            font-family: 'Playfair Display', serif;
            font-size: 38px;
            color: var(--burgundy);
            margin-bottom: 14px;
        }

        .section-header p {
            color: var(--text-muted);
            font-size: 16px;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 28px;
        }

        .feature-card {
            background: var(--card-bg);
            padding: 36px 28px;
            border-radius: 22px;
            border: 1px solid var(--border-light);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.03);
            transition: all 0.25s ease;
        }

        .feature-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 14px 30px rgba(92, 26, 43, 0.08);
            border-color: var(--border);
        }

        .feature-icon-wrap {
            width: 58px;
            height: 58px;
            border-radius: 16px;
            background: var(--burgundy-light);
            color: var(--burgundy);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 22px;
        }

        .feature-card h3 {
            font-size: 20px;
            font-weight: 700;
            color: var(--text-dark);
            margin-bottom: 12px;
        }

        .feature-card p {
            color: var(--text-muted);
            font-size: 15px;
            line-height: 1.6;
        }

        /* Footer */
        footer {
            background: #232328;
            color: #A39B94;
            padding: 50px 0 35px;
            font-size: 14px;
        }

        .footer-wrap {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 24px;
            padding-bottom: 30px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .footer-brand {
            font-family: 'Playfair Display', serif;
            font-size: 26px;
            font-weight: 700;
            color: #fff;
        }

        .footer-links {
            display: flex;
            gap: 24px;
            flex-wrap: wrap;
        }

        .footer-links a {
            color: #CBC4BC;
            text-decoration: none;
            transition: color 0.2s ease;
        }

        .footer-links a:hover {
            color: #fff;
        }

        .footer-bottom {
            padding-top: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
            font-size: 13px;
        }

        /* Responsive */
        @media (max-width: 900px) {
            .hero-grid {
                grid-template-columns: 1fr;
                gap: 50px;
                text-align: center;
            }

            .hero h1 {
                font-size: 40px;
            }

            .hero p.lead {
                margin: 0 auto 30px;
            }

            .download-actions {
                justify-content: center;
            }

            .features-grid {
                grid-template-columns: 1fr;
            }

            .footer-wrap, .footer-bottom {
                flex-direction: column;
                text-align: center;
            }
        }
    </style>
</head>
<body>

    <!-- Header -->
    <header>
        <div class="container nav-wrap">
            <a href="/" class="logo-wrap">
                <div class="logo-badge">D</div>
                <div class="logo-text">Dressy</div>
            </a>
            <div class="lang-switch">
                <button class="lang-btn active" onclick="setLang('fr')">FR</button>
                <button class="lang-btn" onclick="setLang('ar')">عربي</button>
                <button class="lang-btn" onclick="setLang('en')">EN</button>
            </div>
        </div>
    </header>

    <!-- Hero Section -->
    <section class="hero">
        <div class="container hero-grid">
            <div class="hero-content">
                <div class="badge-pill">
                    <span class="badge-dot"></span>
                    <span data-i18n="pill">La Mode & Seconde Main en Algérie • 58 Wilayas</span>
                </div>
                <h1 data-i18n="hero_title">Achetez et vendez votre mode en toute simplicité.</h1>
                <p class="lead" data-i18n="hero_desc">
                    Rejoignez la communauté Dressy. Donnez une seconde vie à votre dressing, découvrez des pépites uniques, profitez de la livraison sécurisée Yalidine Express à domicile ou en point relais, et réglez en espèces à la livraison.
                </p>

                <div class="download-actions">
                    <!-- Google Play -->
                    <a href="https://play.google.com/store/apps/details?id=com.dressy.app" class="store-btn" target="_blank" rel="noopener">
                        <svg viewBox="0 0 24 24"><path d="M3.609 1.814L13.792 12 3.61 22.186a1.99 1.99 0 0 1-.61-.954V2.768c.15-.36.37-.69.61-.954zm11.238 11.241l2.483 2.483-11.458 6.577 8.975-9.06zm0-2.11L5.872 1.885l11.458 6.577-2.483 2.483zm1.488 1.055l4.032 2.315c.954.548.954 1.442 0 1.99l-4.032 2.315-2.274-2.274 2.274-2.346z"/></svg>
                        <div>
                            <span class="sub" data-i18n="get_it_on">Disponible sur</span>
                            <span class="main">Google Play</span>
                        </div>
                    </a>

                    <!-- App Store -->
                    <a href="https://apps.apple.com/app/dressy-dz/id000000000" class="store-btn" target="_blank" rel="noopener">
                        <svg viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 0.92-2.85-.9.04-1.99.6-2.63 1.35-.57.65-1.06 1.71-.93 2.73 1.01.08 2.02-.48 2.64-1.23z"/></svg>
                        <div>
                            <span class="sub" data-i18n="download_on">Télécharger sur</span>
                            <span class="main">App Store</span>
                        </div>
                    </a>

                    <!-- Direct APK Download -->
                    <a href="https://www.dressy-dz.com/download/dressy-latest.apk" class="apk-fallback" download>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        <span data-i18n="direct_apk">Télécharger l'APK direct</span>
                    </a>
                </div>
            </div>

            <!-- Mobile Phone Mockup -->
            <div class="mockup-wrap">
                <div class="phone-frame">
                    <div class="phone-screen">
                        <div class="screen-notch"></div>
                        <div class="app-header">
                            <span style="font-size: 16px;">☰</span>
                            <span class="app-brand">Dressy</span>
                            <span style="font-size: 16px;">🛍️</span>
                        </div>
                        <div class="seller-stories">
                            <div class="seller-avatar"><div class="seller-avatar-inner">Amina</div></div>
                            <div class="seller-avatar"><div class="seller-avatar-inner">Sarah</div></div>
                            <div class="seller-avatar"><div class="seller-avatar-inner">ChicDZ</div></div>
                            <div class="seller-avatar"><div class="seller-avatar-inner">Yasmine</div></div>
                        </div>
                        <div class="product-grid">
                            <div class="product-card">
                                <div class="product-img">
                                    👗 Robe Brodée
                                    <span class="product-tag">Taille M</span>
                                </div>
                                <div class="product-body">
                                    <div class="product-title">Karakou Moderne Alger</div>
                                    <div class="product-price">6 500 DA</div>
                                </div>
                            </div>
                            <div class="product-card">
                                <div class="product-img">
                                    👠 Escarpins
                                    <span class="product-tag">Pointure 38</span>
                                </div>
                                <div class="product-body">
                                    <div class="product-title">Escarpins Cuir Zara</div>
                                    <div class="product-price">4 200 DA</div>
                                </div>
                            </div>
                            <div class="product-card">
                                <div class="product-img">
                                    👜 Sac Bandoulière
                                    <span class="product-tag">Unique</span>
                                </div>
                                <div class="product-body">
                                    <div class="product-title">Sac Mango Neuf</div>
                                    <div class="product-price">3 800 DA</div>
                                </div>
                            </div>
                            <div class="product-card">
                                <div class="product-img">
                                    🧥 Blazer Coupe Droite
                                    <span class="product-tag">Taille S</span>
                                </div>
                                <div class="product-body">
                                    <div class="product-title">Blazer Lin Beige</div>
                                    <div class="product-price">5 100 DA</div>
                                </div>
                            </div>
                        </div>
                        <!-- Sleek Floating Nav Bar in Mockup -->
                        <div class="mockup-nav">
                            <span style="color:#fff; font-size:16px;">⌂</span>
                            <span class="mockup-nav-icon">💬</span>
                            <div class="mockup-nav-center">+</div>
                            <span class="mockup-nav-icon">♡</span>
                            <span class="mockup-nav-icon">👤</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="features">
        <div class="container">
            <div class="section-header">
                <h2 data-i18n="why_dressy">Pourquoi choisir Dressy ?</h2>
                <p data-i18n="why_dressy_sub">Une expérience pensée pour les acheteurs et vendeurs algériens, avec sécurité et rapidité à chaque étape.</p>
            </div>

            <div class="features-grid">
                <!-- Feature 1 -->
                <div class="feature-card">
                    <div class="feature-icon-wrap">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                    </div>
                    <h3 data-i18n="f1_title">Vente express en 30s</h3>
                    <p data-i18n="f1_desc">Prenez quelques photos de votre vêtement, précisez la taille et votre prix en Dinars (DZD), et publiez instantanément auprès de milliers d'acheteurs en Algérie.</p>
                </div>

                <!-- Feature 2 -->
                <div class="feature-card">
                    <div class="feature-icon-wrap">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"></rect><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon><circle cx="5.5" cy="18.5" r="2.5"></circle><circle cx="18.5" cy="18.5" r="2.5"></circle></svg>
                    </div>
                    <h3 data-i18n="f2_title">Livraison Yalidine 58 Wilayas</h3>
                    <p data-i18n="f2_desc">Intégration officielle Yalidine Express avec bordereaux automatiques, suivi en temps réel et choix entre livraison à domicile ou retrait en point relais (Stop Desk).</p>
                </div>

                <!-- Feature 3 -->
                <div class="feature-card">
                    <div class="feature-icon-wrap">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                    </div>
                    <h3 data-i18n="f3_title">Paiement sécurisé à la livraison</h3>
                    <p data-i18n="f3_desc">Zéro risque : vous réglez vos achats en espèces (Cash on Delivery) directement au livreur après réception et vérification de votre colis.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="container">
            <div class="footer-wrap">
                <div>
                    <div class="footer-brand">Dressy</div>
                    <p style="margin-top: 6px; font-size: 13px;">La marketplace de mode n°1 en Algérie.</p>
                </div>
                <div class="footer-links">
                    <a href="/terms-and-conditions" data-i18n="link_terms">Conditions Générales (CGU)</a>
                    <a href="/privacy-policy" data-i18n="link_privacy">Politique de Confidentialité</a>
                    <a href="/account-deletion" data-i18n="link_deletion">Suppression de Compte</a>
                </div>
            </div>
            <div class="footer-bottom">
                <div>© 2026 Dressy Algérie. Tous droits réservés.</div>
                <div>Contact & Support : <a href="mailto:biadwalid@gmail.com" style="color: #fff; text-decoration: none;">biadwalid@gmail.com</a></div>
            </div>
        </div>
    </footer>

    <!-- Multilingual Script -->
    <script>
        const i18n = {
            fr: {
                pill: "La Mode & Seconde Main en Algérie • 58 Wilayas",
                hero_title: "Achetez et vendez votre mode en toute simplicité.",
                hero_desc: "Rejoignez la communauté Dressy. Donnez une seconde vie à votre dressing, découvrez des pépites uniques, profitez de la livraison sécurisée Yalidine Express à domicile ou en point relais, et réglez en espèces à la livraison.",
                get_it_on: "Disponible sur",
                download_on: "Télécharger sur",
                direct_apk: "Télécharger l'APK direct",
                why_dressy: "Pourquoi choisir Dressy ?",
                why_dressy_sub: "Une expérience pensée pour les acheteurs et vendeurs algériens, avec sécurité et rapidité à chaque étape.",
                f1_title: "Vente express en 30s",
                f1_desc: "Prenez quelques photos de votre vêtement, précisez la taille et votre prix en Dinars (DZD), et publiez instantanément auprès de milliers d'acheteurs en Algérie.",
                f2_title: "Livraison Yalidine 58 Wilayas",
                f2_desc: "Intégration officielle Yalidine Express avec bordereaux automatiques, suivi en temps réel et choix entre livraison à domicile ou retrait en point relais (Stop Desk).",
                f3_title: "Paiement sécurisé à la livraison",
                f3_desc: "Zéro risque : vous réglez vos achats en espèces (Cash on Delivery) directement au livreur après réception et vérification de votre colis.",
                link_terms: "Conditions Générales (CGU)",
                link_privacy: "Politique de Confidentialité",
                link_deletion: "Suppression de Compte"
            },
            ar: {
                pill: "منصة الموضة والملابس المستعملة في الجزائر • 58 ولاية",
                hero_title: "اشتري وبيعي ملابسك بكل سهولة وأمان.",
                hero_desc: "انضمي إلى مجتمع Dressy. امنحي ملابسك حياة ثانية، اكتشفي قطعاً فريدة بأسعار مميزة، واستفيدي من التوصيل الموثوق عبر ياليدين إكسبريس والدفع نقداً عند الاستلام في جميع ولايات الجزائر.",
                get_it_on: "متوفر على",
                download_on: "حمليه من",
                direct_apk: "تحميل ملف APK المباشر",
                why_dressy: "لماذا تختارين Dressy؟",
                why_dressy_sub: "تجربة مصممة خصيصاً للمتسوقين والبائعين في الجزائر، بأعلى معايير الأمان والسرعة.",
                f1_title: "بيع سريع في 30 ثانية",
                f1_desc: "التقطي صوراً للملابس، حددي المقاس والسعر بالدينار الجزائري، وانشري إعلانكِ فوراً لآلاف المشترين المهتمين.",
                f2_title: "توصيل ياليدين لـ 58 ولاية",
                f2_desc: "ربط متكامل مع ياليدين إكسبريس لتوليد بوليصات الشحن تلقائياً، مع إمكانية التوصيل للمنزل أو الاستلام من مكتب Stop Desk.",
                f3_title: "دفع آمن عند الاستلام",
                f3_desc: "بدون أي مخاطرة : قومي بالدفع نقداً (COD) مباشرة لرجل التوصيل بعد استلام وفحص طردكِ بكل راحة واطمئنان.",
                link_terms: "شروط الاستخدام (CGU)",
                link_privacy: "سياسة الخصوصية",
                link_deletion: "حذف الحساب والبيانات"
            },
            en: {
                pill: "Fashion & Pre-loved Marketplace in Algeria • 58 Wilayas",
                hero_title: "Buy and sell your fashion with ease.",
                hero_desc: "Join the Dressy community. Give a second life to your wardrobe, find unique fashion gems, enjoy Yalidine Express tracked delivery to your doorstep or pickup desk, and pay securely with Cash on Delivery.",
                get_it_on: "GET IT ON",
                download_on: "Download on the",
                direct_apk: "Direct APK Download",
                why_dressy: "Why choose Dressy?",
                why_dressy_sub: "An editorial experience crafted for Algerian buyers and sellers, built for speed and security.",
                f1_title: "Quick 30s Listing",
                f1_desc: "Snap a few photos of your item, pick the size and price in DZD, and reach thousands of passionate buyers instantly across Algeria.",
                f2_title: "Yalidine Shipping across 58 Wilayas",
                f2_desc: "Official Yalidine Express integration with automated parcels, live tracking, and flexible delivery to your home or nearest Stop Desk.",
                f3_title: "Secure Cash on Delivery",
                f3_desc: "Zero risk: inspect your package upon arrival and pay in cash directly to the courier upon delivery.",
                link_terms: "Terms & Conditions",
                link_privacy: "Privacy Policy",
                link_deletion: "Account Deletion"
            }
        };

        function setLang(lang) {
            document.documentElement.lang = lang;
            document.documentElement.dir = (lang === 'ar') ? 'rtl' : 'ltr';

            document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
            const activeBtn = Array.from(document.querySelectorAll('.lang-btn')).find(b => b.textContent.toLowerCase().includes(lang === 'ar' ? 'عربي' : lang));
            if (activeBtn) activeBtn.classList.add('active');

            const texts = i18n[lang];
            document.querySelectorAll('[data-i18n]').forEach(el => {
                const key = el.getAttribute('data-i18n');
                if (texts[key]) el.textContent = texts[key];
            });

            localStorage.setItem('dressy_lang', lang);
        }

        // Initialize preferred or stored language
        const savedLang = localStorage.getItem('dressy_lang') || 'fr';
        setLang(savedLang);
    </script>
</body>
</html>
