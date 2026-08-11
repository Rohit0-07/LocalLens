"""Tests for F-10 Notifications & Inbox Engine feature according to API Specification.

Endpoints tested:
1. GET /api/v1/notifications?limit=20&offset=0&unread_only=false
2. POST /api/v1/notifications/read-all
3. PATCH /api/v1/notifications/{notification_id}/read
"""

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


async def _create_user(client: AsyncClient, phone: str) -> tuple[dict[str, str], int]:
    """Helper to register/verify a user and return auth headers + user_id."""
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    res = await client.post("/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})
    assert res.status_code == 200, res.text
    data = res.json()
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    return headers, data["user_id"]


async def _seed_notification(
    app,
    user_id: int,
    title: str = "Test Notification",
    body: str = "Test notification body text",
    n_type: str = "system_notice",
    reference_id: str | None = "ref-1001",
    is_read: bool = False,
) -> str:
    """Helper to insert a notification for a specific user into the database."""
    async with app.state.database.session_factory() as session:
        try:
            from app.features.notifications.models import Notification

            notif = Notification(
                user_id=user_id,
                title=title,
                body=body,
                type=n_type,
                reference_id=reference_id,
                is_read=is_read,
            )
            session.add(notif)
            await session.commit()
            await session.refresh(notif)
            return str(notif.id)
        except Exception:
            query = text(
                "INSERT INTO notifications (user_id, title, body, type, reference_id, is_read, created_at) "
                "VALUES (:user_id, :title, :body, :type, :reference_id, :is_read, :created_at) "
                "RETURNING id"
            )
            now_iso = datetime.now(UTC).isoformat()
            result = await session.execute(
                query,
                {
                    "user_id": user_id,
                    "title": title,
                    "body": body,
                    "type": n_type,
                    "reference_id": reference_id,
                    "is_read": is_read,
                    "created_at": now_iso,
                },
            )
            await session.commit()
            row = result.fetchone()
            return str(row[0]) if row else "1"


# --- 1. Authentication Guards ---


async def test_get_notifications_requires_auth(client: AsyncClient) -> None:
    """GET /notifications requires a valid Bearer token."""
    response = await client.get("/api/v1/notifications")
    assert response.status_code in (401, 403)


async def test_read_all_requires_auth(client: AsyncClient) -> None:
    """POST /notifications/read-all requires a valid Bearer token."""
    response = await client.post("/api/v1/notifications/read-all")
    assert response.status_code in (401, 403)


async def test_patch_read_requires_auth(client: AsyncClient) -> None:
    """PATCH /notifications/{id}/read requires a valid Bearer token."""
    response = await client.patch("/api/v1/notifications/1/read")
    assert response.status_code in (401, 403)


# --- 2. Empty State ---


async def test_get_notifications_empty_state(client: AsyncClient) -> None:
    """User with no notifications receives an empty list and unread_count=0."""
    headers, _ = await _create_user(client, "+919900112233")
    response = await client.get("/api/v1/notifications", headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()
    assert "items" in data
    assert data["items"] == []
    assert data["unread_count"] == 0


# --- 3. Notification Contract & Types ---


async def test_get_notifications_schema_and_types(app, client: AsyncClient) -> None:
    """Verify returned notification structure and supported notification types."""
    headers, user_id = await _create_user(client, "+919900112244")

    # Seed notifications of various types
    types = [
        ("escalation", "Issue Escalated", "High priority pothole escalated to Ward 4"),
        ("quorum_request", "Quorum Needed", "Community verification required"),
        ("upvote_milestone", "10 Upvotes Reached", "Your reported issue reached 10 upvotes"),
        ("comment_reply", "New Reply", "Someone replied to your comment"),
        ("system_notice", "Maintenance Notice", "Scheduled server maintenance tonight"),
    ]

    for n_type, title, body in types:
        await _seed_notification(
            app,
            user_id=user_id,
            title=title,
            body=body,
            n_type=n_type,
            reference_id="ref-xyz",
            is_read=False,
        )

    response = await client.get("/api/v1/notifications", headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()

    assert len(data["items"]) == 5
    assert data["unread_count"] == 5

    item = data["items"][0]
    assert "id" in item
    assert "title" in item
    assert "body" in item
    assert "type" in item
    assert "reference_id" in item
    assert "is_read" in item
    assert "created_at" in item
    assert item["is_read"] is False


# --- 4. User Isolation & Privacy Guard ---


async def test_notifications_user_isolation(app, client: AsyncClient) -> None:
    """User A cannot see or mark as read notifications belonging to User B."""
    user_a_headers, user_a_id = await _create_user(client, "+919900112255")
    user_b_headers, user_b_id = await _create_user(client, "+919900112266")

    user_a_notif_id = await _seed_notification(
        app, user_id=user_a_id, title="User A Private Alert", body="Secret for A"
    )
    user_b_notif_id = await _seed_notification(
        app, user_id=user_b_id, title="User B Private Alert", body="Secret for B"
    )

    # User A gets notifications -> only receives User A's notification
    res_a = await client.get("/api/v1/notifications", headers=user_a_headers)
    assert res_a.status_code == 200
    items_a = res_a.json()["items"]
    assert len(items_a) == 1
    assert str(items_a[0]["id"]) == str(user_a_notif_id)

    # User B gets notifications -> only receives User B's notification
    res_b = await client.get("/api/v1/notifications", headers=user_b_headers)
    assert res_b.status_code == 200
    items_b = res_b.json()["items"]
    assert len(items_b) == 1
    assert str(items_b[0]["id"]) == str(user_b_notif_id)

    # User B attempts to mark User A's notification as read -> 404 Not Found
    res_patch = await client.patch(
        f"/api/v1/notifications/{user_a_notif_id}/read", headers=user_b_headers
    )
    assert res_patch.status_code == 404


# --- 5. Filtering with unread_only parameter ---


async def test_unread_only_filter_parameter(app, client: AsyncClient) -> None:
    """Query parameter unread_only=true filters returned items to unread items only."""
    headers, user_id = await _create_user(client, "+919900112277")

    await _seed_notification(app, user_id=user_id, title="Read Alert", is_read=True)
    await _seed_notification(app, user_id=user_id, title="Unread Alert 1", is_read=False)
    await _seed_notification(app, user_id=user_id, title="Unread Alert 2", is_read=False)

    # unread_only=true
    res_unread = await client.get(
        "/api/v1/notifications", params={"unread_only": "true"}, headers=headers
    )
    assert res_unread.status_code == 200
    data_unread = res_unread.json()
    assert len(data_unread["items"]) == 2
    assert all(item["is_read"] is False for item in data_unread["items"])

    # unread_only=false
    res_all = await client.get(
        "/api/v1/notifications", params={"unread_only": "false"}, headers=headers
    )
    assert res_all.status_code == 200
    data_all = res_all.json()
    assert len(data_all["items"]) == 3


# --- 6. Pagination (limit and offset) ---


async def test_notifications_pagination(app, client: AsyncClient) -> None:
    """limit and offset query parameters page through the notification results."""
    headers, user_id = await _create_user(client, "+919900112288")

    for i in range(5):
        await _seed_notification(app, user_id=user_id, title=f"Notification #{i + 1}")

    # Page 1 (limit 2, offset 0)
    res_p1 = await client.get(
        "/api/v1/notifications", params={"limit": 2, "offset": 0}, headers=headers
    )
    assert res_p1.status_code == 200
    data_p1 = res_p1.json()
    assert len(data_p1["items"]) == 2

    # Page 2 (limit 2, offset 2)
    res_p2 = await client.get(
        "/api/v1/notifications", params={"limit": 2, "offset": 2}, headers=headers
    )
    assert res_p2.status_code == 200
    data_p2 = res_p2.json()
    assert len(data_p2["items"]) == 2

    # Page 3 (limit 2, offset 4)
    res_p3 = await client.get(
        "/api/v1/notifications", params={"limit": 2, "offset": 4}, headers=headers
    )
    assert res_p3.status_code == 200
    data_p3 = res_p3.json()
    assert len(data_p3["items"]) == 1

    # Ensure no overlap between page 1 and page 2 items
    p1_ids = {item["id"] for item in data_p1["items"]}
    p2_ids = {item["id"] for item in data_p2["items"]}
    assert p1_ids.isdisjoint(p2_ids)


# --- 7. Single Notification Read Action ---


async def test_patch_mark_single_notification_read(app, client: AsyncClient) -> None:
    """PATCH /notifications/{id}/read marks the notification as read and updates state."""
    headers, user_id = await _create_user(client, "+919900112299")

    notif_id = await _seed_notification(app, user_id=user_id, title="Unread Notice", is_read=False)

    res_patch = await client.patch(f"/api/v1/notifications/{notif_id}/read", headers=headers)
    assert res_patch.status_code == 200, res_patch.text
    updated = res_patch.json()
    assert updated["is_read"] is True

    # Re-fetch notifications list
    res_list = await client.get("/api/v1/notifications", headers=headers)
    assert res_list.status_code == 200
    data = res_list.json()
    assert data["unread_count"] == 0
    assert data["items"][0]["is_read"] is True


async def test_patch_nonexistent_notification_returns_404(
    client: AsyncClient,
) -> None:
    """PATCH /notifications/{id}/read with invalid ID returns 404 Not Found."""
    headers, _ = await _create_user(client, "+919900112200")
    res = await client.patch("/api/v1/notifications/99999999/read", headers=headers)
    assert res.status_code == 404


# --- 8. Batch Operation (read-all) ---


async def test_post_mark_all_notifications_read(app, client: AsyncClient) -> None:
    """POST /notifications/read-all marks all unread notifications for current user as read."""
    user_a_headers, user_a_id = await _create_user(client, "+919900113311")
    user_b_headers, user_b_id = await _create_user(client, "+919900113322")

    for i in range(3):
        await _seed_notification(app, user_id=user_a_id, title=f"User A Notif #{i}", is_read=False)

    for i in range(2):
        await _seed_notification(app, user_id=user_b_id, title=f"User B Notif #{i}", is_read=False)

    # User A calls read-all
    res_read_all = await client.post("/api/v1/notifications/read-all", headers=user_a_headers)
    assert res_read_all.status_code == 200, res_read_all.text
    body = res_read_all.json()
    assert body.get("status") == "ok"
    assert body.get("updated_count") == 3

    # User A GET shows 0 unread
    res_a = await client.get("/api/v1/notifications", headers=user_a_headers)
    data_a = res_a.json()
    assert data_a["unread_count"] == 0
    assert all(item["is_read"] is True for item in data_a["items"])

    # User B GET shows 2 unread (User B untouched)
    res_b = await client.get("/api/v1/notifications", headers=user_b_headers)
    data_b = res_b.json()
    assert data_b["unread_count"] == 2
