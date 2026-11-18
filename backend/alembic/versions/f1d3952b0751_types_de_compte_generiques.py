"""types de compte generiques

Revision ID: f1d3952b0751
Revises: cecd087478fb
Create Date: 2026-11-18 17:45:16.257985

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f1d3952b0751'
down_revision: Union[str, Sequence[str], None] = 'cecd087478fb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

NEW = ("COURANT", "PORTEFEUILLE", "PORTEFEUILLE_EN_LIGNE", "EPARGNE",
       "INVESTISSEMENT", "CRYPTO", "CREDIT", "AUTRE")
OLD = ("LIVRET_A", "COMPTE_COURANT", "LIVRET_JEUNE", "WALLET")


def _swap_type(values, mapping):
    """Remplace l'énumération PostgreSQL `accounttype` en convertissant chaque ligne."""
    sa.Enum(*values, name="accounttype_tmp").create(op.get_bind())
    cases = " ".join(f"WHEN '{old}' THEN '{new}'" for old, new in mapping.items())
    op.execute(
        "ALTER TABLE accounts ALTER COLUMN account_type TYPE accounttype_tmp "
        f"USING (CASE account_type::text {cases} END)::accounttype_tmp"
    )
    op.execute("DROP TYPE accounttype")
    op.execute("ALTER TYPE accounttype_tmp RENAME TO accounttype")


def upgrade() -> None:
    _swap_type(NEW, {
        "COMPTE_COURANT": "COURANT",
        "LIVRET_A": "EPARGNE",
        "LIVRET_JEUNE": "EPARGNE",
        "WALLET": "PORTEFEUILLE",
    })


def downgrade() -> None:
    # Retour en arrière avec perte : les nouveaux types n'existaient pas.
    _swap_type(OLD, {
        "COURANT": "COMPTE_COURANT",
        "PORTEFEUILLE": "WALLET",
        "PORTEFEUILLE_EN_LIGNE": "COMPTE_COURANT",
        "EPARGNE": "LIVRET_A",
        "INVESTISSEMENT": "LIVRET_A",
        "CRYPTO": "LIVRET_A",
        "CREDIT": "COMPTE_COURANT",
        "AUTRE": "COMPTE_COURANT",
    })