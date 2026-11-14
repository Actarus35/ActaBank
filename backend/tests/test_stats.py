from datetime import datetime
from dateutil.relativedelta import relativedelta


def _setup(client, headers, initial="1000.00"):
    b = client.post("/banks/", json={"bank_name": "CIC", "bank_color": "RED"}, headers=headers).json()
    a = client.post("/accounts/", json={"account_name": "C", "account_type": "COMPTE_COURANT", "bank_id": b["bank_id"], "account_initial_balance": initial}, headers=headers).json()
    m = client.post("/transaction_methods/", json={"transmet_type": "CARTE", "account_id": a["account_id"]}, headers=headers).json()
    return m["transmet_id"]


def _tx(client, headers, tid, name, amount, date, category_id=None):
    body = {"transac_name": name, "transac_amount": amount, "transac_date": date.isoformat(), "transmet_id": tid}
    if category_id is not None:
        body["category_id"] = category_id
    return client.post("/transactions/", json=body, headers=headers)


def test_stats_protegees(client):
    for url in ["/stats/summary", "/stats/by-category", "/stats/balance-over-time", "/stats/by-name"]:
        assert client.get(url).status_code == 401


def test_summary_et_periode(client, alice):
    tid = _setup(client, alice)
    now = datetime.now()
    _tx(client, alice, tid, "Salaire", "2000.00", now.replace(day=2))
    _tx(client, alice, tid, "Courses", "-150.00", now.replace(day=3))
    _tx(client, alice, tid, "Vieux", "500.00", now - relativedelta(months=2))
    s = client.get("/stats/summary?period=month", headers=alice).json()
    assert float(s["revenus"]) == 2000
    assert float(s["depenses"]) == -150
    assert float(s["variation"]) == 1850
    assert s["nb_transactions"] == 2
    assert float(s["solde"]) == 3350          # 1000 + 2000 - 150 + 500
    assert client.get("/stats/summary?period=3months", headers=alice).json()["nb_transactions"] == 3


def test_summary_periode_invalide(client, alice):
    assert client.get("/stats/summary?period=foo", headers=alice).status_code == 422


def test_by_category(client, alice):
    tid = _setup(client, alice)
    now = datetime.now()
    courses = client.post("/categories/", json={"category_name": "Courses", "category_color": "GREEN"}, headers=alice).json()
    _tx(client, alice, tid, "A", "-120.00", now.replace(day=5), courses["category_id"])
    _tx(client, alice, tid, "B", "-80.00", now.replace(day=5), courses["category_id"])
    _tx(client, alice, tid, "SansCategorie", "-25.00", now.replace(day=5))
    _tx(client, alice, tid, "Salaire", "2000.00", now.replace(day=5), courses["category_id"])
    data = {d["category_name"]: d for d in client.get("/stats/by-category?period=month", headers=alice).json()}
    assert float(data["Courses"]["total"]) == 200
    assert data["Courses"]["category_color"] == "GREEN"
    assert float(data[None]["total"]) == 25       # bucket non catégorisé
    assert all(float(d["total"]) > 0 for d in data.values())   # revenu exclu


def test_by_category_filtre_par_tag(client, alice):
    tid = _setup(client, alice)
    now = datetime.now()
    courses = client.post("/categories/", json={"category_name": "Courses", "category_color": "GREEN"}, headers=alice).json()
    roumanie = client.post("/tags/", json={"tag_name": "Roumanie", "tag_color": "BLUE"}, headers=alice).json()
    base = {"transac_date": now.replace(day=5).isoformat(), "transmet_id": tid, "category_id": courses["category_id"]}
    client.post("/transactions/", json={**base, "transac_name": "A", "transac_amount": "-30.00", "tag_ids": [roumanie["tag_id"]]}, headers=alice)
    client.post("/transactions/", json={**base, "transac_name": "B", "transac_amount": "-70.00"}, headers=alice)

    tout = client.get("/stats/by-category?period=month", headers=alice).json()
    filtre = client.get(f"/stats/by-category?period=month&tag_id={roumanie['tag_id']}", headers=alice).json()
    assert float(tout[0]["total"]) == 100.0
    assert float(filtre[0]["total"]) == 30.0



def test_by_name_trie(client, alice):
    tid = _setup(client, alice)
    now = datetime.now()
    _tx(client, alice, tid, "Carrefour", "-120.00", now.replace(day=5))
    _tx(client, alice, tid, "Carrefour", "-80.00", now.replace(day=5))
    _tx(client, alice, tid, "Loyer", "-800.00", now.replace(day=5))
    data = client.get("/stats/by-name?period=month", headers=alice).json()
    assert [d["name"] for d in data] == ["Loyer", "Carrefour"]
    assert float(data[0]["total"]) == 800


def test_balance_over_time_coherent(client, alice):
    tid = _setup(client, alice, initial="1000.00")
    now = datetime.now()
    _tx(client, alice, tid, "A", "2000.00", now.replace(day=2))
    _tx(client, alice, tid, "B", "-150.00", now.replace(day=2))   # même jour -> fusionné
    _tx(client, alice, tid, "C", "-50.00", now.replace(day=10))
    d = client.get("/stats/balance-over-time?period=all", headers=alice).json()
    assert len(d["points"]) == 2
    solde = client.get("/stats/summary?period=all", headers=alice).json()["solde"]
    assert float(d["points"][-1]["balance"]) == float(solde)     # cohérence entre endpoints


def test_stats_isolation(client, alice, bob):
    tid = _setup(client, alice)
    _tx(client, alice, tid, "X", "-100.00", datetime.now().replace(day=5))
    s = client.get("/stats/summary?period=all", headers=bob).json()
    assert s["nb_transactions"] == 0 and float(s["solde"]) == 0
    assert client.get("/stats/by-category?period=all", headers=bob).json() == []
