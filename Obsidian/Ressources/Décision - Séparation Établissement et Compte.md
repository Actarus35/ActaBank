---
décision: "Séparation Établissement / Compte"
date: 2026-07-20
statut: "acceptée"
étape-liée: "Étape 01 — Modèle de données"
tags: [décision, ressources]
---

# Décision — Séparation Établissement / Compte

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

Le modèle initial fait porter à la table `banks` deux notions différentes : l'établissement
bancaire (CIC, BoursoBank) **et** le type de compte, via la colonne `bank_account_type`
(compte courant, livret A, livret jeune). Or un même établissement héberge plusieurs comptes
de types différents.

Conséquence concrète : pour représenter un compte courant CIC *et* un livret A CIC, il faut
créer deux lignes `banks` toutes deux nommées « CIC ». Le nom de l'établissement est dupliqué,
il n'existe aucune entité unique « CIC », et il devient impossible de regrouper les données
par établissement.

Second symptôme : `transaction_methods.bank_id` rattache une carte ou un virement à un
**établissement**, alors qu'un moyen de paiement tire en réalité sur un **compte précis**
(la carte du compte courant, pas « le CIC en général » — un livret A n'a d'ailleurs ni carte
ni chéquier).

La question s'est posée pendant la conception de l'interface, à un moment où la base ne
contenait encore aucune donnée.

## Options envisagées

### Option A — Conserver le modèle actuel
**Avantages :**
- Aucun changement de schéma, aucune migration à écrire
- Suffisant tant qu'on ne possède qu'un seul compte par établissement

**Inconvénients :**
- Le nom de l'établissement est dupliqué à chaque compte
- Impossible d'agréger les données par établissement
- Les moyens de paiement sont rattachés au mauvais niveau
- Le défaut devient coûteux à corriger dès que la base contient des données réelles

### Option B — Introduire une entité `Account`
**Avantages :**
- Chaque notion a sa table : `banks` = l'établissement, `accounts` = le compte
- Un moyen de paiement se rattache au compte, ce qui correspond à la réalité
- Permet les agrégations par établissement **comme** par compte, utile pour la BI
- Coût quasi nul aujourd'hui puisque la base est vide

**Inconvénients :**
- Une table et un niveau de relation supplémentaires
- Impacte les schémas Pydantic, le CRUD et les routes existants
- Nécessite de régénérer la migration initiale

## Décision retenue
> **Option B**, parce que le modèle actuel confond deux entités distinctes et que ce défaut deviendrait coûteux à corriger une fois la base peuplée. La restructuration est donc faite maintenant, tant que la base est vide.

Nouvelle hiérarchie :

```
Bank (établissement)
 └── Account (compte : type, nom, solde initial)
      └── TransactionMethod (carte, virement, chèque, espèces)
           └── Transaction
```

## Conséquences
> Ce que ça implique pour la suite du projet.

- Création de la table `accounts` : type de compte, nom, solde initial, rattachement à une banque
- `banks` perd `bank_account_type` et ne conserve que l'identité de l'établissement
- `transaction_methods.bank_id` devient `account_id`, et **reste nullable** : les espèces ne
  dépendent d'aucun compte
- Les schémas de lecture changent de forme : `TransactionMethodRead` imbriquera désormais un
  compte, lui-même rattaché à une banque
- Migration initiale à régénérer
- `backend/DATABASE.md` à mettre à jour

**Choix complémentaire retenu :** le solde d'un compte n'est **pas** stocké comme valeur
courante. On stocke un **solde initial**, et le solde réel se calcule (solde initial + somme
des transactions). Une seule source de vérité, donc aucun risque de désynchronisation.

## Liens
- [[Étape 01 — Modèle de données]]
- [[SQLAlchemy]]
- [[Décision - Architecture multi-utilisateurs]]
