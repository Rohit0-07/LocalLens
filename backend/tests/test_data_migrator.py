"""Tests for the data migration engine (app.core.data_migrator)."""

from __future__ import annotations

import tempfile
from pathlib import Path

import pytest
from app.core.config import Settings
from app.core.data_migrator import (
    DataMigrationRecord,
    ensure_tracking_table,
    get_applied_migration_ids,
    get_migration_status,
    run_data_migrations,
)
from app.core.database import Database
from app.features.auth.models import User
from app.features.wards.models import Ward
from sqlalchemy import select


@pytest.mark.asyncio
async def test_ensure_tracking_table_and_empty_status():
    settings = Settings(database_url="sqlite+aiosqlite:///:memory:")
    db = Database(settings.database_url)
    try:
        await db.create_all()
        await ensure_tracking_table(db.engine)

        async with db.session_factory() as session:
            applied = await get_applied_migration_ids(session)
            assert applied == set()
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_run_custom_data_migrations_idempotent():
    settings = Settings(database_url="sqlite+aiosqlite:///:memory:")
    db = Database(settings.database_url)
    try:
        await db.create_all()

        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)

            # Create test migration 0001
            m1 = tmp_path / "0001_test_add_ward.py"
            m1.write_text(
                """
from app.features.wards.models import Ward

MIGRATION_ID = "0001_test_add_ward"
DESCRIPTION = "Test ward migration"

async def apply(session):
    ward = Ward(
        name="Test Ward Alpha",
        slug="test-ward-alpha",
        code="TWA",
        center_latitude=12.9716,
        center_longitude=77.5946,
    )
    session.add(ward)
""",
                encoding="utf-8",
            )

            # First run applies 0001
            applied = await run_data_migrations(db, settings, migrations_dir=tmp_path)
            assert applied == ["0001_test_add_ward"]

            # Verify ward exists
            async with db.session_factory() as session:
                ward = (
                    await session.execute(select(Ward).where(Ward.slug == "test-ward-alpha"))
                ).scalar_one_or_none()
                assert ward is not None
                assert ward.name == "Test Ward Alpha"

                # Verify tracking record
                record = (
                    await session.execute(
                        select(DataMigrationRecord).where(
                            DataMigrationRecord.id == "0001_test_add_ward"
                        )
                    )
                ).scalar_one_or_none()
                assert record is not None
                assert record.description == "Test ward migration"

            # Second run applies nothing (idempotent)
            applied_again = await run_data_migrations(db, settings, migrations_dir=tmp_path)
            assert applied_again == []

            # Check status helper
            statuses = await get_migration_status(db, settings, migrations_dir=tmp_path)
            assert len(statuses) == 1
            assert statuses[0]["id"] == "0001_test_add_ward"
            assert statuses[0]["applied"] is True

            # Add a second migration
            m2 = tmp_path / "0002_test_add_user.py"
            m2.write_text(
                """
from app.features.auth.models import User

MIGRATION_ID = "0002_test_add_user"
DESCRIPTION = "Test user migration"

async def apply(session):
    user = User(
        id=99999,
        phone="+919999999999",
        display_name="Migration Test User",
        role="citizen",
    )
    session.add(user)
""",
                encoding="utf-8",
            )

            applied_second = await run_data_migrations(db, settings, migrations_dir=tmp_path)
            assert applied_second == ["0002_test_add_user"]

            async with db.session_factory() as session:
                user = (
                    await session.execute(select(User).where(User.id == 99999))
                ).scalar_one_or_none()
                assert user is not None
                assert user.display_name == "Migration Test User"
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_migration_failure_rollback():
    settings = Settings(database_url="sqlite+aiosqlite:///:memory:")
    db = Database(settings.database_url)
    try:
        await db.create_all()

        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)

            m_fail = tmp_path / "0001_fail.py"
            m_fail.write_text(
                """
from app.features.wards.models import Ward

MIGRATION_ID = "0001_fail"
DESCRIPTION = "Should fail and rollback"

async def apply(session):
    ward = Ward(
        name="Rollback Ward",
        slug="rollback-ward",
        code="RW",
        center_latitude=12.0,
        center_longitude=77.0,
    )
    session.add(ward)
    raise RuntimeError("Intentional migration error")
""",
                encoding="utf-8",
            )

            with pytest.raises(RuntimeError, match="Intentional migration error"):
                await run_data_migrations(db, settings, migrations_dir=tmp_path)

            # Verify that ward was not committed and migration was not recorded
            async with db.session_factory() as session:
                ward = (
                    await session.execute(select(Ward).where(Ward.slug == "rollback-ward"))
                ).scalar_one_or_none()
                assert ward is None

                records = (await session.execute(select(DataMigrationRecord))).scalars().all()
                assert len(records) == 0
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_baseline_seed_migration_execution():
    settings = Settings(database_url="sqlite+aiosqlite:///:memory:")
    db = Database(settings.database_url)
    try:
        await db.create_all()

        applied = await run_data_migrations(db, settings)
        assert "0001_initial_seed" in applied

        async with db.session_factory() as session:
            users = (await session.execute(select(User))).scalars().all()
            assert len(users) >= 5

            wards = (await session.execute(select(Ward))).scalars().all()
            assert len(wards) >= 1

        # Re-running does not re-apply
        applied_again = await run_data_migrations(db, settings)
        assert applied_again == []
    finally:
        await db.dispose()
