import httpx
import pytest
from sqlalchemy.exc import IntegrityError

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Dedup vote test issue",
    "description": "Verify unique constraint prevents duplicate votes",
    "category": "road",
    "latitude": 19.1136,
    "longitude": 72.8697,
    "is_anonymous": False,
}


async def _create_issue(client: httpx.AsyncClient, headers: dict[str, str]) -> dict:
    resp = await client.post("/api/v1/issues", json=_ISSUE_PAYLOAD, headers=headers)
    assert resp.status_code == 201, resp.text
    return resp.json()


async def test_upvote_unique_constraint_at_db_level(app, client: httpx.AsyncClient, auth_headers: dict[str, str]) -> None:
    """DB enforces UniqueConstraint(issue_id, user_id) on upvotes — raw duplicate insert raises IntegrityError."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # create voter via OTP flow and get user_id from token response
    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876509991"})
    ver = await client.post("/api/v1/auth/otp/verify", json={"phone": "+919876509991", "code": "000000"})
    voter_id = ver.json()["user_id"]

    from app.features.issues.models import Upvote

    async with app.state.database.session_factory() as session:
        session.add(Upvote(issue_id=issue_id, user_id=voter_id))
        await session.commit()
        # duplicate insert must violate unique constraint
        session.add(Upvote(issue_id=issue_id, user_id=voter_id))
        with pytest.raises(IntegrityError):
            await session.commit()
        await session.rollback()


async def test_quorum_vote_unique_constraint_at_db_level(app, client: httpx.AsyncClient, auth_headers: dict[str, str]) -> None:
    """DB enforces UniqueConstraint(issue_id, user_id) on quorum_votes."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # Put issue into pending_quorum via acknowledge + resolve
    await client.post(f"/api/v1/issues/{issue_id}/acknowledge", headers=auth_headers)
    await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://example.com/proof.jpg", "notes": "fixed"},
        headers=auth_headers,
    )

    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876509992"})
    ver = await client.post("/api/v1/auth/otp/verify", json={"phone": "+919876509992", "code": "000000"})
    voter_id = ver.json()["user_id"]

    from app.features.issues.models import QuorumVote

    async with app.state.database.session_factory() as session:
        session.add(QuorumVote(issue_id=issue_id, user_id=voter_id, vote="confirm"))
        await session.commit()
        session.add(QuorumVote(issue_id=issue_id, user_id=voter_id, vote="confirm"))
        with pytest.raises(IntegrityError):
            await session.commit()
        await session.rollback()


async def test_duplicate_upvote_counter_increments_once(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """API duplicate upvote returns 400 and counter increments exactly once (atomic update)."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    voter = await create_user_headers("+919876509993")
    first = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )
    assert first.status_code == 200
    assert first.json()["upvotes_count"] == 1

    second = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )
    assert second.status_code == 400
    assert second.json().get("code") == "already_upvoted"

    # counter still 1
    get = await client.get(f"/api/v1/issues/{issue_id}", headers=voter)
    assert get.json()["upvotes_count"] == 1


async def test_duplicate_quorum_vote_counter_increments_once(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """Duplicate quorum vote is rejected and confirmations_count increments once."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]
    await client.post(f"/api/v1/issues/{issue_id}/acknowledge", headers=auth_headers)
    await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={"resolution_proof": "https://example.com/proof.jpg"},
        headers=auth_headers,
    )

    voter = await create_user_headers("+919876509994")
    first = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )
    assert first.status_code == 200
    assert first.json()["confirmations_count"] == 1

    second = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )
    assert second.status_code == 400
    assert second.json().get("code") == "already_voted"

    get = await client.get(f"/api/v1/issues/{issue_id}", headers=voter)
    assert get.json()["confirmations_count"] == 1
