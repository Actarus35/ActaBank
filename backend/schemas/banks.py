from pydantic import BaseModel, ConfigDict
from typing import Optional

from schemas.base import CreateModel, Name30, UpdateModel
from enums.colors import Color


class BankBase(BaseModel):
    bank_name: Name30
    bank_color: Color = Color.WHITE
    bank_description: Optional[str] = None


class BankCreate(BankBase, CreateModel):
    pass


class BankRead(BankBase):
    bank_id: int

    model_config = ConfigDict(from_attributes=True)


class BankUpdate(UpdateModel):
    non_nullable = frozenset({"bank_name", "bank_color"})

    bank_name: Optional[Name30] = None
    bank_color: Optional[Color] = None
    bank_description: Optional[str] = None
