import httpx
import pytest

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Pothole on Linking Road",
    "description": "Large pothole causing traffic congestion",
    "category": "road",
    "is_anonymous": False,
}


async def _create_issue(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    latitude: float,
    longitude: float,
    title: str = _ISSUE_PAYLOAD["title"],
) -> dict:
    payload = {**_ISSUE_PAYLOAD, "latitude": latitude, "longitude": longitude, "title": title}
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_feed_without_coords_returns_all_wards(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """GET /feed without lat/lng must return issues from every ward."""
    near = await _create_issue(client, auth_headers, 19.1136, 72.8697, title="Near issue")
    # Delhi is ~1150 km from Mumbai: outside any local radius.
    far = await _create_issue(client, auth_headers, 28.6139, 77.2090, title="Far issue")

    response = await client.get("/api/v1/feed")
    assert response.status_code == 200, response.text
    titles = {item.get("title") for item in response.json() if item.get("item_type") == "issue"}
    assert near["title"] in titles
    assert far["title"] in titles


async def test_feed_with_coords_stays_radius_scoped(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """GET /feed with lat/lng keeps filtering by radius (ward-local mode)."""
    near = await _create_issue(client, auth_headers, 19.1136, 72.8697, title="Near issue")
    far = await _create_issue(client, auth_headers, 28.6139, 77.2090, title="Far issue")

    response = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0},
    )
    assert response.status_code == 200, response.text
    titles = {item.get("title") for item in response.json() if item.get("item_type") == "issue"}
    assert near["title"] in titles
    assert far["title"] not in titles
