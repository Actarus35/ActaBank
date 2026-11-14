# Notes durant la création du backend

## Commandes utiles

#### Commande pour lancer le serveur de développement :

```bash
uvicorn main:app --reload
```
On peut accéder à l'API REST interactive (Swagger) exposée sur [ce lien](http://127.0.0.1:8000/docs/)

On peut également accéder à un autre type de doc sur [ce lien](http://127.0.0.1:8000/redoc)

#### Commande permettant de regénérer / d'actaliser la base de données lorsqu'elle est modifiée

```bash
alembic revision --autogenerate -m "nom de la modif"
alembic upgrade head
```