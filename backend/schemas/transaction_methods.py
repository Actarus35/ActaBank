from pydantic import BaseModel, ConfigDict
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
    bank: Optional[BankRead] = None

    model_config = ConfigDict(from_attributes=True)


class TransactionMethodUpdate(TransactionMethodBase):
    transmet_type: Optional[TransactionType] = None