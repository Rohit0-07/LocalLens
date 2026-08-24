import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_map_pins_returns_empty_list(client: AsyncClient):
    res = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0")
    assert res.status_code == 200
    assert res.json() == []

@pytest.mark.asyncio
async def test_get_map_pins_with_category_filter(client: AsyncClient, auth_headers):
    payload = {
        "title": "Road issue",
        "description": "Pothole",
        "category": "road",
        "latitude": 15.0,
        "longitude": 75.0,
        "media_ids": []
    }
    await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    
    res = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0&category=road")
    assert res.status_code == 200
    pins = res.json()
    if pins:
        assert pins[0]["category"] == "road"
    
    res2 = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0&category=water")
    assert res2.status_code == 200
    assert len(res2.json()) == 0

@pytest.mark.asyncio
async def test_get_map_pins_excludes_shielded_non_resolved(client: AsyncClient, auth_headers):
    payload = {
        "title": "Shielded issue",
        "description": "Bad thing",
        "category": "road",
        "latitude": 15.0,
        "longitude": 75.0,
        "is_shielded": True,
        "status": "open",
        "media_ids": []
    }
    await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    
    res = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0")
    assert res.status_code == 200
    pins = res.json()
    for pin in pins:
        assert pin.get("title") != "Shielded issue"

@pytest.mark.asyncio
async def test_get_map_pins_rate_limit(client: AsyncClient):
    # simulate 60 requests
    for _ in range(60):
        await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0")
    
    res = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=20.0&max_lng=80.0")
    assert res.status_code == 429

@pytest.mark.asyncio
async def test_get_map_pins_bbox_spatial_filter(client: AsyncClient, auth_headers):
    payload = {
        "title": "Mumbai issue",
        "description": "Mumbai",
        "category": "road",
        "latitude": 19.0,
        "longitude": 72.8,
        "media_ids": []
    }
    await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    
    # bbox excluding mumbai
    res = await client.get("/api/v1/geo/map-pins?min_lat=10.0&min_lng=70.0&max_lat=15.0&max_lng=80.0")
    assert res.status_code == 200
    pins = res.json()
    for pin in pins:
        assert not (pin["latitude"] == 19.0 and pin["longitude"] == 72.8)
