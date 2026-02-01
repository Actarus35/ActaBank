from pydantic import BaseModel


class Label(BaseModel):
    label_id: int
    label_name: str
    label_color: str
