from pydantic import BaseModel
from datetime import datetime


class TransactionBase(BaseModel):
    transac_name: str
    transac_date: datetime
    transac_amount: float
    transac_description: str | None


class TransactionCreate(TransactionBase):
    pass


class TransactionRead(TransactionBase):
    transac_id: int

    class Config:
        from_attributes = True
