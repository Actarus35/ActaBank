from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db, get_current_user
from models.users import User
from crud import transfers as crud
from crud import accounts as accounts_crud
from schemas.transfers import TransferCreate
from schemas.transactions import TransactionRead


router = APIRouter(prefix="/transfers", tags=["transfers"])


def _check_account(db, account_id: int, user_id: int):
    account = accounts_crud.get_account(db, account_id, user_id)
    if not account:
        raise HTTPException(status_code=422, detail="Compte introuvable")
    if account.account_archived:
        raise HTTPException(status_code=422, detail="Compte archivé")
    return account


@router.post("/", response_model=list[TransactionRead], status_code=201)
def create_transfer(transfer: TransferCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    _check_account(db, transfer.from_account_id, current_user.user_id)
    _check_account(db, transfer.to_account_id, current_user.user_id)
    if transfer.from_account_id == transfer.to_account_id:
        raise HTTPException(status_code=422, detail="Un transfert relie deux comptes différents")
    return crud.create_transfer(db, transfer, current_user.user_id)