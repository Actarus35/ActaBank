from enum import Enum

from dateutil.relativedelta import relativedelta


class Frequency(str, Enum):
    DAILY = "DAILY"
    WEEKLY = "WEEKLY"
    MONTHLY = "MONTHLY"
    YEARLY = "YEARLY"

    @property
    def step(self) -> relativedelta:
        return _STEPS[self]


_STEPS = {
    Frequency.DAILY: relativedelta(days=1),
    Frequency.WEEKLY: relativedelta(weeks=1),
    Frequency.MONTHLY: relativedelta(months=1),
    Frequency.YEARLY: relativedelta(years=1),
}
