"""Feature F-A (backend): media <-> issue linking.

Covers:
  - creating an issue with ``media_urls`` links each Media row to the issue
    (``Media.issue_id`` is set),
  - linked media cannot be deleted (409) — this proves the linkage is enforced,
  - an issue created without media links nothing.
"""

import base64
from io import BytesIO

import httpx
import pytest
from app.features.media.models import Media
from PIL import Image
from sqlalchemy import select

pytestmark = pytest.mark.asyncio


async def _upload_media(client: httpx.AsyncClient, headers: dict[str, str]) -> dict:
    buffer = BytesIO()
    Image.new("RGB", (64, 64), color=(130, 40, 90)).save(buffer, format="JPEG")
    b64 = base64.b64encode(buffer.getvalue()).decode("utf-8")
    res = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64,
            "is_in_app_camera": True,
            "captured_lat": 19.11,
            "captured_lng": 72.87,
        },
        headers=headers,
    )
    assert res.status_code == 201, res.text
    return res.json()


async def _linked_media_rows(app, media_ids: list[str]) -> list[Media]:
    async with app.state.database.session_factory() as session:
        stmt = select(Media).where(Media.id.in_(media_ids))
        return (await session.execute(stmt)).scalars().all()


async def test_issue_links_uploaded_media(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Media listed in an issue's media_urls get issue_id set; delete is blocked."""
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
    issue_id = issue_res.json()["id"]

    rows = await _linked_media_rows(app, [m1["id"], m2["id"]])
    assert len(rows) == 2
    for row in rows:
        assert row.issue_id == issue_id

    # Follow-up DELETE returning 409 proves the linkage is enforced
    for media in (m1, m2):
        res = await client.delete(f"/api/v1/media/{media['id']}", headers=auth_headers)
        assert res.status_code == 409


async def test_issue_without_media_links_nothing(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """An issue created without media_urls links no Media rows."""
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Deep pothole near the bus stop",
            "description": "Three tires punctured this week",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201, issue_res.text
    issue_id = issue_res.json()["id"]

    async with app.state.database.session_factory() as session:
        stmt = select(Media).where(Media.issue_id == issue_id)
        rows = (await session.execute(stmt)).scalars().all()
    assert rows == []
