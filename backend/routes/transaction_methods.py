from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db

from schemas import transaction_methods as schema
from crud import transaction_methods as crud


router = APIRouter(prefix="/transaction_methods", tags=["transaction_methods"])


@router.get("/", response_model=list[schema.TransactionMethodRead])
def read_transaction_methods(db: Session = Depends(get_db)):
    return crud.get_transaction_methods(db)


@router.get("/{transmet_id}", response_model=schema.TransactionMethodRead)
def read_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    trans = crud.get_transaction_method(db, transmet_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@router.post("/", response_model=schema.TransactionMethodRead, status_code=201)
def create_transaction_method(transaction: schema.TransactionMethodCreate, db: Session = Depends(get_db)):
    return crud.create_transaction_method(db, transaction)


@router.delete("/{transmet_id}", status_code=204)
def delete_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    transaction_method = crud.get_transaction_method(db, transmet_id)
    if not transaction_method:
        raise HTTPException(status_code=404, detail="Transaction method not found")
    if transaction_method.transactions:
        raise HTTPException(status_code=409, detail="Cette méthode est utilisée par des transactions et ne peut pas être supprimée")
    crud.delete_transaction_method(db, transmet_id)
    

@router.patch("/{transmet_id}", response_model=schema.TransactionMethodRead)
def update_transaction_method(transmet_id: int, transaction_update: schema.TransactionMethodUpdate, db: Session = Depends(get_db)):
    transaction_method = crud.modify_transaction_method(db, transmet_id, transaction_update)
    if not transaction_method:
        raise HTTPException(status_code=404, detail="Transaction method not found")
    return transaction_method