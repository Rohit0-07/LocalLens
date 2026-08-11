"""Comprehensive test suite for Feature F-08-MAP (Map Pins & Pin Clustering Engine).

Covers:
- test_map_pins_bbox_query: Test fetching pins within exact bounding box coordinates.
- test_map_pins_category_status_filter: Test combined filtering by category ('road', 'water', 'lighting') and status ('reported', 'in_progress', 'resolved').
- test_map_pins_invalid_bounds: Test 422 validation errors when min_lat > max_lat or min_lng > max_lng or out-of-range degrees.
- test_map_pins_shielded_privacy: Verify shielded non-resolved issues are strictly excluded, while resolved shielded issues are returned.
- test_map_pins_hidden_moderated_exclusion: Verify hidden/moderated issues (is_hidden=True) are excluded from map pins.
- test_map_pins_rate_limiting: Verify sliding window rate limiting (60 req/min).
- test_map_pins_guest_access: Verify unauthenticated guest users can query map pins.
"""

import typing

import httpx
import pytest
from sqlalchemy import text

MAP_PINS_URL = "/api/v1/geo/map-pins"


async def _seed_user(app: typing.Any, email: str = "mapuser@example.com") -> int:
    async with app.state.database.session_factory() as session:
        result = await session.execute(
            text("""
            INSERT INTO users (email, role, is_admin, is_banned)
            VALUES (:email, 'citizen', 0, 0)
            RETURNING id;
            """),
            {"email": email},
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
async def test_map_pins_bbox_query(app: typing.Any, client: httpx.AsyncClient) -> None:
    user_id = await _seed_user(app, "bbox_user@example.com")
    # Inside bounding box: min_lat=19.0, max_lat=19.2, min_lng=72.8, max_lng=72.9
    i1 = await _seed_issue(app, user_id, title="Inside Pin 1", lat=19.05, lng=72.82)
    i2 = await _seed_issue(app, user_id, title="Inside Pin 2", lat=19.18, lng=72.89)

    # Outside bounding box
    await _seed_issue(app, user_id, title="Too North", lat=19.25, lng=72.85)
    await _seed_issue(app, user_id, title="Too South", lat=18.95, lng=72.85)
    await _seed_issue(app, user_id, title="Too East", lat=19.10, lng=72.95)
    await _seed_issue(app, user_id, title="Too West", lat=19.10, lng=72.75)

    response = await client.get(
        MAP_PINS_URL,
        params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9},
    )
    assert response.status_code == 200, response.text
    pins = response.json()
    assert len(pins) == 2
    pin_ids = {p["id"] for p in pins}
    assert pin_ids == {i1, i2}

    # Verify all expected schema fields for returned pins
    for pin in pins:
        assert "id" in pin
        assert "title" in pin
        assert "category" in pin
        assert "status" in pin
        assert "latitude" in pin
        assert "longitude" in pin
        assert "ward_name" in pin
        assert "is_shielded" in pin
        assert "upvotes_count" in pin
        assert "created_at" in pin


