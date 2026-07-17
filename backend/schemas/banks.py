from pydantic import BaseModel, ConfigDict
from typing import Optional

from enums.account_type import AccountType


class BankBase(BaseModel):
    bank_name: str
    bank_account_type: AccountType
    bank_description: Optional[str] = None


class BankCreate(BankBase):
    pass


class BankRead(BankBase):
    bank_id: int

    model_config = ConfigDict(from_attributes=True)


class BankUpdate(BankBase):
    bank_name: Optional[str] = None
    bank_account_type: Optional[AccountType] = None
    bank_description: Optional[str] = None
