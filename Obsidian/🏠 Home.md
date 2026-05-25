---
tags: [home]
---

# ActaBank — Vault de projet

> Application de gestion de comptes personnels. Ce vault suit le développement du projet du début à la fin.

## Roadmap

```dataview
TABLE statut, techno, début, fin
FROM "Roadmap"
WHERE étape != null
SORT étape ASC
```

## En cours

```dataview
LIST
FROM "Roadmap"
WHERE statut = "en-cours"
```

## Journal récent

```dataview
LIST
FROM "Journal"
SORT date DESC
LIMIT 7
```

---

## Navigation rapide

- 📁 [[Roadmap/Vue d'ensemble|Vue d'ensemble Roadmap]]
- 📁 Technologies
- 📁 Journal
- 📁 Ressources/Liens utiles
- 📁 Ressources/Bugs & blocages

---

## Stack technique

| Couche | Techno |
|---|---|
| Base de données | [[SQLite]] → [[PostgreSQL]] |
| ORM | [[SQLAlchemy]] |
| BI | [[Apache Superset]] |
| Backend | [[Python]] + [[FastAPI]] |
| Auth | [[JWT]] + [[bcrypt]] |
| Frontend | À décider |
| Accès distant | [[WireGuard]] |
