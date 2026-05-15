from pydantic import BaseModel

from enums.colors import Color


class LabelBase(BaseModel):
    label_name: str
    label_color: Color


class LabelRead(LabelBase):
    label_id: int

    class Config:
        from_attributes = True
