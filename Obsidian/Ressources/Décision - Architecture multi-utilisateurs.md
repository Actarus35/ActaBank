---
décision: "Architecture multi-utilisateurs sur serveur centralisé"
date: 2026-07-18
statut: "acceptée"
étape-liée: "Étape 04 — Authentification & Sécurité"
tags: [décision, ressources]
---

# Décision — Architecture multi-utilisateurs

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

Le modèle de données ne comporte aucune notion d'utilisateur : les données n'appartiennent à
personne. Tant que l'application tourne en local pour une seule personne, cela fonctionne.

Mais la roadmap prévoit un serveur sur le réseau local, un accès distant via [[WireGuard]],
un frontend multi-plateforme et une couche BI branchée sur [[PostgreSQL]] — autant d'éléments
qui supposent des données **centralisées** et un **accès contrôlé**.

D'où la question : faut-il stocker les données sur l'appareil de chaque utilisateur (pas de
serveur, pas d'authentification), ou les centraliser sur un serveur avec de vrais comptes
utilisateurs ?

Elle se pose maintenant parce que l'étape 04 (authentification) approche et que la base est
encore vide.

## Options envisagées

### Option A — Stockage local sur l'appareil
**Avantages :**
- Aucune authentification à écrire
- Confidentialité par construction : les données ne quittent jamais l'appareil
- Aucun serveur à maintenir ni à sécuriser

**Inconvénients :**
- Aucune synchronisation entre le téléphone et l'ordinateur
- Pas de sauvegarde centralisée
- Superset ne peut pas se brancher sur des bases éparpillées sur chaque appareil
- Rend inutiles WireGuard et l'accès distant prévus dans la roadmap
- Supprime tout l'apprentissage [[JWT]] / bcrypt, qui est un objectif explicite du projet

### Option B — Serveur centralisé avec comptes utilisateurs
**Avantages :**
- Les mêmes données depuis n'importe quel appareil
- Sauvegarde et BI centralisées, cohérent avec PostgreSQL + Superset
- Cohérent avec l'accès distant WireGuard déjà prévu
- Permet l'apprentissage réel de JWT et bcrypt
- Coût quasi nul aujourd'hui puisque la base est vide

**Inconvénients :**
- Chaque requête doit être filtrée par utilisateur
- La sécurité devient critique : l'API est exposée
- Le serveur doit être disponible pour que l'application fonctionne

## Décision retenue
> **Option B**, parce que l'option locale contredirait la majeure partie de la roadmap (accès distant, BI centralisée, frontend multi-plateforme) et priverait le projet de son objectif d'apprentissage en sécurité.

Le point déterminant : **ajouter la notion de propriétaire sur une base déjà peuplée est coûteux** (migration, reprise des données existantes, réécriture de toutes les requêtes), alors que c'est presque gratuit tant que la base est vide.

## Conséquences
> Ce que ça implique pour la suite du projet.

- Création d'une table `users` : identifiant, mot de passe **haché avec bcrypt**, date de création
- Ajout d'un `user_id` sur les ressources exposées par l'API, afin que chaque endpoint filtre
  simplement par utilisateur
- Cette redondance est **assumée** : elle évite des jointures sur toute la chaîne
  Banque → Compte → Moyen de paiement → Transaction pour la requête la plus fréquente de
  l'application. En contrepartie, la cohérence des `user_id` devra être garantie par la
  logique métier
- L'authentification JWT devient le préalable à toute route : plus aucune donnée accessible
  sans token valide
- La sécurité de l'exposition (WireGuard, HTTPS, gestion des secrets) devient un sujet à part
  entière, à traiter à l'étape 08

## Liens
- [[Étape 04 — Authentification & Sécurité]]
- [[JWT]]
- [[Décision - Séparation Établissement et Compte]]
