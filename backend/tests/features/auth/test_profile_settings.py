import httpx
import pytest


@pytest.mark.asyncio
async def test_get_me_authenticated_user(client: httpx.AsyncClient):
    """GET /auth/me for authenticated user returns user info, anon_id, is_guest=False, and activity stats."""
    await client.post(
        "/api/v1/auth/otp/request",
        json={"phone": "+919876543210"},
    )
    verify_resp = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "+919876543210", "code": "000000"},
    )
    assert verify_resp.status_code == 200
    token = verify_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()

    # Schema assertions
    assert "id" in data
    assert data["phone"] == "+919876543210"
    assert data.get("email") is None or isinstance(data.get("email"), str)
    assert "anonymous_identity" in data or "anon_id" in data
    assert "created_at" in data
    assert data["is_guest"] is False
    assert data["issues_count"] == 0
    assert data["upvotes_count"] == 0
    assert data["quorum_votes_count"] == 0


@pytest.mark.asyncio
async def test_get_me_email_authenticated_user(client: httpx.AsyncClient):
    """GET /auth/me for email authenticated user returns email and zeroed initial stats."""
    await client.post(
        "/api/v1/auth/email/request-otp",
        json={"email": "profile_test@example.com"},
    )
    verify_resp = await client.post(
        "/api/v1/auth/email/verify-otp",
        json={"email": "profile_test@example.com", "code": "000000"},
    )
    assert verify_resp.status_code == 200
    token = verify_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["email"] == "profile_test@example.com"
    assert data["is_guest"] is False
    assert data["issues_count"] == 0
    assert data["upvotes_count"] == 0
    assert data["quorum_votes_count"] == 0


@pytest.mark.asyncio
async def test_get_me_guest_user(client: httpx.AsyncClient):
    """GET /auth/me for guest user returns id ('guest:...'), phone=None, email=None, anon_id='guest_anon', is_guest=True, zeroed stats."""
    guest_auth = await client.post("/api/v1/auth/guest")
    assert guest_auth.status_code == 200
    guest_token = guest_auth.json()["access_token"]
    headers = {"Authorization": f"Bearer {guest_token}"}

    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert str(data["id"]).startswith("guest:")
    assert data["phone"] is None
    assert data["email"] is None
    assert data.get("anon_id") == "guest_anon" or data.get("anonymous_identity") == "guest_anon"
    assert data["is_guest"] is True
    assert data["issues_count"] == 0
    assert data["upvotes_count"] == 0
    assert data["quorum_votes_count"] == 0


@pytest.mark.asyncio
async def test_get_me_unauthenticated(client: httpx.AsyncClient):
    """GET /auth/me without authorization header returns 401 Unauthorized."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_invalid_token(client: httpx.AsyncClient):
    """GET /auth/me with invalid bearer token returns 401 Unauthorized."""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token_xyz"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_activity_stats_counts(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
):
    """GET /auth/me correctly reflects counts for issues created, upvotes cast, and quorum votes cast by user."""
    # User A (auth_headers) creates an issue
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Pothole on MG Road",
            "description": "Needs repair urgently",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201

    # User B creates an issue
    user_b_headers = await create_user_headers("+919876543999")
    issue_b_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken street light",
            "description": "Dark area at night",
            "category": "lighting",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=user_b_headers,
    )
    assert issue_b_res.status_code == 201
    issue_b_id = issue_b_res.json()["id"]

    # User A upvotes User B's issue
    upvote_res = await client.post(
        f"/api/v1/issues/{issue_b_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=auth_headers,
    )
    assert upvote_res.status_code == 200

    # User B submits resolution for issue_b
    resolve_res = await client.post(
        f"/api/v1/issues/{issue_b_id}/resolve",
        json={"resolution_proof": "https://example.com/proof.jpg", "notes": "Fixed light"},
        headers=user_b_headers,
    )
    assert resolve_res.status_code == 200

    # User A votes on quorum for issue_b
    quorum_res = await client.post(
        f"/api/v1/issues/{issue_b_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697, "reason": "Verified"},
        headers=auth_headers,
    )
    assert quorum_res.status_code == 200

    # User A checks /auth/me stats
    me_resp = await client.get("/api/v1/auth/me", headers=auth_headers)
    assert me_resp.status_code == 200
    data = me_resp.json()

    assert data["issues_count"] == 1
    assert data["upvotes_count"] == 1
    assert data["quorum_votes_count"] == 1
