import datetime

import httpx
import pytest
from app.features.issues.models import Issue
from sqlalchemy import update

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Cursor test issue",
    "description": "Same timestamp test",
    "category": "road",
    "latitude": 19.1136,
    "longitude": 72.8697,
    "is_anonymous": False,
}


async def _create_issue(client: httpx.AsyncClient, headers, idx: int) -> dict:
    payload = {**_ISSUE_PAYLOAD, "title": f"Cursor test issue {idx}"}
    resp = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert resp.status_code == 201, resp.text
    return resp.json()


async def test_feed_keyset_does_not_drop_same_timestamp_items(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """3 issues with identical created_at must paginate without loss via (created_at,id) keyset."""
    # Create 3 issues
    ids = []
    for i in range(3):
        data = await _create_issue(client, auth_headers, i)
        ids.append(data["id"])

    # Force identical created_at via DB
    fixed_dt = datetime.datetime(2026, 1, 1, 12, 0, 0)
    async with app.state.database.session_factory() as session:
        await session.execute(update(Issue).where(Issue.id.in_(ids)).values(created_at=fixed_dt))
        await session.commit()

    # Fetch feed page by page using cursor "<iso>|<id>"
    # First page limit=1
    first = await client.get("/api/v1/feed", params={"type": "issue", "limit": 1})
    assert first.status_code == 200, first.text
    first_items = first.json()
    assert len(first_items) == 1
    first_id = first_items[0]["id"]
    first_created = first_items[0]["created_at"]

    # Second page using cursor from first
    cursor1 = f"{first_created}|{first_id}"
    second = await client.get("/api/v1/feed", params={"type": "issue", "limit": 1, "cursor": cursor1})
    assert second.status_code == 200
    second_items = second.json()
    assert len(second_items) == 1
    second_id = second_items[0]["id"]
    assert second_id != first_id

    # Third page
    second_created = second_items[0]["created_at"]
    cursor2 = f"{second_created}|{second_id}"
    third = await client.get("/api/v1/feed", params={"type": "issue", "limit": 1, "cursor": cursor2})
    assert third.status_code == 200
    third_items = third.json()
    assert len(third_items) == 1
    third_id = third_items[0]["id"]
    assert third_id not in (first_id, second_id)

    all_three = {first_id, second_id, third_id}
    assert all_three == set(ids)

    # Bare ISO cursor (no id) should still return items strictly before timestamp (i.e. none in this setup, since all share same ts)
    # So using only iso should return 0 because all items are at same ts and strict < excludes them
    bare = await client.get("/api/v1/feed", params={"type": "issue", "limit": 10, "cursor": first_created})
    assert bare.status_code == 200
    # bare cursor with no id should not include any of the 3 (since they are all at same ts)
    bare_ids = {i["id"] for i in bare.json()}
    assert bare_ids.isdisjoint(set(ids)) or len(bare_ids) == 0  # no same-ts items returned


async def test_list_issues_near_keyset_directly(app, client: httpx.AsyncClient, auth_headers):
    """Direct service level: list_issues_near with created_before_id tie-breaker."""
    from app.features.issues.service import list_issues_near

    # Create 3 issues and force same timestamp
    ids = []
    for i in range(3):
        data = await _create_issue(client, auth_headers, 10 + i)
        ids.append(data["id"])
    fixed_dt = datetime.datetime(2026, 1, 2, 12, 0, 0)
    async with app.state.database.session_factory() as session:
        await session.execute(update(Issue).where(Issue.id.in_(ids)).values(created_at=fixed_dt))
        await session.commit()

    async with app.state.database.session_factory() as session:
        # First fetch: no cursor -> gets all 3 ordered desc (id desc)
        all_items = await list_issues_near(
            session, latitude=19.1136, longitude=72.8697, radius_km=5, status_filter=None, limit=10, offset=0
        )
        # Filter to only our 3 ids (other seeded issues may exist but have different ts)
        our = [it for it in all_items if it.id in ids]
        assert len(our) == 3
        # They should be ordered by id desc since same timestamp
        assert our[0].id == max(ids)
        # Now fetch page after first item using keyset
        first = our[0]
        page2 = await list_issues_near(
            session,
            latitude=19.1136,
            longitude=72.8697,
            radius_km=5,
            status_filter=None,
            limit=10,
            offset=0,
            created_before=first.created_at,
            created_before_id=first.id,
        )
        page2_our = [it for it in page2 if it.id in ids]
        assert len(page2_our) == 2
        assert first.id not in {it.id for it in page2_our}
        # Ensure no duplicate
        assert len({it.id for it in page2_our}) == 2
