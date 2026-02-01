from sqlalchemy.orm import Session
from models.transactions import Transaction
from schemas.transactions import TransactionCreate


def get_transactions(db: Session):
    return db.query(Transaction).all()


def get_transaction(db: Session, transaction_id: int):
    return db.query(Transaction).filter(Transaction.id == transaction_id).first()


def create_transaction(db: Session, transaction: TransactionCreate):
    db_trans = Transaction(**transaction.dict())
    db.add(db_trans)
    db.commit()
    db.refresh(db_trans)
    return db_trans


def delete_transaction(db: Session, transaction_id: int):
    trans = get_transaction(db, transaction_id)
    if trans:
        db.delete(trans)
        db.commit()
    return trans
