"""add issue link, soft delete, captured_at to media

Revision ID: a7b8c9d0e1f2
Revises: fc2945538d6e
Create Date: 2026-08-18 10:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = 'a7b8c9d0e1f2'
down_revision: str | Sequence[str] | None = 'c4d5e6f70819'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add issue_id, deleted_at, and captured_at columns to media."""
    with op.batch_alter_table('media', schema=None) as batch_op:
        batch_op.add_column(sa.Column('issue_id', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column('captured_at', sa.DateTime(timezone=True), nullable=True))
        batch_op.create_index(batch_op.f('ix_media_issue_id'), ['issue_id'], unique=False)


def downgrade() -> None:
    """Remove issue_id, deleted_at, and captured_at columns from media."""
    with op.batch_alter_table('media', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_media_issue_id'))
        batch_op.drop_column('captured_at')
        batch_op.drop_column('deleted_at')
        batch_op.drop_column('issue_id')
