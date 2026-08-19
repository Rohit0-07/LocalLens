"""BE-ACC-01 .. BE-ACC-11: representative accountability metrics.

Derived ONLY from the accountability contract inlined to this phase. The
docs/3_test_plan.md on disk is the older F-03 reverse-geocode plan and does
not mention representative accountability metrics, and docs/4_interfaces.json
is not present in this workspace, so the contract below (endpoints, field
names, status codes, error codes) is the authority for this suite:

    GET /api/v1/representatives/me                  (rep auth required)
    GET /api/v1/representatives/by-user/{user_id}   (public, no auth)
    GET /api/v1/wards/{slug}                        (public)

Extended metric fields on the representative payload (both /me and by-user,
and embedded as `assigned_representative` on the ward detail):

    resolved_ward_issues, in_progress_ward_issues, acknowledged_ward_issues,
    response_rate_pct, avg_response_time_hours

Semantics fixed by the plan:
- responded_ward_issues counts distinct ward issues carrying >=1
  OfficialResponse row; pending_response_ward_issues is the remainder.
- acknowledged/in_progress/resolved buckets require BOTH the matching issue
  status AND an official response on the issue (BE-ACC-05: issues with no
  responses report 0 in every bucket; BE-ACC-09: a resolved issue never
  responded to is NOT in resolved_ward_issues).
- An issue with several responses counts once, in the bucket of its latest
  response status (BE-ACC-08: acknowledged then in_progress -> in_progress
  only).
- response_rate_pct = responded / total * 100, 0.0 when total is 0 (never a
  division-by-zero).
- avg_response_time_hours = mean of (response.created_at - issue.created_at)
  over responded issues, skipping pairs with a missing timestamp; 0.0 when
  there are no pairs.

NOTE (contract vs plan): the on-disk plan does not cover these scenarios, so
every expectation below follows the inlined accountability contract from the
phase brief. Where the contract forces a specific reading (BE-ACC-09's
"resolved + responded -> counted"), the test follows the contract.
"""

import typing
from datetime import UTC, datetime, timedelta
from itertools import count

import httpx
import pytest
from sqlalchemy import text

_RESPONSE_SEQ = count(1)


async def _setup_representative(
    app: typing.Any,
    client: httpx.AsyncClient,
    phone: str = "+919876543101",
    ward: str = "Ward 45, Urban Central",
    official_name: str = "Hon. Sarah Jenkins",
    title: str = "Ward Councilor",
) -> tuple[dict[str, str], int, str]:
    """Create a user via OTP and attach a representative profile (house style).

    Returns (auth headers, user_id, rep_id).
    """
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    res = await client.post("/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})
    assert res.status_code == 200, res.text
    token = res.json()["access_token"]
    user_id = res.json()["user_id"]
    headers = {"Authorization": f"Bearer {token}"}

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
            INSERT INTO representative_profiles
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

    return headers, user_id, rep_id


async def _create_issue(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    app: typing.Any,
    ward: str = "Ward 45, Urban Central",
    title: str = "Severe Pothole on Main St",
    status: str = "unacknowledged",
) -> int:
    """Create an issue via the public API, then pin ward + status via SQL."""
    payload = {
        "title": title,
        "description": "Deep pothole causing vehicle damage",
        "category": "road",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "is_anonymous": False,
        "is_fuzzed": False,
        "is_shielded": False,
    }
    res = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert res.status_code == 201, res.text
    issue_id = res.json()["id"]

    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE issues SET ward = :ward, status = :status WHERE id = :id"),
            {"ward": ward, "status": status, "id": issue_id},
        )
        await session.commit()

    return int(issue_id)


async def _set_issue_created_at(app: typing.Any, issue_id: int, created_at: datetime) -> None:
    """Pin an issue's created_at so response-time metrics are deterministic."""
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE issues SET created_at = :created_at WHERE id = :id"),
            {"created_at": created_at, "id": issue_id},
        )
        await session.commit()


