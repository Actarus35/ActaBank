from datetime import datetime

from dateutil.relativedelta import relativedelta
from sqlalchemy import func
from sqlalchemy.orm import Session
from collections import OrderedDict

from models.transactions import Transaction
from models.accounts import Account
from models.labels import Label
from enums.stats_period import StatsPeriod


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

    conds = [Transaction.user_id == user_id]
    if start is not None:
        conds.append(Transaction.transac_date >= start)

    revenus = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                .filter(*conds, Transaction.transac_amount > 0).scalar()
    depenses = db.query(func.coalesce(func.sum(Transaction.transac_amount), 0)) \
                 .filter(*conds, Transaction.transac_amount < 0).scalar()
    nb = db.query(func.count(Transaction.transac_id)).filter(*conds).scalar()

    return {
        "solde": solde,
        "revenus": revenus,
        "depenses": depenses,
        "variation": revenus + depenses,
        "nb_transactions": nb,
    }


def get_by_label(db: Session, user_id: int, period: StatsPeriod, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    conds = [Transaction.user_id == user_id, Transaction.transac_amount < 0]  # dépenses
    if start is not None:
        conds.append(Transaction.transac_date >= start)

    rows = (
        db.query(
            Label.label_id,
            Label.label_name,
            Label.label_color,
            func.sum(-Transaction.transac_amount).label("total"),
        )
        .select_from(Transaction)
        .outerjoin(Label, Transaction.label_id == Label.label_id)
        .filter(*conds)
        .group_by(Label.label_id, Label.label_name, Label.label_color)
        .all()
    )
    return [
        {"label_id": r.label_id, "label_name": r.label_name, "label_color": r.label_color, "total": r.total}
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

    return {"opening": opening, "points": points}


def get_by_beneficiary(db: Session, user_id: int, period: StatsPeriod, now: datetime | None = None):
    now = now or datetime.now()
    start = period_start(period, now)

    conds = [Transaction.user_id == user_id, Transaction.transac_amount < 0]
    if start is not None:
        conds.append(Transaction.transac_date >= start)

    rows = (
        db.query(
            Transaction.transac_name.label("beneficiary"),
            func.sum(-Transaction.transac_amount).label("total"),
        )
        .filter(*conds)
        .group_by(Transaction.transac_name)
        .order_by(func.sum(-Transaction.transac_amount).desc())
        .all()
    )
    return [{"beneficiary": r.beneficiary, "total": r.total} for r in rows]
