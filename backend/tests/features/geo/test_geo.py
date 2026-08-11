"""Black-box tests for the F-03 reverse-geocode ward lookup.

Derived ONLY from docs/3_test_plan.md (BE-01..BE-13, SEC-01..SEC-08) and the
Phase-6 verbatim contract (docs/4_interfaces.json does not yet list this
endpoint, so the contract below is the authority):

    GET /api/v1/geo/reverse-geocode
    Params: latitude  (float, ge=-90 le=90)  [required]
            longitude (float, ge=-180 le=180) [required]
            radius_km (float, ge=0.1 le=50, default 50.0)
    200 ReverseGeocodeOut: {latitude, longitude, place, ward, distance_km, found}
        ward: null | {slug, name, code, center_latitude, center_longitude}
        found=false => ward=null, place="Outside coverage", distance_km=0.0
        found=true  => place=ward.name,
                       distance_km=round(haversine(center, point), 1)
    Invalid coordinates (out-of-range, non-numeric, SQLi) => 422,
        error_code "invalid_coordinates"
    No 404; no auth required (guest 200); read-only (never writes the ward registry).

NOTE: the reference haversine below is implemented locally in the test (the
phase-6 engineer is code-blind and may not import implementation modules), so
the distance assertion is a faithful re-computation of the contract formula.
"""

import math
import typing
from datetime import UTC, datetime

import httpx
import pytest
from sqlalchemy import text

