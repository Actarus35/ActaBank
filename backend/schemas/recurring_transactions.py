from pydantic import BaseModel
from datetime import datetime


class RecurringTransactionBase(BaseModel):
    rectransac_frequency: str
    rectransac_start_date: datetime
    rectransac_end_date: datetime | None


class RecurringTransactionRead(RecurringTransactionBase):
    rectransac_id: int

    class Config:
        from_attributes = True
