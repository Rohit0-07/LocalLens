"""Black-box tests for the Ward details v2 feature (BE-WARD-V2-01..06).

Derived ONLY from the v2 ward-details contract inlined to this phase
(docs/3_test_plan.md on disk is the older F-03 reverse-geocode plan and
does not mention the ward-details v2 representative-performance fields, so
the v2 contract below is the authority):

    GET /api/v1/wards/{slug}   (same endpoint as v1)

    `assigned_representative` (null when the ward has no representative)
    now carries the representative performance snapshot:
        id, user_id, official_name, title, verified_at,
        total_ward_issues, escalated_ward_issues,
        responded_ward_issues, pending_response_ward_issues,
        response_rate_pct
    - responded_ward_issues counts ward issues that carry an
      OfficialResponse row; pending_response_ward_issues is the remainder.
    - response_rate_pct = responded / total * 100, and must be 0.0 (never a
      division-by-zero error) when the ward has zero issues.
    - v1 behavior is preserved: ?issues_limit= still caps recent_issues; a
      zero-issue ward reports total_issues 0, resolution_rate_pct 0.0,
      recent_issues [], top_categories [].

NOTE: the ward seed is idempotent (INSERT OR REPLACE keyed on the unique
slug), so seeding the same ward twice never duplicates rows.
"""

import typing
from datetime import UTC, datetime

import httpx
import pytest
from sqlalchemy import text


async def _seed_ward(
    app: typing.Any,
    slug: str = "ward-45-urban-central",
    name: str = "Ward 45, Urban Central",
    code: str = "W-45",
    lat: float = 19.1136,
    lng: float = 72.8697,
) -> None:
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            CREATE TABLE IF NOT EXISTS wards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                slug TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                code TEXT NOT NULL,
                center_latitude REAL NOT NULL,
                center_longitude REAL NOT NULL,
                created_at DATETIME,
                updated_at DATETIME
            )
            """)
        )
        await session.execute(
            text("""
            INSERT OR REPLACE INTO wards (slug, name, code, center_latitude, center_longitude, updated_at)
            VALUES (:slug, :name, :code, :lat, :lng, :updated_at)
            """),
            {
                "slug": slug,
                "name": name,
                "code": code,
                "lat": lat,
                "lng": lng,
                "updated_at": datetime.now(UTC).replace(tzinfo=None),
            },
        )
        await session.commit()


async def _seed_representative(
    app: typing.Any,
    user_id: int = 42,
    ward: str = "Ward 45, Urban Central",
    official_name: str = "Hon. Sarah Jenkins",
    title: str = "Ward Representative",
) -> str:
    rep_id = f"repr_{user_id}"
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            CREATE TABLE IF NOT EXISTS representative_profiles (
                id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                official_name TEXT NOT NULL,
                title TEXT NOT NULL,
                ward TEXT NOT NULL,
                verified_at DATETIME NOT NULL
            )
            """)
        )
        await session.execute(
            text("""
            INSERT OR REPLACE INTO representative_profiles
            (id, user_id, official_name, title, ward, verified_at)
            VALUES (:id, :user_id, :official_name, :title, :ward, :verified_at)
            """),
            {
                "id": rep_id,
                "user_id": user_id,
                "official_name": official_name,
                "title": title,
                "ward": ward,
                "verified_at": datetime.now(UTC).replace(tzinfo=None),
            },
        )
        await session.commit()
    return rep_id


