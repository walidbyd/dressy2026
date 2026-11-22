<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $item->title ?? 'Article' }} | Dressy Algérie</title>
    
    <!-- OpenGraph & Social Preview -->
    <meta property="og:title" content="{{ $item->title ?? 'Article sur Dressy' }} - {{ number_format((float)($item->price ?? 0), 0, ',', ' ') }} DZD">
    <meta property="og:description" content="{{ Str::limit($item->description ?? 'Achetez et vendez vos vêtements de mode sur Dressy Algérie.', 150) }}">
    <meta property="og:image" content="{{ $imageUrl }}">
    <meta property="og:url" content="{{ url('/item/' . $item->id) }}">
    <meta property="og:type" content="product">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $item->title ?? 'Article sur Dressy' }}">
    <meta name="twitter:description" content="{{ Str::limit($item->description ?? 'Achetez et vendez vos vêtements sur Dressy.', 150) }}">
    <meta name="twitter:image" content="{{ $imageUrl }}">

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
            max-width: 440px;
            background: #FFFFFF;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.06);
            border: 1px solid #F3F4F6;
        }
        .header {
            padding: 16px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid #F3F4F6;
        }
        .header img {
            height: 32px;
            object-fit: contain;
        }
        .badge {
            background: #FDEEEB;
            color: #ED7768;
            font-size: 12px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 20px;
        }
        .image-container {
            width: 100%;
            height: 360px;
            background: #F3F4F6;
            position: relative;
            overflow: hidden;
        }
        .image-container img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .sold-badge {
            position: absolute;
            top: 14px;
            left: 14px;
            background: rgba(31, 41, 55, 0.9);
            color: white;
            font-size: 12px;
            font-weight: 700;
            padding: 6px 12px;
            border-radius: 8px;
            backdrop-filter: blur(4px);
        }
        .content {
            padding: 20px;
        }
        .title {
            font-size: 19px;
            font-weight: 700;
            color: #111827;
            line-height: 1.35;
            margin-bottom: 8px;
        }
        .price {
            font-size: 22px;
            font-weight: 800;
            color: #ED7768;
            margin-bottom: 16px;
        }
        .seller-row {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            background: #F9FAFB;
            border-radius: 12px;
            margin-bottom: 16px;
            border: 1px solid #F3F4F6;
        }
        .avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            object-fit: cover;
            border: 1.5px solid #E5E7EB;
        }
        .seller-info {
            flex: 1;
        }
        .seller-name {
            font-size: 14px;
            font-weight: 700;
            color: #1F2937;
        }
        .seller-sub {
            font-size: 12px;
            color: #6B7280;
        }
        .description {
            font-size: 13.5px;
            color: #4B5563;
            line-height: 1.55;
            margin-bottom: 20px;
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
            text-align: center;
            font-size: 12px;
            color: #9CA3AF;
            margin-top: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('LOGO_DRESSY.png') }}" alt="Dressy">
            <span class="badge">Mode & Dressing DZ</span>
        </div>
        <div class="image-container">
            <img src="{{ $imageUrl }}" alt="{{ $item->title }}">
            @if(isset($item->is_sold_out) && $item->is_sold_out == '1')
                <div class="sold-badge">✓ Vendu</div>
            @endif
        </div>
        <div class="content">
            <h1 class="title">{{ $item->title ?? 'Article Dressy' }}</h1>
            <div class="price">{{ number_format((float)($item->price ?? 0), 0, ',', ' ') }} DZD</div>
            
            @if($sellerName)
            <div class="seller-row">
                <img class="avatar" src="{{ $sellerAvatar }}" alt="{{ $sellerName }}">
                <div class="seller-info">
                    <div class="seller-name">{{ $sellerName }}</div>
                    <div class="seller-sub">{{ $location ?? 'Algérie' }}</div>
                </div>
            </div>
            @endif

            @if($item->description)
                <p class="description">{{ Str::limit($item->description, 180) }}</p>
            @endif

            <a href="dressy://item/{{ $item->id }}" class="cta-btn" id="openAppBtn">
                Ouvrir dans l'application Dressy
            </a>
            <div class="footer-note">Livraison 58 Wilayas disponible avec Yalidine</div>
        </div>
    </div>

    <script>
        // Automatic deep-link attempt if mobile
        window.addEventListener('DOMContentLoaded', function() {
            var appUrl = "dressy://item/{{ $item->id }}";
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
