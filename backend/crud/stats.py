from datetime import datetime
from decimal import Decimal

from dateutil.relativedelta import relativedelta
from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload
from collections import OrderedDict

from models.accounts import Account
from models.categories import Category
from models.tags import transaction_tags
from enums.stats_period import StatsPeriod
from models.transactions import Transaction
from models.transaction_methods import TransactionMethod

NOT_TRANSFER = Transaction.transac_transfer_id.is_(None)

def period_start(period: StatsPeriod, now: datetime) -> datetime | None:
    if period == StatsPeriod.MONTH:
        return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if period == StatsPeriod.THREE_MONTHS:
        return now - relativedelta(months=3)
    if period == StatsPeriod.SIX_MONTHS:
        return now - relativedelta(months=6)
    return None


def get_summary(db: Session, user_id: int, period: StatsPeriod, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    initial = db.query(func.coalesce(func.sum(Account.account_initial_balance), 0)) \
                .filter(Account.user_id == user_id).scalar()
    total_tx = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                 .filter(Transaction.user_id == user_id).scalar()
    solde = initial + total_tx

    conds = [Transaction.user_id == user_id, NOT_TRANSFER]
    if start is not None:
        conds.append(Transaction.transac_date >= start)

    revenus = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                .filter(*conds, Transaction.transac_amount > 0).scalar()
    depenses = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                 .filter(*conds, Transaction.transac_amount < 0).scalar()
    nb = db.query(func.count(Transaction.transac_id)).filter(*conds).scalar()
    nb_revenus = db.query(func.count(Transaction.transac_id)) \
                   .filter(*conds, Transaction.transac_amount > 0).scalar()
    nb_depenses = db.query(func.count(Transaction.transac_id)) \
                    .filter(*conds, Transaction.transac_amount < 0).scalar()

    return {
        "solde": solde,
        "revenus": revenus,
        "depenses": depenses,
        "variation": revenus + depenses,
        "nb_transactions": nb,
        "nb_revenus": nb_revenus,
        "nb_depenses": nb_depenses,
    }


def get_by_category(db: Session, user_id: int, period: StatsPeriod, tag_id: int | None = None, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    conds = [Transaction.user_id == user_id, Transaction.transac_amount < 0, NOT_TRANSFER]
    if start is not None:
        conds.append(Transaction.transac_date >= start)
    if tag_id is not None:
        conds.append(Transaction.tags.any(transaction_tags.c.tag_id == tag_id))

    rows = (
        db.query(
            Category.category_id,
            Category.category_name,
            Category.category_color,
            func.sum(-Transaction.transac_amount).label("total"),
        )
        .select_from(Transaction)
        .outerjoin(Category, Transaction.category_id == Category.category_id)
        .filter(*conds)
        .group_by(Category.category_id, Category.category_name, Category.category_color)
        .order_by(func.sum(-Transaction.transac_amount).desc())
        .all()
    )
    return [
        {"category_id": r.category_id, "category_name": r.category_name, "category_color": r.category_color, "total": r.total}
        for r in rows
    ]


def get_balance_over_time(db: Session, user_id: int, period: StatsPeriod, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    initial = db.query(func.coalesce(func.sum(Account.account_initial_balance), 0)) \
                .filter(Account.user_id == user_id).scalar()
    before = 0
    if start is not None:
        before = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                   .filter(Transaction.user_id == user_id, Transaction.transac_date < start).scalar()
    opening = initial + before

    conds = [Transaction.user_id == user_id]
    if start is not None:
        conds.append(Transaction.transac_date >= start)
    txs = db.query(Transaction.transac_date, Transaction.transac_amount) \
            .filter(*conds).order_by(Transaction.transac_date).all()

    daily = OrderedDict()
    for tdate, amount in txs:
        day = tdate.date()
        daily[day] = daily.get(day, 0) + amount

    points = []
    running = opening
    for day, net in daily.items():
        running += net
        points.append({"date": day, "balance": running})

    return {"opening": opening, "start": start, "points": points}


def get_by_name(db: Session, user_id: int, period: StatsPeriod, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    conds = [Transaction.user_id == user_id, Transaction.transac_amount < 0, NOT_TRANSFER]
    if start is not None:
        conds.append(Transaction.transac_date >= start)

    rows = (
        db.query(
            Transaction.transac_name.label("name"),
            func.sum(-Transaction.transac_amount).label("total"),
        )
        .filter(*conds)
        .group_by(Transaction.transac_name)
        .order_by(func.sum(-Transaction.transac_amount).desc())
        .all()
    )
    return [{"name": r.name, "total": r.total} for r in rows]

def get_monthly(db: Session, user_id: int, months: int, now: datetime | None = None):
    now = now or datetime.now()
    first = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0) - relativedelta(months=months - 1)

    buckets = {}
    for i in range(months):
        start = first + relativedelta(months=i)
        buckets[(start.year, start.month)] = {
            "month": start.date(),
            "revenus": Decimal("0"),
            "depenses": Decimal("0"),
        }

    rows = db.query(Transaction.transac_date, Transaction.transac_amount) \
             .filter(Transaction.user_id == user_id, Transaction.transac_date >= first, NOT_TRANSFER).all()
    for tdate, amount in rows:
        bucket = buckets.get((tdate.year, tdate.month))
        if bucket is None:
            continue
        if amount > 0:
            bucket["revenus"] += amount
        elif amount < 0:
            bucket["depenses"] += -amount

    return list(buckets.values())


def get_balances(db: Session, user_id: int):
    sums = dict(
        db.query(TransactionMethod.account_id, func.sum(Transaction.transac_amount))
        .join(Transaction, Transaction.transmet_id == TransactionMethod.transmet_id)
        .filter(Transaction.user_id == user_id)
        .group_by(TransactionMethod.account_id)
        .all()
    )
    accounts = (
        db.query(Account)
        .filter(Account.user_id == user_id)
        .options(selectinload(Account.bank))
        .order_by(Account.account_name)
        .all()
    )
    return {
        "accounts": [
            {
                "account_id": a.account_id,
                "account_name": a.account_name,
                "account_type": a.account_type,
                "account_archived": a.account_archived,
                "bank_id": a.bank_id,
                "bank_name": a.bank.bank_name if a.bank else None,
                "bank_color": a.bank.bank_color if a.bank else None,
                "balance": a.account_initial_balance + sums.get(a.account_id, 0),
            }
            for a in accounts
        ],
        "unassigned": sums.get(None, Decimal("0")),
    }