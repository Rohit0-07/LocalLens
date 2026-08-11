import httpx


async def test_upvote_proximity_success(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken bench in public garden",
            "category": "other",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]
    assert create_res.json()["upvotes_count"] == 0

    upvoter_headers = await create_user_headers("+919888877701")
    upvote_res = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1140, "longitude": 72.8700},
        headers=upvoter_headers,
    )
    assert upvote_res.status_code == 200
    assert upvote_res.json()["upvotes_count"] == 1


async def test_upvote_duplicate_rejection(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Uncollected leaves piling up",
            "category": "waste",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    upvoter_headers = await create_user_headers("+919888877702")
    first_upvote = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=upvoter_headers,
    )
    assert first_upvote.status_code == 200

    second_upvote = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=upvoter_headers,
    )
    assert second_upvote.status_code == 400
    assert second_upvote.json()["code"] == "already_upvoted"


async def test_upvote_proximity_out_of_radius_rejection(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    create_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Damaged divider on Western Express Highway",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = create_res.json()["id"]

    far_user_headers = await create_user_headers("+919888877703")
    far_upvote = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.4500, "longitude": 72.9500},
        headers=far_user_headers,
    )
    assert far_upvote.status_code == 400
    assert far_upvote.json()["code"] == "out_of_radius"


async def test_upvote_rate_limiting(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
) -> None:
    # Create 6 distinct issues
    issue_ids: list[int] = []
    for i in range(6):
        res = await client.post(
            "/api/v1/issues",
            json={
                "title": f"Civic issue number {i + 1} in area",
                "category": "other",
                "latitude": 19.1136,
                "longitude": 72.8697,
            },
            headers=auth_headers,
        )
        issue_ids.append(res.json()["id"])

    # Single voter attempts 6 upvotes
    voter_headers = await create_user_headers("+919888877704")
    for i in range(5):
        upvote_res = await client.post(
            f"/api/v1/issues/{issue_ids[i]}/upvote",
            json={"latitude": 19.1136, "longitude": 72.8697},
            headers=voter_headers,
        )
        assert upvote_res.status_code == 200, f"Upvote {i + 1} failed"

    # 6th upvote attempt within 10 minutes should fail with 429
    sixth_upvote = await client.post(
        f"/api/v1/issues/{issue_ids[5]}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_headers,
    )
    assert sixth_upvote.status_code == 429
    assert sixth_upvote.json()["code"] == "rate_limited"
