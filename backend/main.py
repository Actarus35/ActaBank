from fastapi import FastAPI

from models import transactions, transaction_methods, labels, banks, recurring_transactions, accounts, users

from routes.auth import router as auth_router
from routes.banks import router as banks_router
from routes.labels import router as labels_router
from routes.accounts import router as accounts_router
from routes.transactions import router as transactions_router
from routes.transaction_methods import router as methods_router
from routes.recurring_transactions import router as recurring_transactions_router


app = FastAPI(title="ActaBank API")

app.include_router(auth_router)
app.include_router(banks_router)
app.include_router(labels_router)
app.include_router(methods_router)
app.include_router(accounts_router)
app.include_router(transactions_router)
app.include_router(recurring_transactions_router)