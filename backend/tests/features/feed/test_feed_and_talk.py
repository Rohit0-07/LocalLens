import pytest
from app.features.wards.service import talk_rate_limiter
from httpx import AsyncClient


@pytest.fixture(autouse=True)
def reset_rate_limiters():
    talk_rate_limiter.reset()


async def test_get_multi_type_feed(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    # 1. Create an issue
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Pothole on 5th street",
            "description": "Large hole causing traffic issues",
            "category": "roads",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201

    # 2. Query multi-type feed
    feed_res = await client.get(
        "/api/v1/feed",
        params={
            "latitude": 19.1136,
            "longitude": 72.8697,
            "radius_km": 5.0,
            "type": "all",
        },
    )
    assert feed_res.status_code == 200
    feed_items = feed_res.json()
    assert len(feed_items) >= 1
    assert feed_items[0]["item_type"] == "issue"


async def test_local_talk_post_creation_and_guest_guard(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    # Request without auth header (guest) should fail / 401 or 403
    guest_res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "Guest talk title",
            "body": "Guest talk body content",
            "topic": "General",
        },
    )
    assert guest_res.status_code in (401, 403)

    # Authenticated user creation should succeed
    talk_res = await client.post(
        "/api/v1/wards/ward-45-urban-central/talk",
        json={
            "title": "Is the water supply fixed?",
            "body": "No water since morning on Main road badword test.",
            "topic": "Q&A",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    assert talk_res.status_code == 200
    talk_data = talk_res.json()
    assert talk_data["ward_slug"] == "ward-45-urban-central"
    assert talk_data["topic"] == "Q&A"
    # Verify profanity sanitization
    assert "badword" not in talk_data["body"]
    assert "*******" in talk_data["body"]

    # Retrieve talk posts for ward
    list_res = await client.get("/api/v1/wards/ward-45-urban-central/talk")
    assert list_res.status_code == 200
    posts = list_res.json()
    assert len(posts) >= 1
    assert posts[0]["title"] == "Is the water supply fixed?"


async def test_win_auto_generation_on_quorum(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_user_headers,
) -> None:
    user2_headers = await create_user_headers("+919876543211")
    user3_headers = await create_user_headers("+919876543212")
    user4_headers = await create_user_headers("+919876543213")

    # Create issue
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken street light",
            "description": "Needs lamp replacement",
            "category": "lighting",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    # Submit resolution
    resolve_res = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={
            "resolution_proof": "http://example.com/after.jpg",
            "notes": "Replaced bulb and tested fixture",
        },
        headers=auth_headers,
    )
    assert resolve_res.status_code == 200
    assert resolve_res.json()["status"] == "pending_quorum"

    # Vote 1
    v1 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user2_headers,
    )
    assert v1.status_code == 200

    # Vote 2
    v2 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user3_headers,
    )
    assert v2.status_code == 200

    # Vote 3 (reaches quorum -> status resolved -> Win record auto-generated)
    v3 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=user4_headers,
    )
    assert v3.status_code == 200
    assert v3.json()["status"] == "resolved"

    # Query wins endpoint
    wins_res = await client.get(
        "/api/v1/wins",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0},
    )
    assert wins_res.status_code == 200
    wins = wins_res.json()
    assert len(wins) >= 1
    win_match = [w for w in wins if w["issue_id"] == issue_id]
    assert len(win_match) == 1
    assert "Resolved: Broken street light" in win_match[0]["title"]

    # Query single win endpoint
    win_id = win_match[0]["id"]
    single_win_res = await client.get(f"/api/v1/wins/{win_id}")
    assert single_win_res.status_code == 200
    assert single_win_res.json()["id"] == win_id
