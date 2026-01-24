from pydantic import BaseModel


class TrnsactionMethod(BaseModel):
    id: int
    type: str
