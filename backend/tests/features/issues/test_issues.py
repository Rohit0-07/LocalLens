from httpx import AsyncClient

_PAYLOAD: dict = {
    "title": "Deep pothole near the bus stop",
    "description": "Three tires punctured this week",
    "category": "road",
    "latitude": 19.1136,
    "longitude": 72.8697,
    "is_anonymous": False,
}


async def _create(client: AsyncClient, headers: dict[str, str], **overrides: object) -> dict:
    payload = {**_PAYLOAD, **overrides}
    response = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_create_issue_requires_auth(client: AsyncClient) -> None:
    response = await client.post("/api/v1/issues", json=_PAYLOAD)
    assert response.status_code == 401


async def test_create_and_list_issue(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    created = await _create(client, auth_headers)
    assert created["status"] == "unacknowledged"
    assert created["reporter_label"] == "Verified citizen"

    response = await client.get(
        "/api/v1/issues", params={"latitude": 19.1136, "longitude": 72.8697}
    )
    assert response.status_code == 200
    issues = response.json()
    assert len(issues) == 1
    assert issues[0]["id"] == created["id"]


async def test_anonymous_issue_hides_reporter(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    created = await _create(client, auth_headers, is_anonymous=True)
    assert created["is_anonymous"] is True
    assert created["reporter_label"] == "Anonymous"


async def test_radius_filter_excludes_far_issue(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    await _create(client, auth_headers)
    await _create(client, auth_headers, latitude=19.5000, longitude=72.9000)

    response = await client.get(
        "/api/v1/issues",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 5.0},
    )
    assert len(response.json()) == 1


async def test_status_filter(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    created = await _create(client, auth_headers)
    response = await client.get(
        "/api/v1/issues",
        params={
            "latitude": 19.1136,
            "longitude": 72.8697,
            "radius_km": 5.0,
            "status": "resolved",
        },
    )
    assert response.json() == []

    response = await client.get(
        "/api/v1/issues",
        params={
            "latitude": 19.1136,
            "longitude": 72.8697,
            "radius_km": 5.0,
            "status": created["status"],
        },
    )
    assert len(response.json()) == 1


async def test_get_single_issue(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    created = await _create(client, auth_headers)
    response = await client.get(f"/api/v1/issues/{created['id']}")
    assert response.status_code == 200
    assert response.json()["title"] == _PAYLOAD["title"]


async def test_get_missing_issue_returns_404(client: AsyncClient) -> None:
    response = await client.get("/api/v1/issues/99999")
    assert response.status_code == 404


async def test_create_issue_rejects_invalid_payload(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    response = await client.post(
        "/api/v1/issues", json={**_PAYLOAD, "latitude": 999.0}, headers=auth_headers
    )
    assert response.status_code == 422


async def test_near_duplicate_detection(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    created = await _create(client, auth_headers)
    response = await client.get(
        "/api/v1/issues/near-duplicate",
        params={"latitude": 19.1136, "longitude": 72.8697, "radius_km": 0.5},
    )
    assert response.status_code == 200
    dups = response.json()
    assert len(dups) >= 1
    assert dups[0]["id"] == created["id"]


async def test_fuzz_and_shield_modes(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    # Fuzzed issue
    fuzzed = await _create(
        client, auth_headers, is_fuzzed=True, latitude=19.113642, longitude=72.869715
    )
    assert fuzzed["is_fuzzed"] is True
    assert fuzzed["latitude"] == 19.11
    assert fuzzed["longitude"] == 72.87

    # Shielded issue
    shielded = await _create(client, auth_headers, is_shielded=True)
    assert shielded["is_shielded"] is True

    # Shielded issue should be hidden from public feed unless resolved
    response = await client.get(
        "/api/v1/issues", params={"latitude": 19.1136, "longitude": 72.8697}
    )
    ids = [i["id"] for i in response.json()]
    assert shielded["id"] not in ids


async def test_resolution_and_quorum_voting(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    issue = await _create(client, auth_headers)
    issue_id = issue["id"]

    # Submit resolution
    res_resp = await client.post(
        f"/api/v1/issues/{issue_id}/resolve",
        json={
            "resolution_proof": "https://storage.example.com/proof.jpg",
            "notes": "Fixed pothole",
        },
        headers=auth_headers,
    )
    assert res_resp.status_code == 200
    assert res_resp.json()["status"] == "pending_quorum"

    # Vote on quorum
    vote_resp = await client.post(
        f"/api/v1/issues/{issue_id}/quorum-vote",
        json={"vote": "confirm", "latitude": 19.1136, "longitude": 72.8697, "reason": "Looks good"},
        headers=auth_headers,
    )
    assert vote_resp.status_code == 200
    assert vote_resp.json()["confirmations_count"] == 1
