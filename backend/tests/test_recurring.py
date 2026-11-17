from datetime import datetime
from decimal import Decimal

from models.tags import Tag
from enums.colors import Color
from schemas.users import UserCreate
from schemas.banks import BankCreate
from enums.frequency import Frequency
from schemas.accounts import AccountCreate
from enums.account_type import AccountType
from models.transactions import Transaction
from enums.transaction_type import TransactionType
from services.recurring import generate_due_transactions
from crud import users, banks, accounts, transaction_methods
from models.recurring_transactions import RecurringTransaction
from schemas.transaction_methods import TransactionMethodCreate


def _prereqs(db):
    u = users.create_user(db, UserCreate(
        user_username="alice",
        user_password="MotDePasse1"
    ))
    b = banks.create_bank(db, BankCreate(
        bank_name="CIC",
        bank_color=Color.RED),
        u.user_id)
    a = accounts.create_account(db, AccountCreate(
        account_name="Courant",
        account_type=AccountType.COMPTE_COURANT,
        bank_id=b.bank_id),
        u.user_id)
    m = transaction_methods.create_transaction_method(db, TransactionMethodCreate(
        transmet_type=TransactionType.VIREMENT, account_id=a.account_id),
        u.user_id)
    return u, m


def _rule(db, user_id, transmet_id, **kw):
    params = dict(
        rectrans_name="Loyer",
        rectrans_amount=Decimal("-800.00"),
        rectrans_frequency=Frequency.MONTHLY,
        rectrans_start_date=datetime(2026, 1, 1),
        rectrans_transmet_id=transmet_id,
        user_id=user_id
    )
    params.update(kw)
    r = RecurringTransaction(**params)
    db.add(r); db.commit(); db.refresh(r)
    return r


def test_backfill_mensuel(db_session):
    u, m = _prereqs(db_session)
    rule = _rule(db_session, u.user_id, m.transmet_id)
    n = generate_due_transactions(db_session, u.user_id, now=datetime(2026, 3, 15))
    assert n == 3  # 1er janvier, février, mars
    txs = db_session.query(Transaction).filter_by(rectrans_id=rule.rectrans_id).all()
    assert len(txs) == 3
    assert all(t.transac_amount == Decimal("-800.00") for t in txs)
    assert all(t.user_id == u.user_id for t in txs)


def test_idempotent(db_session):
    u, m = _prereqs(db_session)
    _rule(db_session, u.user_id, m.transmet_id)
    generate_due_transactions(db_session, u.user_id, now=datetime(2026, 3, 15))
    assert generate_due_transactions(db_session, u.user_id, now=datetime(2026, 3, 15)) == 0


def test_futur_exclu(db_session):
    u, m = _prereqs(db_session)
    _rule(db_session, u.user_id, m.transmet_id, rectrans_start_date=datetime(2099, 1, 1))
    assert generate_due_transactions(db_session, u.user_id, now=datetime(2026, 3, 15)) == 0


def test_date_de_fin(db_session):
    u, m = _prereqs(db_session)
    _rule(db_session, u.user_id, m.transmet_id, rectrans_end_date=datetime(2026, 2, 15))
    assert generate_due_transactions(db_session, u.user_id, now=datetime(2026, 6, 1)) == 2  # janvier + février


def test_recopie_des_tags(db_session):
    u, m = _prereqs(db_session)
    tag = Tag(tag_name="Logement", user_id=u.user_id)
    db_session.add(tag)
    db_session.commit()
    rule = _rule(db_session, u.user_id, m.transmet_id)
    rule.tags = [tag]
    db_session.commit()

    generate_due_transactions(db_session, u.user_id, now=datetime(2026, 2, 15))

    generees = db_session.query(Transaction).all()
    assert len(generees) == 2
    assert all([t.tag_name for t in tx.tags] == ["Logement"] for tx in generees)


def test_methode_archivee_suspend_la_regle(db_session):
    u, m = _prereqs(db_session)
    _rule(db_session, u.user_id, m.transmet_id)
    m.transmet_archived = True
    db_session.commit()
    assert generate_due_transactions(db_session, u.user_id, now=datetime(2026, 3, 15)) == 0
