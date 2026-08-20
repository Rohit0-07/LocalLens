"""Tests for the team data sync engine (app.core.data_sync)."""

from __future__ import annotations

from pathlib import Path

import pytest
from app.core.config import Settings
from app.core.data_sync import (
    TRACKED_TABLES,
    apply_sync_file,
    export_database,
    run_startup_sync,
)
from app.core.database import Database
from app.features.auth.models import User
from app.features.issues.models import Issue
from app.features.media.models import Media
from app.features.wards.models import Ward
from sqlalchemy import select


def _settings() -> Settings:
    return Settings(database_url="sqlite+aiosqlite:///:memory:")


async def _seed_source(db: Database, source_media: Path | None = None) -> None:
    """Insert a small representative dataset into ``db``."""
    await db.create_all()
    async with db.session_factory() as session:
        session.add_all(
            [
                Ward(
                    name="Ward 45, Urban Central",
                    slug="ward-45-urban-central",
                    code="W45",
                    center_latitude=19.1136,
                    center_longitude=72.8697,
                ),
                User(
                    id=1,
                    phone="+919999999999",
                    display_name="Sync Test Citizen",
                    role="citizen",
                ),
                Issue(
                    id=100,
                    title="Pothole near the market",
                    description="Growing fast.",
                    category="infrastructure",
                    status="unacknowledged",
                    latitude=19.1136,
                    longitude=72.8697,
                    reporter_id=1,
                ),
            ]
        )
        if source_media is not None:
            session.add(
                Media(
                    id="media-sync-1",
                    user_id="1",
                    url="/api/v1/media/files/photoburst.jpg",
                    thumbnail_url="/api/v1/media/files/thumb_photoburst.jpg",
                    watermark_label="User Uploaded - Unverified",
                    derived_hash="abc",
                    is_verified=False,
                )
            )
        await session.commit()


async def _dump_counts(db: Database) -> dict[str, int]:
    counts: dict[str, int] = {}
    async with db.session_factory() as session:
        for model, name in [
            (Ward, "wards"),
            (User, "users"),
            (Issue, "issues"),
            (Media, "media"),
        ]:
            rows = (await session.execute(select(model))).scalars().all()
            counts[name] = len(rows)
    return counts


@pytest.mark.asyncio
async def test_export_apply_round_trip(tmp_path: Path):
    source = Database(_settings().database_url)
    target = Database(_settings().database_url)
    out_path = tmp_path / "sync.sql"
    bundle = tmp_path / "bundle"
    try:
        await _seed_source(source)

        summary = await export_database(
            source, out_path=out_path, include_media=False, bundle_dir=bundle
        )
        assert summary["tables"]["wards"] == 1
        assert summary["tables"]["users"] == 1
        assert out_path.is_file()

        await target.create_all()
        apply_summary = await apply_sync_file(
            target, file_path=out_path, delete_on_success=False, bundle_dir=bundle
        )
        assert apply_summary["rows_upserted"] >= 3

        assert await _dump_counts(target) == await _dump_counts(source)

        async with target.session_factory() as session:
            issue = (
                await session.execute(select(Issue).where(Issue.id == 100))
            ).scalar_one_or_none()
            assert issue is not None
            assert issue.title == "Pothole near the market"
            assert issue.reporter_id == 1
    finally:
        await source.dispose()
        await target.dispose()


@pytest.mark.asyncio
async def test_apply_is_idempotent(tmp_path: Path):
    source = Database(_settings().database_url)
    target = Database(_settings().database_url)
    out_path = tmp_path / "sync.sql"
    bundle = tmp_path / "bundle"
    try:
        await _seed_source(source)
        await export_database(source, out_path=out_path, include_media=False, bundle_dir=bundle)

        await target.create_all()
        first = await apply_sync_file(target, file_path=out_path, delete_on_success=False, bundle_dir=bundle)
        second = await apply_sync_file(target, file_path=out_path, delete_on_success=False, bundle_dir=bundle)

        assert first["rows_upserted"] == second["rows_upserted"]
        assert await _dump_counts(target) == await _dump_counts(source)
    finally:
        await source.dispose()
        await target.dispose()


