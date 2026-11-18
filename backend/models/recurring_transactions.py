from sqlalchemy import DateTime, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base
from datetime import datetime
from decimal import Decimal

from enums.frequency import Frequency
from models.tags import recurring_transaction_tags


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"
    rectrans_id: Mapped[int] = mapped_column(primary_key=True)
    rectrans_name: Mapped[str] = mapped_column(nullable=False)
    rectrans_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    rectrans_frequency: Mapped[Frequency] = mapped_column(Enum(Frequency), nullable=False)
    rectrans_start_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    rectrans_end_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    rectrans_last_generated: Mapped[datetime] = mapped_column(DateTime, nullable=True)

    rectrans_transmet_id: Mapped[int] = mapped_column(ForeignKey("transaction_methods.transmet_id"), nullable=False)
    rectrans_category_id: Mapped[int] = mapped_column(ForeignKey("categories.category_id", ondelete='SET NULL'), nullable=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    transaction = relationship("Transaction", back_populates="recurring_transaction", passive_deletes=True)
    tags = relationship("Tag", secondary=recurring_transaction_tags, back_populates="recurring_transactions", passive_deletes=True)

    @property
    def rectrans_next_date(self) -> datetime | None:
        """Prochaine occurrence à générer, ou None si la règle est terminée."""
        if self.rectrans_last_generated is None:
            next_date = self.rectrans_start_date
        else:
            next_date = self.rectrans_last_generated + self.rectrans_frequency.step
        if self.rectrans_end_date is not None and next_date > self.rectrans_end_date:
            return None
        return next_date

    def __repr__(self) -> str:
        return f"RecurringTransaction(id={self.rectrans_id!r}, name={self.rectrans_name!r}, amount={self.rectrans_amount!r}, frequency={self.rectrans_frequency!r})"
