from datetime import UTC, datetime

import httpx
from sqlalchemy import text


async def _setup_representative(
    app,
    client: httpx.AsyncClient,
    phone: str = "+919876543201",
    ward: str = "Ward 45, Urban Central",
    official_name: str = "Hon. Sarah Jenkins",
    title: str = "Ward Councilor",
) -> tuple[dict[str, str], int, str]:
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    res = await client.post("/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})
    assert res.status_code == 200, res.text
    token = res.json()["access_token"]
    user_id = res.json()["user_id"]
    headers = {"Authorization": f"Bearer {token}"}

    rep_id = f"repr_{user_id}"
    async with app.state.database.session_factory() as session:
        await session.execute(
            text("""
            CREATE TABLE IF NOT EXISTS representative_profiles (
                id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                official_name TEXT NOT NULL,
                title TEXT NOT NULL,
                ward TEXT NOT NULL,
                verified_at DATETIME NOT NULL
            )
            """)
        )
        await session.execute(
            text("""
            CREATE TABLE IF NOT EXISTS official_responses (
                id TEXT PRIMARY KEY,
                issue_id INTEGER NOT NULL,
                representative_id TEXT NOT NULL,
                message TEXT NOT NULL,
                estimated_resolution_days INTEGER NULL,
                status_update TEXT NULL,
                created_at DATETIME NOT NULL
            )
            """)
        )
        await session.execute(
            text("""
            INSERT INTO representative_profiles
            (id, user_id, official_name, title, ward, verified_at)
            VALUES (:id, :user_id, :official_name, :title, :ward, :verified_at)
            """),
            {
                "id": rep_id,
                "user_id": user_id,
                "official_name": official_name,
                "title": title,
                "ward": ward,
                "verified_at": datetime.now(UTC).replace(tzinfo=None),
            },
        )
        await session.commit()

    return headers, user_id, rep_id


async def _create_issue(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    app,
    ward: str = "Ward 45, Urban Central",
    title: str = "Severe Pothole on Main St",
    status: str = "unacknowledged",
    is_anonymous: bool = False,
    is_fuzzed: bool = False,
    is_shielded: bool = False,
) -> int:
    payload = {
        "title": title,
        "description": "Deep pothole causing vehicle damage",
        "category": "road",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "is_anonymous": is_anonymous,
        "is_fuzzed": is_fuzzed,
        "is_shielded": is_shielded,
    }
    res = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert res.status_code == 201, res.text
    issue_id = res.json()["id"]

    async with app.state.database.session_factory() as session:
        await session.execute(
            text("UPDATE issues SET ward = :ward, status = :status WHERE id = :id"),
            {"ward": ward, "status": status, "id": issue_id},
        )
        await session.commit()

    return issue_id


async def test_be_rep_01_profile_and_metrics(app, client: httpx.AsyncClient) -> None:
    rep_headers, user_id, rep_id = await _setup_representative(
        app, client, phone="+919876543201", ward="Ward 45, Urban Central"
    )

    await _create_issue(
        client, rep_headers, app, ward="Ward 45, Urban Central", status="unacknowledged"
    )
    await _create_issue(client, rep_headers, app, ward="Ward 45, Urban Central", status="escalated")
    issue3_id = await _create_issue(
        client, rep_headers, app, ward="Ward 45, Urban Central", status="acknowledged"
    )

    resp_res = await client.post(
        f"/api/v1/issues/{issue3_id}/official-response",
        json={"message": "Work in progress by team", "status_update": "acknowledged"},
        headers=rep_headers,
    )
    assert resp_res.status_code == 201, resp_res.text

    profile_res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert profile_res.status_code == 200, profile_res.text
    data = profile_res.json()

    assert data["id"] == rep_id
    assert data["user_id"] == user_id
    assert data["official_name"] == "Hon. Sarah Jenkins"
    assert data["title"] == "Ward Councilor"
    assert data["ward"] == "Ward 45, Urban Central"
    assert "verified_at" in data
    assert data["total_ward_issues"] == 3
    assert data["escalated_ward_issues"] == 1
    assert data["responded_ward_issues"] == 1
    assert data["pending_response_ward_issues"] == 2


async def test_be_rep_02_ward_issues_filters_and_pagination(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(
        app, client, phone="+919876543202", ward="Ward 45, Urban Central"
    )

    i1 = await _create_issue(client, rep_headers, app, title="Issue A", status="unacknowledged")
    i2 = await _create_issue(client, rep_headers, app, title="Issue B", status="escalated")
    i3 = await _create_issue(client, rep_headers, app, title="Issue C", status="in_progress")
    i4 = await _create_issue(client, rep_headers, app, title="Issue D", status="escalated")

    await client.post(
        f"/api/v1/issues/{i3}/official-response",
        json={"message": "Official response to C", "status_update": "in_progress"},
        headers=rep_headers,
    )
    await client.post(
        f"/api/v1/issues/{i4}/official-response",
        json={"message": "Official response to D", "status_update": "acknowledged"},
        headers=rep_headers,
    )

    await _create_issue(
        client, rep_headers, app, ward="Ward 12, West Suburbs", title="Issue Other Ward"
    )

    all_res = await client.get("/api/v1/representatives/ward-issues", headers=rep_headers)
    assert all_res.status_code == 200
    all_data = all_res.json()
    assert all_data["total"] == 4
    assert len(all_data["items"]) == 4

    escalated_res = await client.get(
        "/api/v1/representatives/ward-issues",
        params={"filter": "escalated"},
        headers=rep_headers,
    )
    assert escalated_res.status_code == 200
    esc_data = escalated_res.json()
    assert all(item["status"] == "escalated" for item in esc_data["items"])
    esc_ids = [item["id"] for item in esc_data["items"]]
    assert set(esc_ids) == {i2, i4}

    needs_resp_res = await client.get(
        "/api/v1/representatives/ward-issues",
        params={"filter": "needs_response"},
        headers=rep_headers,
    )
    assert needs_resp_res.status_code == 200
    needs_data = needs_resp_res.json()
    needs_ids = [item["id"] for item in needs_data["items"]]
    assert set(needs_ids) == {i1, i2}

    page1_res = await client.get(
        "/api/v1/representatives/ward-issues",
        params={"limit": 2, "offset": 0},
        headers=rep_headers,
    )
    assert page1_res.status_code == 200
    p1_data = page1_res.json()
    assert len(p1_data["items"]) == 2
    assert p1_data["total"] == 4

    page2_res = await client.get(
        "/api/v1/representatives/ward-issues",
        params={"limit": 2, "offset": 2},
        headers=rep_headers,
    )
    assert page2_res.status_code == 200
    p2_data = page2_res.json()
    assert len(p2_data["items"]) == 2
    assert p2_data["total"] == 4


async def test_be_rep_03_official_response_creation_and_validation(
    app, client: httpx.AsyncClient
) -> None:
    rep_headers, _, rep_id = await _setup_representative(
        app, client, phone="+919876543203", ward="Ward 45, Urban Central"
    )
    issue_id = await _create_issue(client, rep_headers, app, ward="Ward 45, Urban Central")

    valid_res = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={
            "message": "Public Works team dispatched. Work will begin on Wednesday.",
            "estimated_resolution_days": 3,
            "status_update": "acknowledged",
        },
        headers=rep_headers,
    )
    assert valid_res.status_code == 201, valid_res.text
    vdata = valid_res.json()
    assert vdata["issue_id"] == issue_id
    assert vdata["representative_id"] == rep_id
    assert vdata["official_name"] == "Hon. Sarah Jenkins"
    assert vdata["message"] == "Public Works team dispatched. Work will begin on Wednesday."
    assert vdata["estimated_resolution_days"] == 3
    assert vdata["status_update"] == "acknowledged"

    issue2_id = await _create_issue(client, rep_headers, app, ward="Ward 45, Urban Central")
    min_msg_res = await client.post(
        f"/api/v1/issues/{issue2_id}/official-response",
        json={"message": "12345", "status_update": "in_progress"},
        headers=rep_headers,
    )
    assert min_msg_res.status_code == 201

    max_msg = "A" * 1000
    max_msg_res = await client.post(
        f"/api/v1/issues/{issue2_id}/official-response",
        json={"message": max_msg},
        headers=rep_headers,
    )
    assert max_msg_res.status_code == 201

    short_msg_res = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "Tiny"},
        headers=rep_headers,
    )
    assert short_msg_res.status_code in (400, 422)

    too_long_msg_res = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "A" * 1001},
        headers=rep_headers,
    )
    assert too_long_msg_res.status_code in (400, 422)

    invalid_status_res = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "Valid message", "status_update": "resolved"},
        headers=rep_headers,
    )
    assert invalid_status_res.status_code in (400, 422)

    invalid_days_res = await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={"message": "Valid message", "estimated_resolution_days": 0},
        headers=rep_headers,
    )
    assert invalid_days_res.status_code in (400, 422)


