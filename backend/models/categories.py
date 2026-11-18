from sqlalchemy import Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.colors import Color


class Category(Base):
    __tablename__ = "categories"
    category_id: Mapped[int] = mapped_column(primary_key=True)
    category_name: Mapped[str] = mapped_column(nullable=False)
    category_color: Mapped[Color] = mapped_column(Enum(Color), nullable=False, default=Color.WHITE)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    transactions = relationship("Transaction", back_populates="category", passive_deletes=True)

    def __repr__(self) -> str:
        return f"Category(id={self.category_id!r}, name={self.category_name!r}, color={self.category_color!r})"
