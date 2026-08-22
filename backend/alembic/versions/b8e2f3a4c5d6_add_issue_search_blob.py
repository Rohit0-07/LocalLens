"""add issues.search_blob for index-backed search

Revision ID: b8e2f3a4c5d6
Revises: a7b8c9d0e1f2
Create Date: 2026-08-23 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b8e2f3a4c5d6'
down_revision: Union[str, Sequence[str], None] = 'a7b8c9d0e1f2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add the denormalized search blob and backfill existing rows."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.add_column(sa.Column('search_blob', sa.Text(), nullable=True))
        batch_op.create_index(
            'ix_issues_search_blob', ['search_blob'], unique=False
        )
    op.execute(
        "UPDATE issues SET search_blob = LOWER("
        "COALESCE(title, '') || ' ' || COALESCE(description, '') || ' ' || "
        "COALESCE(category, '') || ' ' || COALESCE(ward, ''))"
    )


def downgrade() -> None:
    """Drop the search blob column and its index."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.drop_index('ix_issues_search_blob')
        batch_op.drop_column('search_blob')