async def test_be_rep_04_official_response_non_existent_issue(
    app, client: httpx.AsyncClient
) -> None:
    rep_headers, _, _ = await _setup_representative(app, client, phone="+919876543204")
    res = await client.post(
        "/api/v1/issues/99999/official-response",
        json={"message": "Response to ghost issue"},
        headers=rep_headers,
    )
    assert res.status_code == 404


async def test_be_rep_05_public_official_response_retrieval(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(app, client, phone="+919876543205")
    issue_id = await _create_issue(client, rep_headers, app, ward="Ward 45, Urban Central")

    await client.post(
        f"/api/v1/issues/{issue_id}/official-response",
        json={
            "message": "Official response posted for public view",
            "status_update": "acknowledged",
        },
        headers=rep_headers,
    )

    guest_res = await client.get(f"/api/v1/issues/{issue_id}/official-responses")
    assert guest_res.status_code == 200
    guest_data = guest_res.json()
    assert isinstance(guest_data, list)
    assert len(guest_data) == 1
    assert guest_data[0]["message"] == "Official response posted for public view"

    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543999"})
    cit_verify = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543999", "code": "000000"}
    )
    citizen_token = cit_verify.json()["access_token"]
    citizen_headers = {"Authorization": f"Bearer {citizen_token}"}

    citizen_res = await client.get(
        f"/api/v1/issues/{issue_id}/official-responses", headers=citizen_headers
    )
    assert citizen_res.status_code == 200
    assert len(citizen_res.json()) == 1

    missing_res = await client.get("/api/v1/issues/99999/official-responses")
    assert missing_res.status_code == 404


