"""add is_hidden flag_count comments_count to issues

Revision ID: 3e078a4dc3b1
Revises: d5e4694e6dba
Create Date: 2026-08-10 18:06:08.761456

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3e078a4dc3b1'
down_revision: Union[str, Sequence[str], None] = 'd5e4694e6dba'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add missing columns to issues, users, and otp_codes tables."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_hidden', sa.Boolean(), nullable=False, server_default=sa.text('0')))
        batch_op.add_column(sa.Column('flag_count', sa.Integer(), nullable=False, server_default=sa.text('0')))
        batch_op.add_column(sa.Column('comments_count', sa.Integer(), nullable=False, server_default=sa.text('0')))

    with op.batch_alter_table('otp_codes', schema=None) as batch_op:
        batch_op.add_column(sa.Column('email', sa.String(length=255), nullable=True))
        batch_op.alter_column('phone',
               existing_type=sa.VARCHAR(length=20),
               nullable=True)
        batch_op.create_index(batch_op.f('ix_otp_codes_email'), ['email'], unique=False)

    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('email', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('is_admin', sa.Boolean(), nullable=False, server_default=sa.text('0')))
        batch_op.add_column(sa.Column('role', sa.String(length=32), nullable=False, server_default=sa.text("'citizen'")))
        batch_op.add_column(sa.Column('is_banned', sa.Boolean(), nullable=False, server_default=sa.text('0')))
        batch_op.alter_column('phone',
               existing_type=sa.VARCHAR(length=20),
               nullable=True)
        batch_op.create_index(batch_op.f('ix_users_email'), ['email'], unique=True)


def downgrade() -> None:
    """Remove added columns."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_users_email'))
        batch_op.alter_column('phone',
               existing_type=sa.VARCHAR(length=20),
               nullable=False)
        batch_op.drop_column('is_banned')
        batch_op.drop_column('role')
        batch_op.drop_column('is_admin')
        batch_op.drop_column('email')

    with op.batch_alter_table('otp_codes', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_otp_codes_email'))
        batch_op.alter_column('phone',
               existing_type=sa.VARCHAR(length=20),
               nullable=False)
        batch_op.drop_column('email')

    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.drop_column('comments_count')
        batch_op.drop_column('flag_count')
        batch_op.drop_column('is_hidden')
