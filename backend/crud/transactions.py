from sqlalchemy.orm import Session, selectinload
from models.accounts import Account
from models.transactions import Transaction
from models.transaction_methods import TransactionMethod
from schemas.transactions import TransactionCreate, TransactionUpdate


def get_transactions(db: Session, user_id: int):
    return db.query(Transaction).filter(Transaction.user_id == user_id).options(
        selectinload(Transaction.method).selectinload(TransactionMethod.account).selectinload(Account.bank),
        selectinload(Transaction.label),
        selectinload(Transaction.recurring_transaction),
    ).all()


def get_transaction(db: Session, transaction_id: int, user_id: int):
    return db.query(Transaction).filter(Transaction.transac_id == transaction_id, Transaction.user_id == user_id).first()


def create_transaction(db: Session, transaction: TransactionCreate, user_id: int):
    db_trans = Transaction(**transaction.model_dump(), user_id=user_id)
    db.add(db_trans)
    db.commit()
    db.refresh(db_trans)
    return db_trans


def delete_transaction(db: Session, transaction_id: int, user_id: int):
    trans = get_transaction(db, transaction_id, user_id)
    if trans:
        db.delete(trans)
        db.commit()
    return trans


def modify_transaction(db: Session, transaction_id: int, user_id: int, transaction_update: TransactionUpdate):
    db_trans = get_transaction(db, transaction_id, user_id)
    if not db_trans:
        return None

    update_data = transaction_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_trans, key, value)

    db.commit()
    db.refresh(db_trans)
    return db_trans
