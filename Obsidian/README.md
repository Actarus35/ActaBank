# Comment utiliser ce vault

## Installation rapide

1. Ouvre ce dossier comme vault dans Obsidian (`Ouvrir un dossier en tant que vault`)
2. Installe les plugins communautaires suivants :
   - **Dataview** — pour les tableaux dynamiques dans 🏠 Home
   - **Kanban** — pour la vue Roadmap en colonnes
   - **Templater** — pour les templates avec date automatique
3. Dans Templater, configure le dossier de templates : `Templates/`
4. Dans Daily Notes (natif), configure :
   - Dossier : `Journal`
   - Format : `YYYY-MM-DD`
   - Template : `Templates/Template - Journal`

---

## Structure des dossiers

```
ActaBank-Vault/
├── 🏠 Home.md               ← Point d'entrée, tableaux Dataview
├── Roadmap/
│   ├── Vue d'ensemble.md    ← Kanban des 10 étapes
│   ├── Étape 01 — ...md
│   └── ...
├── Technologies/
│   ├── FastAPI.md
│   └── ...
├── Journal/
│   └── YYYY-MM-DD.md
├── Ressources/
│   ├── Liens utiles.md
│   └── Bugs & blocages.md
└── Templates/
    ├── Template - Étape.md
    ├── Template - Techno.md
    ├── Template - Journal.md
    └── Template - Décision (ADR).md
```

---

## Workflow recommandé

**Début de session**
1. Ouvre le journal du jour (`Ctrl+P` → "Daily Notes: Open today's daily note")
2. Note ce que tu veux faire

**Pendant le dev**
- Mets à jour les tâches dans la note d'étape concernée
- Note les blocages dans `Ressources/Bugs & blocages`
- Crée une note de décision si tu fais un choix important

**Fin de session**
- Complète le journal (ce que tu as fait, ce que tu fais ensuite)
- Met à jour le `statut` dans le frontmatter de l'étape si besoin

---

## Frontmatter — valeurs possibles

**Statut d'une étape** : `à-faire` | `en-cours` | `terminé` | `bloqué`

**Statut d'apprentissage d'une techno** : `découverte` | `en-cours` | `maîtrisé`

**Statut d'une décision ADR** : `en-réflexion` | `acceptée` | `abandonnée` | `remplacée`
