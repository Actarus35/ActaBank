from pydantic import BaseModel
from datetime import datetime


class TrnsactionMethod(BaseModel):
    id: int
    frequency: str
    day: int
    start_date: datetime
    end_date: datetime
