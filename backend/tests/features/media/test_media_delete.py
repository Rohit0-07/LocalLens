"""Feature F-A (backend): media soft-delete.

Covers `DELETE /api/v1/media/{media_id}`:
  - owner may soft-delete (returns ``{"success": True}``, DB ``deleted_at`` is
    set, file is still served by ``GET /api/v1/media/files/...``),
  - deleting a missing media id returns 404,
  - a non-owner gets 403 ``forbidden``,
  - a guest gets 403 ``guest_restricted``,
  - an unauthenticated delete gets 401,
  - media linked to a published issue returns 409 ``media_linked_to_issue``.
"""

import base64
import uuid
from io import BytesIO

import httpx
import pytest
from app.features.media.models import Media
from PIL import Image

pytestmark = pytest.mark.asyncio


def _make_jpeg_bytes() -> bytes:
    buffer = BytesIO()
    Image.new("RGB", (64, 64), color=(40, 90, 130)).save(buffer, format="JPEG")
    return buffer.getvalue()


async def _upload_media(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    *,
    lat: float | None = 19.1136,
    lng: float | None = 72.8697,
    is_in_app_camera: bool = True,
) -> dict:
    """Upload a media item the same way the in-app camera flow does."""
    b64 = base64.b64encode(_make_jpeg_bytes()).decode("utf-8")
    payload: dict = {"base64_payload": b64, "is_in_app_camera": is_in_app_camera}
    if lat is not None:
        payload["captured_lat"] = lat
    if lng is not None:
        payload["captured_lng"] = lng
    res = await client.post("/api/v1/media/upload", json=payload, headers=headers)
    assert res.status_code == 201, res.text
    return res.json()


async def _media_row(app, media_id: str) -> Media | None:
    async with app.state.database.session_factory() as session:
        return await session.get(Media, media_id)


async def test_user_can_soft_delete_own_media(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Owner delete returns success, sets deleted_at, and keeps the file served."""
    data = await _upload_media(client, auth_headers)
    media_id = data["id"]
    url = data["url"]

    # File is served before deletion
    before = await client.get(url)
    assert before.status_code == 200

    res = await client.delete(f"/api/v1/media/{media_id}", headers=auth_headers)
    assert res.status_code == 200
    assert res.json() == {"success": True}

    # DB row is soft-deleted: row still exists, deleted_at is set
    row = await _media_row(app, media_id)
    assert row is not None
    assert row.deleted_at is not None

    # Soft delete: the file is still served by the files endpoint
    after = await client.get(url)
    assert after.status_code == 200
    assert after.content == before.content


async def test_delete_missing_media_returns_404(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Deleting a random (non-existent) media id returns 404."""
    res = await client.delete(f"/api/v1/media/{uuid.uuid4()}", headers=auth_headers)
    assert res.status_code == 404


async def test_delete_other_users_media_returns_403(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    """User B cannot delete user A's media (403 forbidden)."""
    owner = await create_user_headers("+919876543210")
    other = await create_user_headers("+919876543211")
    data = await _upload_media(client, owner)

    res = await client.delete(f"/api/v1/media/{data['id']}", headers=other)
    assert res.status_code == 403
    body = res.json()
    assert body.get("code") == "forbidden" or body.get("error_code") == "forbidden"


async def test_delete_guest_media_returns_403_guest_restricted(
    client: httpx.AsyncClient,
) -> None:
    """A guest cannot delete media, not even their own (403 guest_restricted)."""
    guest_res = await client.post("/api/v1/auth/guest")
    assert guest_res.status_code == 200
    guest_headers = {"Authorization": f"Bearer {guest_res.json()['access_token']}"}

    data = await _upload_media(client, guest_headers)

    res = await client.delete(f"/api/v1/media/{data['id']}", headers=guest_headers)
    assert res.status_code == 403
    body = res.json()
    assert (
        body.get("code") == "guest_restricted"
        or body.get("error_code") == "guest_restricted"
    )


async def test_delete_without_auth_returns_401(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """An unauthenticated DELETE request returns 401."""
    data = await _upload_media(client, auth_headers)

    res = await client.delete(f"/api/v1/media/{data['id']}")
    assert res.status_code == 401


async def test_delete_media_linked_to_published_issue_returns_409(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Media attached to a published issue cannot be deleted (409 media_linked_to_issue)."""
    m1 = await _upload_media(client, auth_headers)
    m2 = await _upload_media(client, auth_headers)

    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Deep pothole near the bus stop",
            "description": "Three tires punctured this week",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
            "media_urls": [m1["url"], m2["url"]],
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201, issue_res.text

    for media in (m1, m2):
        res = await client.delete(f"/api/v1/media/{media['id']}", headers=auth_headers)
        assert res.status_code == 409
        body = res.json()
        code = body.get("code") or ""
        assert code == "media_linked_to_issue"
