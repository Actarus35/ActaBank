# ActaBank — Frontend

Application Flutter d'ActaBank : connexion, tableau de bord et gestion des transactions.

## Stack

- **Flutter** (cible web pour l'instant)
- **Riverpod** — gestion d'état
- **dio** — appels à l'API, avec ajout automatique du token JWT
- **flutter_secure_storage** — stockage du token
- **fl_chart** — graphiques

## Organisation

```
lib/
├── core/        # configuration, client HTTP, stockage du token, formatage
└── features/    # un dossier par fonctionnalité
    ├── auth/          # connexion, état d'authentification
    ├── dashboard/     # tableau de bord et statistiques
    ├── transactions/  # liste et formulaire
    ├── settings/      # paramètres (à venir)
    └── shell/         # navigation principale
```

## Lancer

```bash
flutter pub get
flutter run -d web-server --web-port=8081
```

Puis ouvrir http://localhost:8081. L'adresse de l'API se règle dans `lib/core/config.dart`.