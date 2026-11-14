"""categories et tags

Revision ID: 540e201f6fe4
Revises: f80f86db27f5
Create Date: 2026-11-14 20:32:22.844812

"""
from typing import Sequence, Union

from alembic import op
from sqlalchemy.dialects import postgresql
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '540e201f6fe4'
down_revision: Union[str, Sequence[str], None] = 'f80f86db27f5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. labels -> categories (renommage : les données sont conservées)
    op.rename_table('labels', 'categories')
    op.alter_column('categories', 'label_id', new_column_name='category_id')
    op.alter_column('categories', 'label_name', new_column_name='category_name')
    op.alter_column('categories', 'label_color', new_column_name='category_color')
    op.execute('ALTER TABLE categories RENAME CONSTRAINT labels_pkey TO categories_pkey')
    op.execute('ALTER TABLE categories RENAME CONSTRAINT labels_user_id_fkey TO categories_user_id_fkey')
    op.execute('ALTER SEQUENCE labels_label_id_seq RENAME TO categories_category_id_seq')

    # 2. transactions.label_id -> category_id
    op.drop_constraint('transactions_label_id_fkey', 'transactions', type_='foreignkey')
    op.alter_column('transactions', 'label_id', new_column_name='category_id')
    op.create_foreign_key(
        'transactions_category_id_fkey', 'transactions', 'categories',
        ['category_id'], ['category_id'], ondelete='SET NULL',
    )

    # 3. recurring_transactions.rectrans_label_id -> rectrans_category_id (+ ON DELETE SET NULL)
    op.drop_constraint('recurring_transactions_rectrans_label_id_fkey', 'recurring_transactions', type_='foreignkey')
    op.alter_column('recurring_transactions', 'rectrans_label_id', new_column_name='rectrans_category_id')
    op.create_foreign_key(
        'recurring_transactions_rectrans_category_id_fkey', 'recurring_transactions', 'categories',
        ['rectrans_category_id'], ['category_id'], ondelete='SET NULL',
    )

    # 4. tags
    color = postgresql.ENUM(name='color', create_type=False)
    op.create_table(
        'tags',
        sa.Column('tag_id', sa.Integer(), nullable=False),
        sa.Column('tag_name', sa.String(), nullable=False),
        sa.Column('tag_color', color, nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.user_id']),
        sa.PrimaryKeyConstraint('tag_id'),
    )
    op.create_table(
        'transaction_tags',
        sa.Column('transac_id', sa.Integer(), nullable=False),
        sa.Column('tag_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['transac_id'], ['transactions.transac_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['tag_id'], ['tags.tag_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('transac_id', 'tag_id'),
    )
    op.create_table(
        'recurring_transaction_tags',
        sa.Column('rectrans_id', sa.Integer(), nullable=False),
        sa.Column('tag_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['rectrans_id'], ['recurring_transactions.rectrans_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['tag_id'], ['tags.tag_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('rectrans_id', 'tag_id'),
    )


def downgrade() -> None:
    op.drop_table('recurring_transaction_tags')
    op.drop_table('transaction_tags')
    op.drop_table('tags')

    op.drop_constraint('recurring_transactions_rectrans_category_id_fkey', 'recurring_transactions', type_='foreignkey')
    op.alter_column('recurring_transactions', 'rectrans_category_id', new_column_name='rectrans_label_id')
    op.drop_constraint('transactions_category_id_fkey', 'transactions', type_='foreignkey')
    op.alter_column('transactions', 'category_id', new_column_name='label_id')

    op.execute('ALTER SEQUENCE categories_category_id_seq RENAME TO labels_label_id_seq')
    op.execute('ALTER TABLE categories RENAME CONSTRAINT categories_user_id_fkey TO labels_user_id_fkey')
    op.execute('ALTER TABLE categories RENAME CONSTRAINT categories_pkey TO labels_pkey')
    op.alter_column('categories', 'category_color', new_column_name='label_color')
    op.alter_column('categories', 'category_name', new_column_name='label_name')
    op.alter_column('categories', 'category_id', new_column_name='label_id')
    op.rename_table('categories', 'labels')

    op.create_foreign_key(
        'transactions_label_id_fkey', 'transactions', 'labels',
        ['label_id'], ['label_id'], ondelete='SET NULL',
    )
    op.create_foreign_key(
        'recurring_transactions_rectrans_label_id_fkey', 'recurring_transactions', 'labels',
        ['rectrans_label_id'], ['label_id'],
    )