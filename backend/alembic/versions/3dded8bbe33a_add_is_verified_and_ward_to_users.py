"""add is_verified and ward to users

Revision ID: 3dded8bbe33a
Revises: 3e078a4dc3b1
Create Date: 2026-08-16 13:15:04.885590

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3dded8bbe33a'
down_revision: Union[str, Sequence[str], None] = '3e078a4dc3b1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add is_verified and ward columns to users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_verified', sa.Boolean(), server_default=sa.text('1'), nullable=True))
        batch_op.add_column(sa.Column('ward', sa.String(length=64), server_default='Ward 45, Urban Central', nullable=True))
    op.execute("UPDATE users SET ward = 'Ward 45, Urban Central' WHERE ward IS NULL")


def downgrade() -> None:
    """Remove is_verified and ward columns from users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('ward')
        batch_op.drop_column('is_verified')
