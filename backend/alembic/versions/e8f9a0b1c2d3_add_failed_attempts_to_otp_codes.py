"""add failed_attempts to otp_codes

Revision ID: e8f9a0b1c2d3
Revises: b8e2f3a4c5d6
Create Date: 2026-08-23 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e8f9a0b1c2d3'
down_revision: Union[str, Sequence[str], None] = 'b8e2f3a4c5d6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add brute-force attempt counter to otp_codes."""
    with op.batch_alter_table('otp_codes', schema=None) as batch_op:
        batch_op.add_column(
            sa.Column('failed_attempts', sa.Integer(), server_default=sa.text('0'), nullable=False)
        )


def downgrade() -> None:
    """Remove brute-force attempt counter from otp_codes."""
    with op.batch_alter_table('otp_codes', schema=None) as batch_op:
        batch_op.drop_column('failed_attempts')
