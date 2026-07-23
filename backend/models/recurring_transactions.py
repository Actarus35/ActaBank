from sqlalchemy import DateTime, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base
from datetime import datetime

from enums.frequency import Frequency


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"
    rectrans_id: Mapped[int] = mapped_column(primary_key=True)
    rectrans_frequency: Mapped[Frequency] = mapped_column(Enum(Frequency), nullable=False)
    rectrans_start_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    rectrans_end_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    transaction = relationship("Transaction", back_populates="recurring_transaction", passive_deletes=True)

    def __repr__(self) -> str:
        return f"RecurringTransaction(id={self.rectrans_id!r}, frequency={self.rectrans_frequency!r}, start_date={self.rectrans_start_date!r}, end_date={self.rectrans_end_date!r}, transac_id={self.transaction!r})"
