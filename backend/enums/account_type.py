from enum import Enum


class AccountType(str, Enum):
    LIVRET_A = "LIVRET_A/COMPTE_COURANT"
    COMPTE_COURANT = "COMPTE_COURANT"
    LIVRET_JEUNE = "LIVRET_JEUNE"