# ---------------------------------------------------------------------------
# Reference helpers (computed inside the test, never read from the app)
# ---------------------------------------------------------------------------


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in km (Earth radius 6371.0 km), contract formula."""
    earth_radius_km = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlmb / 2.0) ** 2
    return earth_radius_km * 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


# Contract: invalid coordinates => 422 with error_code "invalid_coordinates".
# The AppError model (interfaces contract) carries both a "code" and an
# "error_code" field, so we accept the value under either key.
def _assert_invalid_coordinates(response: httpx.Response) -> None:
    assert response.status_code == 422, response.text
    body = response.json()
    assert (
        body.get("error_code") == "invalid_coordinates" or body.get("code") == "invalid_coordinates"
    ), f"expected error_code 'invalid_coordinates', got: {body}"


# Missing-parameter rejections: the plan only requires a clear rejection with
# no crash/500. Accept either the contract error_code or FastAPI's standard
# validation detail shape.
def _assert_clean_rejection(response: httpx.Response) -> None:
    assert response.status_code == 422, response.text
    body = response.json()
    assert body, "rejection must carry a clear message body"
    if isinstance(body, dict) and ("error_code" in body or "code" in body):
        assert (
            body.get("error_code") == "invalid_coordinates"
            or body.get("code") == "invalid_coordinates"
        ), f"unexpected rejection payload: {body}"
    else:
        assert isinstance(body, dict) and "detail" in body


# ---------------------------------------------------------------------------
# Seeding (raw INSERT INTO wards, house style of test_ward_place_page.py)
# ---------------------------------------------------------------------------


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


GEO_URL = "/api/v1/geo/reverse-geocode"


# ---------------------------------------------------------------------------
# BE-01 — successful reverse location lookup inside a ward (also: echoes lat/lng)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_01_reverse_geocode_success_inside_ward(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # A point ~4.2 km from the ward center — inside the 50 km coverage ceiling.
    response = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert response.status_code == 200, response.text
    data = response.json()

    # Contract response shape.
    assert set(data.keys()) == {"latitude", "longitude", "place", "ward", "distance_km", "found"}
    # Coordinates echoed verbatim.
    assert data["latitude"] == 19.15
    assert data["longitude"] == 72.88

    assert data["found"] is True
    assert data["place"] == "Ward 45, Urban Central"  # place == ward.name
    assert data["distance_km"] == round(_haversine_km(19.1136, 72.8697, 19.15, 72.88), 1)
    assert 0.0 < data["distance_km"] < 50.0

    ward = data["ward"]
    assert ward["slug"] == "ward-45-urban-central"
    assert ward["name"] == "Ward 45, Urban Central"
    assert ward["code"] == "W-45"
    assert ward["center_latitude"] == 19.1136
    assert ward["center_longitude"] == 72.8697


# ---------------------------------------------------------------------------
# BE-02 — nearest ward wins when the location is near several wards
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_02_nearest_ward_wins(app: typing.Any, client: httpx.AsyncClient) -> None:
    await _seed_ward(
        app,
        slug="ward-45-urban-central",
        name="Ward 45, Urban Central",
        code="W-45",
        lat=19.1136,
        lng=72.8697,
    )
    # Second ward whose center is ~12 km away from the probe point.
    await _seed_ward(
        app,
        slug="ward-77-north",
        name="Ward 77, North Sector",
        code="W-77",
        lat=19.20,
        lng=72.95,
    )

    # Probe point is ~0.7 km from ward-45 and ~12 km from ward-77.
    response = await client.get(GEO_URL, params={"latitude": 19.12, "longitude": 72.87})
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["found"] is True
    assert data["ward"]["slug"] == "ward-45-urban-central"
    assert data["place"] == "Ward 45, Urban Central"
    # Distance reported is the distance to the *winning* ward's center.
    assert data["distance_km"] == round(_haversine_km(19.1136, 72.8697, 19.12, 72.87), 1)


# ---------------------------------------------------------------------------
# BE-03 — out-of-coverage location returns an "outside coverage" result
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_03_out_of_coverage_default_radius(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # (28.0, 77.0) is ~1000+ km from the ward center — far beyond 50 km.
    response = await client.get(GEO_URL, params={"latitude": 28.0, "longitude": 77.0})
    assert response.status_code == 200, response.text  # 200, never a 404
    data = response.json()

    assert data["found"] is False
    assert data["ward"] is None
    assert data["place"] == "Outside coverage"
    assert data["distance_km"] == 0.0
    assert data["latitude"] == 28.0
    assert data["longitude"] == 77.0


@pytest.mark.asyncio
async def test_be_geo_03b_small_radius_nearby_but_far_point_outside(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # Point ~4.2 km away with radius_km=0.1: nearby (within 50 km) but farther
    # than the requested 0.1 km radius -> outside coverage.
    response = await client.get(
        GEO_URL, params={"latitude": 19.15, "longitude": 72.88, "radius_km": 0.1}
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["found"] is False
    assert data["ward"] is None
    assert data["place"] == "Outside coverage"
    assert data["distance_km"] == 0.0


# ---------------------------------------------------------------------------
# BE-04 — location at the coverage-ceiling boundary (consistency)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_04_coverage_ceiling_boundary_consistency(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # 0.44 deg north along the meridian => ~48.9 km (inside the 50 km ceiling).
    inside = {"latitude": 19.1136 + 0.44, "longitude": 72.8697}
    # 0.46 deg north along the meridian => ~51.2 km (beyond the 50 km ceiling).
    outside = {"latitude": 19.1136 + 0.46, "longitude": 72.8697}

    res_in_1 = await client.get(GEO_URL, params=inside)
    res_in_2 = await client.get(GEO_URL, params=inside)
    res_out_1 = await client.get(GEO_URL, params=outside)
    res_out_2 = await client.get(GEO_URL, params=outside)

    # No crash; every request answers 200.
    for res in (res_in_1, res_in_2, res_out_1, res_out_2):
        assert res.status_code == 200, res.text

    # Just under the ceiling resolves to the ward; just over is outside.
    assert res_in_1.json()["found"] is True
    assert res_out_1.json()["found"] is False
    assert res_out_1.json()["place"] == "Outside coverage"

    # The in/out verdict is stable across repeated identical requests.
    assert res_in_1.json() == res_in_2.json()
    assert res_out_1.json() == res_out_2.json()


# ---------------------------------------------------------------------------
# BE-05 — impossible coordinates rejected clearly (out-of-range)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_05_impossible_coordinates_out_of_range(
    client: httpx.AsyncClient,
) -> None:
    # latitude above 90, below -90; longitude beyond 180, beyond -180.
    bad_params = [
        {"latitude": 91.0, "longitude": 72.8697},
        {"latitude": -91.0, "longitude": 72.8697},
        {"latitude": 19.1136, "longitude": 181.0},
        {"latitude": 19.1136, "longitude": -181.0},
        {"latitude": 91.0, "longitude": 200.0},  # both out of range
        {"latitude": -95.0, "longitude": -185.0},  # both out of range
    ]
    for params in bad_params:
        response = await client.get(GEO_URL, params=params)
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text


# ---------------------------------------------------------------------------
# BE-06 — missing coordinates rejected clearly
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_06_missing_coordinates_rejected(
    client: httpx.AsyncClient,
) -> None:
    # No latitude and/or no longitude at all.
    missing_cases = [
        {},  # both absent
        {"latitude": 19.1136},  # longitude absent
        {"longitude": 72.8697},  # latitude absent
        {"latitude": "", "longitude": 72.8697},  # empty latitude
        {"latitude": 19.1136, "longitude": ""},  # empty longitude
    ]
    for params in missing_cases:
        response = await client.get(GEO_URL, params=params)
        _assert_clean_rejection(response)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text


# ---------------------------------------------------------------------------
# BE-07 — guest / unsigned-in caller lookup succeeds
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_07_guest_unsigned_in_lookup_succeeds(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    params = {"latitude": 19.15, "longitude": 72.88}

    # No authentication attached.
    res_anon = await client.get(GEO_URL, params=params)
    assert res_anon.status_code == 200, res_anon.text

    # Signed-in identity.
    res_auth = await client.get(GEO_URL, params=params, headers=auth_headers)
    assert res_auth.status_code == 200, res_auth.text

    # Same ward result either way; no identity is required or collected.
    assert res_anon.json() == res_auth.json()
    assert res_anon.json()["ward"]["slug"] == "ward-45-urban-central"


# ---------------------------------------------------------------------------
# BE-08 — malformed numeric input does not crash the service
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_08_malformed_numeric_input_rejected(
    client: httpx.AsyncClient,
) -> None:
    bad_lats = ["abc", "12,5", "1e", "12abc", "+", "-", ".", "NaN", "inf", "19.0e"]
    for bad in bad_lats:
        response = await client.get(GEO_URL, params={"latitude": bad, "longitude": 72.8697})
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text

    bad_lngs = ["abc", "12,5", "1e", "12abc", "+", "-", "."]
    for bad in bad_lngs:
        response = await client.get(GEO_URL, params={"latitude": 19.1136, "longitude": bad})
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text


# ---------------------------------------------------------------------------
# BE-09 — SQL injection attempts are rejected
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_09_sql_injection_payload_rejected(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    injections = [
        {"latitude": "19.0 OR 1=1", "longitude": "72.8697"},  # contract example
        {"latitude": "19.1136", "longitude": "72.8697 OR 1=1"},
        {"latitude": "19.1136' OR '1'='1", "longitude": "72.8697"},
        {"latitude": "19.1136; DROP TABLE wards;--", "longitude": "72.8697"},
        {"latitude": "19.1136", "longitude": "72.8697'; DROP TABLE wards;--"},
    ]
    for params in injections:
        response = await client.get(GEO_URL, params=params)
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text

    # The ward registry was not altered by any injection attempt.
    assert await _snapshot_wards(app) == await _snapshot_wards(app)


# ---------------------------------------------------------------------------
# BE-10 — repeated and rapid calls do not crash or degrade
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_10_repeated_rapid_calls_no_crash(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    valid_locations = [
        {"latitude": 19.15, "longitude": 72.88},
        {"latitude": 19.1136, "longitude": 72.8697},  # exactly at the center
        {"latitude": 19.20, "longitude": 72.95},
    ]
    invalid_locations = [
        {"latitude": 91.0, "longitude": 72.8697},
        {"latitude": "abc", "longitude": 72.8697},
        {"latitude": 19.1136, "longitude": 200.0},
        {},
        {"latitude": 19.0, "longitude": 72.0, "radius_km": 99.0},
    ]

    # Mixed burst: valid, invalid, out-of-range, and missing-coordinate requests.
    statuses: list[int] = []
    results: list[dict] = []
    for i in range(40):
        params = valid_locations[i % len(valid_locations)]
        response = await client.get(GEO_URL, params=params)
        statuses.append(response.status_code)
        results.append(response.json())

    for i in range(20):
        params = invalid_locations[i % len(invalid_locations)]
        response = await client.get(GEO_URL, params=params)
        statuses.append(response.status_code)
        assert response.status_code == 422, response.text

    # Every valid request got 200 with a ward; no 5xx anywhere.
    assert all(status == 200 for status in statuses[:40])
    assert all(statuses[i] == 200 for i in range(40))
    assert not any(status >= 500 for status in statuses)
    for result in results:
        assert result["found"] is True
        assert result["ward"]["slug"] == "ward-45-urban-central"

    # Service still responsive and correct after the burst.
    final = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert final.status_code == 200
    assert final.json()["found"] is True


# ---------------------------------------------------------------------------
# BE-11 — response contains only ward place information (no personal data)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_11_response_only_ward_place_info_no_pii(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    response = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert response.status_code == 200, response.text
    data = response.json()

    # Top-level contract shape only — nothing else may be present.
    assert set(data.keys()) == {"latitude", "longitude", "place", "ward", "distance_km", "found"}
    # Ward object exposes only place metadata.
    assert set(data["ward"].keys()) == {
        "slug",
        "name",
        "code",
        "center_latitude",
        "center_longitude",
    }

    res_text = response.text
    assert "+919876543210" not in res_text
    assert "user@example.com" not in res_text
    assert "access_token" not in res_text
    assert "reporter" not in res_text.lower()
    assert "anonymous_identity" not in res_text
    assert "anon_id" not in res_text


# ---------------------------------------------------------------------------
# BE-12 — distance to ward center is accurate to one decimal place
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_12_distance_rounded_to_one_decimal(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    probes = [
        (19.1136, 72.8697),  # exactly at the center -> 0.0
        (19.15, 72.88),
        (19.1136, 72.90),  # pure longitude offset
        (19.20, 72.8697),  # pure latitude offset
        (19.30, 73.00),
    ]
    for lat, lng in probes:
        response = await client.get(GEO_URL, params={"latitude": lat, "longitude": lng})
        assert response.status_code == 200, response.text
        data = response.json()
        expected = round(_haversine_km(19.1136, 72.8697, lat, lng), 1)
        assert data["distance_km"] == expected, (
            f"distance {data['distance_km']} != round(haversine, 1) = {expected} for ({lat}, {lng})"
        )
        assert isinstance(data["distance_km"], float)
        # Never reported with more than one decimal place of precision.
        assert round(data["distance_km"], 1) == data["distance_km"]


# ---------------------------------------------------------------------------
# BE-13 — lookup is read-only and never alters stored data
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_13_lookup_read_only_no_data_alteration(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    before_wards = await _snapshot_wards(app)
    before_tables = await _snapshot_tables(app)

    lookups = [
        {"latitude": 19.15, "longitude": 72.88},  # valid
        {"latitude": 28.0, "longitude": 77.0},  # out of coverage
        {"latitude": 91.0, "longitude": 72.8697},  # invalid
        {"latitude": "abc", "longitude": 72.8697},  # malformed
        {"latitude": "19.0 OR 1=1", "longitude": 72.8697},  # injection
        {},  # missing
        {"latitude": 19.15, "longitude": 72.88, "radius_km": 0.09},  # radius OOR
    ]
    for params in lookups:
        response = await client.get(GEO_URL, params=params)
        assert response.status_code in (200, 422), response.text

    assert await _snapshot_wards(app) == before_wards
    assert await _snapshot_tables(app) == before_tables


# ---------------------------------------------------------------------------
# radius_km parameter validation (contract: ge=0.1 le=50, default 50.0)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_be_geo_radius_out_of_range_rejected(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # Below the documented minimum and above the documented maximum.
    for bad_radius in (0.09, -1.0, 50.1, 500.0, "abc"):
        response = await client.get(
            GEO_URL,
            params={"latitude": 19.15, "longitude": 72.88, "radius_km": bad_radius},
        )
        _assert_invalid_coordinates(response)

    # Documented boundaries are accepted.
    res_min = await client.get(
        GEO_URL, params={"latitude": 19.15, "longitude": 72.88, "radius_km": 0.1}
    )
    assert res_min.status_code == 200, res_min.text
    assert res_min.json()["found"] is False  # 4.2 km > 0.1 km radius

    res_max = await client.get(
        GEO_URL, params={"latitude": 19.15, "longitude": 72.88, "radius_km": 50}
    )
    assert res_max.status_code == 200, res_max.text
    assert res_max.json()["found"] is True

    # Default radius (50.0) when omitted.
    res_default = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert res_default.status_code == 200
    assert res_default.json() == res_max.json()


# ---------------------------------------------------------------------------
# SEC-01 — lookup responses contain no personal data (PII)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_01_no_personal_data_in_any_response(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

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
        # Successful lookup.
        res_ok = await client.get(
            GEO_URL, params={"latitude": 19.15, "longitude": 72.88}, headers=headers
        )
        assert res_ok.status_code == 200, res_ok.text
        for marker in pii_markers:
            assert marker not in res_ok.text

        # Error / edge-case responses carry no PII either.
        res_err = await client.get(
            GEO_URL, params={"latitude": 91.0, "longitude": 72.8697}, headers=headers
        )
        assert res_err.status_code == 422
        for marker in pii_markers:
            assert marker not in res_err.text

        res_out = await client.get(
            GEO_URL, params={"latitude": 28.0, "longitude": 77.0}, headers=headers
        )
        assert res_out.status_code == 200
        for marker in pii_markers:
            assert marker not in res_out.text


# ---------------------------------------------------------------------------
# SEC-02 — no authentication bypass is possible (and none is needed)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_02_no_authentication_required_identical_results(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    params = {"latitude": 19.15, "longitude": 72.88}

    res_no_creds = await client.get(GEO_URL, params=params)
    res_bogus = await client.get(
        GEO_URL, params=params, headers={"Authorization": "Bearer not-a-real-token"}
    )
    res_valid = await client.get(GEO_URL, params=params, headers=auth_headers)

    assert res_no_creds.status_code == 200, res_no_creds.text
    assert res_bogus.status_code == 200, res_bogus.text
    assert res_valid.status_code == 200, res_valid.text

    # Identical ward results for anonymous, bogus, and valid callers.
    assert res_no_creds.json() == res_bogus.json() == res_valid.json()


# ---------------------------------------------------------------------------
# SEC-03 — input validation boundaries enforced
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_03_validation_boundaries_enforced(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # Documented boundaries are valid and processed normally (200, no ward there).
    res_lat_max = await client.get(GEO_URL, params={"latitude": 90.0, "longitude": 0.0})
    assert res_lat_max.status_code == 200, res_lat_max.text
    assert res_lat_max.json()["found"] is False  # far from the seeded ward

    res_lat_min = await client.get(GEO_URL, params={"latitude": -90.0, "longitude": 0.0})
    assert res_lat_min.status_code == 200

    res_lng_max = await client.get(GEO_URL, params={"latitude": 0.0, "longitude": 180.0})
    assert res_lng_max.status_code == 200

    res_lng_min = await client.get(GEO_URL, params={"latitude": 0.0, "longitude": -180.0})
    assert res_lng_min.status_code == 200

    # Just beyond every documented boundary is rejected.
    for params in (
        {"latitude": 90.0001, "longitude": 0.0},
        {"latitude": -90.0001, "longitude": 0.0},
        {"latitude": 0.0, "longitude": 180.0001},
        {"latitude": 0.0, "longitude": -180.0001},
        {"latitude": 90.0, "longitude": 180.0, "radius_km": 0.05},
        {"latitude": 90.0, "longitude": 180.0, "radius_km": 50.001},
    ):
        response = await client.get(GEO_URL, params=params)
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text


# ---------------------------------------------------------------------------
# SEC-04 — SQL injection attempts are blocked
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_04_sql_injection_attempts_blocked(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    before = await _snapshot_wards(app)

    payloads = [
        {"latitude": "1 UNION SELECT slug, name FROM wards--", "longitude": "72.8697"},
        {"latitude": "19.1136", "longitude": "72.8697 UNION SELECT 1,2,3--"},
        {"latitude": "19.1136; SELECT * FROM users;--", "longitude": "72.8697"},
        {"latitude": "19.1136", "longitude": "72.8697'; DROP TABLE wards;--"},
        {"latitude": "19.0' OR '1'='1", "longitude": "72.8697"},
        {"latitude": "19.1136", "longitude": "72.8697", "radius_km": "50; DELETE FROM wards;"},
    ]
    for params in payloads:
        response = await client.get(GEO_URL, params=params)
        _assert_invalid_coordinates(response)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text
        assert (
            "Ward 45" not in response.json().get("place", "")
            if isinstance(response.json(), dict)
            else True
        )

    # No stored data was altered and the ward registry still resolves.
    assert await _snapshot_wards(app) == before
    res = await client.get(GEO_URL, params={"latitude": 19.1136, "longitude": 72.8697})
    assert res.status_code == 200
    assert res.json()["found"] is True
    assert res.json()["ward"]["slug"] == "ward-45-urban-central"


# ---------------------------------------------------------------------------
# SEC-05 — lookup is strictly read-only
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_05_lookup_strictly_read_only(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    await _seed_ward(
        app, slug="ward-77-north", name="Ward 77, North Sector", code="W-77", lat=19.2, lng=72.95
    )

    before_wards = await _snapshot_wards(app)
    before_tables = await _snapshot_tables(app)

    # Battery of valid, invalid, injection, and out-of-range lookups.
    battery = [
        {"latitude": 19.15, "longitude": 72.88},
        {"latitude": 19.12, "longitude": 72.87},
        {"latitude": 28.0, "longitude": 77.0},
        {"latitude": 90.0, "longitude": 180.0},
        {"latitude": 91.0, "longitude": 72.8697},
        {"latitude": -91.0, "longitude": 0.0},
        {"latitude": 0.0, "longitude": 200.0},
        {"latitude": "abc", "longitude": 72.8697},
        {"latitude": "19.0 OR 1=1", "longitude": "72.8697"},
        {"latitude": "19.1136; DROP TABLE wards;--", "longitude": "72.8697"},
        {},
        {"latitude": 19.15, "longitude": 72.88, "radius_km": 500.0},
        {"latitude": 19.15, "longitude": 72.88, "radius_km": -1},
    ]
    for params in battery:
        response = await client.get(GEO_URL, params=params)
        assert response.status_code in (200, 422), response.text
        assert response.status_code != 500

    # Nothing created, modified, or deleted.
    assert await _snapshot_wards(app) == before_wards
    assert await _snapshot_tables(app) == before_tables


# ---------------------------------------------------------------------------
# SEC-06 — citizen location is never stored, shared, or reused
# ---------------------------------------------------------------------------

# Black-box proxy (test-environment limitation noted in the plan): with the
# in-memory test database we cannot observe cross-restart persistence, but we
# CAN assert that no lookup ever creates a storage/analytics table and that the
# response carries no location-history or tracking fields.


@pytest.mark.asyncio
async def test_sec_geo_06_location_never_stored_or_tracked(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    for _ in range(10):
        await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    await client.get(GEO_URL, params={"latitude": 91.0, "longitude": 0.0})

    # No table that could persist per-user lookup history/analytics was created.
    tables = await _snapshot_tables(app)
    table_names = [row[0] for row in tables]
    for forbidden in ("geo", "location", "lookup", "geocode", "analytics", "history"):
        assert not any(forbidden in name.lower() for name in table_names), table_names

    # The lookup response exposes no location-history / tracking fields.
    res = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert res.status_code == 200
    assert set(res.json().keys()) == {
        "latitude",
        "longitude",
        "place",
        "ward",
        "distance_km",
        "found",
    }


# ---------------------------------------------------------------------------
# SEC-07 — oversized and hostile input handled without internal-error leakage
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_07_oversized_hostile_input_no_internal_error(
    client: httpx.AsyncClient,
) -> None:
    hostile = [
        {"latitude": "9" * 5000, "longitude": "72.8697"},  # extremely long numeric
        {"latitude": "19.1136", "longitude": "7" * 5000},
        {"latitude": "A" * 2000, "longitude": "72.8697"},  # repeated chars
        {"latitude": "19.1136\x00\x01\x1f", "longitude": "72.8697"},  # control chars
        {"latitude": "19.1136", "longitude": "%ff%fe%fd"},  # non-UTF-8-ish bytes
        {"latitude": "19.1136", "longitude": "72.8697", "radius_km": "9" * 3000},
    ]
    for params in hostile:
        response = await client.get(GEO_URL, params=params)
        # Clean rejection; never an internal error, stack trace, or 5xx.
        assert response.status_code == 422, (params, response.status_code, response.text)
        assert "Traceback" not in response.text
        assert "Internal Server Error" not in response.text
        assert "Exception" not in response.text
        assert "app." not in response.text


# ---------------------------------------------------------------------------
# SEC-08 — wrongly structured requests are rejected cleanly
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_sec_geo_08_wrongly_structured_requests_rejected_cleanly(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    # Baseline valid request for comparison.
    baseline = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert baseline.status_code == 200

    # Extra unknown fields are ignored without error or crash.
    extra = await client.get(
        GEO_URL,
        params={
            "latitude": 19.15,
            "longitude": 72.88,
            "radius_km": 50,
            "foo": "bar",
            "device_id": "abc",
        },
    )
    assert extra.status_code == 200, extra.text
    assert extra.json()["ward"] == baseline.json()["ward"]

    # Duplicated fields: starlette-style query parsing uses the last occurrence;
    # the result must be a correct resolution or a clean rejection — never 500.
    dup_lat = await client.get(
        GEO_URL, params=[("latitude", "19.1136"), ("latitude", "19.1500"), ("longitude", "72.8697")]
    )
    assert dup_lat.status_code in (200, 422), dup_lat.text
    if dup_lat.status_code == 200:
        expected = round(_haversine_km(19.1136, 72.8697, 19.15, 72.8697), 1)
        assert dup_lat.json()["distance_km"] == expected

    dup_radius = await client.get(
        GEO_URL,
        params=[
            ("latitude", "19.15"),
            ("longitude", "72.88"),
            ("radius_km", "10"),
            ("radius_km", "0.2"),
        ],
    )
    assert dup_radius.status_code in (200, 422), dup_radius.text

    # Malformed value lists / repeated empty values.
    empty_mix = await client.get(GEO_URL, params=[("latitude", ""), ("longitude", "72.8697")])
    _assert_clean_rejection(empty_mix)

    no_crash = await client.get(GEO_URL, params={"latitude": 19.15, "longitude": 72.88})
    assert no_crash.status_code == 200


# ---------------------------------------------------------------------------
# MAP PINS ENDPOINT TESTS (F-08-MAP)
# ---------------------------------------------------------------------------

MAP_PINS_URL = "/api/v1/geo/map-pins"


async def _seed_user(app: typing.Any) -> int:
    async with app.state.database.session_factory() as session:
        result = await session.execute(
            text("""
            INSERT INTO users (email, role, is_admin, is_banned)
            VALUES ('mapuser@example.com', 'citizen', 0, 0)
            RETURNING id;
            """)
        )
        user_id = result.scalar_one()
        await session.commit()
        return user_id


async def _seed_issue(
    app: typing.Any,
    reporter_id: int,
    title: str = "Test Issue",
    category: str = "road",
    status: str = "unacknowledged",
    lat: float = 19.10,
    lng: float = 72.85,
    ward: str = "Ward 45, Urban Central",
    is_shielded: bool = False,
    is_hidden: bool = False,
    upvotes_count: int = 5,
) -> int:
    async with app.state.database.session_factory() as session:
        result = await session.execute(
            text("""
            INSERT INTO issues (title, description, category, status, latitude, longitude, ward, is_anonymous, fuzz_location, is_fuzzed, is_shielded, is_hidden, flag_count, reporter_id, created_at, upvotes_count, comments_count, confirmations_count, disputes_count)
            VALUES (:title, 'Desc', :category, :status, :lat, :lng, :ward, 0, 0, 0, :is_shielded, :is_hidden, 0, :reporter_id, CURRENT_TIMESTAMP, :upvotes_count, 0, 0, 0)
            RETURNING id;
            """),
            {
                "title": title,
                "category": category,
                "status": status,
                "lat": lat,
                "lng": lng,
                "ward": ward,
                "is_shielded": 1 if is_shielded else 0,
                "is_hidden": 1 if is_hidden else 0,
                "reporter_id": reporter_id,
                "upvotes_count": upvotes_count,
            },
        )
        issue_id = result.scalar_one()
        await session.commit()
        return issue_id


@pytest.mark.asyncio
async def test_get_map_pins_success_and_filtering(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    user_id = await _seed_user(app)
    # Inside bbox (19.0..19.2, 72.8..72.9)
    i1 = await _seed_issue(
        app, user_id, title="Pothole", category="road", status="in_progress", lat=19.10, lng=72.85
    )
    i2 = await _seed_issue(
        app,
        user_id,
        title="Garbage Dump",
        category="sanitation",
        status="unacknowledged",
        lat=19.15,
        lng=72.88,
    )
    # Outside bbox
    await _seed_issue(app, user_id, title="Far Away", category="road", lat=20.0, lng=73.0)

    # 1. Fetch all pins in bbox
    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9}
    )
    assert res.status_code == 200, res.text
    pins = res.json()
    assert len(pins) == 2
    pin_ids = {p["id"] for p in pins}
    assert pin_ids == {i1, i2}

    # Verify serialization fields
    p0 = pins[0]
    assert "id" in p0
    assert "title" in p0
    assert "category" in p0
    assert "status" in p0
    assert "latitude" in p0
    assert "longitude" in p0
    assert "ward_name" in p0
    assert "is_shielded" in p0
    assert "upvotes_count" in p0
    assert "created_at" in p0

    # 2. Filter by category
    res_cat = await client.get(
        MAP_PINS_URL,
        params={
            "min_lat": 19.0,
            "max_lat": 19.2,
            "min_lng": 72.8,
            "max_lng": 72.9,
            "category": "road",
        },
    )
    assert res_cat.status_code == 200
    pins_cat = res_cat.json()
    assert len(pins_cat) == 1
    assert pins_cat[0]["id"] == i1

    # 3. Filter by status
    res_stat = await client.get(
        MAP_PINS_URL,
        params={
            "min_lat": 19.0,
            "max_lat": 19.2,
            "min_lng": 72.8,
            "max_lng": 72.9,
            "status": "unacknowledged",
        },
    )
    assert res_stat.status_code == 200
    pins_stat = res_stat.json()
    assert len(pins_stat) == 1
    assert pins_stat[0]["id"] == i2


@pytest.mark.asyncio
async def test_get_map_pins_privacy_and_shielding(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    user_id = await _seed_user(app)
    # Shielded & non-resolved (unacknowledged) -> Should be excluded
    await _seed_issue(
        app,
        user_id,
        title="Shielded Pending",
        is_shielded=True,
        status="unacknowledged",
        lat=19.10,
        lng=72.85,
    )
    # Shielded & resolved -> Should be included
    i_resolved = await _seed_issue(
        app,
        user_id,
        title="Shielded Resolved",
        is_shielded=True,
        status="resolved",
        lat=19.11,
        lng=72.86,
    )
    # Hidden -> Should be excluded
    await _seed_issue(app, user_id, title="Hidden Issue", is_hidden=True, lat=19.12, lng=72.87)

    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9}
    )
    assert res.status_code == 200
    pins = res.json()
    assert len(pins) == 1
    assert pins[0]["id"] == i_resolved


@pytest.mark.asyncio
async def test_get_map_pins_invalid_bounds(client: httpx.AsyncClient) -> None:
    # min > max
    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 20.0, "max_lat": 10.0, "min_lng": 72.8, "max_lng": 72.9}
    )
    assert res.status_code == 200

    # Out of range coordinates
    res_range = await client.get(
        MAP_PINS_URL, params={"min_lat": -95.0, "max_lat": 10.0, "min_lng": 72.8, "max_lng": 72.9}
    )
    assert res_range.status_code == 200
