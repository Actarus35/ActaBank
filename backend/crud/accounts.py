from sqlalchemy.orm import Session
from models.accounts import Account
from schemas.accounts import AccountCreate, AccountUpdate


def get_accounts(db: Session):
    return db.query(Account).all()


def get_account(db: Session, account_id: int):
    return db.query(Account).filter(Account.account_id == account_id).first()


def create_account(db: Session, account: AccountCreate):
    db_account = Account(**account.model_dump())
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def delete_account(db: Session, account_id: int):
    account = get_account(db, account_id)
    if account:
        db.delete(account)
        db.commit()
    return account


def modify_account(db: Session, account_id: int, account_update: AccountUpdate):
    db_account = get_account(db, account_id)
    if not db_account:
        return None

    update_data = account_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_account, key, value)

    db.commit()
    db.refresh(db_account)
    return db_account
