from datetime import datetime

from sqlalchemy.orm import Session

from models.recurring_transactions import RecurringTransaction
from models.transaction_methods import TransactionMethod
from models.transactions import Transaction


def generate_due_transactions(db: Session, user_id: int, now: datetime | None = None) -> int:
    if now is None:
        now = datetime.now()

    rules = (
        db.query(RecurringTransaction)
        .join(TransactionMethod, RecurringTransaction.rectrans_transmet_id == TransactionMethod.transmet_id)
        .filter(RecurringTransaction.user_id == user_id, TransactionMethod.transmet_archived.is_(False))
        .all()
    )
    created = 0

    for rule in rules:
        occurrence = rule.rectrans_next_date
        while occurrence is not None and occurrence <= now:
            db.add(Transaction(
                transac_name=rule.rectrans_name,
                transac_date=occurrence,
                transac_amount=rule.rectrans_amount,
                transmet_id=rule.rectrans_transmet_id,
                category_id=rule.rectrans_category_id,
                rectrans_id=rule.rectrans_id,
                tags=list(rule.tags),
                user_id=rule.user_id,
            ))
            rule.rectrans_last_generated = occurrence
            occurrence = rule.rectrans_next_date
            created += 1

    db.commit()
    return created