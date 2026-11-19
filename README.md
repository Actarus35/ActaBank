# ActaBank

Ce dépôt git est un projet personnel ayant pour but de m'initier / me former à différentes technologies dans le cadre d'un projet concret.

Ainsi, le but de ce projet est de créer une application permettant de faire ses comptes, afin de remplacer un fichier excel ou un carnet de comptes.

## Technologies utilisées

Je vais lister les différentes technologies que j'utiliserais dans ce projet dans l'ordre dans lequel je vais les ajouter / implémenter.

### Base de données

Dans un premier temps, j'utiliserais **SQLite** qui est simple à mettre en place, très complet et suffisant pour ce genre de projet au début.

Je me dirigerait plus tard versr une base de données **PostgreSQL** qui sera plus robuste et me permettra différents ajout de fonctionnalités.

J'utiliserais également **SQLAlchemy** pour le mapping objet (ORM)

J'avais prévu d'intégrer **Apache Superset** pour les graphiques. J'y ai renoncé : branché directement sur la base, il aurait contourné le cloisonnement des données par utilisateur, qui est assuré par l'API. Les graphiques sont donc faits dans le frontend, à partir de routes d'agrégation dédiées.

### Backend

Pour le Backend, j'utiliserais le langage **Python** afin de continuer à me familiariser avec celui-ci.

Je mettrais également une API en place avec **FastAPI** que je ne connais pas du tout mais qui semble très performant, avec un typage clair et de la documentation qui se fait automatiquement. Il semble également correspondre parfaitement à une utilisation dans le cadre d'une application multi-plateforme.

Je m'aiderais également de **Swagger**, que je maîtrise déjà bien, pour mettre cette API en place.

### Authentification

Hé oui, car même si c'est une application perso, j'ai pour objectif de faire de la cybersécurité par la suite, c'est pour ça que je souhaite rendre mon application sécurisée afin de m'entraîner à concevoir des applications sans failles de sécurités.

Pour cette partie, j'utiliserais donc **JWT (JSON Web Token)** que j'apprendrais donc à utiliser avec **bcrypt** me permettant de générer des hash pour les mots de passe.

Enfin, je mettrais peut-être plus tard en place un Refresh Token afin d'améliorer encore la sécurité de mon application.

### Frontend

J'ai finalement retenu **Flutter**, pour son aspect multi-plateforme (web, Android, bureau) à partir d'un seul code. La gestion d'état est faite avec **Riverpod**, les appels à l'API avec **dio** et les graphiques avec **fl_chart**.

### Exposition en dehors du réseau local

