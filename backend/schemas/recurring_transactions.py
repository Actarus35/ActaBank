from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

from enums.frequency import Frequency


class RecurringTransactionBase(BaseModel):
    rectrans_frequency: Frequency
    rectrans_start_date: datetime
    rectrans_end_date: datetime | None = None


class RecurringTransactionCreate(RecurringTransactionBase):
    pass


class RecurringTransactionRead(RecurringTransactionBase):
    rectrans_id: int

    model_config = ConfigDict(from_attributes=True)



class RecurringTransactionUpdate(BaseModel):
    rectrans_frequency: Optional[Frequency] = None
    rectrans_start_date: Optional[datetime] = None
    rectrans_end_date: Optional[datetime] = None