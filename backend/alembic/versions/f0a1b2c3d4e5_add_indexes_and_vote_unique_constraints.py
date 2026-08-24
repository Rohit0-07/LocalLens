"""add geo/index coverage and unique vote constraints

Revision ID: f0a1b2c3d4e5
Revises: e8f9a0b1c2d3
Create Date: 2026-08-23 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f0a1b2c3d4e5'
down_revision: Union[str, Sequence[str], None] = 'e8f9a0b1c2d3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

#: Tables that exist in deployed databases but are created outside this
#: migration chain (no prior revision creates them); guard their indexes.
_GUARDED_TABLES = ('notifications', 'flags', 'comments')


def _table_exists(table: str) -> bool:
    return sa.inspect(op.get_bind()).has_table(table)


def upgrade() -> None:
    """Add composite indexes and unique vote constraints."""
    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.create_index(
            'ix_issues_latitude_longitude', ['latitude', 'longitude'], unique=False
        )

    with op.batch_alter_table('upvotes', schema=None) as batch_op:
        batch_op.create_unique_constraint('uq_upvotes_issue_user', ['issue_id', 'user_id'])

    with op.batch_alter_table('quorum_votes', schema=None) as batch_op:
        batch_op.create_unique_constraint('uq_quorum_votes_issue_user', ['issue_id', 'user_id'])

    if _table_exists('notifications'):
        with op.batch_alter_table('notifications', schema=None) as batch_op:
            batch_op.create_index(
                'ix_notifications_user_id_is_read', ['user_id', 'is_read'], unique=False
            )

    if _table_exists('flags'):
        with op.batch_alter_table('flags', schema=None) as batch_op:
            batch_op.create_index('ix_flags_category', ['category'], unique=False)

    if _table_exists('comments'):
        with op.batch_alter_table('comments', schema=None) as batch_op:
            batch_op.create_index(
                'ix_comments_author_id_created_at', ['author_id', 'created_at'], unique=False
            )

    with op.batch_alter_table('upvote_rate_limits', schema=None) as batch_op:
        batch_op.create_index(
            'ix_upvote_rate_limits_user_id_created_at', ['user_id', 'created_at'], unique=False
        )


def downgrade() -> None:
    """Remove composite indexes and unique vote constraints."""
    with op.batch_alter_table('upvote_rate_limits', schema=None) as batch_op:
        batch_op.drop_index('ix_upvote_rate_limits_user_id_created_at')

    if _table_exists('comments'):
        with op.batch_alter_table('comments', schema=None) as batch_op:
            batch_op.drop_index('ix_comments_author_id_created_at')

    if _table_exists('flags'):
        with op.batch_alter_table('flags', schema=None) as batch_op:
            batch_op.drop_index('ix_flags_category')

    if _table_exists('notifications'):
        with op.batch_alter_table('notifications', schema=None) as batch_op:
            batch_op.drop_index('ix_notifications_user_id_is_read')

    with op.batch_alter_table('quorum_votes', schema=None) as batch_op:
        batch_op.drop_constraint('uq_quorum_votes_issue_user', type_='unique')

    with op.batch_alter_table('upvotes', schema=None) as batch_op:
        batch_op.drop_constraint('uq_upvotes_issue_user', type_='unique')

    with op.batch_alter_table('issues', schema=None) as batch_op:
        batch_op.drop_index('ix_issues_latitude_longitude')
