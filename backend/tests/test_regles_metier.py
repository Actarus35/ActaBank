def test_suppression_banque_avec_comptes(client, alice, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    assert client.delete(f"/banks/{bank_id}", headers=alice).status_code == 409


def test_suppression_methode_utilisee(client, alice, univers_alice):
    transmet_id = univers_alice["method"]["transmet_id"]
    assert client.delete(f"/transaction_methods/{transmet_id}", headers=alice).status_code == 409


def test_reference_inexistante(client, alice):
    reponse = client.post("/accounts/", json={
        "account_name": "X", "account_type": "LIVRET_A", "bank_id": 9999,
    }, headers=alice)
    assert reponse.status_code == 422


def test_methode_espece_sans_compte(client, alice):
    reponse = client.post("/transaction_methods/", json={"transmet_type": "ESPECE"}, headers=alice)
    assert reponse.status_code == 201


def test_suppression_categorie_la_retire_de_la_transaction(client, alice, univers_alice):
    category_id = univers_alice["category"]["category_id"]
    transac_id = univers_alice["transaction"]["transac_id"]
    assert client.delete(f"/categories/{category_id}", headers=alice).status_code == 204
    assert client.get(f"/transactions/{transac_id}", headers=alice).json()["category"] is None


def test_suppression_tag_le_retire_de_la_transaction(client, alice, univers_alice):
    tag_id = univers_alice["tag"]["tag_id"]
    transac_id = univers_alice["transaction"]["transac_id"]
    assert client.delete(f"/tags/{tag_id}", headers=alice).status_code == 204
    reponse = client.get(f"/transactions/{transac_id}", headers=alice)
    assert reponse.status_code == 200
    assert reponse.json()["tags"] == []


def test_modification_des_tags(client, alice, univers_alice):
    transac_id = univers_alice["transaction"]["transac_id"]
    url = f"/transactions/{transac_id}"
    sans_toucher = client.patch(url, json={"transac_name": "Leclerc"}, headers=alice).json()
    assert len(sans_toucher["tags"]) == 1
    vide = client.patch(url, json={"tag_ids": []}, headers=alice).json()
    assert vide["tags"] == []


def test_suppression_compte_puis_banque_vides(client, alice):
    bank = client.post("/banks/", json={"bank_name": "CIC", "bank_color": "RED"}, headers=alice).json()
    account = client.post("/accounts/", json={
        "account_name": "Courant", "account_type": "COMPTE_COURANT", "bank_id": bank["bank_id"],
    }, headers=alice).json()
    assert client.delete(f"/accounts/{account['account_id']}", headers=alice).status_code == 204
    assert client.delete(f"/banks/{bank['bank_id']}", headers=alice).status_code == 204
    assert client.get("/accounts/", headers=alice).json() == []
    assert client.get("/banks/", headers=alice).json() == []


def test_suppression_methode_utilisee_par_une_recurrence(client, alice):
    methode = client.post("/transaction_methods/", json={"transmet_type": "VIREMENT"}, headers=alice).json()
    regle = client.post("/recurring_transactions/", json={
        "rectrans_name": "Loyer",
        "rectrans_amount": "-800.00",
        "rectrans_frequency": "MONTHLY",
        "rectrans_start_date": "2099-01-01T00:00:00",
        "rectrans_transmet_id": methode["transmet_id"],
    }, headers=alice)
    assert regle.status_code == 201
    assert client.delete(f"/transaction_methods/{methode['transmet_id']}", headers=alice).status_code == 409


def test_modification_d_une_recurrence(client, alice, univers_alice):
    transmet_id = univers_alice["method"]["transmet_id"]
    regle = client.post("/recurring_transactions/", json={
        "rectrans_name": "Loyer",
        "rectrans_amount": "-800.00",
        "rectrans_frequency": "MONTHLY",
        "rectrans_start_date": "2099-01-01T00:00:00",
        "rectrans_transmet_id": transmet_id,
    }, headers=alice).json()
    url = f"/recurring_transactions/{regle['rectrans_id']}"

    sans_methode = client.patch(url, json={"rectrans_amount": "-850.00"}, headers=alice)
    assert sans_methode.status_code == 200
    assert sans_methode.json()["rectrans_amount"] == "-850.00"

    avec_methode = client.patch(url, json={"rectrans_name": "Loyer T2", "rectrans_transmet_id": transmet_id}, headers=alice)
    assert avec_methode.status_code == 200
    assert avec_methode.json()["rectrans_name"] == "Loyer T2"

    assert client.patch("/recurring_transactions/9999", json={"rectrans_name": "X"}, headers=alice).status_code == 404