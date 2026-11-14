from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional
from decimal import Decimal

from schemas.transaction_methods import TransactionMethodRead
from schemas.categories import CategoryRead
from schemas.recurring_transactions import RecurringTransactionRead
from schemas.tags import TagRead


class TransactionBase(BaseModel):
    transac_name: str
    transac_date: datetime
    transac_amount: Decimal
    transac_description: Optional[str] = None
    transmet_id: int
    category_id: Optional[int] = None
    rectrans_id: Optional[int] = None


class TransactionCreate(TransactionBase):
    tag_ids: list[int] = []
    pass


class TransactionRead(TransactionBase):
    transac_id: int

    method: TransactionMethodRead
    category: Optional[CategoryRead] = None
    recurring_transaction: Optional[RecurringTransactionRead] = None
    tags: list[TagRead] = []

    model_config = ConfigDict(from_attributes=True)



class TransactionUpdate(TransactionBase):
    transac_name: Optional[str] = None
    transac_date: Optional[datetime] = None
    transac_amount: Optional[Decimal] = None
    transac_description: Optional[str] = None
    transmet_id: Optional[int] = None
    category_id: Optional[int] = None
    rectrans_id: Optional[int] = None
    tag_ids: Optional[list[int]] = None
