import pytest
from httpx import AsyncClient


async def test_request_otp_returns_no_content(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543210"})
    assert response.status_code == 204


async def test_request_otp_rejects_invalid_phone(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/otp/request", json={"phone": "not-a-phone"})
    assert response.status_code == 422


async def test_verify_otp_returns_token(client: AsyncClient) -> None:
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543210"})
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "000000"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["access_token"]
    assert body["token_type"] == "bearer"
    assert isinstance(body["user_id"], int)
    assert body["anon_id"].startswith("anon_")


async def test_verify_otp_endpoint_alias_and_hmac_derivation(client: AsyncClient) -> None:
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543211"})
    response = await client.post(
        "/api/v1/auth/verify-otp", json={"phone": "+919876543211", "code": "000000"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["anon_id"].startswith("anon_")


async def test_verify_otp_rejects_wrong_code(client: AsyncClient) -> None:
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543210"})
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "999999"}
    )
    assert response.status_code == 400
    assert response.json()["code"] == "otp_invalid"


async def test_verify_otp_rejects_unknown_phone(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+911111111111", "code": "000000"}
    )
    assert response.status_code == 400


async def test_otp_is_single_use(client: AsyncClient) -> None:
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543210"})
    first = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "000000"}
    )
    assert first.status_code == 200
    second = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "000000"}
    )
    assert second.status_code == 400


async def test_verify_otp_rejects_malformed_code(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543210", "code": "abc"}
    )
    assert response.status_code == 422


@pytest.mark.parametrize("payload", [{}, {"phone": ""}, {"phone": "+1" * 50}])
async def test_otp_payload_validation(client: AsyncClient, payload: dict) -> None:
    response = await client.post("/api/v1/auth/otp/request", json=payload)
    assert response.status_code == 422


async def test_otp_invalidated_after_five_failed_attempts(client: AsyncClient) -> None:
    phone = "+919876543300"
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    for _ in range(5):
        response = await client.post(
            "/api/v1/auth/otp/verify", json={"phone": phone, "code": "999999"}
        )
        assert response.status_code == 400
    # Even the correct code is rejected once the OTP is invalidated.
    response = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"}
    )
    assert response.status_code == 400
    assert response.json()["code"] == "otp_invalid"


async def test_otp_request_rate_limited_per_phone(client: AsyncClient) -> None:
    phone = "+919876543301"
    for _ in range(3):
        response = await client.post("/api/v1/auth/otp/request", json={"phone": phone})
        assert response.status_code == 204
    response = await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    assert response.status_code == 429
    assert response.json()["code"] == "rate_limited"


async def test_otp_verify_rate_limited_per_phone(client: AsyncClient) -> None:
    phone = "+919876543302"
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    wrong = {"phone": phone, "code": "999999"}
    for _ in range(10):
        response = await client.post("/api/v1/auth/otp/verify", json=wrong)
        assert response.status_code == 400
    response = await client.post("/api/v1/auth/otp/verify", json=wrong)
    assert response.status_code == 429
    assert response.json()["code"] == "rate_limited"


async def test_banned_user_rejected_on_authenticated_endpoints(
    app, client: AsyncClient
) -> None:
    from app.features.auth.models import User
    from sqlalchemy import update

    phone = "+919876543303"
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    verify_res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"}
    )
    headers = {"Authorization": f"Bearer {verify_res.json()['access_token']}"}

    async with app.state.database.session_factory() as session:
        await session.execute(update(User).where(User.phone == phone).values(is_banned=True))
        await session.commit()

    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 403
    assert response.json()["code"] == "account_banned"
