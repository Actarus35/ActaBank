import uuid

from sqlalchemy.orm import Session

from models.transactions import Transaction
from schemas.transfers import TransferCreate
from crud.transaction_methods import get_or_create_internal_method


def create_transfer(db: Session, transfer: TransferCreate, user_id: int):
    transfer_id = uuid.uuid4()
    source = get_or_create_internal_method(db, transfer.from_account_id, user_id)
    target = get_or_create_internal_method(db, transfer.to_account_id, user_id)
    common = dict(
        transac_name=transfer.name,
        transac_date=transfer.transfer_date,
        transac_description=transfer.description,
        transac_transfer_id=transfer_id,
        user_id=user_id,
    )
    outgoing = Transaction(**common, transac_amount=-transfer.amount, transmet_id=source.transmet_id)
    incoming = Transaction(**common, transac_amount=transfer.amount, transmet_id=target.transmet_id)
    db.add_all([outgoing, incoming])
    db.commit()
    db.refresh(outgoing)
    db.refresh(incoming)
    return [outgoing, incoming]