En effet, je ne l'ai pas encore mentionnée, mais cette application tournerait (l'API/backend et la base de donnée principalement) sur un ordinateur que je mettrais sur le réseau local. Ainsi, afin de pouvoir accéder à mon application de l'exterieur du réseau local, il faut que je l'expose et ceci crée encore une fois des failles de sécurités importantes (en effet, internet, c'est pas le lieu le plus safe). Je vais donc utiliser **WireGuard** qui est open source et gratuit, très sécurisé et très performant afin de gérer cette partie du projet.

### Autre

Enfin, dans une démarche d'apprentissage, je pourrais une fois le projet bien avancé, l'adapter avec différents outils afin de continuer à apprendre de nouveaux outils informatique.
Ainsi, voici différents outils que je souhaiterais ajouter plus tard :
- Docker
- Test Unitaires (plutôt à faire au fur et à mesure)
- CI (GitHub Actions)
- Monitoring
- Docs techniques

## Gestion de projet / Planification

Voici comment le projet va se dérouler.

### 1 - Création du modéle de données et de la base de données associée

##### Objectif : Créer une base de données saine, évolutive et BI-Compatible

A faire :
- Concevoir les tables
- Choisir les types, les clés, les relations

Commencer à penser Bi dès maintenant :
- tables de faits,
- tables de dimensions
- dates séparées

Résultat attendu :
- Une première base de données claire et structurée

### 2 - Début du backend / API

##### Objectif : Avoir une API qui fonctionne rapidement

A faire :
- Créer un projet FastAPI
- Connecter SQLite
- Créer les routes HTML
- Tester via /Docs

Résultat attendu :
- Ajouter une dépense depuis Swagger

### 3 - Logique métier

##### Objectif : Améliorer l'API pour que celle-ci fonctionne correctement de manière durable

A faire :
- Centraliser la logique métier
- Gérer les erreurs proprement
- Créer des tests unitaires

Résultat attendu :
- Des règles claires et fiables

### 4 - Authentification & Sécurité API

##### Objectif : Sécuriser l'accès avant d'aller plus loin

A faire :
- Auth JWT
- Hash des mots de passe
- Middleware de sécurité
- Rôles (simple : user/admin)

Résultat attendu :
- Impossible d'accéder aux données sans Token

### 5 - Migration PostgreSQL

##### Objectif : Préparer la BI sérieuse

A faire :
- Installer PostgreSQL
- Migrer SQLite --> PostgreSQL
- Adapter SQLAlchemy

Résultat attendu :
- Même API, base de données plus robuste

### 6 - BI : Apache Superset (abandonné)

Étape abandonnée : les tableaux de bord sont réalisés dans le frontend (voir étape 7), à partir de routes d'agrégation de l'API, afin de respecter le cloisonnement des données par utilisateur.

### 7 - Frontend

##### Objectif : Une interface simple mais utilisable

A faire :
- Choisir l'outil à utiliser pour le frontend
- Créer l'interface utilisateur

Résultat attendu :
- Possibilité d'utiliser l'application "pour de vrai"

### 8 - Accès à distance sécurisé (WireGuard)

##### Objectif : Accéder à l'application de partout

A faire :
- Installer WireGuard
- Générer des clé
- Configurer les clients (téléphone / ordinateur)
- Tester l'accès API hors réseau

Résultat attendu :
- L'application fonctionne en dehors du réseau local

### 9 - Fonctionnalités avancées

##### Objectif : Amélioration de l'applications

A faire quand tout le reste fonctionne avec un code clean :
- dépenses récurrentes
- import de relevés bancaires
- catégories (une par transaction) et tags (plusieurs par transaction)
- statistiques avancées
- sauvegardes auto
- logs
- tests (100% de coverage)
- un emoji par catégorie, affiché dans la tuile de chaque transaction (à la place de l'initiale)
- créer une catégorie ou un tag directement depuis le formulaire de transaction
- pagination et recherche côté serveur des transactions
- transferts entre ses propres comptes (« transaction interne », ni dépense ni revenu)
- application **Android** (même code Flutter) : APK signé distribué hors Play Store, API en
  HTTPS obligatoire (Android refuse le HTTP non chiffré), adresse d'API absolue.
  iPhone exclu (compilation impossible sans Mac) : les utilisateurs iPhone passent par la
  version web ajoutée à l'écran d'accueil
- **mode hors ligne**, par niveaux :
  1. lecture hors ligne (cache local des dernières données)
  2. ajout de transactions hors ligne (file d'attente locale rejouée au retour du réseau,
     identifiant généré côté client pour éviter les doublons)
  3. hors ligne complet (base locale, API de synchronisation, gestion des conflits) —
     à décider par un ADR
- applications **Windows et Linux** (même code Flutter ; compilation Windows uniquement
  sous Windows), après l'application mobile
- à plus long terme : transferts entre utilisateurs de l'application et partage de dépenses
  (type Tricount)


### 10 - Bonus

##### Objectif : Apprentissage de nouveaux outils

A faire :
- Docker
- Tests Unitaires
- CI (GitHub Actions)
- Monitoring
- Docs techniques

## Conclusion

Ainsi, ce projet a pour but de développer mes compétences dans les différentes technologies citées précédemment.

Dans le cadre de ce projet, je n'utiliserait aucun LLM écrivant du code à ma place afin d'être conscient de l'entièreté du code de cette application et d'en être le seul auteur. Je pourrais les utiliser à des fins pédagogiques comme pour Claude Code qui est explicitement paramétré pour ne pas pouvoir agir, seulement lire et me conseiller.
