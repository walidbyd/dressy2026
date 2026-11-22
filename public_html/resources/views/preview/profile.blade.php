<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $name }} | Dressy Dressing</title>
    
    <!-- OpenGraph & Social Preview -->
    <meta property="og:title" content="Dressing de {{ $name }} sur Dressy">
    <meta property="og:description" content="Découvrez les articles de mode, vêtements et accessoires de {{ $name }} sur Dressy Algérie.">
    <meta property="og:image" content="{{ $avatarUrl }}">
    <meta property="og:url" content="{{ url('/profile/' . $id) }}">
    <meta property="og:type" content="profile">
    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="Dressing de {{ $name }} sur Dressy">
    <meta name="twitter:description" content="Découvrez le dressing de {{ $name }} sur Dressy Algérie.">
    <meta name="twitter:image" content="{{ $avatarUrl }}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #F9FAFB;
            color: #1F2937;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            align-items: center;
            justify-content: center;
            padding: 20px 16px;
        }
        .container {
            width: 100%;
            max-width: 420px;
            background: #FFFFFF;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.06);
            border: 1px solid #F3F4F6;
            text-align: center;
            padding: 28px 24px;
        }
        .logo-wrap {
            margin-bottom: 24px;
        }
        .logo-wrap img {
            height: 34px;
            object-fit: contain;
        }
        .avatar-wrap {
            position: relative;
            width: 96px;
            height: 96px;
            margin: 0 auto 16px;
            border-radius: 50%;
            padding: 3px;
            border: 2.5px solid #ED7768;
        }
        .avatar-wrap img {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            object-fit: cover;
        }
        .name {
            font-size: 20px;
            font-weight: 800;
            color: #111827;
            margin-bottom: 6px;
        }
        .location {
            font-size: 13px;
            color: #6B7280;
            margin-bottom: 16px;
        }
        .stats-card {
            display: flex;
            justify-content: space-around;
            background: #FAF7F2;
            border: 1px solid #EBE5DC;
            border-radius: 14px;
            padding: 12px 8px;
            margin-bottom: 24px;
        }
        .stat-item {
            flex: 1;
        }
        .stat-item + .stat-item {
            border-left: 1px solid #E0D8CE;
        }
        .stat-value {
            font-size: 15px;
            font-weight: 800;
            color: #1F2937;
        }
        .stat-label {
            font-size: 11px;
            color: #6B7280;
            font-weight: 600;
            margin-top: 2px;
        }
        .cta-btn {
            display: block;
            width: 100%;
            background: #ED7768;
            color: white;
            text-align: center;
            padding: 14px;
            font-size: 15px;
            font-weight: 700;
            border-radius: 14px;
            text-decoration: none;
            box-shadow: 0 4px 14px rgba(237, 119, 104, 0.35);
            transition: all 0.2s ease;
        }
        .cta-btn:hover {
            background: #E06859;
            transform: translateY(-1px);
        }
        .footer-note {
            font-size: 12px;
            color: #9CA3AF;
            margin-top: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo-wrap">
            <img src="{{ asset('LOGO_DRESSY.png') }}" alt="Dressy">
        </div>
        
        <div class="avatar-wrap">
            <img src="{{ $avatarUrl }}" alt="{{ $name }}">
        </div>

        <h1 class="name">{{ $name }}</h1>
        <div class="location">📍 {{ $location ?? 'Algérie' }}</div>

        <div class="stats-card">
            <div class="stat-item">
                <div class="stat-value">{{ $itemCount ?? 0 }}</div>
                <div class="stat-label">Articles</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">{{ $followers ?? 0 }}</div>
                <div class="stat-label">Abonnés</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">{{ $rating ?? '5.0' }} ★</div>
                <div class="stat-label">Avis</div>
            </div>
        </div>

        <a href="dressy://profile/{{ $id }}" class="cta-btn" id="openAppBtn">
            Voir le dressing dans l'application
        </a>
        <div class="footer-note">Disponible sur Android & iOS</div>
    </div>

    <script>
        // Automatic deep-link attempt if mobile
        window.addEventListener('DOMContentLoaded', function() {
            var appUrl = "dressy://profile/{{ $id }}";
            var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
            if (isMobile) {
                setTimeout(function() {
                    window.location.href = appUrl;
                }, 400);
            }
        });
    </script>
</body>
</html>
