from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db

from schemas import transactions as schema
from crud import transactions as crud


router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("/", response_model=list[schema.TransactionRead])
def read_transactions(db: Session = Depends(get_db)):
    return crud.get_transactions(db)


@router.get("/{transaction_id}", response_model=schema.TransactionRead)
def read_transaction(transaction_id: int, db: Session = Depends(get_db)):
    trans = crud.get_transaction(db, transaction_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@router.post("/", response_model=schema.TransactionRead, status_code=201)
def create_transaction(transaction: schema.TransactionCreate, db: Session = Depends(get_db)):
    return crud.create_transaction(db, transaction)


@router.delete("/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: int, db: Session = Depends(get_db)):
    transaction = crud.delete_transaction(db, transaction_id)
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")


@router.patch("/{transaction_id}", response_model=schema.TransactionRead)
def update_transaction(transaction_id: int, transaction_update: schema.TransactionUpdate, db: Session = Depends(get_db)):
    trans = crud.modify_transaction(db, transaction_id, transaction_update)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans
