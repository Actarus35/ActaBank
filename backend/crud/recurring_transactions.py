from sqlalchemy.orm import Session
from models.recurring_transactions import RecurringTransaction
from schemas.recurring_transactions import RecurringTransactionCreate, RecurringTransactionUpdate


def get_recurring_transactions(db: Session):
    return db.query(RecurringTransaction).all()


def get_recurring_transaction(db: Session, rectrans_id: int):
    return db.query(RecurringTransaction).filter(RecurringTransaction.rectrans_id == rectrans_id).first()


def create_recurring_transaction(db: Session, recurring_transaction: RecurringTransactionCreate):
    db_recurring_transaction = RecurringTransaction(**recurring_transaction.model_dump())
    db.add(db_recurring_transaction)
    db.commit()
    db.refresh(db_recurring_transaction)
    return db_recurring_transaction


def delete_recurring_transaction(db: Session, rectrans_id: int):
    recurring_transaction = get_recurring_transaction(db, rectrans_id)
    if recurring_transaction:
        db.delete(recurring_transaction)
        db.commit()
    return recurring_transaction


def modify_recurring_transaction(db: Session, rectrans_id: int, recurring_transaction_update: RecurringTransactionUpdate):
    db_recurring_transaction = get_recurring_transaction(db, rectrans_id)
    if not db_recurring_transaction:
        return None

    update_data = recurring_transaction_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_recurring_transaction, key, value)

    db.commit()
    db.refresh(db_recurring_transaction)
    return db_recurring_transaction
