from enums.account_type import AccountFamily, AccountType


def test_seul_le_portefeuille_se_passe_de_banque():
    assert [t for t in AccountType if not t.requires_bank] == [AccountType.PORTEFEUILLE]


def test_chaque_type_a_une_famille():
    for t in AccountType:
        assert isinstance(t.family, AccountFamily)


def test_ancien_type_refuse(client, alice):
    r = client.post("/accounts/", json={"account_name": "X", "account_type": "LIVRET_A"}, headers=alice)
    assert r.status_code == 422