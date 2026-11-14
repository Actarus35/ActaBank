import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from main import app
from database import Base
from dependencies import get_db
from models import users, banks, accounts, transaction_methods, transactions, categories, recurring_transactions, tags

@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def enable_fk(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        engine.dispose()


@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def _inscrire_et_connecter(client, username, password="MotDePasse1"):
    client.post("/auth/register", json={"user_username": username, "user_password":password})
    response = client.post("/auth/login", data={"username": username, "password": password})
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


@pytest.fixture
def alice(client):
    return _inscrire_et_connecter(client, "alice")


@pytest.fixture
def bob(client):
    return _inscrire_et_connecter(client, "bobby")


@pytest.fixture
def univers_alice(client, alice):
    bank = client.post("/banks/", json={
        "bank_name": "CIC",
        "bank_color": "RED"
    }, headers=alice).json()
    account = client.post("/accounts/", json={
        "account_name": "Courant",
        "account_type": "COMPTE_COURANT",
        "bank_id": bank["bank_id"],
    }, headers=alice).json()
    method = client.post("/transaction_methods/", json={
        "transmet_type": "CARTE",
        "account_id": account["account_id"],
    }, headers=alice).json()
    category = client.post("/categories/", json={
        "category_name": "Courses",
        "category_color": "GREEN"
    }, headers=alice).json()
    tag = client.post("/tags/", json={
        "tag_name": "Roumanie",
        "tag_color": "BLUE"
    }, headers=alice).json()
    transaction = client.post("/transactions/", json={
        "transac_name": "Carrefour",
        "transac_date": "2026-01-05T00:00:00",
        "transac_amount": "42.50",
        "transmet_id": method["transmet_id"],
        "category_id": category["category_id"],
        "tag_ids": [tag["tag_id"]],
    }, headers=alice).json()
    return {
        "bank": bank,
        "account": account,
        "method": method,
        "category": category,
        "tag": tag,
        "transaction": transaction
    }