# Notes durant la création du backend

## Commandes utiles

#### Commande pour lancer le serveur de développement :

```bash
fastapi dev mainpy
```
On peut accéder à l'API REST interactive (Swagger) exposée sur [ce lien](http://127.0.0.1:8000/docs#/)

On peut également accéder à un autre type de doc sur [ce lien](http://127.0.0.1:8000/redoc)

#### Commande pour lancer le serveur en prod :

```bash
fastapi run
```

#### Commande permettant de regénérer / d'actaliser la base de données lorsqu'elle est modifiée

```bash
alembic revision --autogenerate -m "nom de la modif"
alembic upgrade head
```

### Alembic

#### Commandes pour resynchroniser la base de données et alembic

```bash
# 1 - Supprimer toutes les anciennes migrations
rm -rf alembic/versions/*

# 2 - Supprimer la DB
rm database.db

# 3 - Générer une vraie migration initiale propre
alembic revision --autogenerate -m "initial schema"

# 4 - Appliquer
alembic upgrade head
```


