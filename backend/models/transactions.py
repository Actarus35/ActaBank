from sqlalchemy import ForeignKey, DateTime, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime
from decimal import Decimal
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"
    transac_id: Mapped[int] = mapped_column(primary_key=True)
    transac_name: Mapped[str] = mapped_column(nullable=False)
    transac_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    transac_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    transac_description: Mapped[str] = mapped_column(nullable=True)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)
    transmet_id: Mapped[int] = mapped_column(ForeignKey("transaction_methods.transmet_id"), nullable=False)
    label_id: Mapped[int] = mapped_column(ForeignKey("labels.label_id", ondelete="SET NULL"), nullable=True)
    rectrans_id: Mapped[int] = mapped_column(ForeignKey("recurring_transactions.rectrans_id", ondelete="SET NULL"), nullable=True)

    method = relationship("TransactionMethod", back_populates="transactions")
    label = relationship("Label", back_populates="transactions")
    recurring_transaction = relationship("RecurringTransaction", back_populates="transaction")

    def __repr__(self) -> str:
        return f"Transaction(id={self.transac_id!r}, name={self.transac_name!r}, date={self.transac_date!r}, amount={self.transac_amount!r}, description={self.transac_description!r}, transmet_id={self.transmet_id!r}, label_id={self.label_id!r}, rectrans_id={self.rectrans_id!r})"
