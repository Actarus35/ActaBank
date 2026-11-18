def test_archiver_une_banque_archive_comptes_et_methodes(client, alice, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    reponse = client.patch(f"/banks/{bank_id}", json={"bank_archived": True}, headers=alice)
    assert reponse.json()["bank_archived"] is True
    account = client.get(f"/accounts/{univers_alice['account']['account_id']}", headers=alice).json()
    method = client.get(f"/transaction_methods/{univers_alice['method']['transmet_id']}", headers=alice).json()
    assert account["account_archived"] is True
    assert method["transmet_archived"] is True


def test_desarchiver_une_methode_desarchive_compte_et_banque(client, alice, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    transmet_id = univers_alice["method"]["transmet_id"]
    client.patch(f"/banks/{bank_id}", json={"bank_archived": True}, headers=alice)
    client.patch(f"/transaction_methods/{transmet_id}", json={"transmet_archived": False}, headers=alice)
    assert client.get(f"/banks/{bank_id}", headers=alice).json()["bank_archived"] is False
    account = client.get(f"/accounts/{univers_alice['account']['account_id']}", headers=alice).json()
    assert account["account_archived"] is False


def test_methode_archivee_refuse_les_nouvelles_transactions(client, alice, univers_alice):
    transmet_id = univers_alice["method"]["transmet_id"]
    client.patch(f"/transaction_methods/{transmet_id}", json={"transmet_archived": True}, headers=alice)
    nouvelle = client.post("/transactions/", json={
        "transac_name": "Nouvelle",
        "transac_date": "2026-01-06T00:00:00",
        "transac_amount": "-10.00",
        "transmet_id": transmet_id,
    }, headers=alice)
    assert nouvelle.status_code == 422
    ancienne = client.patch(
        f"/transactions/{univers_alice['transaction']['transac_id']}",
        json={"transac_name": "Renommée", "transmet_id": transmet_id},
        headers=alice,
    )
    assert ancienne.status_code == 200


def test_portefeuille_sans_banque(client, alice, univers_alice):
    bank_id = univers_alice["bank"]["bank_id"]
    sans_banque = client.post("/accounts/", json={"account_name": "Poche", "account_type": "PORTEFEUILLE"}, headers=alice)
    assert sans_banque.status_code == 201
    assert sans_banque.json()["bank"] is None
    avec_banque = client.post("/accounts/", json={"account_name": "Poche", "account_type": "PORTEFEUILLE", "bank_id": bank_id}, headers=alice)
    assert avec_banque.status_code == 422
    courant_sans_banque = client.post("/accounts/", json={"account_name": "Courant", "account_type": "COURANT"}, headers=alice)
    assert courant_sans_banque.status_code == 422
