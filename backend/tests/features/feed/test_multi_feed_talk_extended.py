import pytest
from app.features.wards.models import Notice
from app.features.wards.service import talk_rate_limiter
from httpx import AsyncClient


@pytest.fixture(autouse=True)
def reset_rate_limiters():
    talk_rate_limiter.reset()


@pytest.mark.asyncio
async def test_multi_type_feed_filtering(
    client: AsyncClient,
    auth_headers: dict[str, str],
    app,
) -> None:
    """Test GET /api/v1/feed with type=all, type=issue, type=win, type=notice, type=local_talk."""
    # 1. Create issue
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Multi-Feed Test Pothole",
            "description": "Large hole causing traffic issues",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201

    # 2. Create local talk post
    talk_res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "Water supply question",
            "body": "When will maintenance end?",
            "topic": "Water",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    assert talk_res.status_code == 200

    # 3. Seed a Notice directly into DB
    async with app.state.database.session_factory() as session:
        notice = Notice(
            title="Scheduled Power Cut",
            description="Electricity will be off on Sunday 10am-2pm",
            official_header="MUNICIPAL POWER BOARD",
            ward="Ward 45, Urban Central",
            latitude=19.1136,
            longitude=72.8697,
        )
        session.add(notice)
        await session.commit()

    # 4. Test type=all
    res_all = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "all"},
    )
    assert res_all.status_code == 200
    all_items = res_all.json()
    item_types = {item["item_type"] for item in all_items}
    assert "issue" in item_types
    assert "local_talk" in item_types
    assert "notice" in item_types

    # 5. Test type=issue
    res_issue = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "issue"},
    )
    assert res_issue.status_code == 200
    issue_items = res_issue.json()
    assert len(issue_items) >= 1
    assert all(item["item_type"] == "issue" for item in issue_items)

    # 6. Test type=notice
    res_notice = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "notice"},
    )
    assert res_notice.status_code == 200
    notice_items = res_notice.json()
    assert len(notice_items) >= 1
    assert all(item["item_type"] == "notice" for item in notice_items)

    # 7. Test type=local_talk
    res_talk = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "local_talk"},
    )
    assert res_talk.status_code == 200
    talk_items = res_talk.json()
    assert len(talk_items) >= 1
    assert all(item["item_type"] == "local_talk" for item in talk_items)

    # 8. Test type=win
    res_win = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "win"},
    )
    assert res_win.status_code == 200
    win_items = res_win.json()
    assert all(item["item_type"] == "win" for item in win_items)


@pytest.mark.asyncio
async def test_win_auto_generation_on_quorum(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_user_headers,
) -> None:
    """Verify casting 3rd quorum confirm vote automatically generates a Win post with photos & credits."""
    user2_headers = await create_user_headers("+919876543221")
    user3_headers = await create_user_headers("+919876543222")
    user4_headers = await create_user_headers("+919876543223")

    # Create issue
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Fallen tree on 3rd main road",
            "description": "Blocking traffic and driveway",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert create_res.status_code == 201
    issue_id = create_res.json()["id"]

    # Submit resolution
    resolve_res = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={
            "resolution_proof": "http://example.com/tree_removed.jpg",
            "notes": "Tree cleared by municipal worker crew",
        },
        headers=auth_headers,
    )
    assert resolve_res.status_code == 200
    assert resolve_res.json()["status"] == "pending_quorum"

    # Quorum Vote 1
    v1 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user2_headers,
    )
    assert v1.status_code == 200

    # Quorum Vote 2
    v2 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user3_headers,
    )
    assert v2.status_code == 200

    # Quorum Vote 3 (Reaches 3 confirm votes -> triggers status=resolved & win generation)
    v3 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user4_headers,
    )
    assert v3.status_code == 200
    assert v3.json()["status"] == "resolved"

    # Query wins endpoint & feed
    wins_res = await client.get(
        "/api/v1/wins",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0},
    )
    assert wins_res.status_code == 200
    wins = wins_res.json()
    matched_win = [w for w in wins if w["issue_id"] == issue_id]
    assert len(matched_win) == 1
    win = matched_win[0]
    assert "Resolved: Fallen tree on 3rd main road" in win["title"]
    assert win["after_image_url"] == "http://example.com/tree_removed.jpg"
    assert isinstance(win["contributor_credits"], list)
    assert len(win["contributor_credits"]) > 0


