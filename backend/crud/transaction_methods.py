from sqlalchemy.orm import Session
from models.transaction_methods import TransactionMethod
from schemas.transaction_methods import TransactionMethodCreate


def get_transaction_methods(db: Session):
    return db.query(TransactionMethod).all()


def get_transaction_method(db: Session, transmet_id: int):
    return db.query(TransactionMethod).filter(TransactionMethod.transmet_id == transmet_id).first()


def create_transaction_method(db: Session, transmet: TransactionMethodCreate):
    db_trans = TransactionMethod(**transmet.dict())
    db.add(db_trans)
    db.commit()
    db.refresh(db_trans)
    return db_trans


def delete_transaction_method(db: Session, transmet_id: int):
    trans = get_transaction_method(db, transmet_id)
    if trans:
        db.delete(trans)
        db.commit()
    return trans
