from sqlalchemy import Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.colors import Color


class Label(Base):
    __tablename__ = "labels"
    label_id: Mapped[int] = mapped_column(primary_key=True)
    label_name: Mapped[str] = mapped_column(nullable=False)
    label_color: Mapped[Color] = mapped_column(Enum(Color), nullable=False, default=Color.WHITE)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    transactions = relationship("Transaction", back_populates="label", passive_deletes=True)

    def __repr__(self) -> str:
        return f"Label(id={self.label_id!r}, name={self.label_name!r}, color={self.label_color!r})"
