---
décision: "Catégorie unique et tags multiples par transaction"
date: 2026-11-14
statut: "acceptée"
étape-liée: "Étape 09 — Fonctionnalités avancées"
tags: [décision, ressources]
---

# Décision — Catégories et tags

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

Une transaction porte aujourd'hui au plus un `label` (colonne `label_id`). En construisant le
formulaire d'ajout dans le frontend, le besoin est apparu de qualifier une même dépense de
plusieurs façons : sa nature (« Courses », « Transport ») et son contexte (« Roumanie »,
« Déménagement »).

Le `label` unique ne permet pas les deux. Et le rendre simplement multiple poserait un problème
pour le donut « Dépenses par catégorie » : une dépense de 100 € portant deux labels compterait
dans les deux parts, et le total du graphique dépasserait le total réel des dépenses.

## Options envisagées

### Option A — Conserver un label unique
**Avantages :**
- Aucun changement de schéma
- Le donut reste une vraie répartition (les parts s'additionnent)

**Inconvénients :**
- Impossible d'isoler un contexte transversal (un voyage, un projet)

### Option B — Rendre les labels multiples
**Avantages :**
- Une seule notion à comprendre et à gérer

**Inconvénients :**
- Les dépenses multi-labels sont comptées plusieurs fois dans les répartitions
- Mélange deux notions différentes : la nature d'une dépense et son contexte

### Option C — Catégorie unique + tags multiples
**Avantages :**
- La catégorie reste unique : les répartitions par catégorie s'additionnent toujours
- Les tags servent de filtre transversal : « dépenses par catégorie pour le tag Roumanie »
- Chaque notion a un rôle clair

**Inconvénients :**
- Deux notions à gérer dans l'interface
- Une table d'association (relation plusieurs-à-plusieurs) et une migration avec renommage
- Touche toutes les couches : modèles, schémas, CRUD, routes, stats, récurrences, tests, frontend

## Décision retenue
> **Option C**, parce qu'elle répond au besoin (croiser nature et contexte) sans fausser les
> graphiques : la catégorie découpe, le tag filtre.

- `label` est renommé en **catégorie** et reste **unique** par transaction (optionnelle).
- Une nouvelle notion **tag** est ajoutée, **multiple** par transaction, via une table
  d'association `transaction_tags`.
- Les statistiques par catégorie acceptent un filtre optionnel par tag.

## Conséquences
> Ce que ça implique pour la suite du projet.

- Renommage `labels` → `categories` (table, colonnes, schémas, routes `/categories`, frontend)
- Nouvelle table `tags` et table d'association `transaction_tags`
- Migration Alembic avec **renommage** (et non suppression/recréation) pour conserver les données
- `/stats/by-label` devient `/stats/by-category`, avec un paramètre de filtre par tag
- Les récurrences suivent le renommage (`rectrans_label_id` → catégorie)
- Tests à adapter ; `backend/DATABASE.md` et le README du backend à mettre à jour après la migration

**Points encore ouverts :**
- Un tag a-t-il une couleur, comme une catégorie ?
- Une récurrence peut-elle porter des tags, recopiés sur les transactions générées ?
- À la suppression d'un tag : simple retrait du tag sur les transactions concernées (proposé)

## Liens
- [[Étape 09 — Fonctionnalités avancées]]
- [[Étape 07 — Frontend]]
- [[SQLAlchemy]]
