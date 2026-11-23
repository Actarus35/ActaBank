from datetime import datetime


def _deux_comptes(client, headers):
    """Un compte courant (1000 €) et un livret (0 €), chacun avec un moyen de paiement."""
    b = client.post("/banks/", json={"bank_name": "CIC", "bank_color": "RED"}, headers=headers).json()
    methodes = []
    for nom, type_, initial in [("Courant", "COURANT", "1000.00"), ("Livret", "EPARGNE", "0.00")]:
        a = client.post("/accounts/", json={
            "account_name": nom, "account_type": type_,
            "bank_id": b["bank_id"], "account_initial_balance": initial,
        }, headers=headers).json()
        m = client.post("/transaction_methods/", json={"transmet_type": "VIREMENT", "account_id": a["account_id"]}, headers=headers).json()
        methodes.append(m["transmet_id"])
    return methodes


def _transfert(client, headers, source, cible, montant="200.00"):
    return client.post("/transfers/", json={
        "from_method_id": source,
        "to_method_id": cible,
        "amount": montant,
        "transfer_date": datetime.now().isoformat(),
    }, headers=headers)


def test_transfert_cree_deux_transactions_liees(client, alice):
    courant, livret = _deux_comptes(client, alice)
    r = _transfert(client, alice, courant, livret)
    assert r.status_code == 201
    sortie, entree = r.json()
    assert float(sortie["transac_amount"]) == -200
    assert float(entree["transac_amount"]) == 200
    assert sortie["transac_transfer_id"] is not None
    assert sortie["transac_transfer_id"] == entree["transac_transfer_id"]


def test_transfert_exclu_des_stats_mais_compte_dans_les_soldes(client, alice):
    courant, livret = _deux_comptes(client, alice)
    _transfert(client, alice, courant, livret)

    s = client.get("/stats/summary?period=all", headers=alice).json()
    assert float(s["revenus"]) == 0
    assert float(s["depenses"]) == 0
    assert s["nb_transactions"] == 0
    assert float(s["solde"]) == 1000          # -200 + 200 : le total ne bouge pas

    assert client.get("/stats/by-category?period=all", headers=alice).json() == []
    assert client.get("/stats/by-name?period=all", headers=alice).json() == []
    assert all(float(m["depenses"]) == 0 for m in client.get("/stats/monthly?months=1", headers=alice).json())

    soldes = {c["account_name"]: float(c["balance"]) for c in client.get("/stats/balances", headers=alice).json()["accounts"]}
    assert soldes == {"Courant": 800, "Livret": 200}


def test_supprimer_une_moitie_supprime_le_transfert(client, alice):
    courant, livret = _deux_comptes(client, alice)
    sortie, entree = _transfert(client, alice, courant, livret).json()
    assert client.delete(f"/transactions/{sortie['transac_id']}", headers=alice).status_code == 204
    assert client.get(f"/transactions/{entree['transac_id']}", headers=alice).status_code == 404


def test_modifier_un_transfert(client, alice):
    courant, livret = _deux_comptes(client, alice)
    sortie, _ = _transfert(client, alice, courant, livret).json()
    url = f"/transactions/{sortie['transac_id']}"
    assert client.patch(url, json={"transac_amount": "-50.00"}, headers=alice).status_code == 409
    assert client.patch(url, json={"transac_name": "Épargne"}, headers=alice).status_code == 200


def test_transfert_validations(client, alice, bob):
    courant, livret = _deux_comptes(client, alice)
    assert _transfert(client, alice, courant, courant).status_code == 422            # même compte
    assert _transfert(client, alice, courant, livret, "0").status_code == 422        # montant nul
    assert _transfert(client, alice, courant, livret, "-10.00").status_code == 422   # montant négatif
    assert _transfert(client, bob, courant, livret).status_code == 422               # moyens d'Alice
    assert _transfert(client, {}, courant, livret).status_code == 401                # non connecté