import httpx
import pytest

pytestmark = pytest.mark.asyncio


async def test_my_issues_empty_initially(client: httpx.AsyncClient, auth_headers: dict[str, str]):
    """GET /api/v1/auth/me/issues returns an empty list for a user with no reported issues."""
    response = await client.get("/api/v1/auth/me/issues", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == []


async def test_my_issues_returns_created_issues_with_media_and_reporter_id(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
):
    """GET /api/v1/auth/me/issues returns all issues reported by the user with media fields and reporter_id."""
    # User A creates a non-anonymous issue with media
    issue1_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken street lamp",
            "description": "Pitch dark street corner",
            "category": "lighting",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
            "media_urls": ["https://res.cloudinary.com/demo/image/upload/lamp.jpg"],
        },
        headers=auth_headers,
    )
    assert issue1_res.status_code == 201
    issue1_id = issue1_res.json()["id"]

    # User A creates an anonymous issue with media_url & video_url
    issue2_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Water pipeline leakage",
            "description": "High water loss on main street",
            "category": "water",
            "latitude": 19.1140,
            "longitude": 72.8700,
            "is_anonymous": True,
            "media_url": "https://res.cloudinary.com/demo/image/upload/water.jpg",
            "video_url": "https://res.cloudinary.com/demo/video/upload/water.mp4",
        },
        headers=auth_headers,
    )
    assert issue2_res.status_code == 201
    issue2_id = issue2_res.json()["id"]

    # User B creates an issue (should NOT be returned in User A's /me/issues)
    user_b_headers = await create_user_headers("+919876540001")
    issue_b_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Illegal dumping",
            "description": "Garbage near school",
            "category": "sanitation",
            "latitude": 19.1150,
            "longitude": 72.8710,
            "is_anonymous": False,
        },
        headers=user_b_headers,
    )
    assert issue_b_res.status_code == 201
    issue_b_id = issue_b_res.json()["id"]

    # User A fetches /me/issues
    response = await client.get("/api/v1/auth/me/issues", headers=auth_headers)
    assert response.status_code == 200
    issues = response.json()
    assert len(issues) == 2
    issue_ids = [i["id"] for i in issues]
    assert issue1_id in issue_ids
    assert issue2_id in issue_ids
    assert issue_b_id not in issue_ids

    # Verify order is desc by created_at
    assert issues[0]["id"] == issue2_id
    assert issues[1]["id"] == issue1_id

    # Verify media fields
    item1 = next(i for i in issues if i["id"] == issue1_id)
    assert "https://res.cloudinary.com/demo/image/upload/lamp.jpg" in item1["media_urls"]
    assert item1["reporter_id"] is not None

    item2 = next(i for i in issues if i["id"] == issue2_id)
    assert "https://res.cloudinary.com/demo/image/upload/water.jpg" in item2["media_urls"]
    assert "https://res.cloudinary.com/demo/video/upload/water.mp4" in item2["media_urls"]
    assert item2["video_url"] == "https://res.cloudinary.com/demo/video/upload/water.mp4"


async def test_my_issues_status_filter(client: httpx.AsyncClient, auth_headers: dict[str, str]):
    """GET /api/v1/auth/me/issues filters by status query parameter."""
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Open Manhole Cover",
            "description": "Dangerous for vehicles and walkers",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201
    issue_id = issue_res.json()["id"]

    # Filter unacknowledged
    resp_unack = await client.get("/api/v1/auth/me/issues?status=unacknowledged", headers=auth_headers)
    assert resp_unack.status_code == 200
    assert any(i["id"] == issue_id for i in resp_unack.json())

    # Filter resolved (should be empty for this issue)
    resp_res = await client.get("/api/v1/auth/me/issues?status=resolved", headers=auth_headers)
    assert resp_res.status_code == 200
    assert not any(i["id"] == issue_id for i in resp_res.json())


