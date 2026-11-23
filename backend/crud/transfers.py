import uuid

from sqlalchemy.orm import Session

from models.transactions import Transaction
from schemas.transfers import TransferCreate


def create_transfer(db: Session, transfer: TransferCreate, user_id: int):
    transfer_id = uuid.uuid4()
    common = dict(
        transac_name=transfer.name,
        transac_date=transfer.transfer_date,
        transac_description=transfer.description,
        transac_transfer_id=transfer_id,
        user_id=user_id,
    )
    outgoing = Transaction(**common, transac_amount=-transfer.amount, transmet_id=transfer.from_method_id)
    incoming = Transaction(**common, transac_amount=transfer.amount, transmet_id=transfer.to_method_id)
    db.add_all([outgoing, incoming])
    db.commit()
    db.refresh(outgoing)
    db.refresh(incoming)
    return [outgoing, incoming]