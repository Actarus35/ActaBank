# Modèle de données

> **Source de vérité** : les modèles SQLAlchemy dans `backend/models/` et les migrations Alembic
> dans `backend/alembic/versions/`. Ce document n'en est qu'un résumé lisible — en cas de
> divergence, **le code fait foi**.

Base de données : **PostgreSQL** (lancé via Docker Compose ; voir le README du backend).
Les tests, eux, tournent sur une base SQLite en mémoire.

## Vue d'ensemble

Chaque donnée appartient à un utilisateur (`user_id`). Une transaction est l'entité centrale ;
elle est rattachée à un moyen de paiement, et optionnellement à une catégorie, à des tags
et à une récurrence.

```
users
 ├── banks
 │    └── accounts ─────────────────┐   (un portefeuille n'a pas de banque)
 │         └── transaction_methods ──┤
 ├── categories ────────────────────┤
 ├── recurring_transactions ────────┴── transactions
 └── tags ──(transaction_tags / recurring_transaction_tags)── transactions, recurring_transactions
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
| `bank_archived` | BOOLEAN | NOT NULL, défaut `false` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

### `accounts` — les comptes d'un établissement

| Colonne | Type | Contraintes |
|---|---|---|
| `account_id` | INTEGER | clé primaire |
| `account_name` | VARCHAR(50) | NOT NULL |
| `account_type` | enum `AccountType` | NOT NULL |
| `account_initial_balance` | NUMERIC(10,2) | NOT NULL |
| `account_description` | VARCHAR | nullable |
| `account_archived` | BOOLEAN | NOT NULL, défaut `false` |
| `bank_id` | INTEGER | FK → `banks`, nullable — **nul si et seulement si** le compte est un portefeuille |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

Le solde n'est **pas** stocké comme valeur courante : on conserve un **solde initial**, et le
solde réel se calcule (solde initial + somme des transactions). Une seule source de vérité.

Un compte de type `PORTEFEUILLE` n'est rattaché à aucune banque ; tout autre type de compte
en a obligatoirement une. La règle est vérifiée par l'API (422), pas par la base.

### `transaction_methods` — les moyens de paiement

| Colonne | Type | Contraintes |
|---|---|---|
| `transmet_id` | INTEGER | clé primaire |
| `transmet_type` | enum `TransactionType` | nullable |
| `account_id` | INTEGER | FK → `accounts`, nullable |
| `transmet_archived` | BOOLEAN | NOT NULL, défaut `false` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

`account_id` est nullable pour les paiements qui ne dépendent d'aucun compte (espèces).

`transmet_type` est nullable en base pour des raisons historiques, mais l'API l'exige toujours.

### `transactions` — l'entité centrale

| Colonne | Type | Contraintes |
|---|---|---|
| `transac_id` | INTEGER | clé primaire |
| `transac_name` | VARCHAR | NOT NULL |
| `transac_date` | DATETIME | NOT NULL |
| `transac_amount` | NUMERIC(10,2) | NOT NULL |
| `transac_description` | VARCHAR | nullable |
| `transmet_id` | INTEGER | FK → `transaction_methods`, **NOT NULL** |
| `category_id` | INTEGER | FK → `categories`, nullable, `ON DELETE SET NULL` |
| `rectrans_id` | INTEGER | FK → `recurring_transactions`, nullable, `ON DELETE SET NULL` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

Le montant est en `NUMERIC(10,2)` (et non en flottant) pour éviter toute dérive d'arrondi
sur des valeurs monétaires.

### `categories` — la catégorie d'une transaction (une seule)

| Colonne | Type | Contraintes |
|---|---|---|
| `category_id` | INTEGER | clé primaire |
| `category_name` | VARCHAR | NOT NULL |
| `category_color` | enum `Color` | NOT NULL, défaut `WHITE` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

### `tags` — les étiquettes libres (plusieurs par transaction)

| Colonne | Type | Contraintes |
|---|---|---|
| `tag_id` | INTEGER | clé primaire |
| `tag_name` | VARCHAR | NOT NULL |
| `tag_color` | enum `Color` | NOT NULL, défaut `WHITE` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

### `transaction_tags` et `recurring_transaction_tags` — tables d'association

| Table | Colonnes | Contraintes |
|---|---|---|
| `transaction_tags` | `transac_id`, `tag_id` | clé primaire composée, deux FK `ON DELETE CASCADE` |
| `recurring_transaction_tags` | `rectrans_id`, `tag_id` | clé primaire composée, deux FK `ON DELETE CASCADE` |

Une catégorie **découpe** les dépenses (chaque transaction en a au plus une, donc les parts d'un graphique s'additionnent sans double comptage). Un tag **filtre** : il est transversal
aux catégories. Voir l'ADR « Catégories et tags » dans le vault Obsidian.

### `recurring_transactions` — les règles de récurrence

| Colonne | Type | Contraintes |
|---|---|---|
| `rectrans_id` | INTEGER | clé primaire |
| `rectrans_name` | VARCHAR | NOT NULL — libellé recopié sur les transactions générées |
| `rectrans_amount` | NUMERIC(10,2) | NOT NULL — montant signé |
| `rectrans_frequency` | enum `Frequency` | NOT NULL |
| `rectrans_start_date` | DATETIME | NOT NULL |
| `rectrans_end_date` | DATETIME | nullable (récurrence sans fin) |
| `rectrans_last_generated` | DATETIME | nullable — dernière échéance générée |
| `rectrans_transmet_id` | INTEGER | FK → `transaction_methods`, NOT NULL |
| `rectrans_category_id` | INTEGER | FK → `categories`, nullable, `ON DELETE SET NULL` |
| `user_id` | INTEGER | FK → `users`, NOT NULL |

Une récurrence est un **modèle** : à la connexion, l'API génère les transactions échues depuis `rectrans_last_generated`, ce qui rend l'opération répétable sans doublon. La catégorie et les tags de la règle sont recopiés sur chaque transaction générée.



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
| Un moyen de paiement utilisé par des transactions ou des récurrences | **409 Conflict** — refusée | logique métier (route) |
| Une catégorie utilisée par des transactions ou des récurrences | `category_id` / `rectrans_category_id` passent à `NULL` | base (`ON DELETE SET NULL`) |
| Un tag utilisé par des transactions ou des récurrences | les lignes d'association sont supprimées | base (`ON DELETE CASCADE`) |
| Une récurrence utilisée par des transactions | `rectrans_id` passe à `NULL` | base (`ON DELETE SET NULL`) |

La distinction est volontaire : banque, compte et moyen de paiement sont **structurants**, on refuse de les supprimer tant qu'ils servent. Pour ne plus les voir proposés, on les **archive** (voir ci-dessous). Une catégorie, un tag ou une récurrence sont de simples qualificatifs : la transaction leur survit, simplement sans eux.

**À la création ou modification**, toute référence vers une ressource inexistante ou n'appartenant pas à l'utilisateur (`bank_id`, `account_id`, `transmet_id`, `category_id`, `tag_ids`, `rectrans_id`) est refusée avec un **422**. Aucune violation de clé étrangère ne remonte donc en 500.

## Archivage

Banques, comptes et moyens de paiement ne se suppriment que s'ils n'ont jamais servi. Sinon, on les archive : ils ne sont plus proposés, mais l'historique, les statistiques et le solde
restent intacts. Voir l'ADR « Archivage plutôt que suppression ».

| Règle | Où c'est appliqué |
|---|---|
| Archiver une banque archive ses comptes et leurs moyens de paiement | CRUD (`modify_bank`) |
| Archiver un compte archive ses moyens de paiement | CRUD (`modify_account`) |
| Désarchiver un compte désarchive sa banque | CRUD (`modify_account`) |
| Désarchiver un moyen de paiement désarchive son compte et sa banque | CRUD (`modify_transaction_method`) |
| Un moyen de paiement archivé refuse les **nouvelles** transactions et récurrences (422) ; celles qui l'utilisent déjà restent modifiables | routes |
| Une récurrence dont le moyen de paiement est archivé ne génère plus rien ; le désarchiver rattrape les échéances manquées | service `recurring` |

## Validation des entrées

Les schémas Pydantic d'entrée héritent de `CreateModel` ou `UpdateModel` (`schemas/base.py`) :

- **Champs inconnus refusés** (`extra="forbid"`) : une faute de frappe dans une clé JSON renvoie un 422 au lieu d'être ignorée en silence.
- **Longueurs bornées** sur les noms, alignées sur la base : 30 caractères pour une banque, 50 pour un compte, 100 pour une catégorie, un tag, une transaction ou une récurrence ; jamais vides.
- **Montants** au format de `NUMERIC(10,2)` : au plus 10 chiffres dont 2 décimales.
- **`null` explicite** refusé en modification sur les champs obligatoires (`non_nullable`) ; un champ absent, lui, n'est pas modifié. Les champs facultatifs (description, catégorie, tags…) peuvent être vidés en envoyant `null`.

Ces règles garantissent qu'une entrée invalide est refusée en **422** par l'API, avant
d'atteindre PostgreSQL et d'y provoquer une erreur 500.


> Note : la suppression d'un utilisateur n'est pas exposée par l'API. Les FK `user_id` sont
> en `NO ACTION` — le comportement de cascade sera conçu le jour où cette fonctionnalité existera.