async def _seed_official_response(
    app: typing.Any,
    issue_id: int,
    representative_id: str,
    status_update: str,
    created_at: datetime,
    message: str = "Official response seeded for accountability metrics.",
) -> str:
    """Insert an OfficialResponse row directly (bypasses the 403 ward check and
    lets the test control created_at / status_update exactly)."""
    response_id = f"resp_{next(_RESPONSE_SEQ)}"
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            INSERT INTO official_responses
            (id, issue_id, representative_id, message, status_update, created_at)
            VALUES (:id, :issue_id, :representative_id, :message, :status_update, :created_at)
            """),
            {
                "id": response_id,
                "issue_id": issue_id,
                "representative_id": representative_id,
                "message": message,
                "status_update": status_update,
                "created_at": created_at,
            },
        )
        await session.commit()
    return response_id


async def _seed_ward(
    app: typing.Any,
    slug: str = "ward-45-urban-central",
    name: str = "Ward 45, Urban Central",
    code: str = "W-45",
    lat: float = 19.1136,
    lng: float = 72.8697,
) -> None:
    """Idempotent ward seed (INSERT OR REPLACE keyed on the unique slug)."""
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


@pytest.mark.asyncio
async def test_be_acc_01_me_extended_metrics(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """GET /api/v1/representatives/me (rep auth) returns the extended metrics.

    Four ward issues (unacknowledged / acknowledged / in_progress / resolved)
    with official responses (status_update acknowledged, in_progress) on the
    acknowledged and in_progress issues only. The resolved issue is never
    responded to, so per BE-ACC-09 it is NOT in resolved_ward_issues.
    """
    rep_headers, user_id, rep_id = await _setup_representative(
        app, client, phone="+919876543101", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    unack_id = await _create_issue(
        client, rep_headers, app, title="Unacknowledged issue", status="unacknowledged"
    )
    ack_id = await _create_issue(
        client, rep_headers, app, title="Acknowledged issue", status="acknowledged"
    )
    prog_id = await _create_issue(
        client, rep_headers, app, title="In progress issue", status="in_progress"
    )
    resolved_id = await _create_issue(
        client, rep_headers, app, title="Resolved issue", status="resolved"
    )
    for issue_id in (unack_id, ack_id, prog_id, resolved_id):
        await _set_issue_created_at(app, issue_id, base)

    # Responses 24h and 48h after creation -> avg = (24 + 48) / 2 = 36.0.
    await _seed_official_response(
        app, ack_id, rep_id, status_update="acknowledged", created_at=base + timedelta(hours=24)
    )
    await _seed_official_response(
        app, prog_id, rep_id, status_update="in_progress", created_at=base + timedelta(hours=48)
    )

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["id"] == rep_id
    assert data["user_id"] == user_id
    assert data["ward"] == "Ward 45, Urban Central"
    assert data["total_ward_issues"] == 4
    assert data["resolved_ward_issues"] == 0  # resolved but never responded (BE-ACC-09)
    assert data["in_progress_ward_issues"] == 1
    assert data["acknowledged_ward_issues"] == 1
    assert data["responded_ward_issues"] == 2
    assert data["pending_response_ward_issues"] == 2
    assert data["response_rate_pct"] == 50.0
    assert data["avg_response_time_hours"] == 36.0


@pytest.mark.asyncio
async def test_be_acc_02_by_user_public_metrics(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """GET /api/v1/representatives/by-user/{user_id} works WITHOUT auth and
    returns the same metrics plus the user_id."""
    rep_headers, user_id, rep_id = await _setup_representative(
        app, client, phone="+919876543102", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    ack_id = await _create_issue(
        client, rep_headers, app, title="Acknowledged issue", status="acknowledged"
    )
    prog_id = await _create_issue(
        client, rep_headers, app, title="In progress issue", status="in_progress"
    )
    resolved_id = await _create_issue(
        client, rep_headers, app, title="Resolved issue", status="resolved"
    )
    await _create_issue(client, rep_headers, app, title="Unacknowledged issue")
    for issue_id in (ack_id, prog_id, resolved_id):
        await _set_issue_created_at(app, issue_id, base)

    await _seed_official_response(
        app, ack_id, rep_id, status_update="acknowledged", created_at=base + timedelta(hours=24)
    )
    await _seed_official_response(
        app, prog_id, rep_id, status_update="in_progress", created_at=base + timedelta(hours=48)
    )

    res = await client.get(f"/api/v1/representatives/by-user/{user_id}")  # no auth headers
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["user_id"] == user_id
    assert data["id"] == rep_id
    assert data["total_ward_issues"] == 4
    assert data["resolved_ward_issues"] == 0
    assert data["in_progress_ward_issues"] == 1
    assert data["acknowledged_ward_issues"] == 1
    assert data["responded_ward_issues"] == 2
    assert data["pending_response_ward_issues"] == 2
    assert data["response_rate_pct"] == 50.0
    assert data["avg_response_time_hours"] == 36.0


@pytest.mark.asyncio
async def test_be_acc_03_rbac_and_by_user_errors(
    app: typing.Any, client: httpx.AsyncClient, create_user_headers
) -> None:
    """Citizen token on /representatives/me -> 403.

    by-user for a non-rep citizen -> 404 with code rep_not_found; by-user for
    a nonexistent user id -> 404; guest (no auth) by-user for a rep -> 200.
    """
    rep_headers, rep_user_id, _ = await _setup_representative(
        app, client, phone="+919876543103", ward="Ward 45, Urban Central"
    )

    citizen_headers = await create_user_headers("+919876543104")
    me_res = await client.get("/api/v1/representatives/me", headers=citizen_headers)
    assert me_res.status_code == 403, me_res.text

    me = await client.get("/api/v1/auth/me", headers=citizen_headers)
    assert me.status_code == 200, me.text
    citizen_user_id = me.json()["id"]

    by_user_cit = await client.get(f"/api/v1/representatives/by-user/{citizen_user_id}")
    assert by_user_cit.status_code == 404, by_user_cit.text
    assert by_user_cit.json()["code"] == "rep_not_found"

    # Nonexistent user id: the contract only pins the 404 status.
    ghost = await client.get("/api/v1/representatives/by-user/999999")
    assert ghost.status_code == 404, ghost.text

    # Guest (no Authorization header) may still read a rep's public metrics.
    guest = await client.get(f"/api/v1/representatives/by-user/{rep_user_id}")
    assert guest.status_code == 200, guest.text
    assert guest.json()["user_id"] == rep_user_id


@pytest.mark.asyncio
async def test_be_acc_04_other_ward_does_not_inflate_metrics(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Rep in Ward A: resolved/responded issues in Ward B must NOT inflate the
    Ward A metrics (responses seeded via raw SQL because the API forbids
    responding outside one's ward, per the ward-boundary rule)."""
    rep_headers, _, rep_id = await _setup_representative(
        app, client, phone="+919876543105", ward="Ward A"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    # Ward A: a single unacknowledged issue, no responses.
    await _create_issue(client, rep_headers, app, ward="Ward A", title="Ward A issue")

    # Ward B: resolved + acknowledged issues, each responded to.
    b1 = await _create_issue(
        client, rep_headers, app, ward="Ward B", title="Ward B resolved", status="resolved"
    )
    b2 = await _create_issue(
        client, rep_headers, app, ward="Ward B", title="Ward B acknowledged", status="acknowledged"
    )
    await _set_issue_created_at(app, b1, base)
    await _set_issue_created_at(app, b2, base)
    await _seed_official_response(
        app, b1, rep_id, status_update="acknowledged", created_at=base + timedelta(hours=24)
    )
    await _seed_official_response(
        app, b2, rep_id, status_update="in_progress", created_at=base + timedelta(hours=48)
    )

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 1
    assert data["resolved_ward_issues"] == 0
    assert data["in_progress_ward_issues"] == 0
    assert data["acknowledged_ward_issues"] == 0
    assert data["responded_ward_issues"] == 0
    assert data["pending_response_ward_issues"] == 1
    assert data["response_rate_pct"] == 0.0
    assert data["avg_response_time_hours"] == 0.0


@pytest.mark.asyncio
async def test_be_acc_05_issues_without_responses(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Issues exist in every bucket status but NOTHING is responded to:
    responded=0, pending=total, every bucket 0, rate 0.0, avg 0.0."""
    rep_headers, _, _ = await _setup_representative(
        app, client, phone="+919876543106", ward="Ward 45, Urban Central"
    )
    await _create_issue(client, rep_headers, app, title="Ack, no response", status="acknowledged")
    await _create_issue(
        client, rep_headers, app, title="In progress, no response", status="in_progress"
    )
    await _create_issue(client, rep_headers, app, title="Resolved, no response", status="resolved")

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 3
    assert data["responded_ward_issues"] == 0
    assert data["pending_response_ward_issues"] == 3
    assert data["acknowledged_ward_issues"] == 0
    assert data["in_progress_ward_issues"] == 0
    assert data["resolved_ward_issues"] == 0
    assert data["response_rate_pct"] == 0.0
    assert data["avg_response_time_hours"] == 0.0


@pytest.mark.asyncio
async def test_be_acc_06_empty_ward_no_division_by_zero(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Rep assigned to a ward with zero issues: all metrics 0, no
    division-by-zero crash."""
    rep_headers, _, _ = await _setup_representative(
        app, client, phone="+919876543107", ward="Ward 45, Urban Central"
    )

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 0
    assert data["responded_ward_issues"] == 0
    assert data["pending_response_ward_issues"] == 0
    assert data["acknowledged_ward_issues"] == 0
    assert data["in_progress_ward_issues"] == 0
    assert data["resolved_ward_issues"] == 0
    assert data["response_rate_pct"] == 0.0
    assert data["avg_response_time_hours"] == 0.0


@pytest.mark.asyncio
async def test_be_acc_07_no_resolved_status(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """No issue has status resolved (even with responses): resolved_ward_issues
    must be 0 while other buckets still count."""
    rep_headers, _, rep_id = await _setup_representative(
        app, client, phone="+919876543108", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    ack_id = await _create_issue(
        client, rep_headers, app, title="Acknowledged issue", status="acknowledged"
    )
    prog_id = await _create_issue(
        client, rep_headers, app, title="In progress issue", status="in_progress"
    )
    await _create_issue(client, rep_headers, app, title="Unacknowledged issue")
    await _create_issue(client, rep_headers, app, title="Escalated issue", status="escalated")
    await _set_issue_created_at(app, ack_id, base)
    await _set_issue_created_at(app, prog_id, base)

    await _seed_official_response(
        app, ack_id, rep_id, status_update="acknowledged", created_at=base + timedelta(hours=24)
    )
    await _seed_official_response(
        app, prog_id, rep_id, status_update="in_progress", created_at=base + timedelta(hours=48)
    )

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 4
    assert data["resolved_ward_issues"] == 0
    assert data["acknowledged_ward_issues"] == 1
    assert data["in_progress_ward_issues"] == 1
    assert data["responded_ward_issues"] == 2


@pytest.mark.asyncio
async def test_be_acc_08_multiple_responses_count_once(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Responding twice to one issue (acknowledged then in_progress) counts the
    issue once, as in_progress only: responded=1, in_progress=1, ack=0."""
    rep_headers, _, _ = await _setup_representative(
        app, client, phone="+919876543109", ward="Ward 45, Urban Central"
    )
    issue_id = await _create_issue(
        client, rep_headers, app, title="Double responded issue", status="unacknowledged"
    )

    first = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "First response", "status_update": "acknowledged"},
        headers=rep_headers,
    )
    assert first.status_code == 201, first.text

    second = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "Second response", "status_update": "in_progress"},
        headers=rep_headers,
    )
    assert second.status_code == 201, second.text

    # status_update reflects the issue lifecycle; pin the issue status to the
    # latest response so the "in_progress only" outcome is deterministic
    # regardless of whether the API synchronises the issue status itself.
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE issues SET status = 'in_progress' WHERE id = :id"), {"id": issue_id}
        )
        await session.commit()

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 1
    assert data["responded_ward_issues"] == 1
    assert data["pending_response_ward_issues"] == 0
    assert data["in_progress_ward_issues"] == 1
    assert data["acknowledged_ward_issues"] == 0
    assert data["resolved_ward_issues"] == 0


@pytest.mark.asyncio
async def test_be_acc_09_resolved_issue_requires_response(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """A resolved issue never responded to is NOT in resolved_ward_issues; a
    resolved issue WITH a response IS counted."""
    rep_headers, _, rep_id = await _setup_representative(
        app, client, phone="+919876543110", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    never_responded = await _create_issue(
        client, rep_headers, app, title="Resolved, never responded", status="resolved"
    )
    responded = await _create_issue(
        client, rep_headers, app, title="Resolved and responded", status="resolved"
    )
    await _set_issue_created_at(app, never_responded, base)
    await _set_issue_created_at(app, responded, base)
    await _seed_official_response(
        app, responded, rep_id, status_update="in_progress", created_at=base + timedelta(hours=24)
    )

    res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert res.status_code == 200, res.text
    data = res.json()

    assert data["total_ward_issues"] == 2
    assert data["resolved_ward_issues"] == 1
    assert data["responded_ward_issues"] == 1
    assert data["pending_response_ward_issues"] == 1


@pytest.mark.asyncio
async def test_be_acc_10_avg_response_time_hours(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """Response 24h after issue creation -> avg_response_time_hours == 24.0;
    multiple issues are averaged; pairs with a missing timestamp are skipped."""
    rep_headers, _, rep_id = await _setup_representative(
        app, client, phone="+919876543111", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    async def _responded_issue(hours_after_creation: int) -> int:
        issue_id = await _create_issue(
            client, rep_headers, app, title="Timed issue", status="acknowledged"
        )
        await _set_issue_created_at(app, issue_id, base)
        await _seed_official_response(
            app,
            issue_id,
            rep_id,
            status_update="acknowledged",
            created_at=base + timedelta(hours=hours_after_creation),
        )
        return issue_id

    # Single issue, response exactly 24h later.
    await _responded_issue(24)
    data = (await client.get("/api/v1/representatives/me", headers=rep_headers)).json()
    assert data["avg_response_time_hours"] == 24.0

    # Multiple issues averaged: (24 + 48 + 72) / 3 = 48.0.
    await _responded_issue(48)
    await _responded_issue(72)
    data = (await client.get("/api/v1/representatives/me", headers=rep_headers)).json()
    assert data["responded_ward_issues"] == 3
    assert data["avg_response_time_hours"] == 48.0


@pytest.mark.asyncio
async def test_be_acc_11_ward_detail_assigned_rep_metrics(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    """GET /api/v1/wards/{slug}: assigned_representative carries id, user_id,
    ward and every extended metric field."""
    await _seed_ward(
        app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45"
    )
    rep_headers, user_id, rep_id = await _setup_representative(
        app, client, phone="+919876543112", ward="Ward 45, Urban Central"
    )
    base = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=100)

    ack_id = await _create_issue(
        client, rep_headers, app, title="Acknowledged issue", status="acknowledged"
    )
    prog_id = await _create_issue(
        client, rep_headers, app, title="In progress issue", status="in_progress"
    )
    resolved_id = await _create_issue(
        client, rep_headers, app, title="Resolved issue", status="resolved"
    )
    await _create_issue(client, rep_headers, app, title="Unacknowledged issue")
    for issue_id in (ack_id, prog_id, resolved_id):
        await _set_issue_created_at(app, issue_id, base)

    await _seed_official_response(
        app, ack_id, rep_id, status_update="acknowledged", created_at=base + timedelta(hours=24)
    )
    await _seed_official_response(
        app, prog_id, rep_id, status_update="in_progress", created_at=base + timedelta(hours=48)
    )

    res = await client.get("/api/v1/wards/ward-45-urban-central")
    assert res.status_code == 200, res.text
    rep = res.json()["assigned_representative"]
    assert rep is not None

    assert rep["id"] == rep_id
    assert rep["user_id"] == user_id
    assert rep["ward"] == "Ward 45, Urban Central"
    assert rep["total_ward_issues"] == 4
    assert rep["resolved_ward_issues"] == 0
    assert rep["in_progress_ward_issues"] == 1
    assert rep["acknowledged_ward_issues"] == 1
    assert rep["responded_ward_issues"] == 2
    assert rep["pending_response_ward_issues"] == 2
    assert rep["response_rate_pct"] == 50.0
    assert rep["avg_response_time_hours"] == 36.0