@pytest.mark.asyncio
async def test_local_talk_creation_and_profanity_filter(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Test POST /api/v1/wards/{ward_slug}/talk sanitizes offensive words in title/body."""
    talk_res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "Toxic abuse in neighborhood",
            "body": "Is this badword and scam taking place? hate everywhere.",
            "topic": "General",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    assert talk_res.status_code == 200
    data = talk_res.json()
    assert "toxic" not in data["title"].lower()
    assert "abuse" not in data["title"].lower()
    assert "*****" in data["title"]
    assert "badword" not in data["body"].lower()
    assert "scam" not in data["body"].lower()
    assert "hate" not in data["body"].lower()
    assert "*******" in data["body"]
    assert "****" in data["body"]


@pytest.mark.asyncio
async def test_local_talk_guest_restriction(client: AsyncClient) -> None:
    """Test 403 Forbidden when guest user attempts to create a Local Talk post."""
    guest_auth = await client.post("/api/v1/auth/guest")
    assert guest_auth.status_code == 200
    guest_token = guest_auth.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "Guest trying to post talk",
            "body": "Guest talk content should be denied",
            "topic": "General",
        },
        headers=guest_headers,
    )
    assert res.status_code == 403
    body = res.json()
    assert body.get("code") == "guest_restricted" or "Sign in required" in str(body)


@pytest.mark.asyncio
async def test_local_talk_rate_limiting(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    """Test rate limit (10 posts per 5 min)."""
    talk_rate_limiter.reset()

    for i in range(10):
        res = await client.post(
            "/api/v1/wards/ward-45-urban-central/talk",
            json={
                "title": f"Valid talk post {i}",
                "body": f"Talking about neighborhood topic {i}",
                "topic": "General",
            },
            headers=auth_headers,
        )
        assert res.status_code == 200, f"Expected post {i} to succeed"

    # 11th post should be rate limited
    limit_res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "11th talk post",
            "body": "This post should trigger 429 Rate limit",
            "topic": "General",
        },
        headers=auth_headers,
    )
    assert limit_res.status_code == 429
    data = limit_res.json()
    assert data.get("code") == "rate_limited" or "Rate limit exceeded" in str(data)


@pytest.mark.asyncio
async def test_feed_shielded_non_resolved_exclusion(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_user_headers,
) -> None:
    """Verify shielded non-resolved issues are omitted from /api/v1/feed."""
    # 1. Create a public issue
    public_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Public Visible Issue",
            "description": "Standard public issue report",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_shielded": False,
        },
        headers=auth_headers,
    )
    assert public_res.status_code == 201

    # 2. Create a shielded non-resolved issue
    shielded_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Shielded Private Issue",
            "description": "Shielded sensitive issue report",
            "category": "safety",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_shielded": True,
        },
        headers=auth_headers,
    )
    assert shielded_res.status_code == 201
    shielded_id = shielded_res.json()["id"]

    # 3. Query feed -> Shielded issue must NOT appear
    feed_res1 = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "issue"},
    )
    assert feed_res1.status_code == 200
    feed_titles1 = [i["title"] for i in feed_res1.json()]
    assert "Public Visible Issue" in feed_titles1
    assert "Shielded Private Issue" not in feed_titles1

    # 4. Resolve the shielded issue
    user2_headers = await create_user_headers("+919876543231")
    user3_headers = await create_user_headers("+919876543232")
    user4_headers = await create_user_headers("+919876543233")

    await client.post(
        f"/api/v1/issues/{shielded_id}/resolve",
        json={"resolution_proof": "http://example.com/proof.jpg", "notes": "Fixed"},
        headers=auth_headers,
    )
    await client.post(
        f"/api/v1/issues/{shielded_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user2_headers,
    )
    await client.post(
        f"/api/v1/issues/{shielded_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user3_headers,
    )
    await client.post(
        f"/api/v1/issues/{shielded_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user4_headers,
    )

    # 5. Query feed again -> Resolved shielded issue MUST now be included
    feed_res2 = await client.get(
        "/api/v1/feed",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0, "type": "issue"},
    )
    assert feed_res2.status_code == 200
    feed_titles2 = [i["title"] for i in feed_res2.json()]
    assert "Shielded Private Issue" in feed_titles2
