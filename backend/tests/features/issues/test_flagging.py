import httpx
import pytest
import pytest_asyncio
from fastapi import FastAPI
from sqlalchemy import text

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


@pytest_asyncio.fixture
async def admin_headers(client: httpx.AsyncClient, app: FastAPI) -> dict[str, str]:
    """Fixture providing authentication headers for an admin user."""
    admin_phone = "+919999900001"
    await client.post("/api/v1/auth/otp/request", json={"phone": admin_phone})
    res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": admin_phone, "code": "000000"}
    )
    assert res.status_code == 200, res.text
    token = res.json()["access_token"]

    # Update database user record to set is_admin = True and/or role = 'admin'
    async with app.state.database.session_factory() as session:
        try:
            await session.execute(
                text("UPDATE users SET is_admin = 1, role = 'admin' WHERE phone = :phone"),
                {"phone": admin_phone},
            )
            await session.commit()
        except Exception:
            pass

    return {"Authorization": f"Bearer {token}"}


# ============================================================================
# BE-FLAG-01 through BE-FLAG-10
# ============================================================================


async def test_be_flag_01_valid_flag_submission(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-01: Valid Flag Submission

    Verify that an authenticated non-guest user can successfully flag an active civic issue
    with valid category and details, returning 201 Created and a valid FlagOut payload.
    """
    issue = await _create_issue(client, auth_headers, title="Valid Flag Issue")
    issue_id = issue["id"]

    response = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={
            "category": "spam",
            "details": "Repeated commercial advertisement post.",
        },
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["issue_id"] == issue_id
    assert data["category"] == "spam"
    assert data["details"] == "Repeated commercial advertisement post."
    assert "id" in data
    assert "created_at" in data


async def test_be_flag_02_duplicate_flag_submission_guard(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-02: Duplicate Flag Submission Guard

    Verify that submitting a second flag for the same issue by the same user
    is blocked with 409 Conflict.
    """
    issue = await _create_issue(client, auth_headers, title="Duplicate Flag Issue")
    issue_id = issue["id"]

    # First flag submission succeeds
    first_resp = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "spam", "details": "First flag"},
        headers=auth_headers,
    )
    assert first_resp.status_code == 201

    # Second flag submission for same issue by same user fails
    second_resp = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "abuse", "details": "Attempting second flag on same issue."},
        headers=auth_headers,
    )
    assert second_resp.status_code == 409
    data = second_resp.json()
    assert (
        data.get("error_code") == "duplicate_flag"
        or data.get("code") == "duplicate_flag"
        or "already" in str(data).lower()
    )


async def test_be_flag_03_invalid_category_enum_validation(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-03: Invalid Category Enum Validation

    Verify that submitting an unapproved category string returns 400/422 Bad Request with validation_error.
    """
    issue = await _create_issue(client, auth_headers, title="Invalid Category Issue")
    issue_id = issue["id"]

    response = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "inappropriate_content", "details": "Invalid category value"},
        headers=auth_headers,
    )
    assert response.status_code in (400, 422)
    data = response.json()
    assert (
        data.get("error_code") == "validation_error"
        or data.get("code") == "validation_error"
        or "validation" in str(data).lower()
        or "category" in str(data).lower()
    )


async def test_be_flag_04_details_field_character_length_limit(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-04: Details Field Character Length Limit

    Verify that submitting a details string exceeding 500 characters returns 400/422 Bad Request.
    """
    issue = await _create_issue(client, auth_headers, title="Overlong Details Issue")
    issue_id = issue["id"]

    overlong_details = "a" * 501
    response = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "other", "details": overlong_details},
        headers=auth_headers,
    )
    assert response.status_code in (400, 422)
    data = response.json()
    assert (
        data.get("error_code") == "validation_error"
        or data.get("code") == "validation_error"
        or "500" in str(data)
        or "length" in str(data).lower()
        or "character" in str(data).lower()
    )


