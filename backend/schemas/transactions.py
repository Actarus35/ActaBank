from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from schemas.transaction_methods import TransactionMethodRead
from schemas.labels import LabelRead
from schemas.recurring_transactions import RecurringTransactionRead


class TransactionBase(BaseModel):
    transac_name: str
    transac_date: datetime
    transac_amount: float
    transac_description: Optional[str] = None
    transmet_id: int
    label_id: Optional[int] = None
    rectrans_id: Optional[int] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionRead(TransactionBase):
    transac_id: int
    transac_name: str
    transac_date: datetime
    transac_amount: float
    transac_description: Optional[str] = None

    method: TransactionMethodRead
    labels: Optional[LabelRead] = None
    recurring_transaction: Optional[RecurringTransactionRead] = None


class TransactionUpdate(TransactionBase):
    transac_name: Optional[str] = None
    transac_date: Optional[datetime] = None
    transac_amount: Optional[float] = None
    transac_description: Optional[str] = None
    transmet_id: Optional[int] = None
    label_id: Optional[int] = None
    rectrans_id: Optional[int] = None
