---
décision: "Flutter comme framework frontend"
date: 2026-08-01
statut: "acceptée"
étape-liée: "Étape 07 — Frontend"
tags: [décision, ressources]
---

# Décision — Choix du framework frontend

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

L'API étant terminée et déployée, il fallait choisir l'outil pour construire l'interface.
L'objectif est une application utilisable sur téléphone comme sur ordinateur : Android, web, Windows et Linux.

Deux contraintes s'ajoutent. L'abandon de Superset
(voir [[Décision - Abandon d'Apache Superset]]) fait du frontend le seul endroit où afficher les graphiques : ils doivent donc fonctionner sur toutes les plateformes. Et le projet reste pédagogique : le choix doit aussi servir l'apprentissage.

Le README initial hésitait : Flutter répondait au besoin, mais avait déjà été utilisé en cours, ce qui poussait vers un outil nouveau.

## Options envisagées

### Option A — Flutter
**Avantages :**
- Un seul code pour Android, web, Windows et Linux
- Les graphiques sont dessinés par Flutter lui-même : rendu identique partout, sans réécriture
- Consolide des bases acquises en cours, sur une technologie en croissance
- Laisse de la place à un apprentissage nouveau : la gestion d'état avec Riverpod

**Inconvénients :**
- Outil déjà connu : moins de découverte que les autres options
- Langage Dart, peu utilisé en dehors de Flutter
- Rendu web plus lourd qu'un site classique

### Option B — PWA (application web progressive)
**Avantages :**
- Technologies web standards, un seul déploiement
- Outil nouveau à apprendre

**Inconvénients :**
- Pas une vraie application native sur Android ni sur bureau
- Accès limité aux fonctions de l'appareil (stockage sécurisé, par exemple)

### Option C — React Native
**Avantages :**
- Composants natifs sur mobile, grand écosystème

**Inconvénients :**
- Pensé d'abord pour le mobile : le web et le bureau demandent des couches supplémentaires
- React déjà pratiqué : l'argument de la nouveauté ne joue pas non plus

## Décision retenue
> **Option A — Flutter**, parce qu'il est le seul à couvrir les quatre plateformes visées avec un
> seul code, graphiques compris, et que l'apprentissage se déplace sur Riverpod plutôt que sur
> un nouveau framework.

## Conséquences
> Ce que ça implique pour la suite du projet.

- Projet `frontend/` à côté de `backend/`, dans le même dépôt
- Gestion d'état avec Riverpod, appels à l'API avec dio, graphiques avec fl_chart
- Développement sur la cible web d'abord ; Android et bureau seront ajoutés ensuite sans
  modifier le code Dart
- Le token JWT est stocké avec flutter_secure_storage
- L'API doit autoriser l'origine du frontend web (CORS)

## Liens
- [[Étape 07 — Frontend]]
- [[Décision - Abandon d'Apache Superset]]