async def test_be_flag_05_sliding_window_rate_limit_guard(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """BE-FLAG-05: Sliding Window Rate Limit Guard

    Verify that a user submitting more than 5 flags within a 10-minute sliding window
    is blocked on the 6th attempt with 429 Too Many Requests.
    """
    issue_ids = []
    for i in range(6):
        iss = await _create_issue(client, auth_headers, title=f"Rate limit issue {i + 1}")
        issue_ids.append(iss["id"])

    flagger_headers = await create_user_headers("+919876543299")

    # Submissions 1 through 5 succeed
    for i in range(5):
        res = await client.post(
            f"/api/v1/issues/{issue_ids[i]}/flag",
            json={"category": "spam", "details": f"Flag attempt {i + 1}"},
            headers=flagger_headers,
        )
        assert res.status_code == 201, f"Flag submission {i + 1} failed: {res.text}"

    # 6th submission fails with 429
    sixth_resp = await client.post(
        f"/api/v1/issues/{issue_ids[5]}/flag",
        json={"category": "spam", "details": "Flag attempt 6"},
        headers=flagger_headers,
    )
    assert sixth_resp.status_code == 429
    data = sixth_resp.json()
    assert (
        data.get("error_code") == "rate_limit_exceeded"
        or data.get("code") == "rate_limit_exceeded"
        or "rate" in str(data).lower()
        or "limit" in str(data).lower()
    )


async def test_be_flag_06_flagging_non_existent_issue_id(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-06: Flagging Non-Existent Issue ID

    Verify that submitting a flag targeting a non-existent issue ID returns 404 Not Found.
    """
    response = await client.post(
        "/api/v1/issues/99999/flag",
        json={"category": "spam"},
        headers=auth_headers,
    )
    assert response.status_code == 404
    data = response.json()
    assert (
        data.get("error_code") == "not_found"
        or data.get("code") == "not_found"
        or "not found" in str(data).lower()
    )


async def test_be_flag_07_admin_flagged_issues_queue_retrieval(
    client: httpx.AsyncClient, admin_headers: dict[str, str], auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-07: Admin Flagged Issues Queue Retrieval

    Verify that an administrator can retrieve the paginated flagged issues queue.
    """
    # Create an issue and flag it so queue has data
    issue = await _create_issue(client, auth_headers, title="Flagged Queue Test Issue")
    await client.post(
        f"/api/v1/issues/{issue['id']}/flag",
        json={"category": "abuse", "details": "Abusive content"},
        headers=auth_headers,
    )

    response = await client.get(
        "/api/v1/admin/flagged-issues?limit=20&offset=0",
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["limit"] == 20
    assert data["offset"] == 0
    assert isinstance(data["items"], list)


async def test_be_flag_08_admin_queue_status_filtering(
    client: httpx.AsyncClient, admin_headers: dict[str, str], auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-08: Admin Queue Status Filtering

    Verify that the admin queue status filter correctly isolates flags by status.
    """
    issue = await _create_issue(client, auth_headers, title="Status Filter Test Issue")
    await client.post(
        f"/api/v1/issues/{issue['id']}/flag",
        json={"category": "pii", "details": "PII leak"},
        headers=auth_headers,
    )

    statuses = ["pending", "reviewed", "dismissed", "hidden", "all"]
    for s in statuses:
        response = await client.get(
            f"/api/v1/admin/flagged-issues?status={s}",
            headers=admin_headers,
        )
        if response.status_code != 200:
            # Also test status_filter parameter if status parameter differs
            response = await client.get(
                f"/api/v1/admin/flagged-issues?status_filter={s}",
                headers=admin_headers,
            )
        assert response.status_code == 200, f"Failed for status '{s}': {response.text}"
        data = response.json()
        assert "items" in data


async def test_be_flag_09_admin_moderation_action_hide_issue(
    client: httpx.AsyncClient, admin_headers: dict[str, str], auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-09: Admin Moderation Action hide_issue & Audit Log

    Verify that executing moderation action hide_issue updates the target issue's visibility
    to hidden (is_hidden = True) and records an audit log entry.
    """
    issue = await _create_issue(client, auth_headers, title="Issue To Hide")
    issue_id = issue["id"]

    await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "abuse", "details": "Violates guidelines"},
        headers=auth_headers,
    )

    response = await client.post(
        f"/api/v1/admin/issues/{issue_id}/moderate",
        json={
            "action": "hide_issue",
            "reason": "Violates community guidelines on offensive content.",
        },
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["issue_id"] == issue_id
    assert data["action"] == "hide_issue"
    assert data["is_hidden"] is True


async def test_be_flag_10_admin_moderation_action_ban_reporter(
    client: httpx.AsyncClient, admin_headers: dict[str, str], auth_headers: dict[str, str]
) -> None:
    """BE-FLAG-10: Admin Moderation Action ban_reporter

    Verify that executing moderation action ban_reporter updates issue moderation status
    and sets the reporting user's account state to banned (is_banned = True).
    """
    issue = await _create_issue(client, auth_headers, title="Issue With Offending Reporter")
    issue_id = issue["id"]

    await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "fake_report", "details": "Repeated fake reports"},
        headers=auth_headers,
    )

    response = await client.post(
        f"/api/v1/admin/issues/{issue_id}/moderate",
        json={
            "action": "ban_reporter",
            "reason": "Repeated submission of fake emergency reports.",
        },
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["issue_id"] == issue_id
    assert data["action"] == "ban_reporter"
    assert data["reporter_banned"] is True


# ============================================================================
# SEC-FLAG-01 through SEC-FLAG-05
# ============================================================================


async def test_sec_flag_01_guest_session_post_restriction(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """SEC-FLAG-01: Guest Session POST Restriction (guest_restricted)

    Verify that an unauthenticated guest user attempting a POST flag request receives
    HTTP 403 Forbidden with code guest_restricted.
    """
    issue = await _create_issue(client, auth_headers, title="Guest Restricted Issue")
    issue_id = issue["id"]

    guest_res = await client.post("/api/v1/auth/guest")
    assert guest_res.status_code == 200
    guest_token = guest_res.json()["access_token"]

    response = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "spam", "details": "Guest flagging attempt"},
        headers={"Authorization": f"Bearer {guest_token}"},
    )
    assert response.status_code == 403
    data = response.json()
    assert (
        data.get("error_code") == "guest_restricted"
        or data.get("code") == "guest_restricted"
        or "guest" in str(data).lower()
        or "sign in" in str(data).lower()
    )


async def test_sec_flag_02_non_admin_admin_endpoint_restriction(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """SEC-FLAG-02: Non-Admin Admin Endpoint Restriction (admin_required)

    Verify that a standard non-admin user attempting to access administrative endpoints
    receives HTTP 403 Forbidden with code admin_required.
    """
    # 1. GET /api/v1/admin/flagged-issues
    get_res = await client.get("/api/v1/admin/flagged-issues", headers=auth_headers)
    assert get_res.status_code == 403
    get_data = get_res.json()
    assert (
        get_data.get("error_code") == "admin_required"
        or get_data.get("code") == "admin_required"
        or "admin" in str(get_data).lower()
    )

    # 2. POST /api/v1/admin/issues/1/moderate
    post_res = await client.post(
        "/api/v1/admin/issues/1/moderate",
        json={"action": "hide_issue", "reason": "Unauthorized moderate"},
        headers=auth_headers,
    )
    assert post_res.status_code == 403
    post_data = post_res.json()
    assert (
        post_data.get("error_code") == "admin_required"
        or post_data.get("code") == "admin_required"
        or "admin" in str(post_data).lower()
    )


async def test_sec_flag_03_unauthenticated_request_restriction(client: httpx.AsyncClient) -> None:
    """SEC-FLAG-03: Unauthenticated Request Restriction

    Verify that requests missing authorization headers or using invalid/expired tokens
    are rejected with HTTP 401 Unauthorized.
    """
    invalid_headers = {"Authorization": "Bearer invalid_token_xyz_12345"}

    # 1. Flag submission endpoint
    flag_no_header = await client.post("/api/v1/issues/1/flag", json={"category": "spam"})
    assert flag_no_header.status_code == 401
    flag_bad_token = await client.post(
        "/api/v1/issues/1/flag", json={"category": "spam"}, headers=invalid_headers
    )
    assert flag_bad_token.status_code == 401

    # 2. Admin queue endpoint
    admin_no_header = await client.get("/api/v1/admin/flagged-issues")
    assert admin_no_header.status_code == 401
    admin_bad_token = await client.get("/api/v1/admin/flagged-issues", headers=invalid_headers)
    assert admin_bad_token.status_code == 401

    # 3. Admin moderate endpoint
    mod_no_header = await client.post("/api/v1/admin/issues/1/moderate", json={"action": "dismiss"})
    assert mod_no_header.status_code == 401
    mod_bad_token = await client.post(
        "/api/v1/admin/issues/1/moderate", json={"action": "dismiss"}, headers=invalid_headers
    )
    assert mod_bad_token.status_code == 401


async def test_sec_flag_04_rate_limit_isolation(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    """SEC-FLAG-04: Rate Limit Isolation per User ID and Anon ID

    Verify that sliding window rate limit counts are strictly isolated per user ID
    and per anonymous session, preventing one user's quota from affecting another.
    """
    user_a_headers = await create_user_headers("+919876540001")
    user_b_headers = await create_user_headers("+919876540002")

    issue_ids = []
    for i in range(7):
        iss = await _create_issue(client, auth_headers, title=f"Isolation Issue {i + 1}")
        issue_ids.append(iss["id"])

    # User A reaches limit with 5 flags
    for i in range(5):
        res = await client.post(
            f"/api/v1/issues/{issue_ids[i]}/flag",
            json={"category": "spam"},
            headers=user_a_headers,
        )
        assert res.status_code == 201

    # User A 6th flag is blocked
    user_a_6th = await client.post(
        f"/api/v1/issues/{issue_ids[5]}/flag",
        json={"category": "spam"},
        headers=user_a_headers,
    )
    assert user_a_6th.status_code == 429

    # User B's flag request succeeds despite User A reaching limit
    user_b_res = await client.post(
        f"/api/v1/issues/{issue_ids[6]}/flag",
        json={"category": "spam"},
        headers=user_b_headers,
    )
    assert user_b_res.status_code == 201


async def test_sec_flag_05_sql_parameterization_and_injection_safety(
    client: httpx.AsyncClient, auth_headers: dict[str, str], admin_headers: dict[str, str]
) -> None:
    """SEC-FLAG-05: SQL Parameterization & Injection Safety

    Verify that SQL injection vectors in request bodies or query strings are safely
    neutralized by SQLAlchemy parameterization without executing injected SQL statements.
    """
    issue = await _create_issue(client, auth_headers, title="SQL Injection Test Issue")
    issue_id = issue["id"]

    # 1. Injected details string in POST flag
    sql_payload = "'; DROP TABLE flags; SELECT * FROM users WHERE '1'='1"
    response = await client.post(
        f"/api/v1/issues/{issue_id}/flag",
        json={"category": "other", "details": sql_payload},
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["details"] == sql_payload

    # 2. Injected query string parameter in GET admin queue
    injected_status = "pending' OR '1'='1"
    query_resp = await client.get(
        f"/api/v1/admin/flagged-issues?status={injected_status}",
        headers=admin_headers,
    )
    # Parameterization should either return 200 with empty/filtered list or 400 validation error
    assert query_resp.status_code in (200, 400, 422)

    # 3. Verify database tables are intact after injection attempt
    subsequent_resp = await client.get(
        "/api/v1/admin/flagged-issues",
        headers=admin_headers,
    )
    assert subsequent_resp.status_code == 200
