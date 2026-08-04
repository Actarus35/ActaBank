from datetime import datetime

from dateutil.relativedelta import relativedelta
from sqlalchemy.orm import Session

from models.recurring_transactions import RecurringTransaction
from models.transactions import Transaction


STEP = {
    "DAILY": relativedelta(days=1),
    "WEEKLY": relativedelta(weeks=1),
    "MONTHLY": relativedelta(months=1),
    "YEARLY": relativedelta(years=1)
}


def _next(date: datetime, frequency) -> datetime:
    return date + STEP[frequency.value]


def generate_due_transactions(db: Session, user_id: int, now: datetime | None = None) -> int:
    if now is None:
        now = datetime.now()

    rules = db.query(RecurringTransaction).filter(RecurringTransaction.user_id == user_id).all()
    created = 0

    for rule in rules:
        if rule.rectrans_last_generated is None:
            occurrence = rule.rectrans_start_date
        else:
            occurrence = _next(rule.rectrans_last_generated, rule.rectrans_frequency)

        while occurrence <= now and (rule.rectrans_end_date is None or occurrence <= rule.rectrans_end_date):
            db.add(Transaction(
                transac_name=rule.rectrans_name,
                transac_date=occurrence,
                transac_amount=rule.rectrans_amount,
                transmet_id=rule.rectrans_transmet_id,
                label_id=rule.rectrans_label_id,
                rectrans_id=rule.rectrans_id,
                user_id=rule.user_id,    
            ))
            rule.rectrans_last_generated = occurrence
            occurrence = _next(occurrence, rule.rectrans_frequency)
            created += 1

    db.commit()
    return created