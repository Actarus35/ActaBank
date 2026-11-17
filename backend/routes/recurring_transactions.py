from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from crud import tags as tags_crud
from crud import categories as categories_crud
from crud import recurring_transactions as crud
from schemas import recurring_transactions as schema
from crud import transaction_methods as methods_crud
from services.recurring import generate_due_transactions


router = APIRouter(prefix="/recurring_transactions", tags=["recurring_transactions"])


def check_recurring_refs(db, user_id, transmet_id, category_id, tag_ids, current_transmet_id=None):
    if transmet_id is not None:
        method = methods_crud.get_transaction_method(db, transmet_id, user_id)
        if not method:
            raise HTTPException(status_code=422, detail="Méthode de paiement introuvable")
        if method.transmet_archived and transmet_id != current_transmet_id:
            raise HTTPException(status_code=422, detail="Méthode de paiement archivée")
    if category_id is not None and not categories_crud.get_category(db, category_id, user_id):
        raise HTTPException(status_code=422, detail="Categorie introuvable")
    if tag_ids and len(tags_crud.get_tags_by_ids(db, tag_ids, user_id)) != len(set(tag_ids)):
        raise HTTPException(status_code=422, detail="Tag introuvable")


@router.get("/", response_model=list[schema.RecurringTransactionRead])
def read_recurring_transactions(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_recurring_transactions(db, current_user.user_id)


@router.get("/{rectrans_id}", response_model=schema.RecurringTransactionRead)
def read_recurring_transaction(rectrans_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    recurring_transaction = crud.get_recurring_transaction(db, rectrans_id, current_user.user_id)
    if not recurring_transaction:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")
    return recurring_transaction


@router.post("/", response_model=schema.RecurringTransactionRead, status_code=201)
def create_recurring_transaction(recurring_transaction: schema.RecurringTransactionCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    check_recurring_refs(db, current_user.user_id, recurring_transaction.rectrans_transmet_id, recurring_transaction.rectrans_category_id, recurring_transaction.tag_ids)
    created = crud.create_recurring_transaction(db, recurring_transaction, current_user.user_id)
    generate_due_transactions(db, current_user.user_id)
    return created


@router.delete("/{rectrans_id}", status_code=204)
def delete_recurring_transaction(rectrans_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    recurring_transaction = crud.delete_recurring_transaction(db, rectrans_id, current_user.user_id)
    if not recurring_transaction:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")


@router.patch("/{rectrans_id}", response_model=schema.RecurringTransactionRead)
def update_recurring_transaction(rectrans_id: int, recurring_transaction_update: schema.RecurringTransactionUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = crud.get_recurring_transaction(db, rectrans_id, current_user.user_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")
    check_recurring_refs(
        db,
        current_user.user_id,
        recurring_transaction_update.rectrans_transmet_id,
        recurring_transaction_update.rectrans_category_id,
        recurring_transaction_update.tag_ids,
        current_transmet_id=existing.rectrans_transmet_id,
    )
    recurring_transaction = crud.modify_recurring_transaction(db, rectrans_id, current_user.user_id, recurring_transaction_update)
    generate_due_transactions(db, current_user.user_id)
    return recurring_transaction
