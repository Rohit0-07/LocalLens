"""add profile identity fields to users

Revision ID: a1b2c3d4e5f6
Revises: fc2945538d6e
Create Date: 2026-08-16 22:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = 'fc2945538d6e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add display_name, username, date_of_birth, and photo_url to users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('display_name', sa.String(length=120), nullable=True))
        batch_op.add_column(sa.Column('username', sa.String(length=40), nullable=True))
        batch_op.add_column(sa.Column('date_of_birth', sa.Date(), nullable=True))
        batch_op.add_column(sa.Column('photo_url', sa.String(length=500), nullable=True))
        batch_op.create_index('ix_users_username', ['username'], unique=True)


def downgrade() -> None:
    """Remove profile identity fields from users."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_index('ix_users_username')
        batch_op.drop_column('photo_url')
        batch_op.drop_column('date_of_birth')
        batch_op.drop_column('username')
        batch_op.drop_column('display_name')