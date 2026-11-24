# ActaBank — Frontend

Application Flutter d'ActaBank : connexion et inscription, tableau de bord, transactions, transferts et paramètres.

## Stack

- **Flutter** (cible web pour l'instant)
- **Riverpod** — gestion d'état
- **dio** — appels à l'API, avec ajout automatique du jeton JWT et déconnexion sur 401
- **flutter_secure_storage** — stockage du jeton
- **fl_chart** — graphiques

## Organisation

```
lib/
├── core/            # configuration, client HTTP, jeton, formatage, thème, widgets communs
└── features/        # un dossier par fonctionnalité
    ├── auth/          # connexion, inscription, état d'authentification
    ├── dashboard/     # tableau de bord, statistiques, carte « Premiers pas »
    ├── transactions/  # liste, formulaire, transferts
    ├── recurring/     # paiements récurrents
    ├── settings/      # banques, comptes, moyens de paiement, catégories, tags
    └── shell/         # navigation principale
```

## Lancer en développement

```bash
flutter pub get
flutter run -d web-server --web-port=8081
```

Puis ouvrir http://localhost:8081. L'API attendue par défaut est `http://localhost:8000` ; une autre adresse se passe à la compilation :

```bash
flutter run -d web-server --web-port=8081 --dart-define=API_URL=http://autre-adresse:8000
```

`flutter_secure_storage` utilise l'API WebCrypto du navigateur, disponible uniquement en **contexte sécurisé** : HTTPS ou `localhost`.

## Construire pour la production

```bash
flutter build web --release --dart-define=API_URL=/api
docker build -t ghcr.io/actarus35/actabank-web:X.Y.Z .
```

L'image nginx sert l'application et relaie `/api/` vers l'API : le navigateur voit une seule origine, et le CORS n'est plus nécessaire.