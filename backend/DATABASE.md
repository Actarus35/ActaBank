# Modèle de données

> **Source de vérité** : les modèles SQLAlchemy dans `backend/models/` et la migration Alembic
> dans `backend/alembic/versions/`. Ce document n'en est qu'un résumé lisible — en cas de
> divergence, **le code fait foi**.

Base de données : **PostgreSQL** (lancé via Docker Compose ; voir le README du backend).
Les tests, eux, tournent sur une base SQLite en mémoire.

## Vue d'ensemble

Chaque donnée appartient à un utilisateur (`user_id`). Une transaction est l'entité centrale ;
elle est rattachée à un moyen de paiement, et optionnellement à une étiquette et à une récurrence.

```
users
 ├── banks
 │    └── accounts
 │         └── transaction_methods ──┐
 ├── labels ────────────────────────┤
 └── recurring_transactions ────────┴── transactions
```

Toutes les ressources (hors `users`) portent une colonne `user_id` (FK → `users`, NOT NULL)
qui désigne leur propriétaire. Elle n'est jamais exposée par l'API : elle est déduite du token
JWT, côté serveur.

## Tables

### `users` — les comptes utilisateurs

| Colonne | Type | Contraintes |
|---|---|---|
| `user_id` | INTEGER | clé primaire |
| `user_role` | enum `UserRole` | NOT NULL, défaut `USER` |
| `user_username` | VARCHAR(30) | NOT NULL, **unique** |
| `user_password_hash` | VARCHAR(60) | NOT NULL — empreinte **bcrypt**, jamais le mot de passe |
| `user_created_at` | DATETIME | NOT NULL, défaut = date de création |

### `banks` — les établissements bancaires

| Colonne | Type | Contraintes |
|---|---|---|
| `bank_id` | INTEGER | clé primaire |
| `bank_name` | VARCHAR(30) | NOT NULL |
| `bank_color` | enum `Color` | NOT NULL |
| `bank_description` | VARCHAR | nullable |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

### `accounts` — les comptes d'un établissement

| Colonne | Type | Contraintes |
|---|---|---|
| `account_id` | INTEGER | clé primaire |
| `account_name` | VARCHAR(50) | NOT NULL |
| `account_type` | enum `AccountType` | NOT NULL |
| `account_initial_balance` | NUMERIC(10,2) | NOT NULL |
| `account_description` | VARCHAR | nullable |
| `bank_id` | INTEGER | FK → `banks`, NOT NULL |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

Le solde n'est **pas** stocké comme valeur courante : on conserve un **solde initial**, et le
solde réel se calcule (solde initial + somme des transactions). Une seule source de vérité.

### `transaction_methods` — les moyens de paiement

| Colonne | Type | Contraintes |
|---|---|---|
| `transmet_id` | INTEGER | clé primaire |
| `transmet_type` | enum `TransactionType` | nullable |
| `account_id` | INTEGER | FK → `accounts`, nullable |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

`account_id` est nullable pour les paiements qui ne dépendent d'aucun compte (espèces).

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
| `user_id` | INTEGER | FK → `users`, NOT NULL |

Le montant est en `NUMERIC(10,2)` (et non en flottant) pour éviter toute dérive d'arrondi
sur des valeurs monétaires.

### `labels` — les étiquettes de catégorisation

| Colonne | Type | Contraintes |
|---|---|---|
| `label_id` | INTEGER | clé primaire |
| `label_name` | VARCHAR | NOT NULL |
| `label_color` | enum `Color` | NOT NULL, défaut `WHITE` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

### `recurring_transactions` — les règles de récurrence

| Colonne | Type | Contraintes |
|---|---|---|
| `rectrans_id` | INTEGER | clé primaire |
| `rectrans_frequency` | enum `Frequency` | NOT NULL |
| `rectrans_start_date` | DATETIME | NOT NULL |
| `rectrans_end_date` | DATETIME | nullable |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

## Énumérations

Définies dans `backend/enums/`. Les valeurs ci-dessous sont celles exposées par l'API.

| Enum | Valeurs (API) |
|---|---|
| `UserRole` | `USER`, `ADMIN` |
| `AccountType` | `LIVRET_A`, `COMPTE_COURANT`, `LIVRET_JEUNE`, `PORTEFEUILLE` |
| `TransactionType` | `ESPECE`, `CARTE`, `VIREMENT`, `CHEQUE` |
| `Color` | `BLACK`, `BLUE`, `BROWN`, `GRAY`, `GREEN`, `ORANGE`, `PINK`, `PURPLE`, `RED`, `WHITE`, `YELLOW` |
| `Frequency` | `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` |

> **Sous PostgreSQL, ces enums sont de vrais types natifs** (`accounttype`, `color`, etc.),
> créés et supprimés par les migrations Alembic. Conséquence : **ajouter une valeur à un enum
> nécessitera une migration** (`ALTER TYPE`), là où c'était gratuit avec SQLite.
>
> Le type natif stocke le **nom du membre** Python, tandis que l'API expose sa **valeur**.
> Pour la plupart des membres nom = valeur, sauf `AccountType.WALLET` dont la valeur est
> `PORTEFEUILLE` : la base contient donc `WALLET` et l'API renvoie `PORTEFEUILLE`.

## Propriété et sécurité (multi-utilisateurs)

Chaque ressource appartient à un utilisateur via `user_id`. L'API applique cette propriété
de bout en bout :

- **Aucune route ressource n'est accessible sans un JWT valide** (dépendance `get_current_user`).
- Le CRUD **filtre systématiquement par propriétaire**. Accéder à la ressource d'un autre
  utilisateur renvoie **404** (et non 403 : « introuvable » ne révèle pas l'existence de la donnée).
- Créer ou modifier une ressource en **référençant** la donnée d'un autre utilisateur est
  refusé avec un **422** au message neutre.
- Le `user_id` n'apparaît dans **aucun** schéma Pydantic : il provient uniquement du token.

## Intégrité référentielle

PostgreSQL applique les clés étrangères nativement. (Le moteur SQLite utilisé pour les tests,
lui, a besoin d'un `PRAGMA foreign_keys=ON` activé dans `database.py` ; sans quoi il les ignorerait.)

**À la suppression d'un parent :**

| Suppression | Comportement | Où c'est appliqué |
|---|---|---|
| Une banque possédant des comptes | **409 Conflict** — refusée | logique métier (route) |
| Un compte utilisé par des moyens de paiement | **409 Conflict** — refusée | logique métier (route) |
| Un moyen de paiement utilisé par des transactions | **409 Conflict** — refusée | logique métier (route) |
| Une étiquette utilisée par des transactions | `label_id` passe à `NULL` | base (`ON DELETE SET NULL`) |
| Une récurrence utilisée par des transactions | `rectrans_id` passe à `NULL` | base (`ON DELETE SET NULL`) |

La distinction est volontaire : banque, compte et moyen de paiement sont **structurants**, on
refuse de les supprimer tant qu'ils servent. Une étiquette ou une récurrence sont de simples
qualificatifs : la transaction leur survit, simplement dé-taggée.

**À la création ou modification**, toute référence vers une ressource inexistante ou
n'appartenant pas à l'utilisateur (`bank_id`, `account_id`, `transmet_id`, `label_id`,
`rectrans_id`) est refusée avec un **422**. Aucune violation de clé étrangère ne remonte donc en 500.

> Note : la suppression d'un utilisateur n'est pas exposée par l'API. Les FK `user_id` sont
> en `NO ACTION` — le comportement de cascade sera conçu le jour où cette fonctionnalité existera.
