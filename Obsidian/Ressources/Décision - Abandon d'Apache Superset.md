---
décision: "Abandon d'Apache Superset au profit de graphiques dans le frontend"
date: 2026-08-01
statut: "acceptée"
étape-liée: "Étape 06 — BI Apache Superset"
tags: [décision, ressources]
---

# Décision — Abandon d'Apache Superset

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

La roadmap prévoyait une étape BI avec [[Apache Superset]], branché sur [[PostgreSQL]], pour
visualiser les données avant de construire le frontend.

Entre-temps, l'application est devenue multi-utilisateurs
(voir [[Décision - Architecture multi-utilisateurs]]) : chaque donnée appartient à un
utilisateur, et ce cloisonnement est appliqué **par l'API**, qui filtre chaque requête à partir
du token JWT. La base elle-même ne sait pas qui a le droit de lire quoi.

Or Superset se connecte directement à la base, sans passer par l'API.

## Options envisagées

### Option A — Apache Superset branché sur PostgreSQL
**Avantages :**
- Outil BI complet : tableaux de bord, filtres, exploration libre des données
- Apprentissage d'un outil professionnel, prévu dans la roadmap

**Inconvénients :**
- Contourne le cloisonnement par utilisateur : un accès Superset voit les données de tous
- Pour l'éviter, il faudrait redéfinir les règles d'accès une seconde fois dans Superset,
  avec le risque qu'elles divergent de celles de l'API
- Un service de plus à déployer, sécuriser et maintenir sur le serveur
- Une seconde interface pour l'utilisateur, séparée de l'application

### Option B — Graphiques dans le frontend, alimentés par l'API
**Avantages :**
- Le cloisonnement reste appliqué à un seul endroit : l'API
- Une seule application pour saisir et visualiser
- Rien de plus à déployer

**Inconvénients :**
- Chaque graphique demande une route d'agrégation et son affichage : pas d'exploration libre
- L'apprentissage d'un outil BI sort du projet

## Décision retenue
> **Option B**, parce que la sécurité des données repose sur le filtrage par utilisateur fait
> par l'API, et qu'un outil branché directement sur la base le contournerait.

## Conséquences
> Ce que ça implique pour la suite du projet.

- L'étape 06 est abandonnée
- Création de routes d'agrégation dans l'API (`/stats/summary`, `/stats/by-label`,
  `/stats/balance-over-time`, `/stats/by-name`), toutes filtrées par utilisateur et par période
- Les graphiques sont réalisés dans le frontend (bibliothèque fl_chart)
- Les agrégations sont écrites de façon portable entre SQLite (tests) et PostgreSQL : le cumul
  du solde par jour est calculé en Python plutôt qu'avec des fonctions de date propres à une base

## Liens
- [[Étape 06 — BI Apache Superset]]
- [[Étape 07 — Frontend]]
- [[Décision - Architecture multi-utilisateurs]]
- [[Apache Superset]]