async def test_sec_rep_01_rbac_and_endpoint_authorization(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(app, client, phone="+919876543206")
    issue_id = await _create_issue(client, rep_headers, app)

    await client.post("/api/v1/auth/otp/request", json={"phone": "+919876543207"})
    cit_res = await client.post(
        "/api/v1/auth/otp/verify", json={"phone": "+919876543207", "code": "000000"}
    )
    citizen_headers = {"Authorization": f"Bearer {cit_res.json()['access_token']}"}

    endpoints_get = ["/api/v1/representatives/me", "/api/v1/representatives/ward-issues"]
    for ep in endpoints_get:
        no_auth = await client.get(ep)
        assert no_auth.status_code == 401
        cit_auth = await client.get(ep, headers=citizen_headers)
        assert cit_auth.status_code == 403

    post_ep = f"/api/v1/issues/{issue_id}/official-response"
    post_no_auth = await client.post(post_ep, json={"message": "Unauthorized post"})
    assert post_no_auth.status_code == 401

    post_cit_auth = await client.post(
        post_ep, json={"message": "Citizen attempt"}, headers=citizen_headers
    )
    assert post_cit_auth.status_code == 403

    post_rep_auth = await client.post(
        post_ep, json={"message": "Valid rep response"}, headers=rep_headers
    )
    assert post_rep_auth.status_code == 201


async def test_sec_rep_02_ward_boundary_mismatch(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(
        app, client, phone="+919876543208", ward="Ward 45, Urban Central"
    )
    other_issue_id = await _create_issue(
        client, rep_headers, app, ward="Ward 12, West Suburbs", title="Issue in Ward 12"
    )

    res = await client.post(
        f"/api/v1/issues/{other_issue_id}/official-response",
        json={"message": "Attempting to respond outside my ward"},
        headers=rep_headers,
    )
    assert res.status_code == 403

    public_responses = await client.get(f"/api/v1/issues/{other_issue_id}/official-responses")
    assert public_responses.status_code == 200
    assert len(public_responses.json()) == 0


async def test_sec_rep_03_endpoint_rate_limiting(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(app, client, phone="+919876543209")

    statuses = []
    for _ in range(30):
        res = await client.get("/api/v1/representatives/me", headers=rep_headers)
        statuses.append(res.status_code)

    assert all(s == 200 for s in statuses)

    over_limit_res = await client.get("/api/v1/representatives/me", headers=rep_headers)
    assert over_limit_res.status_code == 429


async def test_sec_rep_04_pii_shielding_and_sqli_protection(app, client: httpx.AsyncClient) -> None:
    rep_headers, _, _ = await _setup_representative(app, client, phone="+919876543210")

    anon_issue_id = await _create_issue(
        client,
        rep_headers,
        app,
        ward="Ward 45, Urban Central",
        is_anonymous=True,
        is_fuzzed=True,
        is_shielded=True,
    )

    ward_issues_res = await client.get("/api/v1/representatives/ward-issues", headers=rep_headers)
    assert ward_issues_res.status_code == 200
    items = ward_issues_res.json()["items"]
    target = next((item for item in items if item["id"] == anon_issue_id), None)
    assert target is not None
    assert target["is_anonymous"] is True
    assert target["is_fuzzed"] is True
    assert target["is_shielded"] is True

    sqli_payload = "' OR '1'='1'; DROP TABLE official_responses; -- <script>alert('xss')</script>"
    sqli_res = await client.post(
        f"/api/v1/issues/{anon_issue_id}/official-response",
        json={"message": sqli_payload},
        headers=rep_headers,
    )
    assert sqli_res.status_code == 201

    get_resp = await client.get(f"/api/v1/issues/{anon_issue_id}/official-responses")
    assert get_resp.status_code == 200
    resp_list = get_resp.json()
    assert len(resp_list) == 1
    assert resp_list[0]["message"] == sqli_payload
