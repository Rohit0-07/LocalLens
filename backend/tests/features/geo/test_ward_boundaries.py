"""Black-box tests for the F-B ward-boundaries endpoint (BE-WB-01..BE-WB-07).

Derived ONLY from the F-B phase-6 contract inlined verbatim to this phase
(docs/3_test_plan.md on disk is the older F-03 reverse-geocode plan and does
not mention this endpoint, so the F-B contract below is the authority):

    GET /api/v1/geo/ward-boundaries
    No auth required; rate-limited (60 req / 60 s); read-only.
    200 -> JSON list of ward boundary items:
        {ward_slug: str, name: str, code: str, boundary: [[lat, lng], ...]}
        boundary is a ring of >= 3 [lat, lng] pairs, lat in [-90, 90],
        lng in [-180, 180].
    A ward whose stored `boundary` is NULL or malformed ('not json', a
    non-numeric point, an out-of-range point, or a ring with < 3 points) must
    still answer 200 with a deterministic derived ring whose centroid is
    within ~0.03 degrees of the ward center (center_latitude/longitude).

    BE-WB-01..BE-WB-07 cover seeded rings, empty table, derived-ring
    fallback, guest vs signed-in parity, read-only behavior, no-PII, and
    burst/rate-limit behavior. The F-08 map-pins tests in test_geo.py remain
    the regression guard for the (untouched) map-pins endpoint and are NOT
    modified here.

NOTE: the ward registry is seeded with raw SQL including the new `boundary`
column on `wards` (the seed defensively adds the column if the schema at test
time does not carry it yet).
"""

import json
import typing
from datetime import UTC, datetime

import httpx
import pytest
from sqlalchemy import text

WARD_BOUNDARIES_URL = "/api/v1/geo/ward-boundaries"


# ---------------------------------------------------------------------------
# Seeding (raw SQL incl. the new `boundary` column on `wards`)
# ---------------------------------------------------------------------------


async def _seed_ward(
    app: typing.Any,
    slug: str = "ward-45-urban-central",
    name: str = "Ward 45, Urban Central",
    code: str = "W-45",
    lat: float = 19.1136,
    lng: float = 72.8697,
    boundary: str | None = None,
) -> None:
    """Insert a ward, optionally carrying a stored `boundary` JSON string.

    Written in raw SQL (house style of test_ward_place_page.py / test_geo.py).
    The F-B `boundary` column is ensured defensively: if the table was
    created without it (pre-F-B schema), the ALTER adds it; if it already
    exists, the ALTER failure is ignored.
    """
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
        try:
            await session.execute(text("ALTER TABLE wards ADD COLUMN boundary TEXT"))
            await session.commit()
        except Exception:
            # Column already present (F-B schema) - not an error.
            await session.rollback()
        await session.execute(
            text("""
            INSERT OR REPLACE INTO wards
                (slug, name, code, center_latitude, center_longitude, boundary, updated_at)
            VALUES (:slug, :name, :code, :lat, :lng, :boundary, :updated_at)
            """),
            {
                "slug": slug,
                "name": name,
                "code": code,
                "lat": lat,
                "lng": lng,
                "boundary": boundary,
                "updated_at": datetime.now(UTC).replace(tzinfo=None),
            },
        )
        await session.commit()


async def _snapshot_wards(app: typing.Any) -> list[tuple]:
    async with app.state.database.session_factory() as session:
        rows = (await session.execute(text("SELECT * FROM wards ORDER BY id"))).all()
        return [tuple(row) for row in rows]


async def _snapshot_tables(app: typing.Any) -> list[tuple]:
    async with app.state.database.session_factory() as session:
        rows = (
            await session.execute(
                text("SELECT name, sql FROM sqlite_master WHERE type = 'table' ORDER BY name")
            )
        ).all()
        return [tuple(row) for row in rows]


# ---------------------------------------------------------------------------
# Reference helpers (computed inside the test, never read from the app)
# ---------------------------------------------------------------------------


def _ring_centroid(boundary: list) -> tuple[float, float]:
    """Mean of the ring vertices - the centroid proxy for small polygons."""
    lats = [point[0] for point in boundary]
    lngs = [point[1] for point in boundary]
    return sum(lats) / len(lats), sum(lngs) / len(lngs)


def _assert_valid_ring(boundary: typing.Any) -> None:
    """Contract: boundary is a ring of >= 3 [lat, lng] pairs in range."""
    assert isinstance(boundary, list) and len(boundary) >= 3, boundary
    for point in boundary:
        assert isinstance(point, list) and len(point) == 2, point
        lat, lng = point
        assert isinstance(lat, (int, float)) and -90.0 <= lat <= 90.0, point
        assert isinstance(lng, (int, float)) and -180.0 <= lng <= 180.0, point


