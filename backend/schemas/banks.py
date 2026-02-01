from pydantic import BaseModel


class Bank(BaseModel):
    bank_id: int
    bank_name: str
    bank_account_type: str
    bank_description: str | None
