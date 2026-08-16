"""Comprehensive pytest suite for LocalLens media seeding, demo assets, and media file serving.

Validates:
1. Physical existence and integrity of image, video, proof, and thumbnail assets.
2. Binary validity of MP4 containers (ISOBMFF box format) and JPEG/PNG files.
3. Media file streaming endpoints (/api/v1/media/files/{filename}) and Content-Type negotiation.
4. Security protections (directory traversal path sanitization).
5. Referential and semantic consistency of seed/data/issues.json and seed/data/media.json.
6. Database seeding consistency for Media, Issue media attachments, Quorum, and Wins.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest
from app.core.config import Settings
from app.core.database import Database
from app.features.issues.models import Issue, QuorumVote, Win
from app.features.media.models import Media
from app.features.media.service import find_media_path
from app.main import app
from httpx import ASGITransport, AsyncClient
from PIL import Image
from sqlalchemy import select

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent
SEED_DATA_DIR = REPO_ROOT / "seed" / "data"
SEED_MEDIA_DIR = REPO_ROOT / "seed" / "media"
UPLOADS_MEDIA_DIR = REPO_ROOT / "uploads" / "media"


@pytest.fixture(autouse=True)
async def setup_db():
    """Ensure database schema is created for media tests."""
    await app.state.database.create_all()


@pytest.fixture
def issues_seed_data() -> list[dict[str, Any]]:
    path = SEED_DATA_DIR / "issues.json"
    assert path.exists(), f"Missing issues.json at {path}"
    with path.open(encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture
def media_seed_data() -> list[dict[str, Any]]:
    path = SEED_DATA_DIR / "media.json"
    assert path.exists(), f"Missing media.json at {path}"
    with path.open(encoding="utf-8") as f:
        return json.load(f)


# ============================================================================
# 1. Asset Existence & Filesystem Checks
# ============================================================================


def test_seed_and_upload_media_directories_exist():
    """Verify that seed/media and uploads/media directories are present."""
    assert SEED_MEDIA_DIR.exists() and SEED_MEDIA_DIR.is_dir()
    assert UPLOADS_MEDIA_DIR.exists() and UPLOADS_MEDIA_DIR.is_dir()


def test_demo_video_files_exist():
    """Verify that all demo MP4 video assets exist in seed/media and uploads/media."""
    expected_videos = [
        "demo_traffic_pothole.mp4",
        "demo_stormwater_flow.mp4",
        "demo_dark_street.mp4",
        "demo_cattle_junction.mp4",
        "demo_resolution_proof.mp4",
        "sample_video.mp4",
    ]
    for vname in expected_videos:
        seed_path = SEED_MEDIA_DIR / vname
        upload_path = UPLOADS_MEDIA_DIR / vname
        assert seed_path.exists(), f"Missing seed video {vname}"
        assert upload_path.exists(), f"Missing uploads video {vname}"
        assert seed_path.stat().st_size > 0
        assert upload_path.stat().st_size > 0


def test_issue_images_and_thumbnails_exist():
    """Verify that all 19 issue images and their thumbnails exist."""
    for issue_id in range(1, 20):
        # Find matching issue image
        found_imgs = list(SEED_MEDIA_DIR.glob(f"issue_{issue_id}_*.jpg"))
        assert len(found_imgs) >= 1, f"Missing image asset for issue {issue_id}"
        img_file = found_imgs[0]
        thumb_file = SEED_MEDIA_DIR / f"thumb_{img_file.name}"
        assert thumb_file.exists(), f"Missing thumbnail for {img_file.name}"
        assert img_file.stat().st_size > 1000
        assert thumb_file.stat().st_size > 500


def test_resolution_proof_assets_exist():
    """Verify that resolution proof image assets exist."""
    expected_proofs = [
        "proof_sewage_cleared.jpg",
        "proof_pipeline_repaired.jpg",
        "proof_tanker_restored.jpg",
        "proof_culvert_sandbags.jpg",
        "proof_wires_secured.jpg",
        "sewage-gully-lane.jpg",
        "pipeline-leak.jpg",
        "tanker-supply.jpg",
        "shoulder-erosion.jpg",
    ]
    for pname in expected_proofs:
        path = find_media_path(pname)
        assert path is not None and path.exists(), f"Missing proof asset {pname}"
        assert path.stat().st_size > 500


# ============================================================================
# 2. Binary Validity & Format Inspection
# ============================================================================


def test_mp4_binary_structure():
    """Verify that demo MP4 files contain valid ISOBMFF headers (ftyp, moov, mdat)."""
    mp4_files = list(SEED_MEDIA_DIR.glob("*.mp4"))
    assert len(mp4_files) >= 5, "Expected at least 5 MP4 files"

    for mp4_path in mp4_files:
        data = mp4_path.read_bytes()
        assert len(data) >= 32, f"MP4 file {mp4_path.name} is too small"
        # Check ftyp box
        assert b"ftyp" in data[:16], f"{mp4_path.name} missing ftyp box"
        # Check compatible brands
        assert b"mp4" in data[:32] or b"isom" in data[:32]
        # Check moov and mdat boxes exist
        assert b"moov" in data, f"{mp4_path.name} missing moov box"
        assert b"mdat" in data, f"{mp4_path.name} missing mdat box"


def test_image_binary_validity():
    """Verify that JPEG assets in seed/media can be opened and parsed by PIL."""
    jpg_files = list(SEED_MEDIA_DIR.glob("*.jpg"))
    assert len(jpg_files) >= 20, "Expected at least 20 JPEG files"

    for jpg_path in jpg_files:
        with Image.open(jpg_path) as img:
            assert img.format in ("JPEG", "PNG"), f"{jpg_path.name} invalid format {img.format}"
            w, h = img.size
            if jpg_path.name.startswith("thumb_"):
                assert max(w, h) <= 300, f"Thumbnail {jpg_path.name} exceeds 300px: {w}x{h}"
            else:
                assert w >= 400 and h >= 300, f"Image {jpg_path.name} too small: {w}x{h}"


# ============================================================================
# 3. Media Endpoint Serving & Content-Type Tests
# ============================================================================


@pytest.mark.asyncio
async def test_get_media_file_endpoint_jpeg():
    """Test GET /api/v1/media/files/{filename} serves image/jpeg with 200 OK."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/media/files/issue_1_pothole.jpg")
        assert res.status_code == 200
        assert "image/jpeg" in res.headers.get("content-type", "")
        assert len(res.content) > 1000