# ---------------------------------------------------------------------------
# BE-WB-01 — seeded wards return their stored polygons
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_01_seeded_wards_return_polygons(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    # Rings deliberately offset from the ward centers (19.1136, 72.8697) and
    # (19.2, 72.95) so a derived-fallback ring (which must sit within ~0.03
    # deg of the center) could never satisfy the centroid assertion below -
    # only the stored ring can.
    ring_a = [[19.03, 72.78], [19.07, 72.78], [19.05, 72.83]]
    ring_b = [[19.28, 72.98], [19.32, 72.98], [19.30, 73.03]]
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        lat=19.1136,
        lng=72.8697,
        boundary=json.dumps(ring_a),
    )
    await _seed_ward(
        app,
        slug="ward-77-north",
        name="Ward 77, North Sector",
        code="W-77",
        lat=19.2,
        lng=72.95,
        boundary=json.dumps(ring_b),
    )

    response = await client.get(WARD_BOUNDARIES_URL)
    assert response.status_code == 200, response.text
    items = response.json()
    assert isinstance(items, list) and len(items) == 2

    by_slug = {item["ward_slug"]: item for item in items}
    assert set(by_slug) == {"ward-45-urban-central", "ward-77-north"}

    expected = {
        "ward-45-urban-central": ("Ward 45, Urban Central", "W-45", ring_a),
        "ward-77-north": ("Ward 77, North Sector", "W-77", ring_b),
    }
    for slug, (name, code, ring) in expected.items():
        item = by_slug[slug]
        # Contract item shape - nothing more, nothing less.
        assert set(item.keys()) == {"ward_slug", "name", "code", "boundary"}
        assert item["name"] == name
        assert item["code"] == code
        _assert_valid_ring(item["boundary"])
        # The stored ring is served: its centroid matches the seed, not the
        # derived fallback (which would sit near the ward center instead).
        c_lat, c_lng = _ring_centroid(item["boundary"])
        e_lat, e_lng = _ring_centroid(ring)
        assert abs(c_lat - e_lat) < 1e-6, (slug, c_lat, e_lat)
        assert abs(c_lng - e_lng) < 1e-6, (slug, c_lng, e_lng)


# ---------------------------------------------------------------------------
# BE-WB-02 — empty wards table answers 200 [] (no crash)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_02_empty_wards_table_returns_empty_list(
    client: httpx.AsyncClient,
) -> None:
    response = await client.get(WARD_BOUNDARIES_URL)
    assert response.status_code == 200, response.text
    assert response.json() == []


