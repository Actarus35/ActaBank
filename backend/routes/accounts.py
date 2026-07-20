from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db

from schemas import accounts as schema
from crud import accounts as crud
from crud import banks as banks_crud


def check_account_refs(db, bank_id):
    if bank_id is not None and not banks_crud.get_bank(db, bank_id):
        raise HTTPException(
            status_code=422,
            detail="Banque introuvable",
        )


router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("/", response_model=list[schema.AccountRead])
def read_accounts(db: Session = Depends(get_db)):
    return crud.get_accounts(db)


@router.get("/{account_id}", response_model=schema.AccountRead)
def read_account(account_id: int, db: Session = Depends(get_db)):
    account = crud.get_account(db, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.post("/", response_model=schema.AccountRead, status_code=201)
def create_account(account: schema.AccountCreate, db: Session = Depends(get_db)):
    check_account_refs(db, account.bank_id)
    return crud.create_account(db, account)


@router.delete("/{account_id}", status_code=204)
def delete_account(account_id: int, db: Session = Depends(get_db)):
    account = crud.get_account(db, account_id)
    if not account:
        raise HTTPException(
            status_code=404,
            detail="Account not found",
        )
    if account.methods:
        raise HTTPException(
            status_code=409,
            detail="Ce compte est utilisé par des méthodes de paiement et ne peut pas être supprimé",
        )
    crud.delete_account(db, account_id)


@router.patch("/{account_id}", response_model=schema.AccountRead)
def update_account(account_id: int, account_update: schema.AccountUpdate, db: Session = Depends(get_db)):
    check_account_refs(db, account_update.bank_id) 
    account = crud.modify_account(db, account_id, account_update)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account
