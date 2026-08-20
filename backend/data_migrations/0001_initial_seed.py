"""0001_initial_seed: Baseline database content migration.

Populates initial wards, users, representatives, demo issues, comments,
upvotes, notifications, flags, gamification profiles, and official responses.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from seed import seed_database

MIGRATION_ID = "0001_initial_seed"
DESCRIPTION = "Seed baseline users, wards, demo issues, and system fixtures."


async def apply(session: AsyncSession) -> None:
    """Apply baseline seed migration."""
    settings = get_settings()
    await seed_database(session, settings=settings, clear=False)
