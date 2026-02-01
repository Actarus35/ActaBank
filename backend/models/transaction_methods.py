from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from database import Base


class TransactionMethod(Base):
    __tablename__ = "transaction_methods"
    transmet_id: Mapped[int] = mapped_column(primary_key=True)
    transmet_type: Mapped[str] = mapped_column(nullable=False)
    bank_id: Mapped[int] = mapped_column(ForeignKey("banks.bank_id"), nullable=True)

    def __repr__(self) -> str:
        return f"TransactionMethod(id={self.transmet_id!r}, type={self.transmet_type!r}, bank_id={self.bank_id!r})"