# ---------------------------------------------------------------------------
# BE-WB-03 — NULL / malformed boundary falls back to a deterministic
#            derived ring around the ward center
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_03_null_or_malformed_boundary_derived_ring(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    seeds = [
        ("ward-bad-null", "Ward Bad Null", "WBN", 19.05, 72.80, None),
        ("ward-bad-notjson", "Ward Bad NotJson", "WBNJ", 19.11, 72.86, "not json"),
        ("ward-bad-nonnumeric", "Ward Bad NonNumeric", "WBNN", 19.15, 72.90, '[["a"]]'),
        ("ward-bad-oob", "Ward Bad OutOfRange", "WBOB", 19.20, 72.95, "[[91, 0]]"),
        ("ward-bad-twopoint", "Ward Bad TwoPoint", "WBTP", 19.25, 73.00, "[[19, 72]]"),
    ]
    for slug, name, code, lat, lng, boundary in seeds:
        await _seed_ward(
            app, slug=slug, name=name, code=code, lat=lat, lng=lng, boundary=boundary
        )

    res_1 = await client.get(WARD_BOUNDARIES_URL)
    res_2 = await client.get(WARD_BOUNDARIES_URL)
    assert res_1.status_code == 200, res_1.text
    assert res_2.status_code == 200, res_2.text

    items = res_1.json()
    assert isinstance(items, list) and len(items) == len(seeds)
    by_slug = {item["ward_slug"]: item for item in items}

    for slug, name, code, lat, lng, _boundary in seeds:
        item = by_slug[slug]
        assert set(item.keys()) == {"ward_slug", "name", "code", "boundary"}
        assert item["name"] == name
        assert item["code"] == code
        boundary = item["boundary"]
        # Fallback replaces the malformed ring with a valid derived ring.
        _assert_valid_ring(boundary)
        c_lat, c_lng = _ring_centroid(boundary)
        # Derived ring sits within ~0.03 deg of THIS ward's center.
        assert abs(c_lat - lat) <= 0.03, f"{slug}: centroid lat {c_lat} vs {lat}"
        assert abs(c_lng - lng) <= 0.03, f"{slug}: centroid lng {c_lng} vs {lng}"

    # Deterministic across calls: identical ring bytes on repeat requests.
    assert res_1.json() == res_2.json()


# ---------------------------------------------------------------------------
# BE-WB-04 — guest and signed-in callers get identical responses
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_04_guest_vs_signed_in_identical(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        boundary=json.dumps([[19.03, 72.78], [19.07, 72.78], [19.05, 72.83]]),
    )

    res_anon = await client.get(WARD_BOUNDARIES_URL)
    res_bogus = await client.get(
        WARD_BOUNDARIES_URL, headers={"Authorization": "Bearer guest-token-test"}
    )
    res_auth = await client.get(WARD_BOUNDARIES_URL, headers=auth_headers)

    assert res_anon.status_code == 200, res_anon.text
    assert res_bogus.status_code == 200, res_bogus.text
    assert res_auth.status_code == 200, res_auth.text

    # Identical bodies: no identity is required or collected.
    assert res_anon.json() == res_bogus.json() == res_auth.json()


# ---------------------------------------------------------------------------
# BE-WB-05 — endpoint is strictly read-only
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_05_read_only_battery(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        boundary=json.dumps([[19.03, 72.78], [19.07, 72.78], [19.05, 72.83]]),
    )
    # A malformed-boundary ward exercises the fallback path too.
    await _seed_ward(
        app, slug="ward-bad-notjson", name="Ward Bad NotJson", code="WBNJ",
        lat=19.2, lng=72.95, boundary="not json",
    )

    before_wards = await _snapshot_wards(app)
    before_tables = await _snapshot_tables(app)

    for _ in range(15):
        response = await client.get(WARD_BOUNDARIES_URL)
        assert response.status_code == 200, response.text

    # Nothing created, modified, or deleted - including no schema drift.
    assert await _snapshot_wards(app) == before_wards
    assert await _snapshot_tables(app) == before_tables


# ---------------------------------------------------------------------------
# BE-WB-06 — no PII in any response (markers from test_geo.py SEC-01 list)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_06_no_pii_in_any_response(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        boundary=json.dumps([[19.03, 72.78], [19.07, 72.78], [19.05, 72.83]]),
    )
    await _seed_ward(
        app, slug="ward-bad-notjson", name="Ward Bad NotJson", code="WBNJ",
        lat=19.2, lng=72.95, boundary="not json",
    )

    # Same caller matrix and PII markers as test_geo.py SEC-01.
    callers = [
        None,  # anonymous visitor
        {"Authorization": "Bearer guest-token-test"},  # bogus/guest credential
        auth_headers,  # valid signed-in identity
    ]
    pii_markers = [
        "+919876543210",
        "user@example.com",
        "access_token",
        "anonymous_identity",
        "anon_id",
        "reporter_id",
        "phone",
    ]

    for headers in callers:
        response = await client.get(WARD_BOUNDARIES_URL, headers=headers)
        assert response.status_code == 200, response.text
        for marker in pii_markers:
            assert marker not in response.text, f"{marker!r} leaked for {headers}"
        # Every item exposes only ward place information.
        for item in response.json():
            assert set(item.keys()) == {"ward_slug", "name", "code", "boundary"}


# ---------------------------------------------------------------------------
# BE-WB-07 — burst stays green; limiter still applies above 60 req / 60 s
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_wb_07_burst_and_rate_limit(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        boundary=json.dumps([[19.03, 72.78], [19.07, 72.78], [19.05, 72.83]]),
    )

    try:
        # A normal burst stays fully green: every request answers 200.
        statuses: list[int] = []
        for i in range(60):
            response = await client.get(WARD_BOUNDARIES_URL)
            statuses.append(response.status_code)
            assert response.status_code == 200, f"request {i + 1}: {response.text}"

        # Beyond 60 req / 60 s the limiter still applies: 429 is allowed,
        # 5xx is never.
        tail: list[int] = []
        for _ in range(10):
            response = await client.get(WARD_BOUNDARIES_URL)
            assert response.status_code in (200, 429), response.text
            tail.append(response.status_code)
        assert not any(status >= 500 for status in statuses + tail)
        assert 429 in tail, f"rate limiter never engaged: {tail}"
    finally:
        if hasattr(app.state, "geo_rate_limiter"):
            app.state.geo_rate_limiter.reset()
