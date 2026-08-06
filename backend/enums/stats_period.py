from enum import Enum

class StatsPeriod(str, Enum):
    MONTH = "month"
    THREE_MONTHS = "3months"
    SIX_MONTHS = "6months"
    ALL = "all"