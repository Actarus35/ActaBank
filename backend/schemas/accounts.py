from pydantic import BaseModel, ConfigDict
from typing import Optional
from decimal import Decimal

from schemas.base import CreateModel, Money, Name50, UpdateModel
from enums.account_type import AccountType
from schemas.banks import BankRead

class AccountBase(BaseModel):
    account_name: Name50
    account_type: AccountType
    account_initial_balance: Money = Decimal("0.00")
    account_description: Optional[str] = None
    bank_id: Optional[int] = None


class AccountCreate(AccountBase, CreateModel):
    pass


class AccountRead(AccountBase):
    account_id: int
    bank: Optional[BankRead] = None
    account_archived: bool

    model_config = ConfigDict(from_attributes=True)


class AccountUpdate(UpdateModel):
    non_nullable = frozenset({"account_name", "account_type", "account_initial_balance", "account_archived"})

    account_name: Optional[Name50] = None
    account_type: Optional[AccountType] = None
    account_initial_balance: Optional[Money] = None
    account_description: Optional[str] = None
    bank_id: Optional[int] = None
    account_archived: Optional[bool] = None