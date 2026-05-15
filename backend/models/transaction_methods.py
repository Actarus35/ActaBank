from sqlalchemy import Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.transaction_type import TransactionType


class TransactionMethod(Base):
    __tablename__ = "transaction_methods"
    transmet_id: Mapped[int] = mapped_column(primary_key=True)
    transmet_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType), nullable=True)

    bank_id: Mapped[int] = mapped_column(ForeignKey("banks.bank_id"), nullable=True)

    bank = relationship("Bank", back_populates="methods")
    transactions = relationship("Transaction", back_populates="method")

    def __repr__(self) -> str:
        return f"TransactionMethod(id={self.transmet_id!r}, type={self.transmet_type!r}, bank_id={self.bank_id!r})"
