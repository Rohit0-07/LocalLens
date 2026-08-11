import httpx
import pytest


@pytest.mark.asyncio
async def test_email_request_otp_valid(client: httpx.AsyncClient):
    """POST /auth/email/request-otp with a valid email returns 204 No Content."""
    response = await client.post(
        "/api/v1/auth/email/request-otp",
        json={"email": "citizen@example.com"},
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_email_request_otp_invalid_email(client: httpx.AsyncClient):
    """POST /auth/email/request-otp with invalid email formats returns 422 Unprocessable Entity."""
    invalid_emails = [
        "not-an-email",
        "missingatsign.com",
        "@domain.com",
        "user@.com",
        "user@domain.",
        "",
    ]
    for email in invalid_emails:
        response = await client.post(
            "/api/v1/auth/email/request-otp",
            json={"email": email},
        )
        assert response.status_code == 422, (
            f"Expected 422 for invalid email: '{email}', got {response.status_code}"
        )


@pytest.mark.asyncio
async def test_email_verify_otp_valid(client: httpx.AsyncClient):
    """POST /auth/email/verify-otp with valid email and code returns token response with is_guest=False."""
    await client.post(
        "/api/v1/auth/email/request-otp",
        json={"email": "verified@example.com"},
    )

    response = await client.post(
        "/api/v1/auth/email/verify-otp",
        json={"email": "verified@example.com", "code": "000000"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["is_guest"] is False
    assert "user_id" in data
    assert "anonymous_identity" in data or "anon_id" in data


@pytest.mark.asyncio
async def test_email_verify_otp_invalid_code(client: httpx.AsyncClient):
    """POST /auth/email/verify-otp with an invalid OTP code returns 400 Bad Request or 401 Unauthorized."""
    await client.post(
        "/api/v1/auth/email/request-otp",
        json={"email": "user@example.com"},
    )

    response = await client.post(
        "/api/v1/auth/email/verify-otp",
        json={"email": "user@example.com", "code": "999999"},
    )
    assert response.status_code in (400, 401, 422)


@pytest.mark.asyncio
async def test_email_verify_otp_expired_or_unrequested(client: httpx.AsyncClient):
    """POST /auth/email/verify-otp for email without active OTP returns error."""
    response = await client.post(
        "/api/v1/auth/email/verify-otp",
        json={"email": "never_requested@example.com", "code": "000000"},
    )
    assert response.status_code in (400, 401, 404, 422)


@pytest.mark.asyncio
async def test_guest_login_returns_guest_token(client: httpx.AsyncClient):
    """POST /auth/guest generates guest session token with is_guest=True."""
    response = await client.post("/api/v1/auth/guest")
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["is_guest"] is True
    assert str(data["user_id"]).startswith("guest:")
    assert data.get("anonymous_identity") == "guest_anon" or data.get("anon_id") == "guest_anon"


@pytest.mark.asyncio
async def test_get_me_user_vs_guest(client: httpx.AsyncClient):
    """GET /auth/me returns is_guest=False for authenticated user and is_guest=True for guest token."""
    # Authenticated user
    await client.post(
        "/api/v1/auth/email/request-otp",
        json={"email": "me_user@example.com"},
    )
    user_verify = await client.post(
        "/api/v1/auth/email/verify-otp",
        json={"email": "me_user@example.com", "code": "000000"},
    )
    user_token = user_verify.json()["access_token"]

    user_me_resp = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert user_me_resp.status_code == 200
    user_me_data = user_me_resp.json()
    assert user_me_data["is_guest"] is False
    assert user_me_data.get("email") == "me_user@example.com"

    # Guest token
    guest_auth = await client.post("/api/v1/auth/guest")
    guest_token = guest_auth.json()["access_token"]

    guest_me_resp = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {guest_token}"},
    )
    assert guest_me_resp.status_code == 200
    guest_me_data = guest_me_resp.json()
    assert guest_me_data["is_guest"] is True
    assert str(guest_me_data.get("id", "")).startswith("guest:")
    assert guest_me_data.get("email") is None
    assert guest_me_data.get("phone") is None
    assert (
        guest_me_data.get("anonymous_identity") == "guest_anon"
        or guest_me_data.get("anon_id") == "guest_anon"
    )


@pytest.mark.asyncio
async def test_guest_token_rejected_on_write_endpoints(client: httpx.AsyncClient):
    """Security check: Guest tokens receive HTTP 403 Forbidden on restricted write actions."""
    guest_auth = await client.post("/api/v1/auth/guest")
    guest_token = guest_auth.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    # 1. Create issue restricted
    res_create = await client.post(
        "/api/v1/issues",
        headers=guest_headers,
        json={
            "title": "Guest Test Issue",
            "description": "Guest attempting to create issue",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
    )
    assert res_create.status_code == 403
    create_body = res_create.json()
    assert create_body.get("code") == "guest_restricted" or "Sign in required" in str(create_body)

    # 2. Upvote issue restricted
    res_upvote = await client.post(
        "/api/v1/issues/1/upvote",
        headers=guest_headers,
    )
    assert res_upvote.status_code == 403
    upvote_body = res_upvote.json()
    assert upvote_body.get("code") == "guest_restricted" or "Sign in required" in str(upvote_body)

    # 3. Quorum vote restricted
    res_quorum = await client.post(
        "/api/v1/issues/1/quorum-vote",
        headers=guest_headers,
        json={
            "vote": "confirm",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
    )
    assert res_quorum.status_code == 403
    quorum_body = res_quorum.json()
    assert quorum_body.get("code") == "guest_restricted" or "Sign in required" in str(quorum_body)
