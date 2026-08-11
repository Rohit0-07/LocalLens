"""F-08 Advanced Search Filters — backend contract tests (code-blind).

Covers the new ``GET /api/v1/search`` query parameters ``categories``,
``created_after``, ``created_before`` defined in
``docs/specs/F-08_filters_contracts.md`` §1.2/§1.3, and the §3.1 test contract
(cases 1-22). Issues are created exclusively through the public
``POST /api/v1/issues`` API; dates are computed in-test relative to now.

Mapping of test functions to contract §3.1 cases:
  1  -> test_categories_single_value_filters
  2  -> test_categories_multi_value_union
  3  -> test_categories_combined_with_keyword
  4  -> test_created_after_recent_past_includes_fresh
  5  -> test_created_after_future_excludes_all
  6  -> test_created_before_near_future_includes
  7  -> test_created_before_past_excludes_all
  8  -> test_both_bounds_spanning_and_excluding
  9  -> test_created_after_greater_than_before_422
  10 -> test_created_after_not_a_date_422
  11 -> test_created_before_invalid_month_day_422
  12 -> test_date_only_format_accepted
  13 -> test_iso_z_and_offset_formats_accepted
  14 -> test_categories_item_too_long_422
  15 -> test_categories_too_many_items_422
  16 -> test_categories_absent_means_no_filter
  17 -> test_combined_filters_intersection
  18 -> test_shielded_privacy_preserved_with_filters
  19 -> test_rate_limit_preserved_with_filters
  20 -> test_sqli_and_junk_dates_never_500
  21 -> test_guest_search_with_filters
  22 -> test_pagination_composition_with_filters
"""

from datetime import UTC, datetime, timedelta

import httpx

DEFAULT_LAT = 19.1136
DEFAULT_LNG = 72.8697


