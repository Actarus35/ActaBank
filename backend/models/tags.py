from sqlalchemy import Column, Enum, ForeignKey, Table
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base

from enums.colors import Color


transaction_tags = Table(
    "transaction_tags",
    Base.metadata,
    Column("transac_id", ForeignKey("transactions.transac_id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("tags.tag_id", ondelete="CASCADE"), primary_key=True),
)

recurring_transaction_tags = Table(
    "recurring_transaction_tags",
    Base.metadata,
    Column("rectrans_id", ForeignKey("recurring_transactions.rectrans_id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("tags.tag_id", ondelete="CASCADE"), primary_key=True),
)


class Tag(Base):
    __tablename__ = "tags"
    tag_id: Mapped[int] = mapped_column(primary_key=True)
    tag_name: Mapped[str] = mapped_column(nullable=False)
    tag_color: Mapped[Color] = mapped_column(Enum(Color), nullable=False, default=Color.WHITE)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"), nullable=False)

    transactions = relationship("Transaction", secondary=transaction_tags, back_populates="tags", passive_deletes=True)
    recurring_transactions = relationship("RecurringTransaction", secondary=recurring_transaction_tags, back_populates="tags", passive_deletes=True)

    def __repr__(self) -> str:
        return f"Tag(id={self.tag_id!r}, name={self.tag_name!r}, color={self.tag_color!r})"