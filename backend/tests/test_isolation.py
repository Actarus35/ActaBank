import pytest

RESSOURCES = ["/banks/", "/accounts/", "/categories/", "/recurring_transactions/", "/transaction_methods/", "/transactions/", "/tags/"]


@pytest.mark.parametrize("url", RESSOURCES)
def test_routes_protegees(client, url):
    assert client.get(url).status_code == 401


def test_chaine_complete(client, alice, univers_alice):
    reponse = client.get("/transactions/", headers=alice)
    assert reponse.status_code == 200
    transaction = reponse.json()[0]
    assert transaction["method"]["account"]["bank"]["bank_name"] == "CIC"
    assert transaction["category"]["category_name"] == "Courses"
    assert transaction["tags"][0]["tag_name"] == "Roumanie"


@pytest.mark.parametrize("url", ["/banks/", "/accounts/", "/categories/", "/transactions/", "/tags/"])
def test_bob_ne_voit_rien(client, bob, univers_alice, url):
    assert client.get(url, headers=bob).json() == []


def test_lecture_croisee_404(client, bob, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    transac_id = univers_alice["transaction"]["transac_id"]
    assert client.get(f"/banks/{bank_id}", headers=bob).status_code == 404
    assert client.get(f"/transactions/{transac_id}", headers=bob).status_code == 404


def test_modification_croisee_404(client, bob, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    transac_id = univers_alice["transaction"]["transac_id"]
    assert client.patch(f"/banks/{bank_id}", json={"bank_name": "Piratee"}, headers=bob).status_code == 404
    assert client.delete(f"/transactions/{transac_id}", headers=bob).status_code == 404


def test_reference_croisee_422(client, bob, univers_alice):
    reponse = client.post("/accounts/", json={
        "account_name": "Vol",
        "account_type": "EPARGNE",
        "bank_id": univers_alice["bank"]["bank_id"],
    }, headers=bob)
    assert reponse.status_code == 422


def test_univers_alice_intact(client, alice, bob, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    client.patch(f"/banks/{bank_id}", json={"bank_name": "Piratee"}, headers=bob)
    assert client.get(f"/banks/{bank_id}", headers=alice).json()["bank_name"] == "CIC"

def test_tag_croise_422(client, bob, univers_alice):
    b = client.post("/banks/", json={"bank_name": "BNP", "bank_color": "GREEN"}, headers=bob).json()
    a = client.post("/accounts/", json={"account_name": "C", "account_type": "COURANT", "bank_id": b["bank_id"]}, headers=bob).json()
    m = client.post("/transaction_methods/", json={"transmet_type": "CARTE", "account_id": a["account_id"]}, headers=bob).json()
    reponse = client.post("/transactions/", json={
        "transac_name": "Vol",
        "transac_date": "2026-01-05T00:00:00",
        "transac_amount": "-1.00",
        "transmet_id": m["transmet_id"],
        "tag_ids": [univers_alice["tag"]["tag_id"]],
    }, headers=bob)
    assert reponse.status_code == 422
