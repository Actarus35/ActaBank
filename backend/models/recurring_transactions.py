from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"
    rectransac_id: Mapped[int] = mapped_column(primary_key=True)
    rectransac_frequency: Mapped[str] = mapped_column(nullable=False)
    rectransac_day: Mapped[str] = mapped_column(nullable=True)
    rectransac_start_date: Mapped[str] = mapped_column(nullable=False)
    rectransac_end_date: Mapped[float] = mapped_column(nullable=False)

    transac_id: Mapped[int] = mapped_column(ForeignKey("transactions.transac_id"))

    transaction = relationship("Transaction", back_populates="recurring_transaction")

    def __repr__(self) -> str:
        return f"RecurringTransaction(id={self.rectransac_id!r}, frequency={self.rectransac_frequency!r}, day={self.rectransac_day!r}, start_date={self.rectransac_start_date!r}, end_date={self.rectransac_end_date!r}, transac_id={self.transac_id!r})"
