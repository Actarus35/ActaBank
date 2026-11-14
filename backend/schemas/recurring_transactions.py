from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from decimal import Decimal

from enums.frequency import Frequency
from schemas.tags import TagRead


class RecurringTransactionBase(BaseModel):
    rectrans_name: str
    rectrans_amount: Decimal
    rectrans_frequency: Frequency
    rectrans_start_date: datetime
    rectrans_end_date: datetime | None = None
    rectrans_transmet_id: int
    rectrans_category_id: Optional[int] = None


class RecurringTransactionCreate(RecurringTransactionBase):
    tag_ids: list[int] = []
    pass


class RecurringTransactionRead(RecurringTransactionBase):
    rectrans_id: int
    tags: list[TagRead]

    model_config = ConfigDict(from_attributes=True)



class RecurringTransactionUpdate(BaseModel):
    rectrans_name: Optional[str] = None
    rectrans_amount: Optional[Decimal] = None
    rectrans_frequency: Optional[Frequency] = None
    rectrans_start_date: Optional[datetime] = None
    rectrans_end_date: Optional[datetime] = None
    rectrans_transmet_id: Optional[int] = None
    rectrans_category_id: Optional[int] = None
    tag_ids: Optional[list[int]] = None