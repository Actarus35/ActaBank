from enum import Enum


class AccountFamily(str, Enum):
    DISPONIBLE = "DISPONIBLE"
    EPARGNE = "EPARGNE"
    PLACEMENT = "PLACEMENT"
    DETTE = "DETTE"
    AUTRE = "AUTRE"


class AccountType(str, Enum):
    COURANT = "COURANT"
    PORTEFEUILLE = "PORTEFEUILLE"
    PORTEFEUILLE_EN_LIGNE = "PORTEFEUILLE_EN_LIGNE"
    EPARGNE = "EPARGNE"
    INVESTISSEMENT = "INVESTISSEMENT"
    CRYPTO = "CRYPTO"
    CREDIT = "CREDIT"
    AUTRE = "AUTRE"

    @property
    def family(self) -> AccountFamily:
        return _FAMILIES[self]

    @property
    def requires_bank(self) -> bool:
        return self is not AccountType.PORTEFEUILLE


_FAMILIES = {
    AccountType.COURANT: AccountFamily.DISPONIBLE,
    AccountType.PORTEFEUILLE: AccountFamily.DISPONIBLE,
    AccountType.PORTEFEUILLE_EN_LIGNE: AccountFamily.DISPONIBLE,
    AccountType.EPARGNE: AccountFamily.EPARGNE,
    AccountType.INVESTISSEMENT: AccountFamily.PLACEMENT,
    AccountType.CRYPTO: AccountFamily.PLACEMENT,
    AccountType.CREDIT: AccountFamily.DETTE,
    AccountType.AUTRE: AccountFamily.AUTRE,
}