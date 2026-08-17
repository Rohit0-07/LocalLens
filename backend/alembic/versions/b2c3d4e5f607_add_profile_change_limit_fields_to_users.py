"""add profile change-limit fields to users

Revision ID: b2c3d4e5f607
Revises: a1b2c3d4e5f6
Create Date: 2026-08-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2c3d4e5f607'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add bio and profile change-limit tracking fields to users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('bio', sa.String(length=200), nullable=True))
        batch_op.add_column(
            sa.Column('display_name_changes_count', sa.Integer(), server_default=sa.text('0'), nullable=False)
        )
        batch_op.add_column(sa.Column('display_name_updated_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('bio_updated_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('photo_updated_at', sa.DateTime(), nullable=True))


def downgrade() -> None:
    """Remove bio and profile change-limit tracking fields from users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('photo_updated_at')
        batch_op.drop_column('bio_updated_at')
        batch_op.drop_column('display_name_updated_at')
        batch_op.drop_column('display_name_changes_count')
        batch_op.drop_column('bio')
