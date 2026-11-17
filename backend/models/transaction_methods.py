from sqlalchemy import Enum, ForeignKey, false
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.transaction_type import TransactionType


class TransactionMethod(Base):
    __tablename__ = "transaction_methods"
    transmet_id: Mapped[int] = mapped_column(primary_key=True)
    transmet_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType), nullable=True)
    transmet_archived: Mapped[bool] = mapped_column(nullable=False, default=False, server_default=false())

    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.account_id"), nullable=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    account = relationship("Account", back_populates="methods")
    transactions = relationship("Transaction", back_populates="method")
    recurring_transactions = relationship("RecurringTransaction")

    def __repr__(self) -> str:
        return f"TransactionMethod(id={self.transmet_id!r}, type={self.transmet_type!r}, account_id={self.account_id!r})"