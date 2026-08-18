"""F-08 Search — backend contract tests (code-blind, contract-driven)."""

import httpx

DEFAULT_LAT = 19.1136
DEFAULT_LNG = 72.8697


async def _create_issue(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    *,
    title: str,
    description: str = "",
    category: str = "other",
    latitude: float = DEFAULT_LAT,
    longitude: float = DEFAULT_LNG,
    is_shielded: bool = False,
) -> dict:
    payload = {
        "title": title,
        "description": description,
        "category": category,
        "latitude": latitude,
        "longitude": longitude,
        "is_anonymous": False,
        "fuzz_location": False,
        "is_fuzzed": False,
        "is_shielded": is_shielded,
    }
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def _search(
    client: httpx.AsyncClient,
    q: str,
    headers: dict[str, str] | None = None,
    **params,
) -> httpx.Response:
    return await client.get("/api/v1/search", params={"q": q, **params}, headers=headers)


def _titles(response: httpx.Response) -> list[str]:
    return [issue["title"] for issue in response.json()]


async def test_title_keyword_match(client, create_user_headers):
    headers = await create_user_headers("+919000000001")
    await _create_issue(client, headers, title="Pothole on Main St")
    await _create_issue(client, headers, title="Graffiti near the park")
    for q in ("pothole", "poth", "POTHOLE", "Pothole on Main St"):
        response = await _search(client, q=q, headers=headers)
        assert response.status_code == 200
        titles = _titles(response)
        assert "Pothole on Main St" in titles
        assert "Graffiti near the park" not in titles


