from pydantic import BaseModel
from typing import Optional

from enums.transaction_type import TransactionType
from schemas.banks import BankRead


class TransactionMethodBase(BaseModel):
    transmet_type: TransactionType
    bank_id: Optional[int] = None


class TransactionMethodCreate(TransactionMethodBase):
    pass


class TransactionMethodRead(TransactionMethodBase):
    transmet_id: int
    bank: BankRead

    class Config:
        from_attributes = True
