<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dressy – Conditions Générales d'Utilisation</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Playfair+Display:wght@600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #FAF7F2;
            --burgundy: #5C1A2B;
            --text-dark: #1E1B18;
            --text-muted: #6B655F;
            --card-bg: #FFFFFF;
            --border-color: #E8E2D9;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--bg-color);
            color: var(--text-dark);
            line-height: 1.7;
            padding: 40px 20px;
        }
        .container {
            max-width: 780px;
            margin: 0 auto;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 48px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.03);
        }
        .brand-name {
            font-family: 'Playfair Display', serif;
            font-size: 32px;
            font-weight: 700;
            color: var(--burgundy);
            text-align: center;
            margin-bottom: 24px;
        }
        h2 { font-size: 22px; color: var(--burgundy); margin-bottom: 12px; }
        h3 { font-size: 16px; margin: 24px 0 10px; color: var(--text-dark); }
        p { font-size: 14.5px; margin-bottom: 14px; }
        ul, ol { margin: 10px 0 16px 24px; font-size: 14px; }
        li { margin-bottom: 6px; }
        a { color: var(--burgundy); text-decoration: underline; }
        .footer { text-align: center; margin-top: 40px; border-top: 1px solid var(--border-color); padding-top: 20px; font-size: 12.5px; color: var(--text-muted); }
    </style>
</head>
<body>
    <div class="container">
        <div class="brand-name">Dressy</div>
        {!! $content !!}
        <div class="footer">
            <p>Dressy Algérie – <a href="https://www.dressy-dz.com">www.dressy-dz.com</a> • Contact : <a href="mailto:biadwalid@gmail.com">biadwalid@gmail.com</a></p>
            <p style="margin-top: 6px;"><a href="{{ url('/privacy-policy') }}">Politique de Confidentialité</a> • <a href="{{ url('/account-deletion') }}">Suppression de Compte</a></p>
        </div>
    </div>
</body>
</html>
