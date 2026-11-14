---
étape: 6
titre: BI Apache Superset
statut: abandonné
techno: 
    - Apache Superset
    - PostgreSQL
début: 
fin: 
tags:
    - roadmap
---

# Étape 06 — BI Apache Superset

## Objectif
Visualiser les données avant de construire le frontend.

## Tâches
- [ ] Installer Superset
- [ ] Connecter PostgreSQL
- [ ] Créer le dashboard, les filtres, les graphiques
- [ ] Apprendre les agrégations, les dimensions, les time-series

## Résultat attendu
De vrais tableaux de bord financiers.

## Technologies impliquées
- [[Apache Superset]]
- [[PostgreSQL]]

## Notes & réflexions


## Décisions prises

Étape abandonnée (août 2026). Superset se connecte directement à PostgreSQL : il contournerait le cloisonnement par utilisateur, qui est appliqué par l'API et non par la base. Les graphiques sont donc réalisés dans le frontend, à partir d'endpoints d'agrégation (`/stats/...`) filtrés par utilisateur.

## Blocages rencontrés


## Liens utiles
- 

## Journal de dev lié
- 