async def _seed_issue(
    client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    app: typing.Any,
    ward: str = "Ward 45, Urban Central",
    title: str = "Pothole issue",
    category: str = "road",
    status: str = "open",
    is_anonymous: bool = False,
    is_fuzzed: bool = False,
    is_shielded: bool = False,
    latitude: float = 19.1136,
    longitude: float = 72.8697,
) -> int:
    payload = {
        "title": title,
        "description": "Civic issue description in ward",
        "category": category,
        "latitude": latitude,
        "longitude": longitude,
        "is_anonymous": is_anonymous,
        "is_fuzzed": is_fuzzed,
        "is_shielded": is_shielded,
    }
    res = await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    assert res.status_code == 201, res.text
    issue_id = res.json()["id"]

    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            UPDATE issues
            SET ward = :ward, status = :status, is_shielded = :is_shielded, is_anonymous = :is_anonymous
            WHERE id = :id
            """),
            {
                "ward": ward,
                "status": status,
                "is_shielded": is_shielded,
                "is_anonymous": is_anonymous,
                "id": issue_id,
            },
        )
        await session.commit()

    return int(issue_id)


async def _seed_official_response(
    app: typing.Any,
    issue_id: int,
    representative_id: str,
) -> str:
    """Mark an issue as responded-to by inserting an OfficialResponse row."""
    response_id = f"resp_{issue_id}"
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            CREATE TABLE IF NOT EXISTS official_responses (
                id TEXT PRIMARY KEY,
                issue_id INTEGER NOT NULL,
                representative_id TEXT NOT NULL,
                message TEXT NOT NULL,
                estimated_resolution_days INTEGER NULL,
                status_update TEXT NULL,
                created_at DATETIME NOT NULL
            )
            """)
        )
        await session.execute(
            text("""
            INSERT OR REPLACE INTO official_responses
            (id, issue_id, representative_id, message, status_update, created_at)
            VALUES (:id, :issue_id, :representative_id, :message, :status_update, :created_at)
            """),
            {
                "id": response_id,
                "issue_id": issue_id,
                "representative_id": representative_id,
                "message": "Public Works team has been dispatched.",
                "status_update": "acknowledged",
                "created_at": datetime.now(UTC).replace(tzinfo=None),
            },
        )
        await session.commit()
    return response_id


