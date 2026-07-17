from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional
from decimal import Decimal

from schemas.transaction_methods import TransactionMethodRead
from schemas.labels import LabelRead
from schemas.recurring_transactions import RecurringTransactionRead


class TransactionBase(BaseModel):
    transac_name: str
    transac_date: datetime
    transac_amount: Decimal
    transac_description: Optional[str] = None
    transmet_id: int
    label_id: Optional[int] = None
    rectrans_id: Optional[int] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionRead(TransactionBase):
    transac_id: int

    method: TransactionMethodRead
    label: Optional[LabelRead] = None
    recurring_transaction: Optional[RecurringTransactionRead] = None

    model_config = ConfigDict(from_attributes=True)



class TransactionUpdate(TransactionBase):
    transac_name: Optional[str] = None
    transac_date: Optional[datetime] = None
    transac_amount: Optional[Decimal] = None
    transac_description: Optional[str] = None
    transmet_id: Optional[int] = None
    label_id: Optional[int] = None
    rectrans_id: Optional[int] = None
