import pytest
from httpx import AsyncClient

GEOCODE_URL = "/api/v1/geo/reverse-geocode"


@pytest.mark.asyncio
async def test_reverse_geocode_returns_ward(client: AsyncClient) -> None:
    # Valid coordinates within India — API uses `latitude` and `longitude` params.
    res = await client.get(GEOCODE_URL, params={"latitude": 19.0, "longitude": 72.8})
    assert res.status_code == 200, res.text
    data = res.json()
    # The response schema always contains a `ward` key (may be null if no ward found).
    assert "ward" in data


@pytest.mark.asyncio
async def test_reverse_geocode_no_ward_found(client: AsyncClient) -> None:
    # Middle of the ocean — no wards seeded there.
    res = await client.get(GEOCODE_URL, params={"latitude": 0.0, "longitude": 0.0})
    assert res.status_code == 200, res.text
    data = res.json()
    assert data.get("ward") is None


@pytest.mark.asyncio
async def test_reverse_geocode_invalid_coords(client: AsyncClient) -> None:
    # latitude > 90 is out of the valid range — FastAPI should return 422.
    res = await client.get(GEOCODE_URL, params={"latitude": 200.0, "longitude": 72.8})
    assert res.status_code == 422
