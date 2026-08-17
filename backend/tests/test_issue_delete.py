"""Feature 1 (backend): owner delete of issues.

Covers `DELETE /api/v1/issues/{issue_id}` (soft delete via `is_hidden=True`):
  - owner may delete (returns `{"success": true}`),
  - non-owner gets 403 `forbidden`,
  - guests get 403 `guest_restricted`,
  - deleted issue disappears from nearby `GET /issues`, `GET /auth/me/issues`
    and the public profile `public_issues`,
  - deleting an already-deleted (or missing) issue returns 404.
"""

import httpx


async def _create_issue(
    client: httpx.AsyncClient, headers: dict[str, str], *, title: str = "Deep pothole at main junction"
) -> dict:
    payload = {
        "title": title,
        "description": "Vehicle axles getting damaged",
        "category": "road",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "is_anonymous": False,
        "fuzz_location": False,
    }
    res = await client.post("/api/v1/issues", json=payload, headers=headers)
    assert res.status_code == 201
    return res.json()


async def test_non_owner_cannot_delete_issue(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    owner = await create_user_headers("+919876543210")
    other = await create_user_headers("+919876543211")
    issue = await _create_issue(client, owner)

    res = await client.delete(f"/api/v1/issues/{issue['id']}", headers=other)
    assert res.status_code == 403
    body = res.json()
    assert body["code"] == "forbidden"
    assert body["error_code"] == "forbidden"


async def test_owner_delete_soft_removes_issue_from_listings(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    owner = await create_user_headers("+919876543210")
    issue = await _create_issue(client, owner)
    issue_id = issue["id"]

    me = await client.get("/api/v1/auth/me", headers=owner)
    assert me.status_code == 200
    owner_user_id = me.json()["id"]

    nearby_params = {
        "latitude": 19.1136,
        "longitude": 72.8697,
        "radius_km": 2,
    }
    nearby_before = await client.get("/api/v1/issues", params=nearby_params)
    assert any(i["id"] == issue_id for i in nearby_before.json())

    mine_before = await client.get("/api/v1/auth/me/issues", headers=owner)
    assert any(i["id"] == issue_id for i in mine_before.json())

    public_before = await client.get(f"/api/v1/auth/users/{owner_user_id}")
    assert any(i["id"] == issue_id for i in public_before.json()["public_issues"])

    res = await client.delete(f"/api/v1/issues/{issue_id}", headers=owner)
    assert res.status_code == 200
    assert res.json() == {"success": True}

    nearby_after = await client.get("/api/v1/issues", params=nearby_params)
    assert all(i["id"] != issue_id for i in nearby_after.json())

    mine_after = await client.get("/api/v1/auth/me/issues", headers=owner)
    assert all(i["id"] != issue_id for i in mine_after.json())

    public_after = await client.get(f"/api/v1/auth/users/{owner_user_id}")
    assert all(i["id"] != issue_id for i in public_after.json()["public_issues"])


async def test_deleting_twice_returns_404(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    owner = await create_user_headers("+919876543210")
    issue = await _create_issue(client, owner)

    first = await client.delete(f"/api/v1/issues/{issue['id']}", headers=owner)
    assert first.status_code == 200

    second = await client.delete(f"/api/v1/issues/{issue['id']}", headers=owner)
    assert second.status_code == 404


async def test_guest_cannot_delete_issue(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    owner = await create_user_headers("+919876543210")
    issue = await _create_issue(client, owner)

    guest_res = await client.post("/api/v1/auth/guest")
    assert guest_res.status_code == 200
    guest_headers = {"Authorization": f"Bearer {guest_res.json()['access_token']}"}

    res = await client.delete(f"/api/v1/issues/{issue['id']}", headers=guest_headers)
    assert res.status_code == 403
    body = res.json()
    assert body["code"] == "guest_restricted"
    assert body["error_code"] == "guest_restricted"


async def test_delete_missing_issue_returns_404(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    owner = await create_user_headers("+919876543210")
    res = await client.delete("/api/v1/issues/999999", headers=owner)
    assert res.status_code == 404
