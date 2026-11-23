import uuid

from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional
from decimal import Decimal

from schemas.base import CreateModel, Money, Name100, UpdateModel
from schemas.transaction_methods import TransactionMethodRead
from schemas.categories import CategoryRead
from schemas.recurring_transactions import RecurringTransactionRead
from schemas.tags import TagRead


class TransactionBase(BaseModel):
    transac_name: Name100
    transac_date: datetime
    transac_amount: Money
    transac_description: Optional[str] = None
    transmet_id: int
    category_id: Optional[int] = None
    rectrans_id: Optional[int] = None


class TransactionCreate(TransactionBase, CreateModel):
    tag_ids: list[int] = []


class TransactionRead(TransactionBase):
    transac_id: int

    method: TransactionMethodRead
    category: Optional[CategoryRead] = None
    recurring_transaction: Optional[RecurringTransactionRead] = None
    transac_transfer_id: Optional[uuid.UUID] = None
    tags: list[TagRead] = []

    model_config = ConfigDict(from_attributes=True)



class TransactionUpdate(TransactionBase, UpdateModel):
    non_nullable = frozenset({"transac_name", "transac_date", "transac_amount", "transmet_id"})

    transac_name: Optional[str] = None
    transac_date: Optional[datetime] = None
    transac_amount: Optional[Money] = None
    transac_description: Optional[str] = None
    transmet_id: Optional[int] = None
    category_id: Optional[int] = None
    rectrans_id: Optional[int] = None
    tag_ids: Optional[list[int]] = None
