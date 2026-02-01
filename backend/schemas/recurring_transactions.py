from pydantic import BaseModel
from datetime import datetime


class RecurringTransaction(BaseModel):
    rectransac_id: int
    rectransac_frequency: str
    rectransac_day: int
    rectransac_start_date: datetime
    rectransac_end_date: datetime
