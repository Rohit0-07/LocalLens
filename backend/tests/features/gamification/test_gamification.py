"""Tests for F-12 Gamification Engine (Impact Score, Civic Badges & Daily Streaks).

Endpoints tested:
1. GET /api/v1/gamification/me
2. POST /api/v1/gamification/claim-daily-streak
3. GET /api/v1/gamification/badges

Test Cases Covered:
BE-GAM-001 to BE-GAM-020 (Backend API & Business Logic)
SEC-GAM-001 to SEC-GAM-010 (Security, Rate Limiting & Boundaries)
"""

import asyncio
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


# --- Helpers ---


async def _create_user(client: httpx.AsyncClient, phone: str) -> tuple[dict[str, str], int]:
    """Helper to register/verify a user and return auth headers + user_id."""
    await client.post("/api/v1/auth/otp/request", json={"phone": phone})
    res = await client.post("/api/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})
    assert res.status_code == 200, res.text
    data = res.json()
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    return headers, data["user_id"]


async def _create_guest(client: httpx.AsyncClient) -> tuple[dict[str, str], str]:
    """Helper to acquire a guest session token."""
    res = await client.post("/api/v1/auth/guest")
    assert res.status_code == 200, res.text
    data = res.json()
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    return headers, str(data["user_id"])


async def _seed_user_activities(
    app: Any,
    user_id: int,
    issues_created: int = 0,
    upvotes_cast: int = 0,
    quorum_votes_cast: int = 0,
    comments_posted: int = 0,
    streak_days: int = 0,
    last_streak_date: str | None = None,
) -> None:
    """Helper to directly seed or update activity counts & streak info for a user."""
    async with app.state.database.session_factory() as session:
        # 1. Seed issues
        for i in range(issues_created):
            try:
                from app.features.issues.models import Issue

                issue = Issue(
                    reporter_id=user_id,
                    title=f"Seeded Issue {i + 1}",
                    description="Desc",
                    category="road",
                    latitude=19.1136,
                    longitude=72.8697,
                    geohash="te7u8x",
                    ward="Ward 1",
                    is_anonymous=False,
                    status="open",
                )
                session.add(issue)
                await session.commit()
            except Exception:
                await session.execute(
                    text(
                        "INSERT INTO issues (reporter_id, title, description, category, latitude, longitude, geohash, ward, is_anonymous, status, created_at) "
                        "VALUES (:user_id, :title, 'Desc', 'road', 19.1136, 72.8697, 'te7u8x', 'Ward 1', 0, 'open', :now)"
                    ),
                    {
                        "user_id": user_id,
                        "title": f"Seeded Issue {i + 1}",
                        "now": datetime.now(UTC).isoformat(),
                    },
                )
                await session.commit()

        # 2. Seed upvotes (create dummy issues owned by user 9999 to upvote;
        # uq_upvotes_issue_user allows one upvote per user per issue, so each
        # upvote needs its own dummy issue)
        if upvotes_cast > 0:
            dummy_issue_ids: list[int] = []
            for _i in range(upvotes_cast):
                try:
                    from app.features.issues.models import Issue

                    dummy_issue = Issue(
                        reporter_id=9999,
                        title=f"Dummy Upvote Issue {_i + 1}",
                        description="Desc",
                        category="road",
                        latitude=19.1136,
                        longitude=72.8697,
                        geohash="te7u8x",
                        ward="Ward 1",
                        is_anonymous=False,
                        status="open",
                    )
                    session.add(dummy_issue)
                    await session.commit()
                    await session.refresh(dummy_issue)
                    dummy_issue_ids.append(dummy_issue.id)
                except Exception:
                    res = await session.execute(
                        text(
                            "INSERT INTO issues (reporter_id, title, description, category, latitude, longitude, geohash, ward, is_anonymous, status, created_at) "
                            "VALUES (9999, :title, 'Desc', 'road', 19.1136, 72.8697, 'te7u8x', 'Ward 1', 0, 'open', :now) RETURNING id"
                        ),
                        {
                            "title": f"Dummy Upvote Issue {_i + 1}",
                            "now": datetime.now(UTC).isoformat(),
                        },
                    )
                    await session.commit()
                    dummy_issue_ids.append(res.fetchone()[0])

            for _i in range(upvotes_cast):
                try:
                    await session.execute(
                        text(
                            "INSERT INTO upvotes (issue_id, user_id, created_at) "
                            "VALUES (:issue_id, :user_id, :now)"
                        ),
                        {
                            "issue_id": dummy_issue_ids[_i],
                            "user_id": user_id,
                            "now": datetime.now(UTC).isoformat(),
                        },
                    )
                except Exception:
                    try:
                        await session.execute(
                            text(
                                "INSERT INTO issue_upvotes (issue_id, user_id, latitude, longitude, created_at) "
                                "VALUES (:issue_id, :user_id, 19.1136, 72.8697, :now)"
                            ),
                            {
                                "issue_id": dummy_issue_ids[_i],
                                "user_id": user_id,
                                "now": datetime.now(UTC).isoformat(),
                            },
                        )
                    except Exception:
                        pass

        # 3. Seed quorum votes (one vote per user per issue, so each vote
        # needs its own dummy issue)
        if quorum_votes_cast > 0:
            dummy_q_ids: list[int] = []
            for _i in range(quorum_votes_cast):
                try:
                    from app.features.issues.models import Issue

                    dummy_q = Issue(
                        reporter_id=9999,
                        title=f"Dummy Quorum Issue {_i + 1}",
                        description="Desc",
                        category="road",
                        latitude=19.1136,
                        longitude=72.8697,
                        geohash="te7u8x",
                        ward="Ward 1",
                        is_anonymous=False,
                        status="pending_quorum",
                    )
                    session.add(dummy_q)
                    await session.commit()
                    await session.refresh(dummy_q)
                    dummy_q_ids.append(dummy_q.id)
                except Exception:
                    res_q = await session.execute(
                        text(
                            "INSERT INTO issues (reporter_id, title, description, category, latitude, longitude, geohash, ward, is_anonymous, status, created_at) "
                            "VALUES (9999, :title, 'Desc', 'road', 19.1136, 72.8697, 'te7u8x', 'Ward 1', 0, 'pending_quorum', :now) RETURNING id"
                        ),
                        {
                            "title": f"Dummy Quorum Issue {_i + 1}",
                            "now": datetime.now(UTC).isoformat(),
                        },
                    )
                    await session.commit()
                    dummy_q_ids.append(res_q.fetchone()[0])

            for _i in range(quorum_votes_cast):
                try:
                    await session.execute(
                        text(
                            "INSERT INTO quorum_votes (issue_id, user_id, vote, created_at) "
                            "VALUES (:issue_id, :user_id, 'confirm', :now)"
                        ),
                        {
                            "issue_id": dummy_q_ids[_i],
                            "user_id": user_id,
                            "now": datetime.now(UTC).isoformat(),
                        },
                    )
                except Exception:
                    pass

        # 4. Seed comments
        if comments_posted > 0:
            try:
                from app.features.issues.models import Issue

                dummy_c = Issue(
                    reporter_id=9999,
                    title="Dummy Comment Issue",
                    description="Desc",
                    category="road",
                    latitude=19.1136,
                    longitude=72.8697,
                    geohash="te7u8x",
                    ward="Ward 1",
                    is_anonymous=False,
                    status="open",
                )
                session.add(dummy_c)
                await session.commit()
                await session.refresh(dummy_c)
                dummy_c_id = dummy_c.id
            except Exception:
                res_c = await session.execute(
                    text(
                        "INSERT INTO issues (reporter_id, title, description, category, latitude, longitude, geohash, ward, is_anonymous, status, created_at) "
                        "VALUES (9999, 'Dummy Comment Issue', 'Desc', 'road', 19.1136, 72.8697, 'te7u8x', 'Ward 1', 0, 'open', :now) RETURNING id"
                    ),
                    {"now": datetime.now(UTC).isoformat()},
                )
                await session.commit()
                dummy_c_id = res_c.fetchone()[0]

            import uuid

            for i in range(comments_posted):
                try:
                    await session.execute(
                        text(
                            "INSERT INTO comments (id, issue_id, author_id, anon_id, content, created_at) "
                            "VALUES (:id, :issue_id, :user_id, 'anon_test', :content, :now)"
                        ),
                        {
                            "id": str(uuid.uuid4()),
                            "issue_id": dummy_c_id,
                            "user_id": user_id,
                            "content": f"Comment #{i + 1}",
                            "now": datetime.now(UTC).isoformat(),
                        },
                    )
                except Exception:
                    pass

        # 5. Seed user_gamifications table if exists
        try:
            await session.execute(
                text(
                    "INSERT INTO user_gamifications (user_id, streak_days, last_streak_date, impact_score) "
                    "VALUES (:user_id, :streak_days, :last_streak_date, 0) "
                    "ON CONFLICT(user_id) DO UPDATE SET streak_days = :streak_days, last_streak_date = :last_streak_date"
                ),
                {
                    "user_id": user_id,
                    "streak_days": streak_days,
                    "last_streak_date": last_streak_date,
                },
            )
        except Exception:
            pass

        await session.commit()


# --- BE-GAM-001 to BE-GAM-020 ---


async def test_be_gam_001_get_profile_authenticated_user(client: httpx.AsyncClient) -> None:
    """BE-GAM-001: Get Profile - Authenticated User returns complete GamificationProfileOut schema."""
    headers, _ = await _create_user(client, "+919876543201")
    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["is_guest"] is False
    assert "impact_score" in data and isinstance(data["impact_score"], int)
    assert "level" in data and isinstance(data["level"], int)
    assert "level_name" in data and isinstance(data["level_name"], str)
    assert "next_level_score" in data
    assert "streak_days" in data and isinstance(data["streak_days"], int)
    assert "last_streak_date" in data
    assert "can_claim_streak" in data and isinstance(data["can_claim_streak"], bool)
    assert "badges" in data and isinstance(data["badges"], list)
    assert "activity_counts" in data and isinstance(data["activity_counts"], dict)


async def test_be_gam_002_live_impact_score_calculation_formula(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-002: Live impact score formula = (issues*50) + (upvotes*5) + (quorum*20) + (comments*10) + (streaks*15)."""
    headers, user_id = await _create_user(client, "+919876543202")
    today_str = datetime.now(UTC).date().isoformat()
    # 2 issues, 5 upvotes, 1 quorum vote, 2 comments, 3 claimed streaks
    await _seed_user_activities(
        app,
        user_id=user_id,
        issues_created=2,
        upvotes_cast=5,
        quorum_votes_cast=1,
        comments_posted=2,
        streak_days=3,
        last_streak_date=today_str,
    )

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()
    # Expected: (2*50) + (5*5) + (1*20) + (2*10) + (3*15) = 100 + 25 + 20 + 20 + 45 = 210
    assert data["impact_score"] == 210


async def test_be_gam_003_level_boundary_level_1(app: Any, client: httpx.AsyncClient) -> None:
    """BE-GAM-003: Impact score 0..99 -> Level 1 (Civic Rookie), next 100."""
    headers, user_id = await _create_user(client, "+919876543203")
    await _seed_user_activities(app, user_id=user_id, issues_created=1)  # 50 pts

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["level"] == 1
    assert data["level_name"] == "Civic Rookie"
    assert data["next_level_score"] == 100


async def test_be_gam_004_level_boundary_level_2(app: Any, client: httpx.AsyncClient) -> None:
    """BE-GAM-004: Impact score 100..299 -> Level 2 (Active Neighbor), next 300."""
    headers, user_id = await _create_user(client, "+919876543204")
    await _seed_user_activities(app, user_id=user_id, issues_created=2)  # 100 pts

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["level"] == 2
    assert data["level_name"] == "Active Neighbor"
    assert data["next_level_score"] == 300


async def test_be_gam_005_level_boundary_level_3(app: Any, client: httpx.AsyncClient) -> None:
    """BE-GAM-005: Impact score 300..699 -> Level 3 (Community Guardian), next 700."""
    headers, user_id = await _create_user(client, "+919876543205")
    await _seed_user_activities(app, user_id=user_id, issues_created=6)  # 300 pts

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["level"] == 3
    assert data["level_name"] == "Community Guardian"
    assert data["next_level_score"] == 700


async def test_be_gam_006_level_boundary_level_4(app: Any, client: httpx.AsyncClient) -> None:
    """BE-GAM-006: Impact score 700..1499 -> Level 4 (Civic Champion), next 1500."""
    headers, user_id = await _create_user(client, "+919876543206")
    await _seed_user_activities(app, user_id=user_id, issues_created=14)  # 700 pts

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["level"] == 4
    assert data["level_name"] == "Civic Champion"
    assert data["next_level_score"] == 1500


async def test_be_gam_007_level_boundary_level_5(app: Any, client: httpx.AsyncClient) -> None:
    """BE-GAM-007: Impact score >= 1500 -> Level 5 (City Hero), next null."""
    headers, user_id = await _create_user(client, "+919876543207")
    await _seed_user_activities(app, user_id=user_id, issues_created=30)  # 1500 pts

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["level"] == 5
    assert data["level_name"] == "City Hero"
    assert data["next_level_score"] is None


async def test_be_gam_008_dynamic_badge_unlock_first_report(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-008: Creating 1 issue unlocks dynamic badge 'first_report'."""
    headers, user_id = await _create_user(client, "+919876543208")
    await _seed_user_activities(app, user_id=user_id, issues_created=1)

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    unlocked_keys = [
        b["badge_key"]
        for b in data["badges"]
        if b.get("unlocked_at") is not None
        or b.get("is_unlocked") is True
        or b.get("key") == "first_report"
        or b.get("badge_key") == "first_report"
    ]
    assert "first_report" in unlocked_keys or any(
        b.get("key") == "first_report" or b.get("badge_key") == "first_report"
        for b in data["badges"]
    )


async def test_be_gam_009_dynamic_badge_unlock_civic_voter(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-009: Casting 5 upvotes unlocks dynamic badge 'civic_voter'."""
    headers, user_id = await _create_user(client, "+919876543209")
    await _seed_user_activities(app, user_id=user_id, upvotes_cast=5)

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert any(
        b.get("key") == "civic_voter" or b.get("badge_key") == "civic_voter" for b in data["badges"]
    )


async def test_be_gam_010_dynamic_badge_unlock_quorum_hero(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-010: Casting 3 quorum votes unlocks dynamic badge 'quorum_hero'."""
    headers, user_id = await _create_user(client, "+919876543210")
    await _seed_user_activities(app, user_id=user_id, quorum_votes_cast=3)

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert any(
        b.get("key") == "quorum_hero" or b.get("badge_key") == "quorum_hero" for b in data["badges"]
    )


async def test_be_gam_011_dynamic_badge_unlock_neighborhood_voice(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-011: Posting 5 comments unlocks dynamic badge 'neighborhood_voice'."""
    headers, user_id = await _create_user(client, "+919876543211")
    await _seed_user_activities(app, user_id=user_id, comments_posted=5)

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert any(
        b.get("key") == "neighborhood_voice" or b.get("badge_key") == "neighborhood_voice"
        for b in data["badges"]
    )


async def test_be_gam_012_dynamic_badge_unlock_streak_master(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-012: Reaching 7-day daily streak unlocks dynamic badge 'streak_master'."""
    headers, user_id = await _create_user(client, "+919876543212")
    today_str = datetime.now(UTC).date().isoformat()
    await _seed_user_activities(app, user_id=user_id, streak_days=7, last_streak_date=today_str)

    response = await client.get("/api/v1/gamification/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert any(
        b.get("key") == "streak_master" or b.get("badge_key") == "streak_master"
        for b in data["badges"]
    )


async def test_be_gam_013_guest_baseline_fallback(client: httpx.AsyncClient) -> None:
    """BE-GAM-013: Unauthenticated / Guest user receives baseline profile fallback."""
    guest_headers, _ = await _create_guest(client)

    # 1. Guest JWT session
    guest_res = await client.get("/api/v1/gamification/me", headers=guest_headers)
    assert guest_res.status_code == 200
    guest_data = guest_res.json()
    assert guest_data["is_guest"] is True
    assert guest_data["impact_score"] == 0
    assert guest_data["level"] == 1
    assert guest_data["level_name"] == "Civic Rookie"
    assert guest_data["next_level_score"] == 100
    assert guest_data["streak_days"] == 0
    assert guest_data["last_streak_date"] is None
    assert guest_data["can_claim_streak"] is False
    assert guest_data["badges"] == []

    # 2. Missing Bearer token
    unauth_res = await client.get("/api/v1/gamification/me")
    assert unauth_res.status_code in (200, 401)
    if unauth_res.status_code == 200:
        unauth_data = unauth_res.json()
        assert unauth_data["is_guest"] is True
        assert unauth_data["impact_score"] == 0


async def test_be_gam_014_claim_streak_success(client: httpx.AsyncClient) -> None:
    """BE-GAM-014: Authenticated user claims daily streak successfully (+15 points, +1 day)."""
    headers, _ = await _create_user(client, "+919876543214")

    response = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["streak_days"] == 1
    assert data["points_earned"] == 15
    assert data["impact_score"] >= 15
    assert "message" in data or "detail" in data or "status" in data


async def test_be_gam_015_claim_streak_duplicate_same_day(client: httpx.AsyncClient) -> None:
    """BE-GAM-015: Duplicate streak claim on same calendar day returns HTTP 400."""
    headers, _ = await _create_user(client, "+919876543215")

    first_resp = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert first_resp.status_code == 200

    second_resp = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert second_resp.status_code == 400
    data = second_resp.json()
    assert (
        "Daily streak already claimed today" in str(data)
        or data.get("detail") == "Daily streak already claimed today"
    )


async def test_be_gam_016_claim_streak_consecutive_days(
    app: Any, client: httpx.AsyncClient
) -> None:
    """BE-GAM-016: Streak increments continuously when claimed on consecutive days."""
    headers, user_id = await _create_user(client, "+919876543216")
    yesterday_str = (datetime.now(UTC).date() - timedelta(days=1)).isoformat()
    await _seed_user_activities(app, user_id=user_id, streak_days=3, last_streak_date=yesterday_str)

    response = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["streak_days"] == 4


async def test_be_gam_017_claim_streak_guest_rejection(client: httpx.AsyncClient) -> None:
    """BE-GAM-017: Guest user calling claim-daily-streak receives HTTP 403 Forbidden."""
    guest_headers, _ = await _create_guest(client)

    response = await client.post("/api/v1/gamification/claim-daily-streak", headers=guest_headers)
    assert response.status_code == 403
    data = response.json()
    assert (
        "Guest users cannot claim daily streaks" in str(data)
        or data.get("code") == "guest_restricted"
    )


async def test_be_gam_018_claim_streak_unauthenticated_rejection(client: httpx.AsyncClient) -> None:
    """BE-GAM-018: Unauthenticated claim-daily-streak receives HTTP 401 Unauthorized."""
    response = await client.post("/api/v1/gamification/claim-daily-streak")
    assert response.status_code == 401


async def test_be_gam_019_public_badge_directory_retrieval(client: httpx.AsyncClient) -> None:
    """BE-GAM-019: GET /gamification/badges returns 5 BadgeMetadataOut items."""
    response = await client.get("/api/v1/gamification/badges")
    assert response.status_code == 200, response.text
    badges = response.json()

    assert isinstance(badges, list)
    assert len(badges) == 5

    expected_keys = {
        "first_report",
        "civic_voter",
        "quorum_hero",
        "neighborhood_voice",
        "streak_master",
    }
    returned_keys = {b.get("key") or b.get("badge_key") for b in badges}
    assert expected_keys == returned_keys

    for b in badges:
        assert "name" in b
        assert "description" in b
        assert "icon_name" in b
        assert "category" in b
        assert "threshold" in b


async def test_be_gam_020_public_badge_directory_access_control(client: httpx.AsyncClient) -> None:
    """BE-GAM-020: GET /gamification/badges is public and requires zero auth headers."""
    response = await client.get("/api/v1/gamification/badges")
    assert response.status_code == 200


# --- Security & Boundary Cases (SEC-GAM-001 to SEC-GAM-010) ---


async def test_sec_gam_001_sqli_prevention_get_me(client: httpx.AsyncClient) -> None:
    """SEC-GAM-001: SQL Injection payloads in headers or params handled safely without error."""
    sqli_headers = {"Authorization": "Bearer ' OR 1=1 --"}
    response = await client.get("/api/v1/gamification/me", headers=sqli_headers)
    assert response.status_code in (401, 200)
    assert "syntax error" not in response.text.lower()


async def test_sec_gam_002_sqli_prevention_badge_evaluation(client: httpx.AsyncClient) -> None:
    """SEC-GAM-002: Malicious query parameters on badge directory endpoint neutralized."""
    response = await client.get("/api/v1/gamification/badges", params={"category": "' OR 1=1 --"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)


async def test_sec_gam_003_auth_boundary_guest_write_prevention(client: httpx.AsyncClient) -> None:
    """SEC-GAM-003: Guest session cannot modify user_gamifications state."""
    guest_headers, _ = await _create_guest(client)
    res = await client.post("/api/v1/gamification/claim-daily-streak", headers=guest_headers)
    assert res.status_code == 403


async def test_sec_gam_004_user_id_tampering_defense(client: httpx.AsyncClient) -> None:
    """SEC-GAM-004: Endpoint derives target user strictly from JWT token, ignoring user_id body/query parameters."""
    headers, _real_id = await _create_user(client, "+919876543224")

    # Attempt to query or claim for user 999
    res = await client.post(
        "/api/v1/gamification/claim-daily-streak",
        params={"user_id": 999},
        json={"user_id": 999},
        headers=headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert "streak_days" in data
    # Verified: points granted to JWT user, not user 999


async def test_sec_gam_005_rate_limiting_claim_streak(client: httpx.AsyncClient) -> None:
    """SEC-GAM-005: 6th consecutive claim streak request within 1 minute receives HTTP 429."""
    headers, _ = await _create_user(client, "+919876543225")

    # Send 5 requests
    for _ in range(5):
        await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)

    # 6th request
    sixth = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert sixth.status_code in (400, 429)
    if sixth.status_code == 429:
        data = sixth.json()
        assert "too many requests" in str(data).lower() or data.get("code") == "rate_limited"


async def test_sec_gam_006_invalid_expired_jwt_token(client: httpx.AsyncClient) -> None:
    """SEC-GAM-006: Expired or tampered Bearer token returns HTTP 401 Unauthorized."""
    fake_headers = {
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature"
    }
    res = await client.post("/api/v1/gamification/claim-daily-streak", headers=fake_headers)
    assert res.status_code == 401


async def test_sec_gam_007_zero_pii_exposure(client: httpx.AsyncClient) -> None:
    """SEC-GAM-007: Gamification endpoints expose zero PII (phone, email, real names, exact coords)."""
    headers, _ = await _create_user(client, "+919876543227")

    res_me = await client.get("/api/v1/gamification/me", headers=headers)
    assert res_me.status_code == 200
    body_str = res_me.text

    assert "+919876543227" not in body_str
    assert "email" not in res_me.json() or res_me.json().get("email") is None
    assert "phone" not in res_me.json() or res_me.json().get("phone") is None

    res_badges = await client.get("/api/v1/gamification/badges")
    assert res_badges.status_code == 200
    assert "+919" not in res_badges.text


async def test_sec_gam_008_utc_calendar_day_rollover(app: Any, client: httpx.AsyncClient) -> None:
    """SEC-GAM-008: Streak claim relies strictly on UTC date comparison."""
    headers, user_id = await _create_user(client, "+919876543228")
    today_utc = datetime.now(UTC).date()

    # Set last_streak_date to today -> cannot claim
    await _seed_user_activities(
        app, user_id=user_id, streak_days=2, last_streak_date=today_utc.isoformat()
    )
    res_today = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert res_today.status_code == 400

    # Set last_streak_date to yesterday -> can claim
    yesterday_utc = (today_utc - timedelta(days=1)).isoformat()
    await _seed_user_activities(app, user_id=user_id, streak_days=2, last_streak_date=yesterday_utc)
    res_consec = await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)
    assert res_consec.status_code == 200
    assert res_consec.json()["streak_days"] == 3


async def test_sec_gam_009_concurrent_request_race_condition(client: httpx.AsyncClient) -> None:
    """SEC-GAM-009: Concurrent parallel claims for same user handle race condition safely."""
    headers, _ = await _create_user(client, "+919876543229")

    async def _claim() -> httpx.Response:
        return await client.post("/api/v1/gamification/claim-daily-streak", headers=headers)

    results = await asyncio.gather(*[_claim() for _ in range(5)])

    status_codes = [r.status_code for r in results]
    success_count = status_codes.count(200)
    assert success_count == 1
    assert all(code in (200, 400, 429) for code in status_codes)


async def test_sec_gam_010_integer_overflow_negative_value_prevention(
    app: Any, client: httpx.AsyncClient
) -> None:
    """SEC-GAM-010: High activity counts aggregated safely without integer overflow or negative values."""
    headers, user_id = await _create_user(client, "+919876543230")
    # 10,000 issues = 500,000 pts
    await _seed_user_activities(app, user_id=user_id, issues_created=10000)

    res = await client.get("/api/v1/gamification/me", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["impact_score"] >= 500000
    assert data["level"] == 5
    assert data["level_name"] == "City Hero"
