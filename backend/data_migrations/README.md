# LocalLens Data Migrations

This folder contains **versioned data migrations** to synchronize database records (fixtures, sample wards, notices, users, categories, and system data) across development machines without checking `.db` files into Git.

## How It Works

1. **Alembic** manages schema / table structures (`backend/alembic/`).
2. **Data Migrations** (`backend/data_migrations/`) manage table content / rows.
3. When you run the backend server (`make backend` or `uvicorn app.main:app`), pending data migrations execute automatically inside FastAPI's startup lifecycle and record completion in the `_data_migrations` SQLite table.

## Authoring a New Data Migration

1. Create a new file in this directory with a sequential numeric prefix, e.g. `0002_add_mumbai_wards.py`.
2. Follow the standard template:

```python
"""0002_add_mumbai_wards: Add sample wards for western suburbs."""

from __future__ import annotations
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.features.wards.models import Ward

MIGRATION_ID = "0002_add_mumbai_wards"
DESCRIPTION = "Add Bandra and Andheri ward boundaries and metadata."


async def apply(session: AsyncSession) -> None:
    # Check if records already exist to keep migrations idempotent
    existing = (await session.execute(select(Ward.slug).where(Ward.slug == "ward-50-bandra"))).scalar_one_or_none()
    if not existing:
        ward = Ward(
            name="Ward 50, Bandra West",
            slug="ward-50-bandra",
            code="W50",
            center_latitude=19.0596,
            center_longitude=72.8295,
        )
        session.add(ward)
```

3. Commit and push the migration file to Git.
4. When your teammates pull and run `make backend` (or `make sync-db`), the migration will automatically apply to their local database!

## Useful Commands

```sh
# Apply all pending data migrations manually
make sync-db
# or directly with uv
cd backend && uv run python -m app.core.data_migrator --apply

# Check migration status (applied vs pending)
cd backend && uv run python -m app.core.data_migrator --status
```
