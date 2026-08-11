import httpx
from app.core.security import derive_anonymous_identity
from app.features.auth.models import User
from sqlalchemy import inspect


async def test_phone_otp_flow_and_jwt_authentication(client: httpx.AsyncClient) -> None:
    phone = "+919876543001"
    req_res = await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    assert req_res.status_code == 204

    verify_res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"}
    )
    assert verify_res.status_code == 200
    token_data = verify_res.json()
    assert token_data["access_token"]
    assert token_data["token_type"] == "bearer"
    assert isinstance(token_data["user_id"], int)
    assert token_data["anonymous_identity"].startswith("anon_")

    headers = {"Authorization": f"Bearer {token_data['access_token']}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["id"] == token_data["user_id"]
    assert me_data["phone"] == phone
    assert me_data["anonymous_identity"] == token_data["anonymous_identity"]


async def test_email_otp_flow(client: httpx.AsyncClient) -> None:
    req_res = await client.post(
        "/api/v1/auth/email/request-otp", json={"email": "citizen@example.com"}
    )
    assert req_res.status_code == 204


def test_zero_retention_identity_derivation_properties() -> None:
    secret = "locallens-test-secret-key-12345"
    id1 = derive_anonymous_identity(101, secret)
    id1_repeat = derive_anonymous_identity(101, secret)
    id2 = derive_anonymous_identity(102, secret)
    id1_diff_secret = derive_anonymous_identity(101, "different-secret-999")

    assert id1.startswith("anon_")
    assert len(id1) == 21  # "anon_" (5) + 16 hex chars
    assert id1 == id1_repeat, "HMAC derivation must be deterministic"
    assert id1 != id2, "Different users must derive distinct anonymous identities"
    assert id1 != id1_diff_secret, "Different secrets must produce different anonymous identities"


def test_zero_retention_database_schema_assertion() -> None:
    mapper = inspect(User)
    column_names = [column.key for column in mapper.columns]
    assert "phone" in column_names
    assert "id" in column_names
    assert "anonymous_identity" not in column_names, (
        "DB must not store anonymous identity (zero-retention)"
    )
    assert "anon_id" not in column_names, "DB must not store anonymous identity (zero-retention)"


async def test_unauthenticated_and_invalid_jwt_rejection(client: httpx.AsyncClient) -> None:
    res_no_auth = await client.get("/api/v1/auth/me")
    assert res_no_auth.status_code == 401

    res_invalid_auth = await client.get(
        "/api/v1/auth/me", headers={"Authorization": "Bearer invalid.jwt.token"}
    )
    assert res_invalid_auth.status_code == 401
