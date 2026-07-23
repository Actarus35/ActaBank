from sqlalchemy import Enum, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from decimal import Decimal
from database import Base

from enums.account_type import AccountType


class Account(Base):
    __tablename__ = "accounts"
    account_id: Mapped[int] = mapped_column(primary_key=True)
    account_name: Mapped[str] = mapped_column(String(50), nullable=False)
    account_type: Mapped[AccountType] = mapped_column(Enum(AccountType), nullable=False)
    account_initial_balance: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=Decimal("0.00"))
    account_description: Mapped[str] = mapped_column(nullable=True)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)
    bank_id: Mapped[int] = mapped_column(ForeignKey("banks.bank_id"), nullable=False)

    bank = relationship("Bank", back_populates="accounts")
    methods = relationship("TransactionMethod", back_populates="account")

    def __repr__(self) -> str:
        return f"Account(id={self.account_id!r}, name={self.account_name!r}, type={self.account_type!r}, bank_id={self.bank_id!r})"