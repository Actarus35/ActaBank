from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from schemas import recurring_transactions as schema
from crud import transaction_methods as methods_crud
from crud import labels as labels_crud
from crud import recurring_transactions as crud
from services.recurring import generate_due_transactions


router = APIRouter(prefix="/recurring_transactions", tags=["recurring_transactions"])


def check_recurring_refs(db, user_id, transmet_id, label_id):
    if transmet_id is not None and not methods_crud.get_transaction_method(db, transmet_id, user_id):
        raise HTTPException(status_code=422, detail="Méthode de paiement introuvable")
    if label_id is not None and not labels_crud.get_label(db, label_id, user_id):
        raise HTTPException(status_code=422, detail="Label introuvable")


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
    check_recurring_refs(db, current_user.user_id, recurring_transaction.rectrans_transmet_id, recurring_transaction.rectrans_label_id)
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
    check_recurring_refs(db, current_user.user_id, recurring_transaction_update.rectrans_transmet_id, recurring_transaction_update.rectrans_label_id)
    recurring_transaction = crud.modify_recurring_transaction(db, rectrans_id, current_user.user_id, recurring_transaction_update)
    if not recurring_transaction:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")
    generate_due_transactions(db, current_user.user_id)
    return recurring_transaction