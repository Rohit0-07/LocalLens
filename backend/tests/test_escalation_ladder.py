from datetime import UTC, datetime, timedelta

import httpx
from app.features.issues.models import Issue


async def test_escalation_unacknowledged_to_escalating_after_24h(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Damaged water pipe wasting water",
            "category": "water",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]
    assert create_res.json()["status"] == "unacknowledged"

    # Simulate 25 hours elapsed since creation
    async with app.state.database.session_factory() as session:
        issue = await session.get(Issue, issue_id)
        assert issue is not None
        issue.created_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=25)
        await session.commit()

    # Fetching the issue triggers status evaluation
    get_res = await client.get(f"/api/v1/issues/{issue_id}")
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "escalating"


async def test_representative_acknowledgment_status_change(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Hazardous electrical wire hanging low",
            "category": "power",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]
    assert create_res.json()["status"] == "unacknowledged"

    ack_res = await client.post(f"/api/v1/issues/{issue_id}/acknowledge", headers=auth_headers)
    assert ack_res.status_code == 200
    ack_data = ack_res.json()
    assert ack_data["status"] == "under_review"
    assert ack_data["acknowledged_at"] is not None


async def test_escalation_under_review_to_forwarded_after_7d(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Fallen tree blocking street",
            "category": "safety",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    await client.post(f"/api/v1/issues/{issue_id}/acknowledge", headers=auth_headers)

    # Simulate 8 days elapsed since acknowledgment
    async with app.state.database.session_factory() as session:
        issue = await session.get(Issue, issue_id)
        assert issue is not None
        issue.acknowledged_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(days=8)
        await session.commit()

    get_res = await client.get(f"/api/v1/issues/{issue_id}")
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "forwarded"


async def test_escalation_evaluation_trigger_batch_updates(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    # Issue 1: Recent unacknowledged (2 hours old)
    res1 = await client.post(
        "/api/v1/issues",
        json={
            "title": "Recent issue",
            "category": "other",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    id1 = res1.json()["id"]

    # Issue 2: Old unacknowledged (30 hours old) -> should escalate
    res2 = await client.post(
        "/api/v1/issues",
        json={
            "title": "Old unacknowledged issue",
            "category": "other",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    id2 = res2.json()["id"]

    # Issue 3: Old under review (10 days old) -> should forward
    res3 = await client.post(
        "/api/v1/issues",
        json={
            "title": "Old acknowledged issue",
            "category": "other",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    id3 = res3.json()["id"]
    await client.post(f"/api/v1/issues/{id3}/acknowledge", headers=auth_headers)

    # Age issues in DB
    async with app.state.database.session_factory() as session:
        issue2 = await session.get(Issue, id2)
        assert issue2 is not None
        issue2.created_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(hours=30)

        issue3 = await session.get(Issue, id3)
        assert issue3 is not None
        issue3.acknowledged_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(days=10)
        await session.commit()

    trigger_res = await client.post("/api/v1/issues/evaluate-escalations")
    assert trigger_res.status_code == 200
    assert trigger_res.json()["updated"] == 2

    g1 = await client.get(f"/api/v1/issues/{id1}")
    assert g1.json()["status"] == "unacknowledged"

    g2 = await client.get(f"/api/v1/issues/{id2}")
    assert g2.json()["status"] == "escalating"

    g3 = await client.get(f"/api/v1/issues/{id3}")
    assert g3.json()["status"] == "forwarded"
