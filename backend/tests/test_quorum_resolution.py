from datetime import UTC, datetime, timedelta

import httpx
import pytest_asyncio
from app.features.issues.models import Issue
from fastapi import FastAPI
from sqlalchemy import text


@pytest_asyncio.fixture
async def admin_headers(client: httpx.AsyncClient, app: FastAPI) -> dict[str, str]:
    """Authentication headers for an admin user (see tests/features/issues/test_flagging.py)."""
    admin_phone = "+919999900009"
    await client.post("/api/v1/auth/otp/request", json={"phone": admin_phone})
    res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": admin_phone, "code": "000000"}
    )
    token = res.json()["access_token"]
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE users SET is_admin = 1, role = 'admin' WHERE phone = :phone"),
            {"phone": admin_phone},
        )
        await session.commit()
    return {"Authorization": f"Bearer {token}"}


async def test_quorum_resolution_confirmation_threshold(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    # 1. Create issue
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken storm drain cover on main junction",
            "category": "safety",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    # 2. Authority submits resolution
    resolve_res = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={
            "resolution_proof": "https://cdn.locallens.in/proofs/drain_fixed.jpg",
            "notes": "Replaced cover",
        },
        headers=auth_headers,
    )
    assert resolve_res.status_code == 200
    assert resolve_res.json()["status"] == "pending_quorum"
    assert (
        resolve_res.json()["resolution_proof"] == "https://cdn.locallens.in/proofs/drain_fixed.jpg"
    )

    # 3. Three neighbor confirmations
    u1_headers = await create_user_headers("+919000000001")
    u2_headers = await create_user_headers("+919000000002")
    u3_headers = await create_user_headers("+919000000003")

    vote1 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1140, "longitude": 72.8700},
        headers=u1_headers,
    )
    assert vote1.status_code == 200
    assert vote1.json()["status"] == "pending_quorum"
    assert vote1.json()["confirmations_count"] == 1

    vote2 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1138, "longitude": 72.8695},
        headers=u2_headers,
    )
    assert vote2.status_code == 200
    assert vote2.json()["status"] == "pending_quorum"
    assert vote2.json()["confirmations_count"] == 2

    vote3 = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=u3_headers,
    )
    assert vote3.status_code == 200
    res_data = vote3.json()
    assert res_data["status"] == "resolved"
    assert res_data["confirmations_count"] == 3
    assert res_data["resolved_at"] is not None


async def test_quorum_resolution_dispute_fallback(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Streetlight unserviceable near school",
            "category": "power",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://cdn.locallens.in/proofs/light_fixed.jpg"},
        headers=auth_headers,
    )

    disputer_headers = await create_user_headers("+919000000099")
    dispute_res = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={
            "vote": "dispute",
            "latitude": 19.1137,
            "longitude": 72.8698,
            "reason": "Light is still flickering and dark at night",
        },
        headers=disputer_headers,
    )
    assert dispute_res.status_code == 200
    data = dispute_res.json()
    assert data["status"] == "disputed"
    assert data["disputes_count"] == 1


async def test_quorum_vote_out_of_radius_rejection(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Water leakage from main pipe",
            "category": "water",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://cdn.locallens.in/proofs/leak_fixed.jpg"},
        headers=auth_headers,
    )

    far_user_headers = await create_user_headers("+919000000888")
    far_vote = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.3000, "longitude": 72.9500},
        headers=far_user_headers,
    )
    assert far_vote.status_code == 400
    assert far_vote.json()["code"] == "out_of_radius"


async def test_quorum_duplicate_vote_prevention(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Open manhole cover",
            "category": "safety",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://cdn.locallens.in/proofs/manhole.jpg"},
        headers=auth_headers,
    )

    voter_headers = await create_user_headers("+919000000777")
    first_vote = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert first_vote.status_code == 200

    second_vote = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert second_vote.status_code == 400
    assert second_vote.json()["code"] == "already_voted"


async def test_quorum_expiration_fallback(
    app, client: httpx.AsyncClient, auth_headers: dict[str, str], admin_headers: dict[str, str]
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken pavement tiles",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    resolve_res = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://cdn.locallens.in/proofs/tiles.jpg"},
        headers=auth_headers,
    )
    assert resolve_res.json()["status"] == "pending_quorum"

    # Manually expire the quorum in database
    async with app.state.database.session_factory() as session:
        issue = await session.get(Issue, issue_id)
        assert issue is not None
        issue.quorum_expires_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(days=1)
        await session.commit()

    # Missing token -> 401; authenticated non-admin -> 403 (admin/moderator only)
    anon_check = await client.post(f"/api/v1/issues/{issue_id}/check-quorum-status")
    assert anon_check.status_code == 401
    citizen_check = await client.post(
        f"/api/v1/issues/{issue_id}/check-quorum-status", headers=auth_headers
    )
    assert citizen_check.status_code == 403
    assert citizen_check.json()["error_code"] == "admin_required"

    check_res = await client.post(
        f"/api/v1/issues/{issue_id}/check-quorum-status", headers=admin_headers
    )
    assert check_res.status_code == 200
    assert check_res.json()["status"] == "disputed"
