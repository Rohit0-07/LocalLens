"""add ward boundary column

Revision ID: c4d5e6f70819
Revises: b2c3d4e5f607
Create Date: 2026-08-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4d5e6f70819'
down_revision: Union[str, Sequence[str], None] = 'b2c3d4e5f607'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add the nullable boundary ring column to wards."""
    with op.batch_alter_table('wards', schema=None) as batch_op:
        batch_op.add_column(sa.Column('boundary', sa.Text(), nullable=True))


def downgrade() -> None:
    """Drop the boundary ring column from wards."""
    with op.batch_alter_table('wards', schema=None) as batch_op:
        batch_op.drop_column('boundary')