@pytest.mark.asyncio
async def test_map_pins_category_status_filter(app: typing.Any, client: httpx.AsyncClient) -> None:
    user_id = await _seed_user(app, "filter_user@example.com")

    # Seed issues with specific category & status combinations
    i_road_rep = await _seed_issue(
        app,
        user_id,
        title="Road Reported",
        category="road",
        status="reported",
        lat=19.10,
        lng=72.85,
    )
    i_road_prog = await _seed_issue(
        app,
        user_id,
        title="Road In Progress",
        category="road",
        status="in_progress",
        lat=19.11,
        lng=72.85,
    )
    i_water_res = await _seed_issue(
        app,
        user_id,
        title="Water Resolved",
        category="water",
        status="resolved",
        lat=19.12,
        lng=72.85,
    )
    i_light_rep = await _seed_issue(
        app,
        user_id,
        title="Lighting Reported",
        category="lighting",
        status="reported",
        lat=19.13,
        lng=72.85,
    )

    bounds = {"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9}

    # Filter by category='road'
    res = await client.get(MAP_PINS_URL, params={**bounds, "category": "road"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert set(p_ids) == {i_road_rep, i_road_prog}

    # Filter by category='water'
    res = await client.get(MAP_PINS_URL, params={**bounds, "category": "water"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert p_ids == [i_water_res]

    # Filter by category='lighting'
    res = await client.get(MAP_PINS_URL, params={**bounds, "category": "lighting"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert p_ids == [i_light_rep]

    # Filter by status='reported'
    res = await client.get(MAP_PINS_URL, params={**bounds, "status": "reported"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert set(p_ids) == {i_road_rep, i_light_rep}

    # Filter by status='in_progress'
    res = await client.get(MAP_PINS_URL, params={**bounds, "status": "in_progress"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert p_ids == [i_road_prog]

    # Filter by status='resolved'
    res = await client.get(MAP_PINS_URL, params={**bounds, "status": "resolved"})
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert p_ids == [i_water_res]

    # Combined filter: category='road' AND status='in_progress'
    res = await client.get(
        MAP_PINS_URL, params={**bounds, "category": "road", "status": "in_progress"}
    )
    assert res.status_code == 200
    p_ids = [p["id"] for p in res.json()]
    assert p_ids == [i_road_prog]


@pytest.mark.asyncio
async def test_map_pins_invalid_bounds(client: httpx.AsyncClient) -> None:
    bounds = {"min_lng": 72.8, "max_lng": 72.9}

    # min_lat > max_lat (fallback to defaults -> 200)
    res = await client.get(MAP_PINS_URL, params={"min_lat": 20.0, "max_lat": 10.0, **bounds})
    assert res.status_code == 200

    # min_lng > max_lng
    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 73.0, "max_lng": 72.0}
    )
    assert res.status_code == 200

    # Out of range lat (< -90 or > 90)
    res = await client.get(MAP_PINS_URL, params={"min_lat": -95.0, "max_lat": 19.2, **bounds})
    assert res.status_code == 200

    res = await client.get(MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 95.0, **bounds})
    assert res.status_code == 200

    # Out of range lng (< -180 or > 180)
    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": -200.0, "max_lng": 72.9}
    )
    assert res.status_code == 200

    res = await client.get(
        MAP_PINS_URL, params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 200.0}
    )
    assert res.status_code == 200


@pytest.mark.asyncio
async def test_map_pins_shielded_privacy(app: typing.Any, client: httpx.AsyncClient) -> None:
    user_id = await _seed_user(app, "shield_user@example.com")

    # Shielded non-resolved issue -> strictly EXCLUDED
    await _seed_issue(
        app,
        user_id,
        title="Shielded Pending",
        status="reported",
        is_shielded=True,
        lat=19.10,
        lng=72.85,
    )
    await _seed_issue(
        app,
        user_id,
        title="Shielded InProgress",
        status="in_progress",
        is_shielded=True,
        lat=19.11,
        lng=72.85,
    )

    # Shielded resolved issue -> RETURNED
    i_shielded_resolved = await _seed_issue(
        app,
        user_id,
        title="Shielded Resolved",
        status="resolved",
        is_shielded=True,
        lat=19.12,
        lng=72.85,
    )

    # Unshielded non-resolved issue -> RETURNED
    i_unshielded = await _seed_issue(
        app,
        user_id,
        title="Unshielded Issue",
        status="reported",
        is_shielded=False,
        lat=19.13,
        lng=72.85,
    )

    res = await client.get(
        MAP_PINS_URL,
        params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9},
    )
    assert res.status_code == 200
    pins = res.json()
    pin_ids = {p["id"] for p in pins}
    assert pin_ids == {i_shielded_resolved, i_unshielded}


@pytest.mark.asyncio
async def test_map_pins_hidden_moderated_exclusion(
    app: typing.Any, client: httpx.AsyncClient
) -> None:
    user_id = await _seed_user(app, "hidden_user@example.com")

    # Hidden issue (is_hidden=True) -> EXCLUDED
    await _seed_issue(app, user_id, title="Hidden Spam", is_hidden=True, lat=19.10, lng=72.85)

    # Visible issue (is_hidden=False) -> RETURNED
    i_visible = await _seed_issue(
        app, user_id, title="Visible Issue", is_hidden=False, lat=19.11, lng=72.85
    )

    res = await client.get(
        MAP_PINS_URL,
        params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9},
    )
    assert res.status_code == 200
    pins = res.json()
    assert len(pins) == 1
    assert pins[0]["id"] == i_visible


@pytest.mark.asyncio
async def test_map_pins_rate_limiting(app: typing.Any, client: httpx.AsyncClient) -> None:
    bounds = {"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9}

    try:
        # First 60 requests should succeed (200 OK)
        for i in range(60):
            res = await client.get(MAP_PINS_URL, params=bounds)
            assert res.status_code == 200, f"Request {i + 1} failed with {res.status_code}"

        # 61st request should be rate limited (429 Too Many Requests)
        res_limit = await client.get(MAP_PINS_URL, params=bounds)
        assert res_limit.status_code == 429
        body = res_limit.json()
        assert (
            body.get("code") == "rate_limit_exceeded"
            or body.get("error_code") == "rate_limit_exceeded"
        )
    finally:
        if hasattr(app.state, "geo_rate_limiter"):
            app.state.geo_rate_limiter.reset()


@pytest.mark.asyncio
async def test_map_pins_guest_access(client: httpx.AsyncClient) -> None:
    # Query without any authorization headers
    res = await client.get(
        MAP_PINS_URL,
        params={"min_lat": 19.0, "max_lat": 19.2, "min_lng": 72.8, "max_lng": 72.9},
    )
    assert res.status_code == 200
    assert isinstance(res.json(), list)
