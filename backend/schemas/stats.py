from pydantic import BaseModel
from decimal import Decimal
from typing import Optional
from enums.colors import Color
from datetime import date as DateType


class StatsSummary(BaseModel):
    solde: Decimal
    revenus: Decimal
    depenses: Decimal
    variation: Decimal
    nb_transactions: int


class LabelStat(BaseModel):
    label_id: Optional[int]
    label_name: Optional[str]
    label_color: Optional[Color]
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