async def test_my_issues_pagination_limit_offset(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """GET /api/v1/auth/me/issues supports limit and offset parameters."""
    created_ids = []
    for i in range(4):
        res = await client.post(
            "/api/v1/issues",
            json={
                "title": f"Pagination Issue {i + 1}",
                "description": f"Description {i + 1}",
                "category": "other",
                "latitude": 19.1136,
                "longitude": 72.8697,
            },
            headers=auth_headers,
        )
        assert res.status_code == 201
        created_ids.append(res.json()["id"])

    # Page 1: limit 2, offset 0
    p1 = await client.get("/api/v1/auth/me/issues?limit=2&offset=0", headers=auth_headers)
    assert p1.status_code == 200
    p1_data = p1.json()
    assert len(p1_data) == 2

    # Page 2: limit 2, offset 2
    p2 = await client.get("/api/v1/auth/me/issues?limit=2&offset=2", headers=auth_headers)
    assert p2.status_code == 200
    p2_data = p2.json()
    assert len(p2_data) == 2

    # Ensure no overlap between page 1 and page 2
    p1_ids = {i["id"] for i in p1_data}
    p2_ids = {i["id"] for i in p2_data}
    assert p1_ids.isdisjoint(p2_ids)


async def test_my_issues_has_upvoted_state(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """GET /api/v1/auth/me/issues accurately returns has_upvoted flag for reported issues."""
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Traffic signal malfunction",
            "description": "Signal is stuck on red",
            "category": "traffic",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    # Before upvoting
    my_issues = await client.get("/api/v1/auth/me/issues", headers=auth_headers)
    assert my_issues.status_code == 200
    item = next(i for i in my_issues.json() if i["id"] == issue_id)
    assert item["has_upvoted"] is False

    # Upvote the issue
    upvote_res = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=auth_headers,
    )
    assert upvote_res.status_code == 200

    # After upvoting
    my_issues_after = await client.get("/api/v1/auth/me/issues", headers=auth_headers)
    assert my_issues_after.status_code == 200
    item_after = next(i for i in my_issues_after.json() if i["id"] == issue_id)
    assert item_after["has_upvoted"] is True
    assert item_after["upvotes_count"] == 1


async def test_my_issues_guest_and_unauthorized(client: httpx.AsyncClient):
    """GET /api/v1/auth/me/issues returns 401 unauth and empty list for guests."""
    # Unauthenticated -> 401
    unauth_resp = await client.get("/api/v1/auth/me/issues")
    assert unauth_resp.status_code == 401

    # Guest user -> returns []
    guest_auth = await client.post("/api/v1/auth/guest")
    assert guest_auth.status_code == 200
    guest_token = guest_auth.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    guest_issues = await client.get("/api/v1/auth/me/issues", headers=guest_headers)
    assert guest_issues.status_code == 200
    assert guest_issues.json() == []


async def test_issues_my_alias_endpoint(client: httpx.AsyncClient, auth_headers: dict[str, str]):
    """GET /api/v1/issues/my alias endpoint works identically to /api/v1/auth/me/issues."""
    res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Fallen tree branch",
            "description": "Blocking side lane",
            "category": "parks",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = res.json()["id"]

    alias_resp = await client.get("/api/v1/issues/my", headers=auth_headers)
    assert alias_resp.status_code == 200
    assert any(i["id"] == issue_id for i in alias_resp.json())


async def test_public_user_profile_structure_and_stats(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
):
    """GET /api/v1/auth/users/{user_id} returns complete PublicUserProfileOut."""
    me_resp = await client.get("/api/v1/auth/me", headers=auth_headers)
    user_id = me_resp.json()["id"]

    # User creates 1 public issue and 1 anonymous issue
    await client.post(
        "/api/v1/issues",
        json={
            "title": "Public Pothole Issue",
            "description": "Large road defect",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    await client.post(
        "/api/v1/issues",
        json={
            "title": "Private Anonymous Issue",
            "description": "Sensitive report",
            "category": "sanitation",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": True,
        },
        headers=auth_headers,
    )

    # Another user fetches User A's public profile
    user_b_headers = await create_user_headers("+919876540002")
    profile_resp = await client.get(f"/api/v1/auth/users/{user_id}", headers=user_b_headers)
    assert profile_resp.status_code == 200
    data = profile_resp.json()

    # Field assertions
    assert data["id"] == user_id
    assert "anon_id" in data
    assert data["role"] in ("citizen", "representative", "admin")
    assert isinstance(data["is_verified"], bool)
    assert "ward" in data
    assert "created_at" in data
    assert data["issues_count"] == 2
    assert data["resolutions_count"] == 0
    assert isinstance(data["upvotes_count"], int)
    assert isinstance(data["quorum_votes_count"], int)
    assert data["level"] >= 1
    assert data["impact_score"] >= 0
    assert isinstance(data["badges"], list)

    # Privacy verification: only public (non-anonymous) issue is in public_issues list!
    assert len(data["public_issues"]) == 1
    assert data["public_issues"][0]["title"] == "Public Pothole Issue"
    assert data["public_issues"][0]["is_anonymous"] is False


async def test_public_user_profile_without_auth_headers(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """GET /api/v1/auth/users/{user_id} and /api/v1/users/{user_id} are publicly accessible."""
    me_resp = await client.get("/api/v1/auth/me", headers=auth_headers)
    user_id = me_resp.json()["id"]

    # Public access on /auth/users/{user_id}
    res1 = await client.get(f"/api/v1/auth/users/{user_id}")
    assert res1.status_code == 200
    assert res1.json()["id"] == user_id

    # Public access on /users/{user_id} alias
    res2 = await client.get(f"/api/v1/users/{user_id}")
    assert res2.status_code == 200
    assert res2.json()["id"] == user_id


async def test_public_user_profile_not_found_returns_404(client: httpx.AsyncClient):
    """GET /api/v1/auth/users/{user_id} returns 404 for nonexistent user ID."""
    response = await client.get("/api/v1/auth/users/99999")
    assert response.status_code == 404
