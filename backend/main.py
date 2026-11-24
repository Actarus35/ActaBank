from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from models import transactions, transaction_methods, categories, banks, recurring_transactions, accounts, users, tags

from config import settings
from routes.auth import router as auth_router
from routes.tags import router as tags_router
from routes.stats import router as stats_router
from routes.banks import router as banks_router
from routes.accounts import router as accounts_router
from routes.transfers import router as transfers_router
from routes.categories import router as categories_router
from routes.transactions import router as transactions_router
from routes.transaction_methods import router as methods_router
from routes.recurring_transactions import router as recurring_transactions_router


app = FastAPI(title="ActaBank API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(tags_router)
app.include_router(stats_router)
app.include_router(banks_router)
app.include_router(methods_router)
app.include_router(accounts_router)
app.include_router(transfers_router)
app.include_router(categories_router)
app.include_router(transactions_router)
app.include_router(recurring_transactions_router)