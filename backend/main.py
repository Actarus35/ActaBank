from fastapi import FastAPI

from models import transactions, transaction_methods, labels, banks, recurring_transactions

from routes.transactions import router as transactions_router
from routes.transaction_methods import router as methods_router
from routes.banks import router as banks_router


app = FastAPI(title="ActaBank API")

app.include_router(transactions_router)
app.include_router(methods_router)
app.include_router(banks_router)
