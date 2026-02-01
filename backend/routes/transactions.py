from main import app, get_db

from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

import schemas.transactions as schema
import crud.transactions as crud


@app.get("/transactions", response_model=list[schema.TransactionRead])
def read_transactions(db: Session = Depends(get_db)):
    return crud.get_transactions(db)


@app.get("/transactions/{transaction_id}", response_model=schema.TransactionRead)
def read_transaction(transaction_id: int, db: Session = Depends(get_db)):
    trans = crud.get_transaction(db, transaction_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@app.post("/transactions", response_model=schema.TransactionRead, status_code=201)
def create_transaction(transaction: schema.TransactionCreate, db: Session = Depends(get_db)):
    return crud.create_transaction(db, transaction)


@app.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: int, db: Session = Depends(get_db)):
    crud.delete_transaction(db, transaction_id)
