"""add media columns to issues

Revision ID: fc2945538d6e
Revises: 3dded8bbe33a
Create Date: 2026-08-16 13:19:18.194970

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fc2945538d6e'
down_revision: Union[str, Sequence[str], None] = '3dded8bbe33a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add media columns to issues."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.add_column(sa.Column('media_url', sa.String(length=500), nullable=True))
        batch_op.add_column(sa.Column('video_url', sa.String(length=500), nullable=True))
        batch_op.add_column(sa.Column('media_urls', sa.Text(), nullable=True))


def downgrade() -> None:
    """Remove media columns from issues."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.drop_column('media_urls')
        batch_op.drop_column('video_url')
        batch_op.drop_column('media_url')
