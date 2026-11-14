from typing import Optional
from pydantic import BaseModel, ConfigDict

from enums.colors import Color


class CategoryBase(BaseModel):
    category_name: str
    category_color: Color = Color.WHITE


class CategoryCreate(CategoryBase):
    pass


class CategoryRead(CategoryBase):
    category_id: int

    model_config = ConfigDict(from_attributes=True)


class CategoryUpdate(CategoryBase):
    category_name: Optional[str] = None
    category_color: Optional[Color] = None