import httpx
import pytest

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Pothole on Linking Road",
    "description": "Large pothole causing traffic congestion",
    "category": "road",
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


async def test_upvote_within_radius_success(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{issue_id}/upvote upvotes an issue when authenticated user is within 5.0 km.

    Response IssueOut contains has_upvoted: bool = True and updated upvotes_count.
    """
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]
    initial_count = issue.get("upvotes_count", 0)

    voter_headers = await create_user_headers("+919876500001")
    response = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["has_upvoted"] is True
    assert data["upvotes_count"] == initial_count + 1


async def test_upvote_out_of_radius_returns_400(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{issue_id}/upvote returns HTTP 400 out_of_radius if user is > 5 km away."""
    issue = await _create_issue(client, auth_headers, latitude=19.1136, longitude=72.8697)
    issue_id = issue["id"]

    far_voter_headers = await create_user_headers("+919876500002")
    response = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.5000, "longitude": 72.9500},  # > 5km away
        headers=far_voter_headers,
    )
    assert response.status_code == 400
    data = response.json()
    assert data.get("code") == "out_of_radius" or data.get("detail") == "out_of_radius"


async def test_upvote_duplicate_returns_400(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{issue_id}/upvote returns HTTP 400 already_upvoted if user attempts duplicate upvote."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    voter_headers = await create_user_headers("+919876500003")
    first_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert first_resp.status_code == 200

    second_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert second_resp.status_code == 400
    data = second_resp.json()
    assert data.get("code") == "already_upvoted" or data.get("detail") == "already_upvoted"


async def test_upvote_rate_limited_returns_429(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{issue_id}/upvote returns HTTP 429 rate_limited if user exceeds 5 upvotes in 10 minutes."""
    issue_ids = []
    for i in range(6):
        iss = await _create_issue(client, auth_headers, title=f"Rate limit test issue {i + 1}")
        issue_ids.append(iss["id"])

    voter_headers = await create_user_headers("+919876500004")
    # First 5 upvotes succeed
    for i in range(5):
        res = await client.post(
            f"/api/v1/issues/{issue_ids[i]}/upvote",
            json={"latitude": 19.1136, "longitude": 72.8697},
            headers=voter_headers,
        )
        assert res.status_code == 200, f"Upvote {i + 1} failed unexpectedly"

    # 6th upvote attempt should fail with rate limit error
    sixth_resp = await client.post(
        f"/api/v1/issues/{issue_ids[5]}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert sixth_resp.status_code == 429
    data = sixth_resp.json()
    assert data.get("code") == "rate_limited" or data.get("detail") == "rate_limited"


async def test_un_upvote_success(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """DELETE /issues/{issue_id}/upvote un-upvotes an issue previously upvoted by user.

    Response IssueOut contains has_upvoted: bool = False and decremented upvotes_count.
    """
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    voter_headers = await create_user_headers("+919876500005")
    # First upvote
    upvote_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert upvote_resp.status_code == 200
    assert upvote_resp.json()["has_upvoted"] is True
    assert upvote_resp.json()["upvotes_count"] == 1

    # Un-upvote via DELETE
    un_upvote_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=voter_headers,
    )
    assert un_upvote_resp.status_code == 200, un_upvote_resp.text
    data = un_upvote_resp.json()
    assert data["has_upvoted"] is False
    assert data["upvotes_count"] == 0


async def test_un_upvote_not_upvoted_returns_400(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """DELETE /issues/{issue_id}/upvote returns HTTP 400 not_upvoted if user has not upvoted this issue."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    non_voter_headers = await create_user_headers("+919876500006")
    response = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=non_voter_headers,
    )
    assert response.status_code == 400
    data = response.json()
    assert data.get("code") == "not_upvoted" or data.get("detail") == "not_upvoted"


async def test_get_issue_has_upvoted_flag_single(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """GET /issues/{id} returns has_upvoted: bool = True if current authenticated user upvoted, otherwise False."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    voter_a = await create_user_headers("+919876500007")
    voter_b = await create_user_headers("+919876500008")

    # Before upvoting: GET by voter_a returns has_upvoted = False
    get_before = await client.get(f"/api/v1/issues/{issue_id}", headers=voter_a)
    assert get_before.status_code == 200
    assert get_before.json()["has_upvoted"] is False

    # voter_a upvotes
    await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_a,
    )

    # After upvoting: GET by voter_a returns has_upvoted = True
    get_voter_a = await client.get(f"/api/v1/issues/{issue_id}", headers=voter_a)
    assert get_voter_a.status_code == 200
    assert get_voter_a.json()["has_upvoted"] is True

    # GET by voter_b (who has not upvoted) returns has_upvoted = False
    get_voter_b = await client.get(f"/api/v1/issues/{issue_id}", headers=voter_b)
    assert get_voter_b.status_code == 200
    assert get_voter_b.json()["has_upvoted"] is False

    # GET without auth header returns has_upvoted = False
    get_unauth = await client.get(f"/api/v1/issues/{issue_id}")
    assert get_unauth.status_code == 200
    assert get_unauth.json()["has_upvoted"] is False


async def test_get_issues_list_has_upvoted_flag(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """GET /issues returns has_upvoted: bool = True if current authenticated user upvoted the issue, otherwise False."""
    issue1 = await _create_issue(client, auth_headers, title="Issue One")
    issue2 = await _create_issue(client, auth_headers, title="Issue Two")

    voter = await create_user_headers("+919876500009")

    # voter upvotes only issue1
    await client.post(
        f"/api/v1/issues/{issue1['id']}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )

    # GET /issues with voter headers
    response = await client.get(
        "/api/v1/issues",
        params={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter,
    )
    assert response.status_code == 200
    issues_by_id = {i["id"]: i for i in response.json()}
    assert issues_by_id[issue1["id"]]["has_upvoted"] is True
    assert issues_by_id[issue2["id"]]["has_upvoted"] is False
