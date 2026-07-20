from pydantic import BaseModel, ConfigDict
from typing import Optional
from decimal import Decimal

from enums.account_type import AccountType
from schemas.banks import BankRead

class AccountBase(BaseModel):
    account_name: str
    account_type: AccountType
    account_initial_balance: Decimal = Decimal("0.00")
    account_description: Optional[str] = None
    bank_id: int


class AccountCreate(AccountBase):
    pass


class AccountRead(AccountBase):
    account_id: int
    bank: Optional[BankRead] = None

    model_config = ConfigDict(from_attributes=True)


class AccountUpdate(BaseModel):
    account_name: Optional[str] = None
    account_type: Optional[AccountType] = None
    account_initial_balance: Optional[Decimal] = None
    account_description: Optional[str] = None
    bank_id: Optional[int] = None