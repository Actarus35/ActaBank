from pydantic import BaseModel


class Bank(BaseModel):
    id: int
    name: str
    account_type: str
    description: str | None
