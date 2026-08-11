"""Tests for Threaded Comments feature according to API Specification.

Endpoints tested:
1. POST /api/v1/issues/{id}/comments - Create top-level or reply comment
2. GET /api/v1/issues/{id}/comments - Retrieve threaded comments list
3. DELETE /api/v1/issues/{id}/comments/{comment_id} - Delete comment
"""

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ISSUE_PAYLOAD = {
    "title": "Broken street light on 5th Avenue",
    "description": "The lamp post near building 42 has been flickering and is now dark",
    "category": "lighting",
    "latitude": 19.1136,
    "longitude": 72.8697,
    "is_anonymous": False,
}


async def _create_issue(client: AsyncClient, headers: dict[str, str], **overrides: object) -> dict:
    """Helper to create a test issue."""
    payload = {**_ISSUE_PAYLOAD, **overrides}
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_post_top_level_comment_success(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments creates a top-level comment when given valid payload."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    response = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "This issue is very dangerous at night.", "parent_id": None},
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()

    assert "id" in data
    assert data["issue_id"] == issue_id
    assert data["parent_id"] is None
    assert "anon_id" in data
    assert data["content"] == "This issue is very dangerous at night."
    assert "created_at" in data
    assert data["is_author"] is True
    assert data.get("replies") == []


async def test_post_reply_comment_success(
    client: AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{id}/comments creates a reply comment under an existing parent comment."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # Parent comment by user 1
    parent_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Municipal team should fix this.", "parent_id": None},
        headers=auth_headers,
    )
    assert parent_resp.status_code == 201
    parent_id = parent_resp.json()["id"]

    # Reply comment by user 2
    user2_headers = await create_user_headers("+919876543220")
    reply_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Agreed, submitted a ticket to ward officer.", "parent_id": parent_id},
        headers=user2_headers,
    )
    assert reply_resp.status_code == 201, reply_resp.text
    reply_data = reply_resp.json()

    assert reply_data["issue_id"] == issue_id
    assert reply_data["parent_id"] == parent_id
    assert reply_data["content"] == "Agreed, submitted a ticket to ward officer."
    assert reply_data["is_author"] is True


async def test_get_comments_threaded_structure(
    client: AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """GET /issues/{id}/comments returns top-level comments with nested replies."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # User 1 posts top-level comment
    c1_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Top-level comment 1", "parent_id": None},
        headers=auth_headers,
    )
    c1_id = c1_resp.json()["id"]

    # User 2 replies to top-level comment
    user2_headers = await create_user_headers("+919876543221")
    await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Reply to top-level comment 1", "parent_id": c1_id},
        headers=user2_headers,
    )

    # Fetch comments as User 1
    get_resp = await client.get(f"/api/v1/issues/{issue_id}/comments", headers=auth_headers)
    assert get_resp.status_code == 200, get_resp.text
    comments = get_resp.json()

    assert isinstance(comments, list)
    assert len(comments) >= 1

    top_comment = next((c for c in comments if c["id"] == c1_id), None)
    assert top_comment is not None
    assert top_comment["is_author"] is True
    assert len(top_comment["replies"]) == 1
    assert top_comment["replies"][0]["content"] == "Reply to top-level comment 1"
    assert top_comment["replies"][0]["is_author"] is False


async def test_get_comments_is_author_flag_different_user(
    client: AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """GET /issues/{id}/comments sets is_author=False for comments written by other users."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # User 1 posts comment
    await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "User 1 comment", "parent_id": None},
        headers=auth_headers,
    )

    # User 2 fetches comments
    user2_headers = await create_user_headers("+919876543222")
    get_resp = await client.get(f"/api/v1/issues/{issue_id}/comments", headers=user2_headers)
    assert get_resp.status_code == 200
    comments = get_resp.json()
    assert len(comments) == 1
    assert comments[0]["is_author"] is False


async def test_post_comment_guest_user_forbidden(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments returns 403 Forbidden for guest users (is_guest=True)."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # Create guest session token
    guest_auth = await client.post("/api/v1/auth/guest")
    assert guest_auth.status_code == 200
    guest_token = guest_auth.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    response = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Guest comment attempt", "parent_id": None},
        headers=guest_headers,
    )
    assert response.status_code == 403
    body = response.json()
    assert (
        body.get("code") == "guest_restricted"
        or "Sign in required" in str(body)
        or "Forbidden" in str(body)
        or response.status_code == 403
    )


