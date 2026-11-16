<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dressy – Demande de Suppression de Compte</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Playfair+Display:wght@600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #FAF7F2;
            --burgundy: #5C1A2B;
            --burgundy-hover: #481321;
            --text-dark: #1E1B18;
            --text-muted: #6B655F;
            --card-bg: #FFFFFF;
            --border-color: #E8E2D9;
            --success: #15803D;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--bg-color);
            color: var(--text-dark);
            line-height: 1.6;
            padding: 40px 20px;
        }
        .container {
            max-width: 680px;
            margin: 0 auto;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.03);
        }
        .logo-wrap {
            text-align: center;
            margin-bottom: 24px;
        }
        .brand-name {
            font-family: 'Playfair Display', serif;
            font-size: 36px;
            font-weight: 700;
            color: var(--burgundy);
            letter-spacing: 1px;
        }
        h1 {
            font-size: 22px;
            font-weight: 700;
            color: var(--text-dark);
            margin-bottom: 12px;
            text-align: center;
        }
        .subtitle {
            font-size: 14px;
            color: var(--text-muted);
            text-align: center;
            margin-bottom: 30px;
        }
        .info-card {
            background-color: #FFF8F6;
            border-left: 4px solid var(--burgundy);
            padding: 16px 20px;
            border-radius: 8px;
            margin-bottom: 28px;
            font-size: 14px;
        }
        .info-card strong {
            color: var(--burgundy);
        }
        .step-list {
            margin: 16px 0 0 20px;
            font-size: 13.5px;
            color: var(--text-dark);
        }
        .step-list li {
            margin-bottom: 6px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-dark);
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        input[type="text"], input[type="email"], textarea {
            width: 100%;
            padding: 12px 16px;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            font-family: inherit;
            font-size: 14px;
            background: #FAFAFA;
            outline: none;
            transition: border-color 0.2s;
        }
        input:focus, textarea:focus {
            border-color: var(--burgundy);
            background: #FFFFFF;
        }
        button.btn-submit {
            width: 100%;
            background-color: var(--burgundy);
            color: #FFFFFF;
            border: none;
            padding: 14px 20px;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        button.btn-submit:hover {
            background-color: var(--burgundy-hover);
        }
        .alert-success {
            background-color: #ECFDF5;
            border: 1px solid #A7F3D0;
            color: var(--success);
            padding: 14px;
            border-radius: 10px;
            font-size: 14px;
            margin-bottom: 20px;
            text-align: center;
        }
        .footer-links {
            text-align: center;
            margin-top: 30px;
            font-size: 12.5px;
            color: var(--text-muted);
        }
        .footer-links a {
            color: var(--burgundy);
            text-decoration: none;
            margin: 0 8px;
        }
        .footer-links a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo-wrap">
            <div class="brand-name">Dressy</div>
        </div>

        <h1>Suppression de Compte & Effacement des Données</h1>
        <p class="subtitle">Conforme aux directives Google Play Store et Apple App Store (Guideline 5.1.1(v))</p>

        @if(session('success'))
            <div class="alert-success">
                ✓ {{ session('success') }}
            </div>
        @endif

        <div class="info-card">
            <strong>Comment supprimer votre compte directement dans l'application :</strong>
            <ol class="step-list">
                <li>Ouvrez l'application <strong>Dressy</strong> sur votre smartphone.</li>
                <li>Rendez-vous dans votre <strong>Profil</strong> (icône en bas à droite).</li>
                <li>Appuyez sur <strong>Paramètres du compte</strong>.</li>
                <li>Faites défiler vers le bas et touchez <strong>« Supprimer mon compte »</strong>.</li>
                <li>Confirmez : la suppression de l'ensemble de vos données est immédiate et irréversible.</li>
            </ol>
        </div>

        <p style="font-size: 14px; margin-bottom: 20px; color: var(--text-muted);">
            Si vous n'avez plus accès à votre appareil mobile, vous pouvez remplir ce formulaire pour demander la suppression manuelle de votre compte et de toutes les données associées :
        </p>

        <form action="{{ url('/account-deletion') }}" method="POST">
            @csrf
            <div class="form-group">
                <label for="identifier">Email ou Numéro de Téléphone *</label>
                <input type="text" id="identifier" name="identifier" required placeholder="Ex: contact@email.com ou 0550123456" value="{{ old('identifier') }}">
            </div>

            <div class="form-group">
                <label for="reason">Motif de la suppression (facultatif)</label>
                <textarea id="reason" name="reason" rows="3" placeholder="Dites-nous pourquoi vous souhaitez supprimer votre compte...">{{ old('reason') }}</textarea>
            </div>

            <button type="submit" class="btn-submit">Demander la suppression définitive</button>
        </form>

        <div class="footer-links">
            <p>Support : <a href="mailto:biadwalid@gmail.com">biadwalid@gmail.com</a></p>
            <p style="margin-top: 6px;">
                <a href="{{ url('/privacy-policy') }}">Politique de Confidentialité</a> •
                <a href="{{ url('/terms-and-conditions') }}">Conditions Générales d'Utilisation</a> •
                <a href="https://www.dressy-dz.com">www.dressy-dz.com</a>
            </p>
        </div>
    </div>
</body>
</html>
