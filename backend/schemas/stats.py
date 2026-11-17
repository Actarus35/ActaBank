from pydantic import BaseModel
from decimal import Decimal
from typing import Optional
from enums.colors import Color
from enums.account_type import AccountType
from datetime import date as DateType


class StatsSummary(BaseModel):
    solde: Decimal
    revenus: Decimal
    depenses: Decimal
    variation: Decimal
    nb_transactions: int
    nb_revenus: int
    nb_depenses: int


class CategoryStat(BaseModel):
    category_id: Optional[int]
    category_name: Optional[str]
    category_color: Optional[Color]
    total: Decimal


class BalancePoint(BaseModel):
    date: DateType
    balance: Decimal


class BalanceOverTime(BaseModel):
    opening: Decimal
    points: list[BalancePoint]


class TransactionNameStat(BaseModel):
    name: str
    total: Decimal

class MonthlyStat(BaseModel):
    month: DateType
    revenus: Decimal
    depenses: Decimal


class AccountBalance(BaseModel):
    account_id: int
    account_name: str
    account_type: AccountType
    account_archived: bool
    bank_id: Optional[int]
    bank_name: Optional[str]
    bank_color: Optional[Color]
    balance: Decimal


class Balances(BaseModel):
    accounts: list[AccountBalance]
    unassigned: Decimal