# Backend

## Diagramme représentant les données

```mermaid
classDiagram
    Transaction "*" o-- "*" Label
    Transaction o-- "1" TransactionMethod
    TransactionMethod o-- "*" Bank
    Transaction "1" o-- "0..1" RecurringTransaction
    class Transaction{
      -id : int
      -name : string
      -?title : string
      -date : Date
      -amount : int
      -transaction_method_id : int
      -?label_id : int
      -?description : string
      -is_recurring : bool
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
        -day : int
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

## Routes REST API

### GET

#### Transaction

##### Get /transactions

##### Get /transactions/{trans_id}


#### Banks

##### Get /banks


#### Labels

##### Get /labels


#### Transaction Methods

##### Get /transaction_methods


### POST

### PUT

### PATCH

### DELETE



