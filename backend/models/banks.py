from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column
from database import Base


class Bank(Base):
    __tablename__ = "banks"
    bank_id: Mapped[int] = mapped_column(primary_key=True)
    bank_name: Mapped[str] = mapped_column(String(30), nullable=False)
    bank_account_type: Mapped[str] = mapped_column(unique=True, nullable=False)
    bank_description: Mapped[str] = mapped_column(nullable=True)

    def __repr__(self) -> str:
        return f"Bank(id={self.bank_id!r}, name={self.bank_name!r}, account_type={self.bank_account_type!r}, description={self.bank_description!r})"