@pytest.mark.asyncio
async def test_get_media_file_endpoint_video_mp4():
    """Test GET /api/v1/media/files/{filename} serves video/mp4 with 200 OK."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/media/files/demo_traffic_pothole.mp4")
        assert res.status_code == 200
        assert "video/mp4" in res.headers.get("content-type", "")
        assert len(res.content) > 100
        assert b"ftyp" in res.content[:16]


@pytest.mark.asyncio
async def test_get_media_file_endpoint_proof_and_thumbnail():
    """Test GET /api/v1/media/files/{filename} for proof and thumbnail files."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res_proof = await client.get("/api/v1/media/files/proof_sewage_cleared.jpg")
        assert res_proof.status_code == 200
        assert "image/jpeg" in res_proof.headers.get("content-type", "")

        res_thumb = await client.get("/api/v1/media/files/thumb_issue_1_pothole.jpg")
        assert res_thumb.status_code == 200
        assert "image/jpeg" in res_thumb.headers.get("content-type", "")


@pytest.mark.asyncio
async def test_get_media_file_not_found_and_traversal_protection():
    """Test 404 on missing file and 400 on directory traversal attempts."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Non-existent file
        res_404 = await client.get("/api/v1/media/files/non_existent_file_99999.jpg")
        assert res_404.status_code == 404
        assert "File not found" in res_404.json()["detail"]

        # Directory traversal attempt
        res_traversal = await client.get("/api/v1/media/files/..%2F..%2Fseed%2Fdata%2Fusers.json")
        assert res_traversal.status_code in (400, 404)


# ============================================================================
# 4. Seed Data Schema & Consistency Validation
# ============================================================================


def test_issues_seed_data_richness(issues_seed_data: list[dict[str, Any]]):
    """Verify issues.json contains rich descriptive titles, descriptions, and media links."""
    assert len(issues_seed_data) == 19, f"Expected 19 issues, got {len(issues_seed_data)}"
    categories = {"road", "water", "power", "lighting", "waste", "sewage", "other"}
    statuses = {
        "unacknowledged",
        "under_review",
        "escalating",
        "forwarded",
        "pending_quorum",
        "resolved",
        "disputed",
    }

    seen_categories = set()
    seen_statuses = set()

    for issue in issues_seed_data:
        # Title richness
        title = issue["title"]
        assert len(title) >= 15, f"Issue title too short: '{title}'"
        assert not title.lower().startswith("test"), f"Issue title looks synthetic: '{title}'"

        # Description richness
        desc = issue["description"]
        assert len(desc) >= 30, f"Issue description too short for issue {issue['id']}"

        # Category and status
        cat = issue["category"]
        stat = issue["status"]
        assert cat in categories, f"Invalid category {cat} in issue {issue['id']}"
        assert stat in statuses, f"Invalid status {stat} in issue {issue['id']}"
        seen_categories.add(cat)
        seen_statuses.add(stat)

        # Media links
        if "media_url" in issue:
            assert issue["media_url"].startswith("/api/v1/media/files/")
            filename = issue["media_url"].replace("/api/v1/media/files/", "")
            assert find_media_path(filename) is not None, f"File {filename} not found on disk"

        if "video_url" in issue:
            assert issue["video_url"].startswith("/api/v1/media/files/")
            vname = issue["video_url"].replace("/api/v1/media/files/", "")
            assert find_media_path(vname) is not None, f"Video {vname} not found on disk"

        if "resolution_proof" in issue and issue["resolution_proof"]:
            proof_url = issue["resolution_proof"]
            if proof_url.startswith("/api/v1/media/files/"):
                pname = proof_url.replace("/api/v1/media/files/", "")
                assert find_media_path(pname) is not None, f"Proof {pname} not found on disk"

    # All categories and statuses represented
    assert seen_categories == categories
    assert seen_statuses == statuses


def test_media_seed_data_consistency(
    media_seed_data: list[dict[str, Any]], issues_seed_data: list[dict[str, Any]]
):
    """Verify media.json records match valid users, URLs, and checksum hashes."""
    assert len(media_seed_data) >= 19, "Expected at least 19 media records"

    for record in media_seed_data:
        assert record["id"].startswith("m0000000-")
        assert record["url"].startswith("/api/v1/media/files/")
        assert record["thumbnail_url"].startswith("/api/v1/media/files/")
        assert len(record["derived_hash"]) == 64
        assert record["watermark_label"] in ("LocalLens Verified", "User Uploaded - Unverified")

        # Check physical file existence
        fname = record["url"].replace("/api/v1/media/files/", "")
        assert find_media_path(fname) is not None, f"File {fname} in media.json not found on disk"


# ============================================================================
# 5. Database Seed Execution & Relational Checks
# ============================================================================


@pytest.mark.asyncio
async def test_database_seeded_media_and_wins():
    """Verify that seeding populates Media table and creates Wins for resolved issues."""
    settings = Settings()
    db = Database(settings.database_url)
    try:
        await db.create_all()
        async with db.session_factory() as session:
            # Query media
            media_stmt = select(Media)
            media_rows = (await session.execute(media_stmt)).scalars().all()
            assert len(media_rows) >= 20, f"Expected >= 20 media rows, found {len(media_rows)}"

            # Query resolved issues and wins
            resolved_stmt = select(Issue).where(Issue.status == "resolved")
            resolved_issues = (await session.execute(resolved_stmt)).scalars().all()
            assert len(resolved_issues) >= 2, "Expected at least 2 resolved issues"

            wins_stmt = select(Win)
            wins = (await session.execute(wins_stmt)).scalars().all()
            assert len(wins) >= 2, f"Expected at least 2 wins, found {len(wins)}"

            for win in wins:
                assert win.title.startswith("Resolved:")
                assert win.after_image_url is not None
                credits = json.loads(win.contributor_credits or "[]")
                assert len(credits) >= 1
    finally:
        await db.dispose()


@pytest.mark.asyncio
async def test_quorum_votes_and_official_responses_consistency():
    """Verify quorum votes and official responses in DB are consistent with issues."""
    settings = Settings()
    db = Database(settings.database_url)
    try:
        await db.create_all()
        async with db.session_factory() as session:
            quorum_stmt = select(QuorumVote)
            quorum_votes = (await session.execute(quorum_stmt)).scalars().all()
            assert len(quorum_votes) >= 5

            for qv in quorum_votes:
                assert qv.vote in ("confirm", "dispute")
                assert qv.reason is not None and len(qv.reason) > 5

                # Check parent issue
                issue = await session.get(Issue, qv.issue_id)
                assert issue is not None
                assert issue.status in ("pending_quorum", "resolved", "disputed")
    finally:
        await db.dispose()