@pytest.mark.asyncio
async def test_be_ward_v2_01_rep_performance_fields(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Ward with rep + open/escalated/resolved issues + OfficialResponses.

    The embedded representative snapshot reports total/escalated/responded/
    pending-response counts, the response-rate percentage, and the rep's
    id + user_id.
    """
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    rep_id = await _seed_representative(
        app, user_id=42, ward="Ward 45, Urban Central", official_name="Hon. Sarah Jenkins"
    )

    # 15 ward issues: 8 open, 3 escalated, 4 resolved.
    categories = ["road", "water", "lighting"]
    open_ids: list[int] = []
    for i in range(8):
        open_ids.append(
            await _seed_issue(
                client,
                auth_headers,
                app,
                ward="Ward 45, Urban Central",
                category=categories[i % 3],
                status="open",
            )
        )
    escalated_ids = [
        await _seed_issue(
            client, auth_headers, app, ward="Ward 45, Urban Central", category="water",
            status="escalated",
        )
        for _ in range(3)
    ]
    resolved_ids = [
        await _seed_issue(
            client, auth_headers, app, ward="Ward 45, Urban Central", category="lighting",
            status="resolved",
        )
        for _ in range(4)
    ]

    # Official responses on 2 open + 1 escalated + 3 resolved = 6 of 15.
    for issue_id in open_ids[:2] + escalated_ids[:1] + resolved_ids[:3]:
        await _seed_official_response(app, issue_id=issue_id, representative_id=rep_id)

    response = await client.get("/api/v1/wards/ward-45-urban-central")
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["total_issues"] == 15
    rep = data["assigned_representative"]
    assert rep is not None
    assert rep["id"] == rep_id
    assert rep["user_id"] == 42
    assert rep["official_name"] == "Hon. Sarah Jenkins"
    assert rep["total_ward_issues"] == 15
    assert rep["escalated_ward_issues"] == 3
    assert rep["responded_ward_issues"] == 6
    assert rep["pending_response_ward_issues"] == 9
    assert rep["response_rate_pct"] == 40.0


@pytest.mark.asyncio
async def test_be_ward_v2_02_no_rep_edge(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Ward without a representative: assigned_representative is None."""
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")

    response = await client.get("/api/v1/wards/ward-45-urban-central")
    assert response.status_code == 200, response.text
    assert response.json()["assigned_representative"] is None


@pytest.mark.asyncio
async def test_be_ward_v2_03_empty_ward_edge(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Empty ward: zero issues, zero rate, empty lists, no representative."""
    await _seed_ward(app, slug="empty-ward-v2", name="Empty Ward V2")

    response = await client.get("/api/v1/wards/empty-ward-v2")
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["total_issues"] == 0
    assert data["resolution_rate_pct"] == 0.0
    assert data["recent_issues"] == []
    assert data["top_categories"] == []
    assert data["assigned_representative"] is None


@pytest.mark.asyncio
async def test_be_ward_v2_04_rep_zero_division(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Rep assigned to a ward with zero issues: no division-by-zero crash.

    response_rate_pct must be 0.0 and every performance count must be 0.
    """
    await _seed_ward(app, slug="ward-rep-zero", name="Ward Rep Zero")
    await _seed_representative(app, user_id=42, ward="Ward Rep Zero")

    response = await client.get("/api/v1/wards/ward-rep-zero")
    assert response.status_code == 200, response.text
    rep = response.json()["assigned_representative"]
    assert rep is not None
    assert rep["total_ward_issues"] == 0
    assert rep["escalated_ward_issues"] == 0
    assert rep["responded_ward_issues"] == 0
    assert rep["pending_response_ward_issues"] == 0
    assert rep["response_rate_pct"] == 0.0


@pytest.mark.asyncio
async def test_be_ward_v2_05_seed_idempotent_and_coordinates(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Seeding the same two wards twice yields exactly 2 rows (no dupes).

    Coordinates are stable: ward-45-urban-central @ 19.1136/72.8697 and
    ward-12-metro-corridor @ 19.0760/72.8777, both via the detail endpoint.
    """
    for _ in range(2):
        await _seed_ward(
            app, slug="ward-45-urban-central", name="Ward 45, Urban Central",
            code="W-45", lat=19.1136, lng=72.8697,
        )
        await _seed_ward(
            app, slug="ward-12-metro-corridor", name="Ward 12, Metro Corridor",
            code="W-12", lat=19.0760, lng=72.8777,
        )

    async with app.state.database.session_factory() as session:
        rows = (
            await session.execute(
                text("SELECT slug, center_latitude, center_longitude FROM wards ORDER BY slug")
            )
        ).all()
    assert len(rows) == 2

    by_slug = {slug: (lat, lng) for slug, lat, lng in rows}
    assert set(by_slug) == {"ward-45-urban-central", "ward-12-metro-corridor"}
    assert by_slug["ward-45-urban-central"] == (19.1136, 72.8697)
    assert by_slug["ward-12-metro-corridor"] == (19.0760, 72.8777)

    res_45 = await client.get("/api/v1/wards/ward-45-urban-central")
    assert res_45.status_code == 200, res_45.text
    assert res_45.json()["center_latitude"] == 19.1136
    assert res_45.json()["center_longitude"] == 72.8697

    res_12 = await client.get("/api/v1/wards/ward-12-metro-corridor")
    assert res_12.status_code == 200, res_12.text
    assert res_12.json()["center_latitude"] == 19.0760
    assert res_12.json()["center_longitude"] == 72.8777


@pytest.mark.asyncio
async def test_be_ward_v2_06_issues_limit_still_respected(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """v2 keeps the v1 ?issues_limit= contract on recent_issues (<= 3)."""
    await _seed_ward(app, slug="ward-limit-v2", name="Ward Limit V2")
    for i in range(5):
        await _seed_issue(
            client,
            auth_headers,
            app,
            ward="Ward Limit V2",
            title=f"Issue {i + 1}",
            status="open",
        )

    response = await client.get("/api/v1/wards/ward-limit-v2?issues_limit=3")
    assert response.status_code == 200, response.text
    recent = response.json()["recent_issues"]
    assert len(recent) <= 3
    assert len(recent) == 3
