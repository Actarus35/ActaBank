from main import app, get_db

from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

import schemas.transaction_methods as schema
import crud.transaction_methods as crud


@app.get("/transaction_methods", response_model=list[schema.TransactionMethodRead])
def read_transaction_methods(db: Session = Depends(get_db)):
    return crud.get_transaction_methods(db)


@app.get("/transaction_methods/{transmet_id}", response_model=schema.TransactionMethodRead)
def read_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    trans = crud.get_transaction_method(db, transmet_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@app.post("/transaction_methods", response_model=schema.TransactionMethodRead, status_code=201)
def create_transaction_method(transaction: schema.TransactionMethodCreate, db: Session = Depends(get_db)):
    return crud.create_transaction_method(db, transaction)


@app.delete("/transaction_methods/{transmet_id}", status_code=204)
def delete_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    crud.delete_transaction_method(db, transmet_id)
