from typing import Optional
from pydantic import BaseModel, ConfigDict

from enums.colors import Color


class TagBase(BaseModel):
    tag_name: str
    tag_color: Color = Color.WHITE


class TagCreate(TagBase):
    pass


class TagRead(TagBase):
    tag_id: int

    model_config = ConfigDict(from_attributes=True)


class TagUpdate(TagBase):
    tag_name: Optional[str] = None
    tag_color: Optional[Color] = None