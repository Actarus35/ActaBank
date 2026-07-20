from pydantic import BaseModel, ConfigDict
from typing import Optional

from enums.colors import Color


class BankBase(BaseModel):
    bank_name: str
    bank_color: Color = Color.WHITE
    bank_description: Optional[str] = None


class BankCreate(BankBase):
    pass


class BankRead(BankBase):
    bank_id: int

    model_config = ConfigDict(from_attributes=True)


class BankUpdate(BankBase):
    bank_name: Optional[str] = None
    bank_color: Optional[Color] = None
    bank_description: Optional[str] = None
