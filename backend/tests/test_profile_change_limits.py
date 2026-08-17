"""Feature 1 (backend): profile identity change limits.

Covers server-side enforcement of:
  - display_name: max 2 lifetime changes; first-time setup exempt; identical
    value is a no-op; 3rd real change -> 429 `name_change_limit`.
  - bio: at most once per 7 days (first-time setup exempt but still sets clock);
    early second change -> 429 `bio_change_limited`.
  - photo_url: at most once per 1 hour (first-time exempt); early change ->
    429 `photo_change_limited`.
  - GET/PATCH /api/v1/auth/me echo `bio` and the limit bookkeeping fields.
"""

import httpx


async def test_first_time_display_name_setup_does_not_consume_limit(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")
    me = await client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["display_name"] is None
    assert me.json()["display_name_changes_remaining"] == 2

    res = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Alice"}
    )
    assert res.status_code == 200
    data = res.json()
    assert data["display_name"] == "Alice"
    # First-time setup (was NULL) must NOT consume a change.
    assert data["display_name_changes_remaining"] == 2


async def test_display_name_two_changes_then_third_real_change_429(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")

    # First-time setup (no-op on the budget).
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Alice"}
    )
    assert r.status_code == 200
    assert r.json()["display_name_changes_remaining"] == 2

    # Change 1.
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Bob"}
    )
    assert r.status_code == 200
    assert r.json()["display_name_changes_remaining"] == 1

    # Change 2.
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Carol"}
    )
    assert r.status_code == 200
    assert r.json()["display_name_changes_remaining"] == 0

    # Change 3 -> 429 with code `name_change_limit`.
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Dave"}
    )
    assert r.status_code == 429
    body = r.json()
    assert body["code"] == "name_change_limit"
    assert body["error_code"] == "name_change_limit"


async def test_identical_display_name_is_noop_and_keeps_remaining(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")
    await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Alice"}
    )
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Bob"}
    )
    assert r.status_code == 200
    assert r.json()["display_name_changes_remaining"] == 1

    # Identical value must not consume a change.
    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"display_name": "Bob"}
    )
    assert r.status_code == 200
    data = r.json()
    assert data["display_name"] == "Bob"
    assert data["display_name_changes_remaining"] == 1


async def test_bio_set_once_then_immediate_second_change_429(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")

    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"bio": "Hello neighbours!"}
    )
    assert r.status_code == 200
    data = r.json()
    assert data["bio"] == "Hello neighbours!"
    # First-time setup still sets the clock.
    assert data["bio_next_change_allowed_at"] is not None

    r = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"bio": "Updated bio"}
    )
    assert r.status_code == 429
    body = r.json()
    assert body["code"] == "bio_change_limited"
    assert body["error_code"] == "bio_change_limited"


async def test_photo_url_set_once_then_immediate_second_change_429(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")

    r = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        json={"photo_url": "https://cdn.example.com/avatar_a.jpg"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["photo_url"] == "https://cdn.example.com/avatar_a.jpg"
    assert data["photo_next_change_allowed_at"] is not None

    r = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        json={"photo_url": "https://cdn.example.com/avatar_b.jpg"},
    )
    assert r.status_code == 429
    body = r.json()
    assert body["code"] == "photo_change_limited"
    assert body["error_code"] == "photo_change_limited"


async def test_me_echoes_bio_and_limit_fields_after_updates(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")
    res = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        json={
            "display_name": "Alice",
            "bio": "Ward 45 resident",
            "photo_url": "https://cdn.example.com/a.jpg",
        },
    )
    assert res.status_code == 200

    me = await client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200
    data = me.json()
    assert data["bio"] == "Ward 45 resident"
    assert data["display_name"] == "Alice"
    assert isinstance(data["display_name_changes_remaining"], int)
    assert data["display_name_changes_remaining"] == 2
    assert data["bio_next_change_allowed_at"] is not None
    assert data["photo_next_change_allowed_at"] is not None


async def test_bio_exceeding_200_chars_rejected_by_schema(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    headers = await create_user_headers("+919876543210")
    res = await client.patch(
        "/api/v1/auth/me", headers=headers, json={"bio": "x" * 201}
    )
    assert res.status_code == 422


async def test_guest_cannot_update_profile(
    client: httpx.AsyncClient, create_user_headers
) -> None:
    guest_res = await client.post("/api/v1/auth/guest")
    assert guest_res.status_code == 200
    guest_headers = {"Authorization": f"Bearer {guest_res.json()['access_token']}"}

    res = await client.patch(
        "/api/v1/auth/me", headers=guest_headers, json={"bio": "hi"}
    )
    assert res.status_code == 400
    assert res.json()["code"] == "guest_restricted"
