from typing import Optional
from pydantic import BaseModel, ConfigDict

from schemas.base import CreateModel, Name100, UpdateModel
from enums.colors import Color


class CategoryBase(BaseModel):
    category_name: Name100
    category_color: Color = Color.WHITE


class CategoryCreate(CategoryBase, CreateModel):
    pass


class CategoryRead(CategoryBase):
    category_id: int

    model_config = ConfigDict(from_attributes=True)


class CategoryUpdate(UpdateModel):
    non_nullable = frozenset({"category_name", "category_color"})

    category_name: Optional[str] = None
    category_color: Optional[Color] = None