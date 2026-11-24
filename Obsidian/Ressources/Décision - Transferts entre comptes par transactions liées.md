---
décision: "Transferts entre comptes par transactions liées"
date: 2026-11-22
statut: "acceptée"
# statut possible : en-réflexion | acceptée | abandonnée | remplacée
étape-liée: ""
tags: [décision, ressources]
---

# Décision — Transferts entre comptes par transactions liées

## Contexte
> Un virement entre deux de mes comptes (courant → livret) ou un retrait au distributeur
> (courant → portefeuille) se saisissait comme deux transactions indépendantes : −X et +X.
> Les **soldes** restaient justes, mais les **statistiques** comptaient X de dépenses et
> X de revenus fictifs, car `crud/stats.py` classe tout montant négatif en dépense.
> Rien ne liait les deux écritures : en supprimer une seule faussait les soldes.
> Contrainte : les soldes sont calculés **à partir des transactions** (`get_balances`,
> solde global de `get_summary`) et cette source de vérité unique doit être conservée.

## Options envisagées

### Option A — Catégorie exclue des statistiques
**Avantages :**
- une seule colonne booléenne sur `categories`, très peu de code

**Inconvénients :**
- toujours deux saisies manuelles, sans lien entre elles
- supprimer une moitié fausse les soldes sans que rien ne le signale
- dépend de la discipline de l'utilisateur (oublier la catégorie = stats fausses)

### Option B — Deux transactions liées par un identifiant commun
**Avantages :**
- les soldes restent justes **sans toucher** à leur calcul : un transfert reste deux transactions
- les statistiques n'ont qu'**une condition** à ajouter (`transac_transfer_id IS NULL`)
- création des deux moitiés dans **un seul commit** (atomicité) : jamais de transfert à moitié créé
- un UUID généré avant l'insertion évite la dépendance circulaire d'une clé étrangère croisée

**Inconvénients :**
- un endpoint dédié (`POST /transfers`) et des règles de suppression et de modification spécifiques
- deux lignes par transfert dans la liste (une par compte)

### Option C — Table `transfers` séparée
**Avantages :**
- modèle « pur » : un transfert n'est pas une dépense

**Inconvénients :**
- **tous** les calculs de solde doivent ajouter les transferts à part : deux sources de vérité
- touche `get_balances`, `get_summary`, l'évolution du solde… risque élevé de bugs

## Décision retenue
> **Option B — deux transactions liées**, parce qu'elle garde les transactions comme source
> de vérité unique des soldes, qu'elle se limite à un filtre côté statistiques et que
> l'atomicité garantit la cohérence des deux moitiés.

## Conséquences
> - Nouvelle colonne `transactions.transac_transfer_id` (UUID, nullable, indexée) ;
>   NULL pour une transaction normale.
> - `POST /transfers` : `from_method_id`, `to_method_id`, `amount` > 0, `date`, nom et
>   description facultatifs. Validations : méthodes de l'utilisateur, non archivées,
>   liées à **deux comptes différents**. Pas de catégorie ni de tags.
> - Statistiques : les transferts sont exclus des revenus, dépenses, compteurs,
>   répartition par catégorie, par nom et par mois ; ils restent comptés dans les soldes.
> - Supprimer une moitié supprime l'autre.
> - **Première version** : le `PATCH` du montant, de la date ou du moyen de paiement d'une
>   moitié est refusé (409, supprimer puis recréer) ; nom et description restent modifiables.
> - Frontend : 3ᵉ choix « ⇄ Transfert » à côté de Dépense et Revenu (le booléen
>   `isExpense` devient une énumération), deux listes « De » et « Vers ».
> - Les anciens transferts saisis à la main en prod sont supprimés et recréés.
> - **Plus tard** : modification d'un transfert (répercutée sur les deux moitiés),
>   transferts récurrents (le moteur de récurrences ne crée qu'une transaction par règle).
> - Mode hors ligne : un transfert = deux écritures à synchroniser **ensemble**.

## Liens
- [[Décision - Architecture multi-utilisateurs]]
