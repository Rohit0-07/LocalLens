"""create media table

Revision ID: a2b3c4d5e6f0
Revises: c4d5e6f70819
Create Date: 2026-08-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a2b3c4d5e6f0'
down_revision: Union[str, Sequence[str], None] = 'c4d5e6f70819'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the media table if it does not already exist.

    The table was previously created only implicitly via
    ``Base.metadata.create_all`` (app startup / seed / tests), so a fresh
    database upgraded purely with alembic had no ``media`` table and the
    subsequent ``a7b8c9d0e1f2`` migration (ALTER TABLE media ADD issue_id /
    deleted_at / captured_at) failed. The three columns added by
    ``a7b8c9d0e1f2`` are deliberately not created here so the historical
    migration semantics are preserved. Existing databases that already have
    the table (created via ``create_all``) are left untouched by the
    inspector guard.
    """
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if 'media' in inspector.get_table_names():
        return

    op.create_table(
        'media',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('url', sa.String(), nullable=False),
        sa.Column('thumbnail_url', sa.String(), nullable=False),
        sa.Column('is_verified', sa.Boolean(), nullable=False),
        sa.Column('watermark_label', sa.String(), nullable=False),
        sa.Column('derived_hash', sa.String(), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column('is_fuzzed', sa.Boolean(), nullable=False),
        sa.Column('is_in_app_camera', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    """Drop the media table if it exists (created by this migration)."""
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if 'media' not in inspector.get_table_names():
        return

    op.drop_table('media')