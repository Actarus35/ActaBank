import pytest

RESSOURCES = ["/banks/", "/accounts/", "/labels/", "/recurring_transactions/", "/transaction_methods/", "/transactions/"]


@pytest.mark.parametrize("url", RESSOURCES)
def test_routes_protegees(client, url):
    assert client.get(url).status_code == 401


def test_chaine_complete(client, alice, univers_alice):
    reponse = client.get("/transactions/", headers=alice)
    assert reponse.status_code == 200
    transaction = reponse.json()[0]
    assert transaction["method"]["account"]["bank"]["bank_name"] == "CIC"
    assert transaction["label"]["label_name"] == "Courses"


@pytest.mark.parametrize("url", ["/banks/", "/accounts/", "/labels/", "/transactions/"])
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
        "account_type": "LIVRET_A",
        "bank_id": univers_alice["bank"]["bank_id"],
    }, headers=bob)
    assert reponse.status_code == 422


def test_univers_alice_intact(client, alice, bob, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    client.patch(f"/banks/{bank_id}", json={"bank_name": "Piratee"}, headers=bob)
    assert client.get(f"/banks/{bank_id}", headers=alice).json()["bank_name"] == "CIC"