@pytest.mark.asyncio
async def test_apply_deletes_snapshot_on_success(tmp_path: Path):
    source = Database(_settings().database_url)
    target = Database(_settings().database_url)
    out_path = tmp_path / "sync.sql"
    bundle = tmp_path / "bundle"
    try:
        await _seed_source(source)
        await export_database(source, out_path=out_path, include_media=False, bundle_dir=bundle)
        assert out_path.is_file()

        await target.create_all()
        await apply_sync_file(target, file_path=out_path, delete_on_success=True, bundle_dir=bundle)

        assert not out_path.exists()
    finally:
        await source.dispose()
        await target.dispose()


@pytest.mark.asyncio
async def test_apply_failure_rolls_back(tmp_path: Path):
    db = Database(_settings().database_url)
    bad_file = tmp_path / "bad.sql"
    bad_file.write_text(
        "INSERT INTO wards (name, slug, code, center_latitude, center_longitude) "
        "VALUES ('Should Roll Back', 'rollback-ward', 'RB', 12.0, 77.0);\n"
        "INSERT INTO does_not_exist (id) VALUES (1);\n",
        encoding="utf-8",
    )
    try:
        await db.create_all()

        with pytest.raises(Exception, match="does_not_exist"):
            await apply_sync_file(
                db,
                file_path=bad_file,
                bundle_dir=tmp_path / "bundle",
                delete_on_success=False,
            )

        async with db.session_factory() as session:
            ward = (
                await session.execute(select(Ward).where(Ward.slug == "rollback-ward"))
            ).scalar_one_or_none()
            assert ward is None
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_media_bundled_and_restored(tmp_path: Path):
    source_dir = tmp_path / "uploads"
    target_dir = tmp_path / "target_uploads"
    source_dir.mkdir(parents=True)
    media_file = source_dir / "photoburst.jpg"
    media_file.write_bytes(b"\xff\xd8fake-image-bytes")

    source = Database(_settings().database_url)
    target = Database(_settings().database_url)
    out_path = tmp_path / "sync.sql"
    bundle = tmp_path / "bundle"
    try:
        await _seed_source(source, source_media=source_dir)
        summary = await export_database(
            source,
            out_path=out_path,
            media_dirs=[source_dir],
            include_media=True,
            bundle_dir=bundle,
        )
        assert summary["media"] == ["photoburst.jpg"]
        assert (bundle / "photoburst.jpg").is_file()

        await target.create_all()
        result = await apply_sync_file(
            target,
            file_path=out_path,
            media_dirs=[target_dir],
            delete_on_success=False,
            bundle_dir=bundle,
        )
        assert result["media"] == ["photoburst.jpg"]
        assert (target_dir / "photoburst.jpg").is_file()
        assert (target_dir / "photoburst.jpg").read_bytes() == b"\xff\xd8fake-image-bytes"
    finally:
        await source.dispose()
        await target.dispose()


@pytest.mark.asyncio
async def test_apply_missing_snapshot_raises(tmp_path: Path):
    db = Database(_settings().database_url)
    try:
        await db.create_all()
        with pytest.raises(FileNotFoundError):
            await apply_sync_file(db, file_path=tmp_path / "nope.sql")
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_run_startup_sync_noop_without_snapshot(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    db = Database(_settings().database_url)
    monkeypatch.setattr("app.core.data_sync.SYNC_FILE", tmp_path / "absent.sql")
    try:
        await db.create_all()
        assert await run_startup_sync(db) is None
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_export_covers_all_tracked_tables(tmp_path: Path):
    source = Database(_settings().database_url)
    try:
        await _seed_source(source)
        for table in ["wards", "users", "issues"]:
            assert table in TRACKED_TABLES
        assert "otp_codes" not in TRACKED_TABLES
    finally:
        await source.dispose()


@pytest.mark.asyncio
async def test_export_is_plain_sql_snapshot(tmp_path: Path):
    source = Database(_settings().database_url)
    out_path = tmp_path / "sync.sql"
    bundle = tmp_path / "bundle"
    try:
        await _seed_source(source)
        await export_database(source, out_path=out_path, include_media=False, bundle_dir=bundle)

        text_content = out_path.read_text(encoding="utf-8")
        assert "INSERT INTO" in text_content
        assert "ON CONFLICT" in text_content
        assert "photoburst" not in text_content  # no media rows were seeded
    finally:
        await source.dispose()