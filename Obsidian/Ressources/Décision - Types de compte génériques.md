---
décision: "Types de compte génériques et nom libre"
date: 2026-11-18
statut: "acceptée"
# statut possible : en-réflexion | acceptée | abandonnée | remplacée
étape-liée: "Étape 07 — Frontend"
tags: [décision, ressources]
---

# Décision — Types de compte génériques et nom libre

## Contexte
> Un compte a deux champs : un **type** (liste fixe) et un **nom** (texte libre).
> La liste des types actuelle — `LIVRET_A`, `LIVRET_JEUNE`, `COMPTE_COURANT`,
> `PORTEFEUILLE` — mélange des **produits précis** (Livret A, Livret Jeune) et des
> **catégories** (courant, portefeuille). Résultat :
> - le type ressemble à un nom, on ne voit plus à quoi servent les deux champs ;
> - beaucoup de comptes réels n'ont pas de case (LDDS, LEP, PEL, PEA, assurance-vie, crédit…).
>
> Or le type a un rôle dans le code : c'est lui qui dit qu'un portefeuille n'a pas de
> banque (`check_account_consistency`), et il servira demain à distinguer l'argent
> disponible de l'épargne (transferts internes, solde « disponible »).

## Options envisagées

### Option A — Garder la liste actuelle et ajouter les produits au fil de l'eau
**Avantages :**
- aucune migration immédiate

**Inconvénients :**
- une migration à chaque nouveau produit (LDDS, PEL, PEA…)
- le type reste confondu avec le nom
- le code ne peut pas raisonner par « famille » (épargne, placement, dette)

### Option B — Types créés librement par l'utilisateur
**Avantages :**
- souplesse totale, chacun nomme ses types

**Inconvénients :**
- le code ne peut plus s'appuyer sur le type : comment savoir qu'un type « Tirelire »
  n'a pas de banque, ou que « Mon PEA » est un placement ?
- il faudrait leur ajouter des propriétés (banque obligatoire ? disponible ?) :
  on réinvente des catégories, en plus compliqué
- doublon avec le nom, qui est déjà libre

### Option C — Types génériques fixes (liste large) + nom libre
**Avantages :**
- chaque type a un **sens pour le code** (banque obligatoire ou non, famille)
- le produit précis va dans le **nom** : « Livret A », « LDDS », « PEA Boursorama »
- liste volontairement large : mieux vaut des types peu utilisés que devoir migrer plus tard

**Inconvénients :**
- une migration pour renommer les valeurs existantes
- le produit exact (Livret A vs LDDS) n'est plus connu du code — seulement sa famille

## Décision retenue
> **Option C**, parce que le type doit porter une **règle** et le nom une **étiquette**.
> On choisit une liste large dès maintenant pour éviter les migrations à répétition.

| Type (`AccountType`) | Libellé | Famille | Banque | Exemples de noms |
|---|---|---|---|---|
| `COURANT` | Compte courant | disponible | obligatoire | Compte perso, Compte joint |
| `PORTEFEUILLE` | Portefeuille | disponible | **aucune** | Espèces, Tirelire |
| `PORTEFEUILLE_EN_LIGNE` | Portefeuille en ligne | disponible | obligatoire | PayPal, Lydia, Revolut |
| `EPARGNE` | Épargne | épargne | obligatoire | Livret A, LDDS, LEP, Livret Jeune |
| `INVESTISSEMENT` | Investissement | placement | obligatoire | PEA, compte-titres, assurance-vie |
| `CRYPTO` | Crypto-actifs | placement | obligatoire | Binance, Ledger |
| `CREDIT` | Crédit | dette | obligatoire | Prêt immobilier, crédit auto |
| `AUTRE` | Autre | autre | obligatoire | — |

Le **nom** devient facultatif dans le formulaire : il est prérempli avec le libellé
du type, et on ne le change que pour préciser.

## Conséquences
> - **Migration Alembic** de l'énumération PostgreSQL : `LIVRET_A` et `LIVRET_JEUNE`
>   → `EPARGNE`, `COMPTE_COURANT` → `COURANT`. Les noms des comptes existants ne changent
>   pas (« Livret A » reste « Livret A »).
> - SQLAlchemy stocke le **nom** du membre Python (`WALLET`), pas sa valeur
>   (`"PORTEFEUILLE"`) : le membre `WALLET` est renommé `PORTEFEUILLE` pour que nom et
>   valeur soient identiques partout (base, API, Flutter).
> - La **famille** devient une propriété de l'énumération Python : le code raisonne
>   par famille (« disponible », « épargne »…) plutôt que type par type.
> - Plus tard : solde « disponible » (famille disponible seulement), transferts
>   internes vers l'épargne, comptes de crédit au solde négatif.
> - Ajouter un type reste possible (nouvelle valeur + migration), mais devrait être rare.

## Liens
- [[Étape 01 — Modèle de données]]
- [[Étape 07 — Frontend]]
- [[Décision - Séparation Établissement et Compte]]
- [[Décision - Archivage plutôt que suppression]]
