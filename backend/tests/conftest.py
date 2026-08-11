from collections.abc import AsyncIterator

import httpx
import pytest_asyncio
from app.core.config import Settings
from app.main import create_app
from fastapi import FastAPI

_TEST_SETTINGS = Settings(
    environment="test",
    database_url="sqlite+aiosqlite:///:memory:",
    jwt_secret="test-secret-that-is-long-enough-for-hs256-signing",
    otp_master_code="000000",
)


@pytest_asyncio.fixture
async def app() -> AsyncIterator[FastAPI]:
    application = create_app(_TEST_SETTINGS)
    await application.state.database.create_all()
    yield application
    await application.state.database.dispose()


@pytest_asyncio.fixture
async def client(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as test_client:
        yield test_client


@pytest_asyncio.fixture
async def auth_headers(client: httpx.AsyncClient) -> dict[str, str]:
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543210"})
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "000000"}
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def create_user_headers(client: httpx.AsyncClient):
    async def _create_user(phone: str) -> dict[str, str]:
        await client.post("/api/v1/auth/otp/request", json={"phone": phone})
        response = await client.post(
            "/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"}
        )
        token = response.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    return _create_user