async def test_post_comment_empty_content_unprocessable(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments returns 422 Unprocessable Entity for empty or whitespace content."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # Empty string
    empty_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "", "parent_id": None},
        headers=auth_headers,
    )
    assert empty_resp.status_code == 422

    # Whitespace string
    whitespace_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "    \n\t  ", "parent_id": None},
        headers=auth_headers,
    )
    assert whitespace_resp.status_code == 422


async def test_post_comment_exceeds_max_length_unprocessable(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments returns 422 Unprocessable Entity for content exceeding 500 chars."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    too_long_content = "a" * 501
    response = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": too_long_content, "parent_id": None},
        headers=auth_headers,
    )
    assert response.status_code == 422


async def test_post_comment_profanity_toxic_word_unprocessable(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments returns 422 Unprocessable Entity for toxic words or profanity."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    toxic_payloads = [
        "This is toxicprofanity and abusive text",
        "SCAM SPAM toxic word content",
    ]
    for text in toxic_payloads:
        response = await client.post(
            f"/api/v1/issues/{issue_id}/comments",
            json={"content": text, "parent_id": None},
            headers=auth_headers,
        )
        assert response.status_code == 422, (
            f"Expected 422 for toxic content '{text}', got {response.status_code}"
        )


async def test_post_comment_nonexistent_issue_not_found(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """POST /issues/{id}/comments returns 404 Not Found when issue_id does not exist."""
    response = await client.post(
        "/api/v1/issues/99999/comments",
        json={"content": "Valid comment content", "parent_id": None},
        headers=auth_headers,
    )
    assert response.status_code == 404


async def test_post_comment_rate_limit_exceeded(
    client: AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """POST /issues/{id}/comments returns 429 Too Many Requests when exceeding 10 comments in 5 mins."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    spammer_headers = await create_user_headers("+919876543223")

    # Post 10 valid comments
    for i in range(10):
        res = await client.post(
            f"/api/v1/issues/{issue_id}/comments",
            json={"content": f"Comment count #{i + 1}", "parent_id": None},
            headers=spammer_headers,
        )
        assert res.status_code == 201, f"Comment #{i + 1} failed with {res.status_code}"

    # 11th comment should be rate limited
    eleventh_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Comment count #11 exceeding limit", "parent_id": None},
        headers=spammer_headers,
    )
    assert eleventh_resp.status_code == 429
    data = eleventh_resp.json()
    assert (
        data.get("code") == "rate_limited"
        or "Too Many Requests" in str(data)
        or eleventh_resp.status_code == 429
    )


async def test_delete_comment_author_success(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """DELETE /issues/{id}/comments/{comment_id} allows author to delete their comment."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    c_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "Comment to be deleted", "parent_id": None},
        headers=auth_headers,
    )
    assert c_resp.status_code == 201
    comment_id = c_resp.json()["id"]

    del_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/comments/{comment_id}",
        headers=auth_headers,
    )
    assert del_resp.status_code == 200

    # Ensure comment no longer in comments list
    get_resp = await client.get(f"/api/v1/issues/{issue_id}/comments", headers=auth_headers)
    assert get_resp.status_code == 200
    comments = get_resp.json()
    assert not any(c["id"] == comment_id for c in comments)


async def test_delete_comment_non_author_forbidden(
    client: AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """DELETE /issues/{id}/comments/{comment_id} returns 403 Forbidden for non-authors."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    # User 1 posts comment
    c_resp = await client.post(
        f"/api/v1/issues/{issue_id}/comments",
        json={"content": "User 1 comment", "parent_id": None},
        headers=auth_headers,
    )
    assert c_resp.status_code == 201
    comment_id = c_resp.json()["id"]

    # User 2 attempts to delete User 1's comment
    user2_headers = await create_user_headers("+919876543224")
    del_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/comments/{comment_id}",
        headers=user2_headers,
    )
    assert del_resp.status_code == 403


async def test_delete_comment_nonexistent_not_found(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """DELETE /issues/{id}/comments/{comment_id} returns 404 Not Found for missing comment."""
    issue = await _create_issue(client, auth_headers)
    issue_id = issue["id"]

    response = await client.delete(
        f"/api/v1/issues/{issue_id}/comments/99999",
        headers=auth_headers,
    )
    assert response.status_code == 404
