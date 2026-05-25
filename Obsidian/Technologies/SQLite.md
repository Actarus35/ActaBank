---
techno: "SQLite"
catégorie: ""
statut-apprentissage: "découverte"
étapes-liées: []
tags: [techno]
---

# SQLite

## C'est quoi ?
> C'est la base de données du projet, elle permet le stockage de toutes les données utilisateurs.

## Installation / mise en place

Pour l'installation, référez-vous à la [documentation de SQLite](https://sqlite.org/index.html). Si vous êtes sur fedora, vous pouvez faire la commande suivante :

```bash
sudo dnf install sqlite
```

## Utilisation dans ActaBank
> Elle permet le stockage de toutes les données de l'utilisateur, c'est à dire, la banque, les méthodes de transactions, les transactions, ...

Voici comment les données sont représentées : 
```mermaid
classDiagram
    Transaction "*" o-- "*" Label
    Transaction o-- "1" TransactionMethod
    TransactionMethod "*" o-- "0..1" Bank
    Transaction "1" o-- "0..1" RecurringTransaction
    class Transaction{
      -id : int
      -name : string
      -date : Date
      -amount : float
      -transaction_method_id : int
      -?label_id : int
      -?recurring_transaction_id : int
      -?description : string
    }

    class Label{
      -id : int
      -name : string
      -?couleur : Color
    }
    class TransactionMethod{
      -id : int
      -type : TransactionType
      -?bank_id : int
    }

    class Bank{
        -id : int
        -name : string
        -account_type : AccountType
        -?description : string
    }

    class RecurringTransaction{
        -transaction_id : int
        -frequency : Frequency
        -start_date : Date
        -?end_date : Date
    }

    class Color{
        <<enumeration>>
        YELLOW
        RED
        BLUE
        GREEN
        WHITE
        BLACK
    }

    class AccountType{
        <<enumeration>>
        LIVRET A
        COMPTE COURANT
        LIVRET JEUNE
    }

    class TransactionType{
        <<enumeration>>
        ESPECE
        CARTE
        VIREMENT
        LYFPAY
        CHEQUE
    }

    class Frequency{
        <<enumeraton>>
        DAYLY
        WEEKLY
        MONTHLY
        YEARLY
    }

```
## Commandes / snippets utiles

Il n'est pas nécessaire de modifier le fichier .db de SQLite pour modifier la base de données car celle-ci est entièrement gérée par Python 
```python
# snippet fréquemment utilisé
```

## Pièges & points d'attention
> Ce qui m'a bloqué ou surpris.

## Ce que j'ai appris
> Notions découvertes, concepts compris.

## Liens
- [Documentation officielle]()

## Utilisée dans les étapes
- 
