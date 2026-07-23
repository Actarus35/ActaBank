from sqlalchemy import String, DateTime, Enum
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime, timezone
from database import Base

from enums.user_role import UserRole


class User(Base):
    __tablename__ = "users"
    user_id: Mapped[int] = mapped_column(primary_key=True)
    user_role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False, default=UserRole.USER)
    user_username: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    user_password_hash: Mapped[str] = mapped_column(String(60), nullable=False)
    user_created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self) -> str:
        return f"User(id={self.user_id!r}, username={self.user_username!r}, created_at={self.user_created_at!r})"
