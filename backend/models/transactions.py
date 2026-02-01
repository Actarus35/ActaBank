from sqlalchemy import ForeignKey, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"
    transac_id: Mapped[int] = mapped_column(primary_key=True)
    transac_name: Mapped[str] = mapped_column(nullable=False)
    transac_title: Mapped[str] = mapped_column(nullable=True)
    transac_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    transac_amount: Mapped[float] = mapped_column(nullable=False)
    transac_description: Mapped[str] = mapped_column(nullable=True)
    transac_is_recurring: Mapped[bool] = mapped_column(Boolean, nullable=False, default=0)

    transmet_id: Mapped[int] = mapped_column(ForeignKey("transaction_methods.transmet_id"))
    label_id: Mapped[int] = mapped_column(ForeignKey("labels.label_id"))

    method = relationship("TransactionMethod", back_populates="transaction")
    label = relationship("Label", back_populates="transaction")
    recurring_transaction = relationship("RecurringTransaction", back_populates="transaction")

    def __repr__(self) -> str:
        return f"Transaction(id={self.transac_id!r}, name={self.transac_name!r}, title={self.transac_title!r}, date={self.transac_date!r}, amount={self.transac_amount!r}, description={self.transac_description!r}, is_recurring={self.transac_is_recurring!r}, transmet_id={self.transmet_id!r}, label_id={self.label_id!r})"
