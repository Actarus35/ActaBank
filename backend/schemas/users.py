from pydantic import BaseModel, ConfigDict, Field, field_validator
from datetime import datetime

from enums.user_role import UserRole


class UserBase(BaseModel):
    user_username: str = Field(min_length=3, max_length=30)


class UserCreate(UserBase):
    user_password: str = Field(min_length=8, max_length=72)

    @field_validator("user_password")
    @classmethod
    def password_max_bytes(cls, value:str) -> str:
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Le mot de passe ne doit pas dépasser 72 octets")
        return value


class UserRead(UserBase):
    user_id: int
    user_role: UserRole
    user_created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"