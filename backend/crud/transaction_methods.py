from sqlalchemy.orm import Session
from models.transaction_methods import TransactionMethod
from schemas.transaction_methods import TransactionMethodCreate


def get_transaction_methods(db: Session):
    return db.query(TransactionMethod).all()


def get_transaction_method(db: Session, transmet_id: int):
    return db.query(TransactionMethod).filter(TransactionMethod.id == transmet_id).first()


def create_transaction_method(db: Session, transaction: TransactionMethodCreate):
    db_trans = TransactionMethod(**transaction.dict())
    db.add(db_trans)
    db.commit()
    db.refresh(db_trans)
    return db_trans


def delete_transaction_method(db: Session, transaction_id: int):
    trans = get_transaction_method(db, transaction_id)
    if trans:
        db.delete(trans)
        db.commit()
    return trans
