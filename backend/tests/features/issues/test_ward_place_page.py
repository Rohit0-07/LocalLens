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


@pytest.mark.asyncio
async def test_be_ward_01_retrieve_ward_details_by_valid_slug(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")
    await _seed_representative(
        app, user_id=42, ward="Ward 45, Urban Central", official_name="Hon. Sarah Jenkins"
    )

    # 15 issues: 8 active, 3 escalated, 4 resolved
    categories = ["road", "water", "lighting"]
    for i in range(8):
        await _seed_issue(
            client,
            auth_headers,
            app,
            ward="Ward 45, Urban Central",
            category=categories[i % 3],
            status="open",
        )
    for _i in range(3):
        await _seed_issue(
            client,
            auth_headers,
            app,
            ward="Ward 45, Urban Central",
            category="water",
            status="escalated",
        )
    for _i in range(4):
        await _seed_issue(
            client,
            auth_headers,
            app,
            ward="Ward 45, Urban Central",
            category="lighting",
            status="resolved",
        )

    response = await client.get("/api/v1/wards/ward-45-urban-central")
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["slug"] == "ward-45-urban-central"
    assert data["name"] == "Ward 45, Urban Central"
    assert data["code"] == "W-45"
    assert data["center_latitude"] == 19.1136
    assert data["center_longitude"] == 72.8697
    assert data["total_issues"] == 15
    assert data["active_issues"] == 8
    assert data["escalated_issues"] == 3
    assert data["resolved_issues"] == 4
    assert data["resolution_rate_pct"] == 26.67
    assert isinstance(data["top_categories"], list)
    assert data["assigned_representative"] is not None
    assert data["assigned_representative"]["official_name"] == "Hon. Sarah Jenkins"
    assert data["assigned_representative"]["title"] == "Ward Representative"
    assert isinstance(data["recent_issues"], list)
    assert "updated_at" in data


@pytest.mark.asyncio
async def test_be_ward_02_retrieve_ward_details_by_raw_ward_name(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central", code="W-45")

    response = await client.get("/api/v1/wards/Ward%2045,%20Urban%20Central")
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["slug"] == "ward-45-urban-central"
    assert data["name"] == "Ward 45, Urban Central"


@pytest.mark.asyncio
async def test_be_ward_03_issues_limit_parameter_handling(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")
    for i in range(12):
        await _seed_issue(
            client,
            auth_headers,
            app,
            ward="Ward 45, Urban Central",
            title=f"Issue {i + 1}",
            status="open",
        )

    res_3 = await client.get("/api/v1/wards/ward-45-urban-central?issues_limit=3")
    assert res_3.status_code == 200
    assert len(res_3.json()["recent_issues"]) == 3

    res_50 = await client.get("/api/v1/wards/ward-45-urban-central?issues_limit=50")
    assert res_50.status_code == 200
    assert len(res_50.json()["recent_issues"]) == 12


@pytest.mark.asyncio
async def test_be_ward_04_ward_detail_not_found(client: httpx.AsyncClient) -> None:
    response = await client.get("/api/v1/wards/non-existent-ward-99")
    assert response.status_code == 404
    data = response.json()
    assert data["detail"] == "Ward not found"
    assert data["code"] == "ward_not_found"


@pytest.mark.asyncio
async def test_be_ward_05_list_active_wards_with_pagination(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    for i in range(1, 26):
        await _seed_ward(app, slug=f"ward-{i}", name=f"Ward {i}", code=f"W-{i}")

    response = await client.get("/api/v1/wards?limit=10&offset=5")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) == 10
    assert data["total"] == 25
    assert data["limit"] == 10
    assert data["offset"] == 5


@pytest.mark.asyncio
async def test_be_ward_06_list_active_wards_default_pagination(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    for i in range(1, 26):
        await _seed_ward(app, slug=f"ward-def-{i}", name=f"Ward Def {i}", code=f"WD-{i}")

    response = await client.get("/api/v1/wards")
    assert response.status_code == 200
    data = response.json()
    assert data["limit"] == 20
    assert data["offset"] == 0
    assert len(data["items"]) == 20
    assert data["total"] >= 25


@pytest.mark.asyncio
async def test_be_ward_07_resolve_ward_by_valid_gps_coordinates(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(
        app, slug="ward-45-urban-central", name="Ward 45, Urban Central", lat=19.1136, lng=72.8697
    )

    response = await client.get("/api/v1/wards/by-location?latitude=19.1136&longitude=72.8697")
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["slug"] == "ward-45-urban-central"
    assert data["name"] == "Ward 45, Urban Central"
    assert data["code"] == "W-45"


@pytest.mark.asyncio
async def test_be_ward_08_gps_coordinates_out_of_bounds(client: httpx.AsyncClient) -> None:
    res_lat = await client.get("/api/v1/wards/by-location?latitude=95.0000&longitude=72.8697")
    assert res_lat.status_code in (400, 422)
    assert res_lat.json()["code"] in ("invalid_coordinates", "validation_error")

    res_lng = await client.get("/api/v1/wards/by-location?latitude=19.1136&longitude=-185.0000")
    assert res_lng.status_code in (400, 422)
    assert res_lng.json()["code"] in ("invalid_coordinates", "validation_error")


@pytest.mark.asyncio
async def test_be_ward_09_resolve_ward_out_of_jurisdiction_range(client: httpx.AsyncClient) -> None:
    response = await client.get("/api/v1/wards/by-location?latitude=0.0000&longitude=0.0000")
    assert response.status_code == 404
    data = response.json()
    assert data["code"] == "ward_not_found"


@pytest.mark.asyncio
async def test_be_ward_10_ward_slugification_standard_verification() -> None:
    def slugify_ward_name(raw_name: str) -> str:
        import re

        s = raw_name.lower()
        s = re.sub(r"[^\w\s-]", "", s)
        s = re.sub(r"[\s,]+", "-", s)
        return s.strip("-")

    assert slugify_ward_name("Ward 45, Urban Central") == "ward-45-urban-central"
    assert slugify_ward_name("Ward  12 (North Sector)") == "ward-12-north-sector"
    assert slugify_ward_name("St. Mary's Ward #3") == "st-marys-ward-3"


@pytest.mark.asyncio
async def test_be_ward_11_resolution_rate_calculation_formula(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-calc-1", name="Ward Calc 1")
    for _ in range(11):
        await _seed_issue(client, auth_headers, app, ward="Ward Calc 1", status="open")
    for _ in range(4):
        await _seed_issue(client, auth_headers, app, ward="Ward Calc 1", status="resolved")

    response = await client.get("/api/v1/wards/ward-calc-1")
    assert response.status_code == 200
    data = response.json()
    assert data["total_issues"] == 15
    assert data["resolved_issues"] == 4
    assert data["resolution_rate_pct"] == 26.67


@pytest.mark.asyncio
async def test_be_ward_12_zero_total_issues_division_by_zero_protection(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="empty-ward-1", name="Empty Ward 1")

    response = await client.get("/api/v1/wards/empty-ward-1")
    assert response.status_code == 200
    data = response.json()
    assert data["total_issues"] == 0
    assert data["resolution_rate_pct"] == 0.0


@pytest.mark.asyncio
async def test_be_ward_13_shielded_unresolved_issue_exclusion_in_recent_issues(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-shield-test", name="Ward Shield Test")

    i1 = await _seed_issue(
        client,
        auth_headers,
        app,
        ward="Ward Shield Test",
        title="Public Open Issue",
        is_shielded=False,
        status="open",
    )
    i2 = await _seed_issue(
        client,
        auth_headers,
        app,
        ward="Ward Shield Test",
        title="Shielded Open Issue",
        is_shielded=True,
        status="open",
    )
    i3 = await _seed_issue(
        client,
        auth_headers,
        app,
        ward="Ward Shield Test",
        title="Shielded Resolved Issue",
        is_shielded=True,
        status="resolved",
    )

    response = await client.get("/api/v1/wards/ward-shield-test")
    assert response.status_code == 200
    recent = response.json()["recent_issues"]
    recent_ids = [issue["id"] for issue in recent]

    assert i1 in recent_ids
    assert i3 in recent_ids
    assert i2 not in recent_ids


@pytest.mark.asyncio
async def test_be_ward_14_shielded_resolved_issue_inclusion_in_recent_issues(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-shield-res", name="Ward Shield Res")
    i_res = await _seed_issue(
        client,
        auth_headers,
        app,
        ward="Ward Shield Res",
        title="Resolved Shielded Issue",
        is_shielded=True,
        status="resolved",
    )

    response = await client.get("/api/v1/wards/ward-shield-res")
    assert response.status_code == 200
    recent = response.json()["recent_issues"]
    recent_ids = [issue["id"] for issue in recent]
    assert i_res in recent_ids


@pytest.mark.asyncio
async def test_sec_ward_01_sqli_parameterization_protection(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")

    res_1 = await client.get("/api/v1/wards/'%20OR%20'1'='1")
    assert res_1.status_code == 404
    assert res_1.json()["code"] == "ward_not_found"

    res_2 = await client.get("/api/v1/wards/ward-45-urban-central;DROP%20TABLE%20wards;--")
    assert res_2.status_code == 404

    res_3 = await client.get(
        "/api/v1/wards/by-location?latitude=19.1136'%20OR%201=1--&longitude=72.8697"
    )
    assert res_3.status_code in (400, 422)


@pytest.mark.asyncio
async def test_sec_ward_02_anonymous_identity_protection_and_zero_pii_leakage(
    app: typing.Any, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")
    await _seed_issue(
        client,
        auth_headers,
        app,
        ward="Ward 45, Urban Central",
        title="Pothole by sensitive user",
        is_anonymous=True,
        status="open",
    )

    response = await client.get("/api/v1/wards/ward-45-urban-central")
    assert response.status_code == 200
    res_text = response.text
    assert "+919876543210" not in res_text
    assert "user@example.com" not in res_text

    recent = response.json()["recent_issues"]
    assert len(recent) >= 1
    anon_issue = recent[0]
    assert anon_issue["is_anonymous"] is True
    assert "reporter_label" in anon_issue
    assert "anonymous_identity" in anon_issue


@pytest.mark.asyncio
async def test_sec_ward_03_sliding_window_rate_limiting_protection(
    app: typing.Any, client: httpx.AsyncClient
) -> None:

    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")

    statuses = []
    for _ in range(60):
        res = await client.get("/api/v1/wards/ward-45-urban-central")
        statuses.append(res.status_code)

    assert all(s == 200 for s in statuses)

    over_limit_res = await client.get("/api/v1/wards/ward-45-urban-central")
    assert over_limit_res.status_code == 429
    assert over_limit_res.json()["code"] == "rate_limit_exceeded"


@pytest.mark.asyncio
async def test_sec_ward_04_unauthenticated_public_and_guest_access(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    await _seed_ward(app, slug="ward-45-urban-central", name="Ward 45, Urban Central")

    res_detail = await client.get("/api/v1/wards/ward-45-urban-central")
    assert res_detail.status_code == 200

    res_list = await client.get("/api/v1/wards")
    assert res_list.status_code == 200

    res_loc = await client.get("/api/v1/wards/by-location?latitude=19.1136&longitude=72.8697")
    assert res_loc.status_code == 200

    guest_headers = {"Authorization": "Bearer guest-token-test"}
    res_guest = await client.get("/api/v1/wards/ward-45-urban-central", headers=guest_headers)
    assert res_guest.status_code == 200
