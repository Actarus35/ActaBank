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
