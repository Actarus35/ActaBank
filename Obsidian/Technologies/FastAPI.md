---
techno: FastAPI
catégorie: ""
statut-apprentissage: découverte
étapes-liées:
  - "[[Étape 02 — Backend & API]]"
tags:
  - techno
---
# FastAPI

## C'est quoi ?
> C'est un framework python qui permet de créer des routes API facilement à partir des types existants en Python.

## Installation / mise en place
Dans votre environnement virtuel ou sur votre machine, pour l'installer, il vous suffit de faire : 
```bash
pip install fastapi
```

## Utilisation dans ActaBank

> Pour ActaBank, [[FastAPI]] permet de créer une API permettant de relier backend et frontend, principalement dans le but de permettre aux utilisateurs d'interagir avec la base de données.

## Commandes / snippets utiles

Voici la commande permettant de lancer le serveur [[FastAPI]] : 
```bash
fastapi dev main.py
```

Le serveur tourne en localhost (sur votre machine) et vous pouvez voir les routes créées grâce à [[Swagger]] qui est intégré à FastAPI sur [ce lien](http://127.0.0.1:8000)
## Pièges & points d'attention
> C'était difficile de gérer tout en même temps autour des données au début, de faire la différence entre ce qui était de [[SQLite]], de [[SQLAlchemy]], de [[Pydantic]] ou encore de [[FastAPI]].

## Ce que j'ai appris
> Créer des routes API avec Python en utilisant les types existant de python dans une base de données [[SQLite]], un ORM tel que [[SQLAlchemy]] et une librairie de validation des données : [[Pydantic]].

## Liens
- [Documentation officielle](https://fastapi.tiangolo.com/)

## Utilisée dans les étapes
- [[Étape 02 — Backend & API]]
