from sqlalchemy import ForeignKey, String, Enum, false
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.colors import Color


class Bank(Base):
    __tablename__ = "banks"
    bank_id: Mapped[int] = mapped_column(primary_key=True)
    bank_name: Mapped[str] = mapped_column(String(30), nullable=False)
    bank_color: Mapped[Color] = mapped_column(Enum(Color), default=Color.WHITE, nullable=False)
    bank_description: Mapped[str] = mapped_column(nullable=True)
    bank_archived: Mapped[bool] = mapped_column(nullable=False, default=False, server_default=false())

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    accounts = relationship("Account", back_populates="bank")

    def __repr__(self) -> str:
        return f"Bank(id={self.bank_id!r}, name={self.bank_name!r}, color={self.bank_color!r}, description={self.bank_description!r})"
