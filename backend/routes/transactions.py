from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from crud import tags as tags_crud
from crud import transactions as crud
from schemas import transactions as schema
from crud import categories as categories_crud
from crud import recurring_transactions as rec_crud
from crud import transaction_methods as methods_crud


router = APIRouter(prefix="/transactions", tags=["transactions"])


def check_transaction_refs(db, user_id, transmet_id, category_id, rectrans_id, tag_ids, current_transmet_id=None):
    if transmet_id is not None:
        method = methods_crud.get_transaction_method(db, transmet_id, user_id)
        if not method:
            raise HTTPException(status_code=422, detail="Méthode de paiement introuvable")
        if method.transmet_archived and transmet_id != current_transmet_id:
            raise HTTPException(status_code=422, detail="Méthode de paiement archivée")
    if category_id is not None and not categories_crud.get_category(db, category_id, user_id):
        raise HTTPException(status_code=422, detail="Categorie introuvable")
    if rectrans_id is not None and not rec_crud.get_recurring_transaction(db, rectrans_id, user_id):
        raise HTTPException(status_code=422, detail="Récurrence introuvable")
    if tag_ids and len(tags_crud.get_tags_by_ids(db, tag_ids, user_id)) != len(set(tag_ids)):
        raise HTTPException(status_code=422, detail="Tag introuvable")


@router.get("/", response_model=list[schema.TransactionRead])
def read_transactions(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_transactions(db, current_user.user_id)


@router.get("/{transaction_id}", response_model=schema.TransactionRead)
def read_transaction(transaction_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trans = crud.get_transaction(db, transaction_id, current_user.user_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@router.post("/", response_model=schema.TransactionRead, status_code=201)
def create_transaction(transaction: schema.TransactionCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    check_transaction_refs(db, current_user.user_id, transaction.transmet_id, transaction.category_id, transaction.rectrans_id, transaction.tag_ids)
    return crud.create_transaction(db, transaction, current_user.user_id)


@router.delete("/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    transaction = crud.delete_transaction(db, transaction_id, current_user.user_id)
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")


@router.patch("/{transaction_id}", response_model=schema.TransactionRead)
def update_transaction(transaction_id: int, transaction_update: schema.TransactionUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = crud.get_transaction(db, transaction_id, current_user.user_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Transaction not found")
    check_transaction_refs(db, current_user.user_id, transaction_update.transmet_id, transaction_update.category_id, transaction_update.rectrans_id, transaction_update.tag_ids, current_transmet_id=existing.transmet_id)
    return crud.modify_transaction(db, transaction_id, current_user.user_id, transaction_update)
