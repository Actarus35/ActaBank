from sqlalchemy.orm import Session
from models.transaction_methods import TransactionMethod
from schemas.transaction_methods import TransactionMethodCreate, TransactionMethodUpdate


def get_transaction_methods(db: Session, user_id: int):
    return db.query(TransactionMethod).filter(TransactionMethod.user_id == user_id).all()


def get_transaction_method(db: Session, transmet_id: int, user_id: int):
    return db.query(TransactionMethod).filter(TransactionMethod.transmet_id == transmet_id, TransactionMethod.user_id == user_id).first()


def create_transaction_method(db: Session, transmet: TransactionMethodCreate, user_id: int):
    db_trans = TransactionMethod(**transmet.model_dump(), user_id=user_id)
    db.add(db_trans)
    db.commit()
    db.refresh(db_trans)
    return db_trans


def delete_transaction_method(db: Session, transmet_id: int, user_id: int):
    trans = get_transaction_method(db, transmet_id, user_id)
    if trans:
        db.delete(trans)
        db.commit()
    return trans


def modify_transaction_method(db: Session, transmet_id: int, user_id: int, transmet_update: TransactionMethodUpdate):
    db_transmet = get_transaction_method(db, transmet_id, user_id)
    if not db_transmet:
        return None
    
    update_data = transmet_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_transmet, key, value)

    db.flush()
    db.refresh(db_transmet)
    account = db_transmet.account
    if update_data.get("transmet_archived") is False and account is not None:
        account.account_archived = False
        if account.bank is not None:
            account.bank.bank_archived = False

    db.commit()
    db.refresh(db_transmet)
    return db_transmet