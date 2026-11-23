from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db, get_current_user
from models.users import User
from crud import transfers as crud
from crud import transaction_methods as methods_crud
from schemas.transfers import TransferCreate
from schemas.transactions import TransactionRead


router = APIRouter(prefix="/transfers", tags=["transfers"])


def _check_method(db, method_id: int, user_id: int):
    method = methods_crud.get_transaction_method(db, method_id, user_id)
    if not method:
        raise HTTPException(status_code=422, detail="Moyen de paiement introuvable")
    if method.transmet_archived:
        raise HTTPException(status_code=422, detail="Moyen de paiement archivé")
    return method


@router.post("/", response_model=list[TransactionRead], status_code=201)
def create_transfer(transfer: TransferCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    source = _check_method(db, transfer.from_method_id, current_user.user_id)
    target = _check_method(db, transfer.to_method_id, current_user.user_id)
    if source.account_id == target.account_id:
        raise HTTPException(status_code=422, detail="Un transfert relie deux comptes différents")
    return crud.create_transfer(db, transfer, current_user.user_id)