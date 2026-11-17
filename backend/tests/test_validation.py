def test_champ_inconnu_refuse(client, alice):
    reponse = client.post("/categories/", json={"category_name": "Courses", "categry_color": "RED"}, headers=alice)
    assert reponse.status_code == 422


def test_nom_trop_long_refuse(client, alice):
    reponse = client.post("/banks/", json={"bank_name": "x" * 31, "bank_color": "RED"}, headers=alice)
    assert reponse.status_code == 422


def test_nom_vide_refuse(client, alice):
    reponse = client.post("/tags/", json={"tag_name": "", "tag_color": "RED"}, headers=alice)
    assert reponse.status_code == 422


def test_montant_trop_grand_refuse(client, alice, univers_alice):
    reponse = client.post("/transactions/", json={
        "transac_name": "Yacht",
        "transac_date": "2026-01-05T00:00:00",
        "transac_amount": "-100000000.00",
        "transmet_id": univers_alice["method"]["transmet_id"],
    }, headers=alice)
    assert reponse.status_code == 422


def test_null_explicite_sur_champ_obligatoire_refuse(client, alice, univers_alice):
    url = f"/transactions/{univers_alice['transaction']['transac_id']}"
    assert client.patch(url, json={"transac_name": None}, headers=alice).status_code == 422
    assert client.patch(url, json={"transmet_id": None}, headers=alice).status_code == 422


def test_null_explicite_sur_champ_facultatif_accepte(client, alice, univers_alice):
    url = f"/transactions/{univers_alice['transaction']['transac_id']}"
    reponse = client.patch(url, json={"category_id": None, "transac_description": None}, headers=alice)
    assert reponse.status_code == 200
    assert reponse.json()["category"] is None
