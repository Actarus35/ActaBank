from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from models.users import User
from crud import banks as crud
from schemas import banks as schema
from dependencies import get_db, get_current_user


router = APIRouter(prefix="/banks", tags=["banks"])


@router.get("/", response_model=list[schema.BankRead])
def read_banks(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_banks(db, current_user.user_id)


@router.get("/{bank_id}", response_model=schema.BankRead)
def read_bank(bank_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    bank = crud.get_bank(db, bank_id, current_user.user_id)
    if not bank:
        raise HTTPException(status_code=404, detail="Bank not found")
    return bank


@router.post("/", response_model=schema.BankRead, status_code=201)
def create_bank(bank: schema.BankCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.create_bank(db, bank, current_user.user_id)


@router.delete("/{bank_id}", status_code=204)
def delete_bank(bank_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    bank = crud.get_bank(db, bank_id, current_user.user_id)
    if not bank:
        raise HTTPException(
            status_code=404,
            detail="Bank not found",
        )
    if bank.accounts:
        raise HTTPException(
            status_code=409,
            detail="Cette banque est utilisée par des comptes et ne peut pas être supprimée",
        )
    crud.delete_bank(db, bank_id)


@router.patch("/{bank_id}", response_model=schema.BankRead)
def update_bank(bank_id: int, bank_update: schema.BankUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    bank = crud.modify_bank(db, bank_id, current_user.user_id, bank_update)
    if not bank:
        raise HTTPException(status_code=404, detail="Bank not found")
    return bank
