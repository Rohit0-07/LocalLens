import httpx


async def test_issue_posting_geohash_indexing(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    payload = {
        "title": "Massive pothole on Link Road",
        "description": "Vehicle axles damaged",
        "category": "road",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "is_anonymous": False,
        "fuzz_location": False,
    }
    response = await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == payload["title"]
    assert data["status"] == "unacknowledged"
    assert data["geohash"] is not None
    assert len(data["geohash"]) == 8
    assert isinstance(data["id"], int)


async def test_issue_posting_location_fuzzing(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    payload = {
        "title": "Garbage dump near residential block",
        "description": "Smell spreading to apartments",
        "category": "waste",
        "latitude": 19.118451,
        "longitude": 72.864319,
        "is_anonymous": True,
        "fuzz_location": True,
    }
    response = await client.post("/api/v1/issues", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["fuzz_location"] is True
    assert data["latitude"] == 19.12
    assert data["longitude"] == 72.86
    assert data["geohash"] is not None
    assert data["reporter_label"] == "Anonymous"


async def test_near_duplicate_detection_endpoint(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    issue_near_payload = {
        "title": "Severe water logging near Andheri West market",
        "description": "Flooding up to 2 feet",
        "category": "water",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "is_anonymous": False,
    }
    create_res = await client.post("/api/v1/issues", json=issue_near_payload, headers=auth_headers)
    assert create_res.status_code == 201
    created_issue = create_res.json()

    issue_far_payload = {
        "title": "Broken pipe in Thane West",
        "description": "Clean water wasting",
        "category": "water",
        "latitude": 19.2183,
        "longitude": 72.9781,
        "is_anonymous": False,
    }
    await client.post("/api/v1/issues", json=issue_far_payload, headers=auth_headers)

    # Near duplicate check near Andheri West (~50m away)
    near_check_res = await client.get(
        "/api/v1/issues/near-duplicate",
        params={"latitude": 19.1140, "longitude": 72.8700, "radius_km": 0.5},
    )
    assert near_check_res.status_code == 200
    duplicates = near_check_res.json()
    assert len(duplicates) == 1
    assert duplicates[0]["id"] == created_issue["id"]
    assert duplicates[0]["distance_meters"] > 0
    assert duplicates[0]["distance_meters"] < 200

    # Near duplicate check in remote area
    remote_check_res = await client.get(
        "/api/v1/issues/near-duplicate",
        params={"latitude": 19.5000, "longitude": 72.5000, "radius_km": 0.5},
    )
    assert remote_check_res.status_code == 200
    assert remote_check_res.json() == []
