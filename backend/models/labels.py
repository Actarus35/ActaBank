from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base


class Label(Base):
    __tablename__ = "labels"
    label_id: Mapped[int] = mapped_column(primary_key=True)
    label_name: Mapped[str] = mapped_column(nullable=False)
    label_color: Mapped[str] = mapped_column(nullable=False, default="white")

    transaction = relationship("Transaction", back_populates="label")

    def __repr__(self) -> str:
        return f"Label(id={self.label_id!r}, name={self.label_name!r}, color={self.label_color!r})"
