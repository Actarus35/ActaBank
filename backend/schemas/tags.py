from typing import Optional
from pydantic import BaseModel, ConfigDict

from schemas.base import CreateModel, Name100, UpdateModel
from enums.colors import Color


class TagBase(BaseModel):
    tag_name: Name100
    tag_color: Color = Color.WHITE


class TagCreate(TagBase, CreateModel):
    pass


class TagRead(TagBase):
    tag_id: int

    model_config = ConfigDict(from_attributes=True)


class TagUpdate(UpdateModel):
    non_nullable = frozenset({"tag_name", "tag_color"})
    tag_name: Optional[str] = None
    tag_color: Optional[Color] = None