from typing import Optional
from pydantic import BaseModel, ConfigDict

from enums.colors import Color


class LabelBase(BaseModel):
    label_name: str
    label_color: Color = Color.WHITE


class LabelCreate(LabelBase):
    pass


class LabelRead(LabelBase):
    label_id: int

    model_config = ConfigDict(from_attributes=True)


class LabelUpdate(LabelBase):
    label_name: Optional[str] = None
    label_color: Optional[Color] = None