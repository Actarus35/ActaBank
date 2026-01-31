from pydantic import BaseModel
from datetime import datetime


class Transaction(BaseModel):
    id: int
    name: str
    title: str
    date: datetime
    amount: float
    description: str | None
    is_recurring: bool


class TransactionList(BaseModel):
    id: int
    name: str
    date: datetime
    amount: float


class CreateTransaction(BaseModel):
    name: str
    amount: float
