from sqlalchemy.orm import Session
from models.accounts import Account
from schemas.accounts import AccountCreate, AccountUpdate


def get_accounts(db: Session, user_id: int):
    return db.query(Account).filter(Account.user_id == user_id).all()


def get_account(db: Session, account_id: int, user_id: int):
    return db.query(Account).filter(Account.account_id == account_id, Account.user_id == user_id).first()


def create_account(db: Session, account: AccountCreate, user_id: int):
    db_account = Account(**account.model_dump(), user_id=user_id)
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def delete_account(db: Session, account_id: int, user_id: int):
    account = get_account(db, account_id, user_id)
    if account:
        db.delete(account)
        db.commit()
    return account


def modify_account(db: Session, account_id: int, user_id: int, account_update: AccountUpdate):
    db_account = get_account(db, account_id, user_id)
    if not db_account:
        return None

    update_data = account_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_account, key, value)

    db.commit()
    db.refresh(db_account)
    return db_account
