# Décision - Archivage plutôt que suppression

**Date :** 17/11/2026
**Statut :** acceptée

## Contexte
Un utilisateur qui quitte une banque ou clôture un compte ne veut plus les voir proposés dans
les formulaires. Mais ses anciennes transactions y restent rattachées.

## Options envisagées
1. **Supprimer** et vider le lien sur les transactions (« moyen de paiement inexistant »).
   Rejetée : le solde devient faux (le solde initial du compte disparaît du calcul),
   l'historique perd son sens, et l'opération est irréversible.
2. **Archiver** : un indicateur sur la banque, le compte et le moyen de paiement.

## Décision
Archivage. Un élément archivé n'est plus proposé pour de nouvelles transactions, mais
l'historique, les statistiques et le solde restent intacts. L'opération est réversible.

## Règles
- Archiver descend : banque → comptes → moyens de paiement.
- Désarchiver remonte : moyen de paiement → compte → banque.
- Un moyen de paiement archivé refuse les nouvelles transactions ; les anciennes restent modifiables.
- Une récurrence dont le moyen de paiement est archivé est suspendue.
- La suppression reste réservée aux éléments jamais utilisés (409 sinon).

## Décision liée : portefeuille sans banque
Un compte de type Portefeuille n'est rattaché à aucune banque (`bank_id` nul) ; tout autre
type de compte en a obligatoirement une.

## Conséquences
- Les formulaires du frontend doivent filtrer les éléments archivés.
- Désarchiver un moyen de paiement fait rattraper les échéances manquées de ses récurrences.