from pydantic import BaseModel, ConfigDict
from typing import Optional

from schemas.base import CreateModel, UpdateModel
from enums.transaction_type import TransactionType
from schemas.accounts import AccountRead


class TransactionMethodBase(BaseModel):
    transmet_type: TransactionType
    account_id: Optional[int] = None


class TransactionMethodCreate(TransactionMethodBase, CreateModel):
    pass


class TransactionMethodRead(TransactionMethodBase):
    transmet_id: int
    account: Optional[AccountRead] = None

    model_config = ConfigDict(from_attributes=True)


class TransactionMethodUpdate(UpdateModel):
    non_nullable = frozenset({"transmet_type"})

    transmet_type: Optional[TransactionType] = None
    account_id: Optional[int] = None