from enum import Enum


class TransactionType(str, Enum):
    ESPECE = "ESPECE"
    CARTE = "CARTE"
    VIREMENT = "VIREMENT"
    LYFPAY = "LYFPAY"
    CHEQUE = "CHEQUE"
