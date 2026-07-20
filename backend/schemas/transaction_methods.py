from pydantic import BaseModel, ConfigDict
from typing import Optional

from enums.transaction_type import TransactionType
from schemas.accounts import AccountRead


class TransactionMethodBase(BaseModel):
    transmet_type: TransactionType
    account_id: Optional[int] = None


class TransactionMethodCreate(TransactionMethodBase):
    pass


class TransactionMethodRead(TransactionMethodBase):
    transmet_id: int
    account: Optional[AccountRead] = None

    model_config = ConfigDict(from_attributes=True)


class TransactionMethodUpdate(TransactionMethodBase):
    transmet_type: Optional[TransactionType] = None