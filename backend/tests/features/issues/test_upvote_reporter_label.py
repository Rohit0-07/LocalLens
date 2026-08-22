import httpx
import pytest

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Broken streetlight near park",
    "description": "Streetlight not working for a week",
    "category": "electricity",
    "latitude": 19.1136,
    "longitude": 72.8697,
    "is_anonymous": False,
}


async def _create_issue(
    client: httpx.AsyncClient, headers: dict[str, str], **overrides: object
) -> dict:
    payload = {**_ISSUE_PAYLOAD, **overrides}
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_upvote_response_preserves_reporter_label(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{id}/upvote must not change reporter_label/reporter_name."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    fetched = await client.get(f"/api/v1/issues/{issue_id}")
    assert fetched.status_code == 200, fetched.text
    label_before = fetched.json()["reporter_label"]
    name_before = fetched.json()["reporter_name"]
    assert label_before != "Verified citizen"

    voter_headers = await create_user_headers("+919876501001")
    response = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["has_upvoted"] is True
    assert data["upvotes_count"] == issue.get("upvotes_count", 0) + 1
    assert data["reporter_label"] == label_before
    assert data["reporter_name"] == name_before


async def test_remove_upvote_response_preserves_reporter_label(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """DELETE /issues/{id}/upvote must not change reporter_label/reporter_name."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    voter_headers = await create_user_headers("+919876501002")
    upvote_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert upvote_resp.status_code == 200, upvote_resp.text

    unvote_resp = await client.delete(f"/api/v1/issues/{issue_id}/upvote", headers=voter_headers)
    assert unvote_resp.status_code == 200, unvote_resp.text
    data = unvote_resp.json()
    assert data["has_upvoted"] is False
    assert data["upvotes_count"] == 0

    fetched = await client.get(f"/api/v1/issues/{issue_id}")
    assert fetched.status_code == 200, fetched.text
    assert data["reporter_label"] == fetched.json()["reporter_label"]
    assert data["reporter_name"] == fetched.json()["reporter_name"]
