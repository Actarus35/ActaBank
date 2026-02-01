from pydantic import BaseModel


class TransactionMethodBase(BaseModel):
    transmet_type: str


class TransactionMethodCreate(TransactionMethodBase):
    pass


class TransactionMethodRead(TransactionMethodBase):
    transac_id: int

    class Config:
        from_attributes = True
