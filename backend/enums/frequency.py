from enum import Enum


class Frequency(str, Enum):
    DAYLY = "DAYLY"
    WEEKLY = "WEEKLY"
    MONTHLY = "MONTHLY"
    YEARLY = "YEARLY"
