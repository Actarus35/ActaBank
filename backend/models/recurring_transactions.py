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

    def __repr__(self) -> str:
        return f"RecurringTransaction(id={self.rectrans_id!r}, name={self.rectrans_name!r}, amount={self.rectrans_amount!r}, frequency={self.rectrans_frequency!r})"