async def _create_issue(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    *,
    title: str,
    description: str = "",
    category: str = "road",
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


def _now_iso(**kwargs) -> str:
    """ISO-8601 for now plus the given ``timedelta`` kwargs (relative, never backdated)."""
    return (datetime.now(UTC) + timedelta(**kwargs)).isoformat()


async def test_categories_single_value_filters(client, create_user_headers):
    """§3.1.1 — a single `categories` value keeps only issues in that category."""
    headers = await create_user_headers("+919000100001")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    await _create_issue(client, headers, title="Filtered water leak", category="water")
    response = await _search(client, q="filtered", categories="road", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Filtered road pothole"]


async def test_categories_multi_value_union(client, create_user_headers):
    """§3.1.2 — repeated `categories` query params act as an OR within the list."""
    headers = await create_user_headers("+919000100002")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    await _create_issue(client, headers, title="Filtered water leak", category="water")
    await _create_issue(client, headers, title="Filtered power outage", category="power")
    response = await client.get(
        "/api/v1/search",
        params=[("q", "filtered"), ("categories", "road"), ("categories", "water")],
        headers=headers,
    )
    assert response.status_code == 200
    assert sorted(_titles(response)) == ["Filtered road pothole", "Filtered water leak"]


async def test_categories_combined_with_keyword(client, create_user_headers):
    """§3.1.3 — `categories` AND `q` both apply (keyword AND category)."""
    headers = await create_user_headers("+919000100003")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    await _create_issue(client, headers, title="Unrelated road issue", category="road")
    await _create_issue(client, headers, title="Filtered water leak", category="water")
    response = await _search(client, q="filtered", categories="road", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Filtered road pothole"]


async def test_created_after_recent_past_includes_fresh(client, create_user_headers):
    """§3.1.4 — `created_after` just in the past keeps freshly created issues."""
    headers = await create_user_headers("+919000100004")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(client, q="recent", created_after=_now_iso(days=-1), headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Recent road pothole"]


async def test_created_after_future_excludes_all(client, create_user_headers):
    """§3.1.5 — a future `created_after` yields an empty result set."""
    headers = await create_user_headers("+919000100005")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(client, q="recent", created_after=_now_iso(days=1), headers=headers)
    assert response.status_code == 200
    assert response.json() == []


async def test_created_before_near_future_includes(client, create_user_headers):
    """§3.1.6 — a near-future `created_before` keeps the created issues."""
    headers = await create_user_headers("+919000100006")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(client, q="recent", created_before=_now_iso(days=1), headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Recent road pothole"]


async def test_created_before_past_excludes_all(client, create_user_headers):
    """§3.1.7 — a past `created_before` yields an empty result set."""
    headers = await create_user_headers("+919000100007")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(client, q="recent", created_before=_now_iso(days=-1), headers=headers)
    assert response.status_code == 200
    assert response.json() == []


async def test_both_bounds_spanning_and_excluding(client, create_user_headers):
    """§3.1.8 — a spanning window returns issues; a window covering nothing is empty."""
    headers = await create_user_headers("+919000100008")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(
        client,
        q="recent",
        created_after=_now_iso(days=-1),
        created_before=_now_iso(days=1),
        headers=headers,
    )
    assert response.status_code == 200
    assert _titles(response) == ["Recent road pothole"]
    response = await _search(
        client,
        q="recent",
        created_after=_now_iso(days=2),
        created_before=_now_iso(days=3),
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json() == []


async def test_created_after_greater_than_before_422(client, create_user_headers):
    """§3.1.9 — `created_after > created_before` → 422 invalid_date_range."""
    headers = await create_user_headers("+919000100009")
    response = await _search(
        client,
        q="recent",
        created_after=_now_iso(days=1),
        created_before=_now_iso(days=-1),
        headers=headers,
    )
    assert response.status_code == 422
    assert response.json()["code"] == "invalid_date_range"


async def test_created_after_not_a_date_422(client, create_user_headers):
    """§3.1.10 — unparseable `created_after` → 422 invalid_date_format."""
    headers = await create_user_headers("+919000100010")
    response = await _search(client, q="recent", created_after="not-a-date", headers=headers)
    assert response.status_code == 422
    assert response.json()["code"] == "invalid_date_format"


async def test_created_before_invalid_month_day_422(client, create_user_headers):
    """§3.1.11 — impossible `created_before` (2026-13-99) → 422 invalid_date_format."""
    headers = await create_user_headers("+919000100011")
    response = await _search(client, q="recent", created_before="2026-13-99", headers=headers)
    assert response.status_code == 422
    assert response.json()["code"] == "invalid_date_format"


async def test_date_only_format_accepted(client, create_user_headers):
    """§3.1.12 — date-only `YYYY-MM-DD` is accepted (interpreted as midnight UTC)."""
    headers = await create_user_headers("+919000100012")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    response = await _search(client, q="recent", created_after="2020-01-01", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Recent road pothole"]


async def test_iso_z_and_offset_formats_accepted(client, create_user_headers):
    """§3.1.13 — trailing `Z` and explicit offsets are accepted and normalized to UTC."""
    headers = await create_user_headers("+919000100013")
    await _create_issue(client, headers, title="Recent road pothole", category="road")
    for value in ("2020-01-01T00:00:00Z", "2020-01-01T00:00:00+05:30"):
        response = await _search(client, q="recent", created_after=value, headers=headers)
        assert response.status_code == 200
        assert _titles(response) == ["Recent road pothole"]


async def test_categories_item_too_long_422(client, create_user_headers):
    """§3.1.14 — any `categories` item longer than 32 chars → 422 invalid_category."""
    headers = await create_user_headers("+919000100014")
    response = await _search(client, q="recent", categories="a" * 33, headers=headers)
    assert response.status_code == 422
    assert response.json()["code"] == "invalid_category"


async def test_categories_too_many_items_422(client, create_user_headers):
    """§3.1.15 — more than 20 `categories` items → 422 invalid_category."""
    headers = await create_user_headers("+919000100015")
    response = await client.get(
        "/api/v1/search",
        params=[("q", "recent")] + [("categories", "road")] * 21,
        headers=headers,
    )
    assert response.status_code == 422
    assert response.json()["code"] == "invalid_category"


async def test_categories_absent_means_no_filter(client, create_user_headers):
    """§3.1.16 — no `categories` at all → 200 and no category restriction."""
    headers = await create_user_headers("+919000100016")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    await _create_issue(client, headers, title="Filtered water leak", category="water")
    response = await _search(client, q="filtered", headers=headers)
    assert response.status_code == 200
    assert sorted(_titles(response)) == ["Filtered road pothole", "Filtered water leak"]


async def test_combined_filters_intersection(client, create_user_headers):
    """§3.1.17 — status + categories + radius_km + created-window → intersection only."""
    headers = await create_user_headers("+919000100017")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    await _create_issue(
        client,
        headers,
        title="Filtered far road issue",
        category="road",
        latitude=28.6139,
        longitude=77.2090,
    )
    await _create_issue(client, headers, title="Filtered water leak", category="water")
    response = await _search(
        client,
        q="filtered",
        status="unacknowledged",
        categories="road",
        latitude=DEFAULT_LAT,
        longitude=DEFAULT_LNG,
        radius_km=5.0,
        created_after=_now_iso(days=-1),
        created_before=_now_iso(days=1),
        headers=headers,
    )
    assert response.status_code == 200
    assert _titles(response) == ["Filtered road pothole"]


async def test_shielded_privacy_preserved_with_filters(client, create_user_headers):
    """§3.1.18 — shielded non-resolved issues stay hidden under active filters."""
    headers = await create_user_headers("+919000100018")
    await _create_issue(
        client, headers, title="Filtered hidden pothole", category="road", is_shielded=True
    )
    await _create_issue(client, headers, title="Filtered hidden pothole", category="road")
    response = await _search(client, q="filtered", categories="road", headers=headers)
    assert response.status_code == 200
    assert _titles(response) == ["Filtered hidden pothole"]
    assert response.json()[0]["is_shielded"] is False


async def test_rate_limit_preserved_with_filters(client, create_user_headers):
    """§3.1.19 — rate limit unchanged under filters: 60 OK, the 61st → 429."""
    headers = await create_user_headers("+919000100019")
    for _ in range(60):
        response = await _search(client, q="pothole", categories="road", headers=headers)
        assert response.status_code == 200
    response = await _search(client, q="pothole", categories="road", headers=headers)
    assert response.status_code == 429
    assert response.json()["code"] == "rate_limited"


async def test_sqli_and_junk_dates_never_500(client, create_user_headers):
    """§3.1.20 — crafted `categories`/date values are data: never 500, never widening."""
    headers = await create_user_headers("+919000100020")
    await _create_issue(client, headers, title="Filtered road pothole", category="road")
    response = await client.get(
        "/api/v1/search",
        params=[("q", "filtered"), ("categories", "road' OR 1=1 --")],
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json() == []
    for param in ("created_after", "created_before"):
        response = await _search(client, q="filtered", **{param: "not-a-date"}, headers=headers)
        assert response.status_code == 422
        assert response.json()["code"] == "invalid_date_format"


async def test_guest_search_with_filters(client, create_user_headers):
    """§3.1.21 — a guest can search with filters active on the same terms."""
    user_headers = await create_user_headers("+919000100021")
    await _create_issue(client, user_headers, title="Filtered road pothole", category="road")
    guest_response = await client.post("/api/v1/auth/guest")
    assert guest_response.status_code == 200
    token = guest_response.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {token}"}
    response = await _search(
        client,
        q="filtered",
        categories="road",
        created_after=_now_iso(days=-1),
        headers=guest_headers,
    )
    assert response.status_code == 200
    assert _titles(response) == ["Filtered road pothole"]


async def test_pagination_composition_with_filters(client, create_user_headers):
    """§3.1.22 — limit/offset slice correctly while filters are active."""
    headers = await create_user_headers("+919000100022")
    for number in range(1, 6):
        await _create_issue(
            client, headers, title=f"Filtered paged marker {number}", category="road"
        )
    full = (
        await _search(client, q="filtered", categories="road", limit=50, headers=headers)
    ).json()
    assert len(full) == 5
    expected_ids = [issue["id"] for issue in full[2:4]]
    response = await _search(
        client, q="filtered", categories="road", limit=2, offset=2, headers=headers
    )
    assert response.status_code == 200
    assert [issue["id"] for issue in response.json()] == expected_ids
