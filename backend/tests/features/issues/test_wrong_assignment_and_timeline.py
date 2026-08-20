import httpx
import pytest
import pytest_asyncio
from fastapi import FastAPI
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def admin_headers(client: httpx.AsyncClient, app: FastAPI) -> dict[str, str]:
    """Fixture providing authentication headers for an admin user."""
    admin_phone = "+919999900099"
    await client.post("/api/v1/auth/otp/request", json={"phone": admin_phone})
    res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": admin_phone, "code": "000000"}
    )
    assert res.status_code == 200, res.text
    token = res.json()["access_token"]

    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE users SET is_admin = 1, role = 'admin' WHERE phone = :phone"),
            {"phone": admin_phone},
        )
        await session.commit()

    return {"Authorization": f"Bearer {token}"}


async def _create_issue(
    client: httpx.AsyncClient, headers: dict[str, str], **overrides: object
) -> dict:
    payload = {
        "title": "Water pipeline leakage near station",
        "description": "Clean water overflowing onto the road for 3 days",
        "category": "water",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "is_anonymous": False,
        **overrides,
    }
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_report_wrong_assignment(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    response = await client.post(
        f"/api/v1/issues/{issue_id}/report-wrong-assignment",
        json={
            "suggested_ward": "Ward 12, Metro Corridor",
            "suggested_category": "sewage",
            "reason": "This issue is located on the boundary of Ward 12 and relates to sewage backflow.",
        },
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["issue_id"] == issue_id
    assert data["suggested_ward"] == "Ward 12, Metro Corridor"
    assert data["suggested_category"] == "sewage"
    assert "Ward 12" in data["reason"]


async def test_admin_reassign_issue(
    client: httpx.AsyncClient, auth_headers: dict[str, str], admin_headers: dict[str, str]
) -> None:
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    response = await client.post(
        f"/api/v1/admin/issues/{issue_id}/reassign",
        json={
            "ward": "Ward 12, Metro Corridor",
            "category": "power",
            "reason": "Corrected ward and department assignment after field verification",
        },
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["ward"] == "Ward 12, Metro Corridor"
    assert data["category"] == "power"


async def test_issue_timeline_events(
    client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    create_user_headers,
) -> None:
    # 1. Create issue
    issue = await _create_issue(client, auth_headers, title="Broken streetlight in Ward 45")
    issue_id = issue["id"]

    # 2. Submit resolution proof
    proof_res = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={
            "resolution_proof": "https://storage.example.com/proofs/fixed_light.jpg",
            "notes": "Replaced bulb and repaired wiring fixture",
        },
        headers=auth_headers,
    )
    assert proof_res.status_code == 200, proof_res.text

    # 3. Add confirmation vote
    voter1_headers = await create_user_headers("+919876599001")
    vote1 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={
            "vote": "confirm",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "reason": "Verified on my evening walk, light is working now",
        },
        headers=voter1_headers,
    )
    assert vote1.status_code == 200, vote1.text

    # 4. Fetch timeline
    timeline_res = await client.get(f"/api/v1/issues/{issue_id}/timeline")
    assert timeline_res.status_code == 200, timeline_res.text
    timeline = timeline_res.json()

    assert timeline["issue_id"] == issue_id
    assert len(timeline["events"]) >= 2
    event_types = [e["event_type"] for e in timeline["events"]]
    assert "reported" in event_types
    assert "proof_submitted" in event_types

    assert len(timeline["confirmations"]) == 1
    assert timeline["confirmations"][0]["vote"] == "confirm"
    assert timeline["confirmations"][0]["reason"] == "Verified on my evening walk, light is working now"


async def test_search_by_account_handle(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    u1_headers = await create_user_headers("+919876599002")
    # Update profile to set distinct username
    await client.patch(
        "/api/v1/auth/me",
        json={"username": "civic_hero_45"},
        headers=u1_headers,
    )
    await _create_issue(client, u1_headers, title="Deep crater pothole near highway")

    # Search by account
    res = await client.get("/api/v1/search", params={"account": "civic_hero_45"})
    assert res.status_code == 200, res.text
    issues = res.json()
    assert len(issues) >= 1
    assert any(i["title"] == "Deep crater pothole near highway" for i in issues)


async def test_search_with_filters_and_empty_query(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _create_issue(client, auth_headers, title="Unique Water Surge 9988", category="water")

    res = await client.get(
        "/api/v1/search",
        params={"category": "water", "q": ""},
        headers=auth_headers,
    )
    assert res.status_code == 200, res.text
    issues = res.json()
    assert any(i["title"] == "Unique Water Surge 9988" for i in issues)
