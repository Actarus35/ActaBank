from config import settings

def test_inscription(client):
    reponse = client.post("/auth/register", json={
        "user_username": "alice",
        "user_password": "MotDePasse1"
    })
    assert reponse.status_code == 201
    corps = reponse.json()
    assert corps["user_username"] == "alice"
    assert "user_password_hash" not in corps
    assert "user_password" not in corps


def test_inscription_doublon(client):
    client.post("/auth/register", json={
        "user_username": "alice",
        "user_password": "MotDePasse1"
    })
    reponse = client.post("/auth/register", json={
        "user_username": "alice",
        "user_password": "AutreMdp12"
    })
    assert reponse.status_code == 409


def test_connexion(client):
    client.post("/auth/register", json={
        "user_username": "alice",
        "user_password": "MotDePasse1"
    })
    reponse = client.post("/auth/login", data={
        "username": "alice",
        "password": "MotDePasse1"
    })
    assert reponse.status_code == 200
    assert reponse.json()["token_type"] == "bearer"
    assert reponse.json()["access_token"]


def test_connexion_message_identique(client):
    client.post("/auth/register", json={
        "user_username": "alice",
        "user_password": "MotDePasse1"
    })
    mauvais_mdp = client.post("/auth/login", data={
        "username": "alice",
        "password": "faux"
    })
    inconnu = client.post("/auth/login", data={
        "username": "inconnu",
        "password": "faux"
    })
    assert mauvais_mdp.status_code == 401
    assert inconnu.status_code == 401
    assert mauvais_mdp.json()["detail"] == inconnu.json()["detail"]


def test_me_sans_token(client):
    assert client.get("/auth/me").status_code == 401


def test_me_avec_token(client, alice):
    reponse = client.get("/auth/me", headers=alice)
    assert reponse.status_code == 200
    assert reponse.json()["user_username"] == "alice"


def test_inscription_fermee(client, monkeypatch):
    monkeypatch.setattr(settings, "registration_open", False)
    r = client.post("/auth/register", json={"user_username": "bob", "user_password": "motdepasse123"})
    assert r.status_code == 403