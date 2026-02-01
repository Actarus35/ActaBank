from database import engine
from models import banks, transactions, labels, transaction_methods, recurring_transactions
from database import Base, SessionLocal

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session

import schemas.transactions as sTrans
import crud.transactions as crudTrans


import schemas.transaction_methods as sTransMet
import crud.transaction_methods as crudTransMet

app = FastAPI()

Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ==============================TRANSACATIONS==============================

@app.get("/transactions", response_model=list[sTrans.TransactionRead])
def read_transactions(db: Session = Depends(get_db)):
    return crudTrans.get_transactions(db)


@app.get("/transactions/{transaction_id}", response_model=sTrans.TransactionRead)
def read_transaction(transaction_id: int, db: Session = Depends(get_db)):
    trans = crudTrans.get_transaction(db, transaction_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@app.post("/transactions", response_model=sTrans.TransactionRead, status_code=201)
def create_transaction(transaction: sTrans.TransactionCreate, db: Session = Depends(get_db)):
    return crudTrans.create_transaction(db, transaction)


@app.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: int, db: Session = Depends(get_db)):
    crudTrans.delete_transaction(db, transaction_id)


# ==============================TRANSACATION_METHODS==============================

@app.get("/transaction_methods", response_model=list[sTransMet.TransactionMethodRead])
def read_transaction_methods(db: Session = Depends(get_db)):
    return crudTrans.get_transaction_methods(db)


@app.get("/transaction_methods/{transmet_id}", response_model=sTransMet.TransactionMethodRead)
def read_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    trans = crudTransMet.get_transaction_method(db, transmet_id)
    if not trans:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return trans


@app.post("/transaction_methods", response_model=sTransMet.TransactionMethodRead, status_code=201)
def create_transaction_method(transaction: sTransMet.TransactionMethodCreate, db: Session = Depends(get_db)):
    return crudTransMet.create_transaction_method(db, transaction)


@app.delete("/transaction_methods/{transmet_id}", status_code=204)
def delete_transaction_method(transmet_id: int, db: Session = Depends(get_db)):
    crudTransMet.delete_transaction_method(db, transmet_id)
