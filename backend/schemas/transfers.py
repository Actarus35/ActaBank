from datetime import datetime
from typing import Annotated, Optional

from pydantic import Field

from schemas.base import CreateModel, Money, Name100


class TransferCreate(CreateModel):
    from_method_id: int
    to_method_id: int
    amount: Annotated[Money, Field(gt=0)]   # toujours positif : le sens est donné par from/to
    transfer_date: datetime
    name: Name100 = "Transfert"
    description: Optional[str] = None