from fastapi import FastAPI, Depends
from BDD.bdd import SessionLocal

import models.transactions as tr

app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/transactions", response_model=list[tr.TransactionList])
def get_all_transactions(db=Depends(get_db)):
    return db.query(tr.Transaction).all()


@app.post("/transaction/")
def create_transaction(trans: tr.CreateTransaction, db=Depends(get_db)):
    new_trans = tr.Transaction(name=trans.name, amount=trans.amount)
    db.add(new_trans)
    db.commit()
    db.refresh(new_trans)
    return new_trans
