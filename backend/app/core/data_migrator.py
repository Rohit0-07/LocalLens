"""Data migration engine for syncing development and team database state.

This module discovers and applies sequential data migrations from the
``backend/data_migrations/`` directory, recording applied migrations in the
``_data_migrations`` table in the database so team members keep identical data
records across machines without checking the SQLite file into VCS.
"""

from __future__ import annotations

import argparse
import asyncio
import importlib.util
import logging
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, cast

from app.core.config import Settings, get_settings
from app.core.database import Base, Database
from sqlalchemy import DateTime, String, Table, select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession
from sqlalchemy.orm import Mapped, mapped_column

logger = logging.getLogger("locallens.data_migrator")


class DataMigrationRecord(Base):
    """Tracks applied data migrations to avoid re-execution."""

    __tablename__ = "_data_migrations"

    id: Mapped[str] = mapped_column(String(255), primary_key=True)
    applied_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(UTC), nullable=False
    )
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)


MIGRATIONS_DIR = Path(__file__).resolve().parent.parent.parent / "data_migrations"


async def ensure_tracking_table(engine: AsyncEngine) -> None:
    """Ensure the _data_migrations table exists in the target database."""
    async with engine.begin() as conn:
        await conn.run_sync(
            Base.metadata.create_all, tables=[cast(Table, DataMigrationRecord.__table__)]
        )


async def get_applied_migration_ids(session: AsyncSession) -> set[str]:
    """Retrieve all previously applied migration IDs."""
    stmt = select(DataMigrationRecord.id)
    result = await session.execute(stmt)
    return set(result.scalars().all())


def get_available_migrations(migrations_dir: Path | None = None) -> list[tuple[str, Path]]:
    """Scan and return sorted (id, path) pairs of migration scripts."""
    target_dir = migrations_dir or MIGRATIONS_DIR
    if not target_dir.is_dir():
        return []
    files = sorted(
        [p for p in target_dir.glob("*.py") if p.is_file() and not p.name.startswith(("_", "."))],
        key=lambda p: p.name,
    )
    return [(p.stem, p) for p in files]


def load_migration_module(file_path: Path) -> Any:
    """Dynamically import a data migration file as a module."""
    spec = importlib.util.spec_from_file_location(file_path.stem, file_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load migration module from {file_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


async def run_data_migrations(
    database: Database | None = None,
    settings: Settings | None = None,
    migrations_dir: Path | None = None,
) -> list[str]:
    """Execute all pending data migrations sequentially.

    Args:
        database: Database instance to use (or created from settings).
        settings: Application Settings.
        migrations_dir: Optional custom directory to load migrations from.

    Returns:
        List of migration IDs applied during this run.
    """
    settings = settings or get_settings()
    db = database or Database(settings.database_url)

    await ensure_tracking_table(db.engine)
    available = get_available_migrations(migrations_dir)
    applied_now: list[str] = []

    async with db.session_factory() as session:
        applied_ids = await get_applied_migration_ids(session)

    for migration_id, file_path in available:
        if migration_id in applied_ids:
            continue

        logger.info("Applying data migration: %s", migration_id)
        module = load_migration_module(file_path)

        if not hasattr(module, "apply") or not callable(module.apply):
            raise AttributeError(
                f"Data migration {file_path.name} must define an async 'apply(session)' function."
            )

        description = getattr(module, "DESCRIPTION", None)

        async with db.session_factory() as session:
            try:
                await module.apply(session)
                record = DataMigrationRecord(
                    id=migration_id,
                    applied_at=datetime.now(UTC),
                    description=description,
                )
                session.add(record)
                await session.commit()
            except Exception:
                await session.rollback()
                raise

        applied_now.append(migration_id)
        logger.info("Successfully applied data migration: %s", migration_id)

    return applied_now


async def get_migration_status(
    database: Database | None = None,
    settings: Settings | None = None,
    migrations_dir: Path | None = None,
) -> list[dict[str, Any]]:
    """Return status (applied / pending) for all available migrations."""
    settings = settings or get_settings()
    db = database or Database(settings.database_url)

    await ensure_tracking_table(db.engine)
    available = get_available_migrations(migrations_dir)

    async with db.session_factory() as session:
        applied_ids = await get_applied_migration_ids(session)

    status_list = []
    for migration_id, path in available:
        status_list.append(
            {
                "id": migration_id,
                "path": str(path),
                "applied": migration_id in applied_ids,
            }
        )
    return status_list


async def _cli_main(args: argparse.Namespace) -> None:
    settings = Settings(database_url=args.db) if args.db else Settings()
    db = Database(settings.database_url)
    try:
        if args.status:
            statuses = await get_migration_status(db, settings)
            print(f"{'Status':<10} {'Migration ID'}")
            print("-" * 50)
            for s in statuses:
                tag = "[APPLIED]" if s["applied"] else "[PENDING]"
                print(f"{tag:<10} {s['id']}")
            return

        print(f"Running data migrations on {settings.database_url}...")
        applied = await run_data_migrations(db, settings)
        if applied:
            print(f"Applied {len(applied)} data migration(s):")
            for m in applied:
                print(f"  + {m}")
        else:
            print("Database is up to date. No pending data migrations.")
    finally:
        await db.dispose()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        default=True,
        help="Apply pending data migrations (default).",
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show applied vs pending migrations without running them.",
    )
    parser.add_argument("--db", default=None, help="Override database URL.")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    asyncio.run(_cli_main(args))


if __name__ == "__main__":
    main()
