from sqlalchemy.orm import Session
from crud.tags import get_tags_by_ids
from models.recurring_transactions import RecurringTransaction
from schemas.recurring_transactions import RecurringTransactionCreate, RecurringTransactionUpdate


def get_recurring_transactions(db: Session, user_id: int):
    return db.query(RecurringTransaction).filter(RecurringTransaction.user_id == user_id).all()


def get_recurring_transaction(db: Session, rectrans_id: int, user_id: int):
    return db.query(RecurringTransaction).filter(RecurringTransaction.rectrans_id == rectrans_id, RecurringTransaction.user_id == user_id).first()


def create_recurring_transaction(db: Session, recurring_transaction: RecurringTransactionCreate, user_id: int):
    data = recurring_transaction.model_dump()
    tag_ids = data.pop("tag_ids")
    db_recurring_transaction = RecurringTransaction(**data, user_id=user_id)
    db_recurring_transaction.tags = get_tags_by_ids(db, tag_ids, user_id)
    db.add(db_recurring_transaction)
    db.commit()
    db.refresh(db_recurring_transaction)
    return db_recurring_transaction


def delete_recurring_transaction(db: Session, rectrans_id: int, user_id: int):
    recurring_transaction = get_recurring_transaction(db, rectrans_id, user_id)
    if recurring_transaction:
        db.delete(recurring_transaction)
        db.commit()
    return recurring_transaction


def modify_recurring_transaction(db: Session, rectrans_id: int, user_id: int, recurring_transaction_update: RecurringTransactionUpdate):
    db_recurring_transaction = get_recurring_transaction(db, rectrans_id, user_id)
    if not db_recurring_transaction:
        return None

    update_data = recurring_transaction_update.model_dump(exclude_unset=True)

    tag_ids = update_data.pop("tag_ids", None)
    if tag_ids is not None:
        db_recurring_transaction.tags = get_tags_by_ids(db, tag_ids, user_id)

    for key, value in update_data.items():
        setattr(db_recurring_transaction, key, value)

    db.commit()
    db.refresh(db_recurring_transaction)
    return db_recurring_transaction
