# Modèle de données

> **Source de vérité** : les modèles SQLAlchemy dans `backend/models/` et la migration Alembic
> dans `backend/alembic/versions/`. Ce document n'en est qu'un résumé lisible — en cas de
> divergence, **le code fait foi**.

## Vue d'ensemble

Une transaction est l'entité centrale. Elle est toujours rattachée à un moyen de paiement,
et optionnellement à une étiquette et à une récurrence.

```
banks (établissement)
  └── transaction_methods (carte, virement, chèque, espèces)
        └── transactions
              ├── labels                 (optionnel)
              └── recurring_transactions (optionnel)
```

## Tables

### `banks` — les établissements bancaires

| Colonne | Type | Contraintes |
|---|---|---|
| `bank_id` | INTEGER | clé primaire |
| `bank_name` | VARCHAR(30) | NOT NULL |
| `bank_account_type` | enum `AccountType` | NOT NULL |
| `bank_description` | VARCHAR | nullable |

### `accounts`

Table **non implémentée** — voir la section « Évolution décidée » en bas de ce document.

### `transaction_methods` — les moyens de paiement

| Colonne | Type | Contraintes |
|---|---|---|
| `transmet_id` | INTEGER | clé primaire |
| `transmet_type` | enum `TransactionType` | nullable |
| `bank_id` | INTEGER | FK → `banks.bank_id`, nullable |

`bank_id` est nullable pour permettre les paiements en espèces, qui ne dépendent d'aucune banque.

### `transactions` — l'entité centrale

| Colonne | Type | Contraintes |
|---|---|---|
| `transac_id` | INTEGER | clé primaire |
| `transac_name` | VARCHAR | NOT NULL |
| `transac_date` | DATETIME | NOT NULL |
| `transac_amount` | NUMERIC(10,2) | NOT NULL |
| `transac_description` | VARCHAR | nullable |
| `transmet_id` | INTEGER | FK → `transaction_methods`, **NOT NULL** |
| `label_id` | INTEGER | FK → `labels`, nullable, `ON DELETE SET NULL` |
| `rectrans_id` | INTEGER | FK → `recurring_transactions`, nullable, `ON DELETE SET NULL` |

Le montant est en `NUMERIC(10,2)` (et non en flottant) pour éviter toute dérive d'arrondi
sur des valeurs monétaires.

### `labels` — les étiquettes de catégorisation

| Colonne | Type | Contraintes |
|---|---|---|
| `label_id` | INTEGER | clé primaire |
| `label_name` | VARCHAR | NOT NULL |
| `label_color` | enum `Color` | NOT NULL, défaut `WHITE` |

### `recurring_transactions` — les règles de récurrence

| Colonne | Type | Contraintes |
|---|---|---|
| `rectrans_id` | INTEGER | clé primaire |
| `rectrans_frequency` | enum `Frequency` | NOT NULL |
| `rectrans_start_date` | DATETIME | NOT NULL |
| `rectrans_end_date` | DATETIME | nullable |

## Énumérations

Définies dans `backend/enums/`.

| Enum | Valeurs |
|---|---|
| `AccountType` | `LIVRET_A`, `COMPTE_COURANT`, `LIVRET_JEUNE` |
| `TransactionType` | `ESPECE`, `CARTE`, `VIREMENT`, `CHEQUE` |
| `Color` | `BLACK`, `BLUE`, `BROWN`, `GRAY`, `GREEN`, `ORANGE`, `PINK`, `PURPLE`, `RED`, `WHITE`, `YELLOW` |
| `Frequency` | `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` |

> À noter : depuis SQLAlchemy 2.0, un `Enum` ne crée **pas** de contrainte `CHECK` en base par
> défaut. Les colonnes sont de simples `VARCHAR` : c'est **Pydantic** qui refuse les valeurs
> invalides à l'entrée de l'API.

## Intégrité référentielle

Les clés étrangères SQLite sont activées explicitement par un *event listener* dans
`backend/database.py` (`PRAGMA foreign_keys=ON`) — sans cela, SQLite les ignorerait.

**À la suppression d'un parent :**

| Suppression | Comportement | Où c'est appliqué |
|---|---|---|
| Une banque utilisée par des moyens de paiement | **409 Conflict** — refusée | logique métier (route) |
| Un moyen de paiement utilisé par des transactions | **409 Conflict** — refusée | logique métier (route) |
| Une étiquette utilisée par des transactions | `label_id` passe à `NULL` | base (`ON DELETE SET NULL`) |
| Une récurrence utilisée par des transactions | `rectrans_id` passe à `NULL` | base (`ON DELETE SET NULL`) |

La distinction est volontaire : une banque et un moyen de paiement sont **structurants**, on
refuse de les supprimer tant qu'ils servent. Une étiquette ou une récurrence sont de simples
qualificatifs : la transaction leur survit, simplement dé-taggée.

**À la création ou modification**, toute référence vers une ressource inexistante
(`transmet_id`, `label_id`, `rectrans_id`, `bank_id`) est refusée avec un **422** et un message
nommant la ressource manquante. Aucune violation de clé étrangère ne remonte donc en 500.

## Évolution décidée (non encore implémentée)

Deux décisions d'architecture ont été prises et sont documentées dans le vault Obsidian :

- **[[Décision - Séparation Établissement et Compte]]** — introduire une table `accounts`.
  `banks` ne portera plus que l'établissement ; le type de compte et le solde initial
  passeront sur `accounts` ; `transaction_methods.bank_id` deviendra `account_id`.
- **[[Décision - Architecture multi-utilisateurs]]** — introduire une table `users`
  (bcrypt) et un `user_id` sur les ressources exposées par l'API.

Schéma cible :

```
users
 ├── banks
 │    └── accounts
 │         └── transaction_methods ──┐
 ├── labels ────────────────────────┤
 └── recurring_transactions ────────┴── transactions
```

Ce document devra être mis à jour une fois la restructuration effectuée.
