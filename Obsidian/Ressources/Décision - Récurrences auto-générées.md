---
décision: "Récurrences sous forme de modèles générant automatiquement les transactions"
date: 2026-08-01
statut: "acceptée"
étape-liée: "Étape 09 — Fonctionnalités avancées"
tags: [décision, ressources]
---

# Décision — Récurrences auto-générées

## Contexte
> Pourquoi cette décision s'est posée. Quelle était la situation.

La table `recurring_transactions` ne contenait qu'une cadence : une fréquence, une date de début
et une date de fin. Elle servait à relier entre elles des transactions saisies à la main, mais ne
créait rien : un loyer mensuel devait toujours être ressaisi chaque mois.

La maquette de l'application prévoit au contraire des opérations récurrentes (loyer, salaire,
abonnements) qui apparaissent d'elles-mêmes dans les comptes.

## Options envisagées

### Option A — Conserver une simple cadence
**Avantages :**
- Aucun changement de schéma

**Inconvénients :**
- Aucune automatisation : la récurrence n'est qu'une étiquette sur des saisies manuelles

### Option B — Un modèle de transaction, généré à la consultation
La récurrence décrit la transaction à créer (libellé, montant, moyen de paiement, étiquette).
Les échéances dues sont générées quand l'utilisateur se connecte.

**Avantages :**
- Aucune infrastructure supplémentaire : pas de tâche planifiée à déployer ni à surveiller
- Rattrapage naturel : si personne ne se connecte pendant trois mois, les trois échéances sont
  créées à la connexion suivante
- Les transactions générées sont de vraies transactions, modifiables et comptées dans les soldes

**Inconvénients :**
- Rien n'est généré tant que l'utilisateur ne se connecte pas
- La génération ajoute un traitement au moment de la connexion

### Option C — Une tâche planifiée côté serveur
**Avantages :**
- Les transactions existent à l'heure, même sans connexion

**Inconvénients :**
- Un composant de plus à déployer, superviser et relancer en cas de panne
- Doit de toute façon savoir rattraper les exécutions manquées

## Décision retenue
> **Option B**, parce qu'elle apporte l'automatisation attendue sans ajouter d'infrastructure,
> et que les données ne sont de toute façon consultées qu'après une connexion.

## Conséquences
> Ce que ça implique pour la suite du projet.

- `recurring_transactions` devient un modèle : ajout de `rectrans_name`, `rectrans_amount`
  (signé), `rectrans_transmet_id` (obligatoire), `rectrans_label_id` (optionnel)
- Ajout de `rectrans_last_generated`, la dernière échéance créée : c'est ce marqueur qui rend la
  génération **répétable sans doublon**
- Nouvelle couche `services/` (`services/recurring.py`) pour cette logique métier
- La génération est déclenchée à la connexion, et après la création ou la modification d'une
  récurrence
- Elle part de la date de début, ne crée jamais d'échéance future, et respecte la date de fin
  (absente pour une récurrence sans terme)
- Les calculs de mois et d'années utilisent `dateutil.relativedelta` (un 31 janvier + 1 mois)

**Limites connues :**
- Modifier une récurrence ne corrige pas les transactions déjà générées
- Supprimer une récurrence conserve ses transactions, simplement détachées (`rectrans_id` à `NULL`)

## Liens
- [[Étape 09 — Fonctionnalités avancées]]
- [[Décision - Catégories et tags]]
- [[SQLAlchemy]]
