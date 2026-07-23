from sqlalchemy.orm import Session
from models.banks import Bank
from schemas.banks import BankCreate, BankUpdate


def get_banks(db: Session, user_id: int):
    return db.query(Bank).filter(Bank.user_id == user_id).all()


def get_bank(db: Session, bank_id: int, user_id: int):
    return db.query(Bank).filter(Bank.bank_id == bank_id, Bank.user_id == user_id).first()


def create_bank(db: Session, bank: BankCreate, user_id: int):
    db_bank = Bank(**bank.model_dump(), user_id=user_id)
    db.add(db_bank)
    db.commit()
    db.refresh(db_bank)
    return db_bank


def delete_bank(db: Session, bank_id: int, user_id: int):
    bank = get_bank(db, bank_id, user_id)
    if bank:
        db.delete(bank)
        db.commit()
    return bank


def modify_bank(db: Session, bank_id: int, user_id: int, bank_update: BankUpdate):
    db_bank = get_bank(db, bank_id, user_id)
    if not db_bank:
        return None

    update_data = bank_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_bank, key, value)

    db.commit()
    db.refresh(db_bank)
    return db_bank