async def test_category_match_and_category_filter(client, create_user_headers):
    headers = await create_user_headers("+919000000002")
    await _create_issue(client, headers, title="Pothole on Main St", category="Roads")
    response = await _search(client, q="roads", headers=headers)
    assert response.status_code == 200
    assert "Pothole on Main St" in _titles(response)
    response = await _search(client, q="pothole", category="Roads", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Pothole on Main St"]
    response = await _search(client, q="pothole", category="Parks", headers=headers)
    assert response.status_code == 200
    assert response.json() == []


async def test_ward_match(client, create_user_headers):
    headers = await create_user_headers("+919000000003")
    await _create_issue(client, headers, title="Pothole on Main St")
    response = await _search(client, q="Ward 45", headers=headers)
    assert response.status_code == 200
    assert "Pothole on Main St" in _titles(response)
    assert response.json()[0]["ward"] == "Ward 45, Urban Central"


async def test_ward_filter(client, create_user_headers, app):
    async with app.state.database.session_factory() as session:
        from app.features.wards.models import Ward

        session.add(
            Ward(
                name="Ward 45, Urban Central",
                slug="ward-45-urban-central",
                code="W-45",
                center_latitude=19.1136,
                center_longitude=72.8697,
            )
        )
        await session.commit()

    headers = await create_user_headers("+919000000010")
    await _create_issue(client, headers, title="Sewage overflow near temple")
    await _create_issue(client, headers, title="Streetlight flicker on boulevard")

    for ward_param in (
        "Ward 45, Urban Central",
        "ward-45-urban-central",
        "W-45",
        "ward 45",
    ):
        response = await _search(client, q="other", ward=ward_param, headers=headers)
        assert response.status_code == 200, response.text
        titles = _titles(response)
        assert "Sewage overflow near temple" in titles
        assert "Streetlight flicker on boulevard" in titles

    response = await _search(client, q="other", ward="ward-99-nonexistent", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == []

    response = await _search(
        client, q="sewage", ward="ward-45-urban-central", headers=headers
    )
    assert response.status_code == 200
    assert _titles(response) == ["Sewage overflow near temple"]


async def test_unicode_description_match(client, create_user_headers):
    headers = await create_user_headers("+919000000004")
    await _create_issue(
        client, headers, title="Streetlight", description="café lights on the promenade"
    )
    response = await _search(client, q="café", headers=headers)
    assert response.status_code == 200
    assert "Streetlight" in _titles(response)


async def test_proximity_radius_and_global_set(client, create_user_headers):
    near = "anchor at mumbai hub"
    far = "anchor at delhi corner"
    mid = "anchor one km away"
    headers = await create_user_headers("+919000000005")
    await _create_issue(client, headers, title=near)
    await _create_issue(client, headers, title=far, latitude=28.6139, longitude=77.2090)
    await _create_issue(client, headers, title=mid, latitude=19.1226, longitude=72.8697)

    response = await _search(
        client,
        q="anchor",
        latitude=19.1136,
        longitude=72.8697,
        radius_km=5.0,
        headers=headers,
    )
    assert response.status_code == 200
    titles = _titles(response)
    assert near in titles
    assert mid in titles
    assert far not in titles

    response = await _search(client, q="anchor", headers=headers)
    assert response.status_code == 200
    assert {near, mid, far} <= set(_titles(response))

    response = await _search(
        client, q="anchor", latitude=19.1136, longitude=72.8697, headers=headers
    )
    assert response.status_code == 200
    assert mid in _titles(response)

    response = await _search(
        client,
        q="anchor",
        latitude=19.1136,
        longitude=72.8697,
        radius_km=0.5,
        headers=headers,
    )
    assert response.status_code == 200
    titles = _titles(response)
    assert near in titles
    assert mid not in titles


async def test_status_filter(client, create_user_headers):
    headers = await create_user_headers("+919000000006")
    await _create_issue(client, headers, title="Pothole on Main St")
    response = await _search(client, q="pothole", status="unacknowledged", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Pothole on Main St"]
    response = await _search(client, q="pothole", status="resolved", headers=headers)
    assert response.status_code == 200
    assert response.json() == []


async def test_pagination_limit_offset(client, create_user_headers):
    headers = await create_user_headers("+919000000007")
    for number in range(1, 6):
        await _create_issue(client, headers, title=f"Streetlight flickering {number}")
    full = (await _search(client, q="streetlight", limit=50, headers=headers)).json()
    assert len(full) == 5
    expected_ids = [issue["id"] for issue in full[2:4]]
    response = await _search(client, q="streetlight", limit=2, offset=2, headers=headers)
    assert response.status_code == 200
    assert [issue["id"] for issue in response.json()] == expected_ids


async def test_shielded_privacy(client, create_user_headers):
    headers = await create_user_headers("+919000000008")
    await _create_issue(client, headers, title="Hidden pothole marker", is_shielded=True)
    await _create_issue(client, headers, title="Hidden pothole marker")
    response = await _search(client, q="hidden", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Hidden pothole marker"]
    assert response.json()[0]["is_shielded"] is False


async def test_sqli_probes_safe(client, create_user_headers):
    headers = await create_user_headers("+919000000009")
    await _create_issue(client, headers, title="Pothole on Main St")
    probes = ["%' OR 1=1 --", "pothole%' --"]
    for q in probes:
        response = await _search(client, q=q, headers=headers)
        assert response.status_code == 200
        assert response.json() == []


async def test_whitespace_only_q_422(client, create_user_headers):
    headers = await create_user_headers("+919000000010")
    for q in ("", "  "):
        response = await _search(client, q=q, headers=headers)
        assert response.status_code == 422
        assert response.json()["detail"]


async def test_single_coordinate_400(client, create_user_headers):
    headers = await create_user_headers("+919000000011")
    for params in ({"latitude": 40.0}, {"longitude": -74.0}):
        response = await _search(client, q="k", headers=headers, **params)
        assert response.status_code == 400
        assert response.json()["code"] == "both_coordinates_required"


async def test_out_of_range_coordinates_422(client, create_user_headers):
    headers = await create_user_headers("+919000000012")
    cases = (
        {"latitude": 91, "longitude": 0},
        {"latitude": -91, "longitude": 0},
        {"latitude": 0, "longitude": 181},
        {"latitude": 0, "longitude": -181},
    )
    for params in cases:
        response = await _search(client, q="k", headers=headers, **params)
        assert response.status_code == 422


async def test_invalid_and_valid_status(client, create_user_headers):
    headers = await create_user_headers("+919000000013")
    for status in ("invalid", "Resolved"):
        response = await _search(client, q="k", status=status, headers=headers)
        assert response.status_code == 422
    valid = (
        "unacknowledged",
        "open",
        "under_review",
        "acknowledged",
        "escalating",
        "forwarded",
        "pending_quorum",
        "resolved",
        "disputed",
    )
    for status in valid:
        response = await _search(client, q="k", status=status, headers=headers)
        assert response.status_code == 200


async def test_rate_limit_isolation(client, create_user_headers):
    headers = await create_user_headers("+919000000014")
    for _ in range(60):
        response = await _search(client, q="pothole", headers=headers)
        assert response.status_code == 200
    response = await _search(client, q="pothole", headers=headers)
    assert response.status_code == 429
    assert response.json()["code"] == "rate_limited"
    await _create_issue(client, headers, title="Post rate limit issue")
    other_headers = await create_user_headers("+919000000015")
    response = await _search(client, q="pothole", headers=other_headers)
    assert response.status_code == 200


async def test_guest_can_search(client, create_user_headers):
    user_headers = await create_user_headers("+919000000016")
    await _create_issue(client, user_headers, title="Pothole on Main St")
    guest_response = await client.post("/api/v1/auth/guest")
    assert guest_response.status_code == 200
    token = guest_response.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {token}"}
    response = await _search(client, q="pothole", headers=guest_headers)
    assert response.status_code == 200
    assert response.json()


async def test_q_length_bounds(client, create_user_headers):
    headers = await create_user_headers("+919000000017")
    response = await _search(client, q="k" * 100, headers=headers)
    assert response.status_code == 200
    response = await _search(client, q="k" * 101, headers=headers)
    assert response.status_code == 422


async def test_radius_km_bounds(client, create_user_headers):
    headers = await create_user_headers("+919000000018")
    for radius in (0.05, 60.0):
        response = await _search(
            client,
            q="k",
            latitude=19.1136,
            longitude=72.8697,
            radius_km=radius,
            headers=headers,
        )
        assert response.status_code == 422
    for radius in (0.1, 50.0):
        response = await _search(
            client,
            q="k",
            latitude=19.1136,
            longitude=72.8697,
            radius_km=radius,
            headers=headers,
        )
        assert response.status_code == 200


async def test_category_limit_offset_bounds(client, create_user_headers):
    headers = await create_user_headers("+919000000019")
    response = await _search(client, q="k", category="a" * 33, headers=headers)
    assert response.status_code == 422
    response = await _search(client, q="k", category="a" * 32, headers=headers)
    assert response.status_code == 200
    for limit in (0, 51):
        response = await _search(client, q="k", limit=limit, headers=headers)
        assert response.status_code == 422
    for limit in (1, 50):
        response = await _search(client, q="k", limit=limit, headers=headers)
        assert response.status_code == 200
    response = await _search(client, q="k", offset=-1, headers=headers)
    assert response.status_code == 422
    response = await _search(client, q="k", offset=0, headers=headers)
    assert response.status_code == 200


async def test_float_precision_proximity(client, create_user_headers):
    headers = await create_user_headers("+919000000020")
    await _create_issue(
        client, headers, title="Precision anchor", latitude=40.7128, longitude=-74.0060
    )
    await _create_issue(
        client, headers, title="Precision far", latitude=40.7143, longitude=-74.0060
    )
    response = await _search(
        client,
        q="precision",
        latitude=40.7128,
        longitude=-74.006,
        radius_km=0.1,
        headers=headers,
    )
    assert response.status_code == 200
    titles = _titles(response)
    assert "Precision anchor" in titles
    assert "Precision far" not in titles


async def test_search_result_schema(client, create_user_headers):
    required = {
        "id",
        "title",
        "description",
        "category",
        "status",
        "latitude",
        "longitude",
        "geohash",
        "ward",
        "is_anonymous",
        "fuzz_location",
        "is_fuzzed",
        "is_shielded",
        "reporter_label",
        "reporter_name",
        "reporter_photo_url",
        "anonymous_identity",
        "created_at",
        "acknowledged_at",
        "resolved_at",
        "upvotes_count",
        "comments_count",
        "confirmations_count",
        "disputes_count",
        "resolution_proof",
        "resolution_notes",
        "has_upvoted",
        "has_official_response",
        "reporter_id",
        "media_url",
        "video_url",
        "media_urls",
    }
    headers = await create_user_headers("+919000000021")
    await _create_issue(client, headers, title="Pothole on Main St")
    response = await _search(client, q="pothole", headers=headers)
    assert response.status_code == 200
    issues = response.json()
    assert isinstance(issues, list)
    assert issues
    for field in required:
        assert field in issues[0]
    assert set(issues[0]) == required


async def test_literal_wildcard_security_probes(client, create_user_headers):
    headers = await create_user_headers("+919000000022")
    await _create_issue(client, headers, title="progress is 100% done")
    await _create_issue(client, headers, title="progress is 100XX done")
    await _create_issue(client, headers, title="a_b literal")
    await _create_issue(client, headers, title="aXb wildcard")
    await _create_issue(client, headers, title="back\\slash literal")
    await _create_issue(client, headers, title="backslash plain")

    response = await _search(client, q="100%", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["progress is 100% done"]

    response = await _search(client, q="a_b", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["a_b literal"]

    response = await _search(client, q="back\\slash", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["back\\slash literal"]


async def test_shielded_resolved_passes_through(client, create_user_headers):
    headers = await create_user_headers("+919000000023")
    issue = await _create_issue(client, headers, title="shielded resolved marker", is_shielded=True)
    response = await client.post(
        f"/api/v1/issues/{issue['id']}/resolve",
        json={"resolution_proof": "https://proof.example/x", "notes": "done"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "pending_quorum"

    vote_payload = {"vote": "confirm", "latitude": DEFAULT_LAT, "longitude": DEFAULT_LNG}
    for phone in ("+919000000024", "+919000000025", "+919000000026"):
        voter_headers = await create_user_headers(phone)
        response = await client.post(
            f"/api/v1/issues/{issue['id']}/quorum-vote",
            json=vote_payload,
            headers=voter_headers,
        )
        assert response.status_code == 200, response.text
    assert response.json()["status"] == "resolved"

    response = await _search(client, q="shielded", headers=headers)
    assert response.status_code == 200
    titles = _titles(response)
    assert "shielded resolved marker" in titles
    assert response.json()[0]["is_shielded"] is True


async def test_search_runs_escalation_for_both_statuses(client, create_user_headers):
    headers = await create_user_headers("+919000000027")
    open_issue = await _create_issue(client, headers, title="Escalation open probe")
    await _create_issue(client, headers, title="Escalation acknowledged probe")
    await client.post(f"/api/v1/issues/{open_issue['id']}/acknowledge", headers=headers)

    response = await _search(client, q="escalation", status="unacknowledged", headers=headers)
    assert response.status_code == 200
    assert "Escalation acknowledged probe" in _titles(response)

    response = await _search(client, q="escalation", headers=headers)
    assert response.status_code == 200
    titles = _titles(response)
    assert "Escalation acknowledged probe" in titles
    assert "Escalation open probe" in titles


async def test_two_guest_tokens_pool_on_anon_key(client, create_user_headers):
    user_headers = await create_user_headers("+919000000028")
    await _create_issue(client, user_headers, title="Pothole on Main St")

    guest_1 = (await client.post("/api/v1/auth/guest")).json()["access_token"]
    guest_2 = (await client.post("/api/v1/auth/guest")).json()["access_token"]
    headers_1 = {"Authorization": f"Bearer {guest_1}"}
    headers_2 = {"Authorization": f"Bearer {guest_2}"}

    for _ in range(60):
        response = await _search(client, q="pothole", headers=headers_1)
        assert response.status_code == 200

    response = await _search(client, q="pothole", headers=headers_2)
    assert response.status_code == 429
    assert response.json()["code"] == "rate_limited"


async def test_missing_q_422(client):
    response = await client.get("/api/v1/search")
    assert response.status_code == 422
