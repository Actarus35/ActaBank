---
tags: [ressources]
---

# Bugs & blocages

> Log des problèmes rencontrés pendant le développement. Un problème résolu ici peut en débloquer un autre plus tard.

---

## Template d'entrée

```
### [YYYY-MM-DD] Titre court du problème
**Étape :** [[Étape XX]]
**Techno :** [[NomTechno]]
**Symptôme :** Ce qui se passe concrètement (message d'erreur, comportement inattendu…)
**Cause :** Ce qui l'a provoqué.
**Solution :** Ce qui a résolu le problème.
**Liens :** SO / doc / commit concerné
```

---

- **Moyens de paiement indiscernables** : deux comptes sans nom du même type dans deux
  banques (ex. deux « Compte courant ») donnent deux cartes affichées pareil.
  Piste : ajouter la banque au libellé du moyen de paiement quand le compte n'a pas de nom
  (« Carte · Compte courant (CIC) »).