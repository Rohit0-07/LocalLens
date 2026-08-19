"""create wards table

Revision ID: 0f3a7b9c1d2e
Revises: b2c3d4e5f607
Create Date: 2026-08-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0f3a7b9c1d2e'
down_revision: Union[str, Sequence[str], None] = 'b2c3d4e5f607'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the wards table if it does not already exist.

    The table was previously created only implicitly via
    ``Base.metadata.create_all`` (app startup / seed / tests), so a fresh
    database upgraded purely with alembic had no ``wards`` table and the
    subsequent ``c4d5e6f70819`` migration (ALTER TABLE wards ADD boundary)
    failed. Existing databases that already have the table (created via
    ``create_all``) are left untouched by the inspector guard.
    """
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if 'wards' in inspector.get_table_names():
        return

    op.create_table(
        'wards',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('slug', sa.String(length=255), nullable=False),
        sa.Column('code', sa.String(length=50), nullable=False),
        sa.Column('center_latitude', sa.Float(), nullable=False),
        sa.Column('center_longitude', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_wards_name'), 'wards', ['name'], unique=False)
    op.create_index(op.f('ix_wards_slug'), 'wards', ['slug'], unique=True)
    op.create_index(op.f('ix_wards_code'), 'wards', ['code'], unique=False)


def downgrade() -> None:
    """Drop the wards table if it exists (created by this migration)."""
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if 'wards' not in inspector.get_table_names():
        return

    op.drop_index(op.f('ix_wards_code'), table_name='wards')
    op.drop_index(op.f('ix_wards_slug'), table_name='wards')
    op.drop_index(op.f('ix_wards_name'), table_name='wards')
    op.drop_table('wards')
