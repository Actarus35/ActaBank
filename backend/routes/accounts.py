from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from crud import accounts as crud
from crud import banks as banks_crud
from schemas import accounts as schema
from enums.account_type import AccountType


def check_account_refs(db, user_id, bank_id):
    if bank_id is not None and not banks_crud.get_bank(db, bank_id, user_id):
        raise HTTPException(
            status_code=422,
            detail="Banque introuvable",
        )

def check_account_consistency(account_type, bank_id):
    if not account_type.requires_bank and bank_id is not None:
        raise HTTPException(status_code=422, detail="Un portefeuille n'est rattaché à aucune banque")
    if account_type.requires_bank and bank_id is None:
        raise HTTPException(status_code=422, detail="Ce type de compte doit être rattaché à une banque")


router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("/", response_model=list[schema.AccountRead])
def read_accounts(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_accounts(db, current_user.user_id)


@router.get("/{account_id}", response_model=schema.AccountRead)
def read_account(account_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = crud.get_account(db, account_id, current_user.user_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.post("/", response_model=schema.AccountRead, status_code=201)
def create_account(account: schema.AccountCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    check_account_refs(db, current_user.user_id, account.bank_id)
    check_account_consistency(account.account_type, account.bank_id)
    return crud.create_account(db, account, current_user.user_id)


@router.delete("/{account_id}", status_code=204)
def delete_account(account_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = crud.get_account(db, account_id, current_user.user_id)
    if not account:
        raise HTTPException(
            status_code=404,
            detail="Account not found",
        )
    if any(not m.transmet_internal or m.transactions for m in account.methods):
        raise HTTPException(
            status_code=409,
            detail="Ce compte a encore des moyens de paiement ou des transferts : archive-le plutôt",
        )
    crud.delete_account(db, account_id, current_user.user_id)


@router.patch("/{account_id}", response_model=schema.AccountRead)
def update_account(account_id: int, account_update: schema.AccountUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = crud.get_account(db, account_id, current_user.user_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    check_account_refs(db, current_user.user_id, account_update.bank_id)
    final_type = account_update.account_type or account.account_type
    final_bank = account_update.bank_id if "bank_id" in account_update.model_fields_set else account.bank_id
    check_account_consistency(final_type, final_bank)
    return crud.modify_account(db, account_id, current_user.user_id, account_update)