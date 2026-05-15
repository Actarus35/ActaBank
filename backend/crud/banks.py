from sqlalchemy.orm import Session
from models.banks import Bank
from schemas.banks import BankCreate, BankUpdate


def get_banks(db: Session):
    return db.query(Bank).all()


def get_bank(db: Session, bank_id: int):
    return db.query(Bank).filter(Bank.bank_id == bank_id).first()


def create_bank(db: Session, bank: BankCreate):
    db_bank = Bank(**bank.dict())
    db.add(db_bank)
    db.commit()
    db.refresh(db_bank)
    return db_bank


def delete_bank(db: Session, bank_id: int):
    bank = get_bank(db, bank_id)
    if bank:
        db.delete(bank)
        db.commit()
    return bank


def modify_bank(db: Session, bank_id: int, bank_update: BankUpdate):
    db_bank = get_bank(db, bank_id)
    if not db_bank:
        return None

    update_data = bank_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_bank, key, value)

    db.commit()
    db.refresh(db_bank)
    return db_bank
