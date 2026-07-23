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


def test_suppression_label_detague_la_transaction(client, alice, univers_alice):
    label_id = univers_alice["label"]["label_id"]
    transac_id = univers_alice["transaction"]["transac_id"]
    assert client.delete(f"/labels/{label_id}", headers=alice).status_code == 204
    assert client.get(f"/transactions/{transac_id}", headers=alice).json()["label"] is None
