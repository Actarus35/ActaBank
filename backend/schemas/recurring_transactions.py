from pydantic import BaseModel
from datetime import datetime

from enums.frequency import Frequency


class RecurringTransactionBase(BaseModel):
    rectrans_frequency: Frequency
    rectrans_start_date: datetime
    rectrans_end_date: datetime | None


class RecurringTransactionRead(RecurringTransactionBase):
    rectrans_id: int

    class Config:
        from_attributes = True