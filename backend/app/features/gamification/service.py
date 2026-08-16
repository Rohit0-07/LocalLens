import asyncio
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.features.gamification.models import UserBadge, UserGamification
from app.features.gamification.schemas import (
    ActivityCountsOut,
    BadgeMetadataOut,
    GamificationProfileOut,
    StreakClaimOut,
    UserBadgeOut,
)

SYSTEM_BADGES: list[BadgeMetadataOut] = [
    BadgeMetadataOut(
        id="first_report",
        key="first_report",
        badge_key="first_report",
        name="First Report",
        description="Reported 1+ civic issues",
        icon_name="report_icon",
        category="reporting",
        threshold=1,
    ),
    BadgeMetadataOut(
        id="civic_voter",
        key="civic_voter",
        badge_key="civic_voter",
        name="Civic Voter",
        description="Upvoted 5+ civic issues",
        icon_name="vote_icon",
        category="voting",
        threshold=5,
    ),
    BadgeMetadataOut(
        id="quorum_hero",
        key="quorum_hero",
        badge_key="quorum_hero",
        name="Verification Hero",
        description="Participated in 3+ community verification votes",
        icon_name="quorum_icon",
        category="quorum",
        threshold=3,
    ),
    BadgeMetadataOut(
        id="neighborhood_voice",
        key="neighborhood_voice",
        badge_key="neighborhood_voice",
        name="Neighborhood Voice",
        description="Posted 5+ comments in community discussions",
        icon_name="comment_icon",
        category="discussion",
        threshold=5,
    ),
    BadgeMetadataOut(
        id="streak_master",
        key="streak_master",
        badge_key="streak_master",
        name="Streak Master",
        description="Maintained a 7-day daily streak",
        icon_name="streak_icon",
        category="streak",
        threshold=7,
    ),
]

BADGE_MAP: dict[str, BadgeMetadataOut] = {b.id: b for b in SYSTEM_BADGES}


async def get_or_create_user_gamification(
    db: AsyncSession, user_id: int, *, for_update: bool = False
) -> UserGamification:
    stmt = select(UserGamification).where(UserGamification.user_id == user_id)
    if for_update:
        stmt = stmt.with_for_update()
    result = await db.execute(stmt)
    gamif = result.scalar_one_or_none()
    if not gamif:
        try:
            async with db.begin_nested():
                gamif = UserGamification(
                    user_id=user_id, streak_days=0, last_streak_date=None, impact_score=0
                )
                db.add(gamif)
                await db.flush()
        except Exception:
            result = await db.execute(
                select(UserGamification).where(UserGamification.user_id == user_id)
            )
            gamif = result.scalar_one_or_none()
            if not gamif:
                gamif = UserGamification(
                    user_id=user_id, streak_days=0, last_streak_date=None, impact_score=0
                )
    return gamif


async def fetch_activity_counts(db: AsyncSession, user_id: int) -> ActivityCountsOut:
    from app.features.issues.models import Comment, Issue, QuorumVote, Upvote

    issues_stmt = select(func.count(Issue.id)).where(Issue.reporter_id == user_id)
    upvotes_stmt = select(func.count(Upvote.id)).where(Upvote.user_id == user_id)
    quorum_stmt = select(func.count(QuorumVote.id)).where(QuorumVote.user_id == user_id)
    comments_stmt = select(func.count(Comment.id)).where(Comment.author_id == user_id)

    issues_count = (await db.execute(issues_stmt)).scalar() or 0
    upvotes_count = (await db.execute(upvotes_stmt)).scalar() or 0
    quorum_count = (await db.execute(quorum_stmt)).scalar() or 0
    comments_count = (await db.execute(comments_stmt)).scalar() or 0

    return ActivityCountsOut(
        issues_created=issues_count,
        upvotes_cast=upvotes_count,
        quorum_votes_cast=quorum_count,
        comments_posted=comments_count,
    )


def calculate_impact_score(counts: ActivityCountsOut, streak_days: int) -> int:
    return (
        (counts.issues_created * 50)
        + (counts.upvotes_cast * 5)
        + (counts.quorum_votes_cast * 20)
        + (counts.comments_posted * 10)
        + (streak_days * 15)
    )


def get_level_info(impact_score: int) -> tuple[int, str, int | None]:
    if impact_score < 100:
        return 1, "Civic Rookie", 100
    elif impact_score < 300:
        return 2, "Active Neighbor", 300
    elif impact_score < 700:
        return 3, "Community Guardian", 700
    elif impact_score < 1500:
        return 4, "Civic Champion", 1500
    else:
        return 5, "City Hero", None


async def evaluate_and_unlock_badges(
    db: AsyncSession, user_id: int, counts: ActivityCountsOut, streak_days: int
) -> list[UserBadgeOut]:
    existing_stmt = select(UserBadge).where(UserBadge.user_id == user_id)
    existing_badges = list((await db.execute(existing_stmt)).scalars().all())
    unlocked_badge_ids = {b.badge_id for b in existing_badges}

    badges_to_unlock: list[str] = []
    if "first_report" not in unlocked_badge_ids and counts.issues_created >= 1:
        badges_to_unlock.append("first_report")
    if "civic_voter" not in unlocked_badge_ids and counts.upvotes_cast >= 5:
        badges_to_unlock.append("civic_voter")
    if "quorum_hero" not in unlocked_badge_ids and counts.quorum_votes_cast >= 3:
        badges_to_unlock.append("quorum_hero")
    if "neighborhood_voice" not in unlocked_badge_ids and counts.comments_posted >= 5:
        badges_to_unlock.append("neighborhood_voice")
    if "streak_master" not in unlocked_badge_ids and streak_days >= 7:
        badges_to_unlock.append("streak_master")

    new_badge_objs: list[UserBadge] = []
    now_utc = datetime.now(UTC)
    for b_id in badges_to_unlock:
        new_b = UserBadge(user_id=user_id, badge_id=b_id, unlocked_at=now_utc)
        db.add(new_b)
        new_badge_objs.append(new_b)

    if badges_to_unlock:
        await db.flush()

    all_user_badges = existing_badges + new_badge_objs
    res: list[UserBadgeOut] = []
    for b in all_user_badges:
        meta = BADGE_MAP.get(b.badge_id)
        if meta:
            res.append(
                UserBadgeOut(
                    badge_id=b.badge_id,
                    key=b.badge_id,
                    badge_key=b.badge_id,
                    name=meta.name,
                    description=meta.description,
                    icon_name=meta.icon_name,
                    category=meta.category,
                    unlocked_at=b.unlocked_at,
                )
            )
    return res


async def get_my_gamification_profile(db: AsyncSession, user: Any | None) -> GamificationProfileOut:
    if (
        user is None
        or getattr(user, "is_guest", False)
        or isinstance(getattr(user, "id", None), str)
    ):
        return GamificationProfileOut(
            user_id=None,
            is_guest=True,
            impact_score=0,
            level=1,
            level_name="Civic Rookie",
            next_level_score=100,
            streak_days=0,
            last_streak_date=None,
            can_claim_streak=False,
            badges=[],
            activity_counts=ActivityCountsOut(),
        )

    try:
        user_id = int(user.id)
    except (ValueError, TypeError):
        return GamificationProfileOut(
            user_id=None,
            is_guest=True,
            impact_score=0,
            level=1,
            level_name="Civic Rookie",
            next_level_score=100,
            streak_days=0,
            last_streak_date=None,
            can_claim_streak=False,
            badges=[],
            activity_counts=ActivityCountsOut(),
        )

    gamif = await get_or_create_user_gamification(db, user_id)
    counts = await fetch_activity_counts(db, user_id)
    score = calculate_impact_score(counts, gamif.streak_days)
    gamif.impact_score = score
    level, level_name, next_score = get_level_info(score)

    user_badges = await evaluate_and_unlock_badges(db, user_id, counts, gamif.streak_days)

    today_utc = datetime.now(UTC).date()
    can_claim = gamif.last_streak_date != today_utc

    return GamificationProfileOut(
        user_id=user_id,
        is_guest=False,
        impact_score=score,
        level=level,
        level_name=level_name,
        next_level_score=next_score,
        streak_days=gamif.streak_days,
        last_streak_date=gamif.last_streak_date,
        can_claim_streak=can_claim,
        badges=user_badges,
        activity_counts=counts,
    )


_user_claim_locks: dict[int, asyncio.Lock] = {}
_locks_guard = asyncio.Lock()


async def _get_user_lock(user_id: int) -> asyncio.Lock:
    async with _locks_guard:
        if user_id not in _user_claim_locks:
            _user_claim_locks[user_id] = asyncio.Lock()
        return _user_claim_locks[user_id]


async def claim_user_streak(db: AsyncSession, user: Any) -> StreakClaimOut:
    if getattr(user, "is_guest", False) or isinstance(getattr(user, "id", None), str):
        raise AppError(
            "Guest users cannot claim daily streaks. Please sign in.",
            status_code=403,
            code="guest_restricted",
        )

    try:
        user_id = int(user.id)
    except (ValueError, TypeError):
        raise AppError(
            "Guest users cannot claim daily streaks. Please sign in.",
            status_code=403,
            code="guest_restricted",
        ) from None

    user_lock = await _get_user_lock(user_id)
    async with user_lock:
        today_utc = datetime.now(UTC).date()
        gamif = await get_or_create_user_gamification(db, user_id, for_update=True)

        if gamif.last_streak_date == today_utc:
            raise AppError(
                "Daily streak already claimed today",
                status_code=400,
                code="already_claimed",
            )

        gamif.streak_days += 1
        gamif.last_streak_date = today_utc

        counts = await fetch_activity_counts(db, user_id)
        await evaluate_and_unlock_badges(db, user_id, counts, gamif.streak_days)
        new_score = calculate_impact_score(counts, gamif.streak_days)
        gamif.impact_score = new_score
        await db.commit()

        return StreakClaimOut(
            streak_days=gamif.streak_days,
            points_earned=15,
            impact_score=new_score,
            message="Daily streak claimed! +15 Impact Points",
        )


def get_all_badge_metadata() -> list[BadgeMetadataOut]:
    return SYSTEM_BADGES


class GamificationService:
    get_or_create_user_gamification = staticmethod(get_or_create_user_gamification)
    fetch_activity_counts = staticmethod(fetch_activity_counts)
    calculate_impact_score = staticmethod(calculate_impact_score)
    get_level_info = staticmethod(get_level_info)
    evaluate_and_unlock_badges = staticmethod(evaluate_and_unlock_badges)
    get_profile = staticmethod(get_my_gamification_profile)
    get_my_gamification_profile = staticmethod(get_my_gamification_profile)
    claim_daily_streak = staticmethod(claim_user_streak)
    claim_user_streak = staticmethod(claim_user_streak)
    get_all_badge_metadata = staticmethod(get_all_badge_metadata)
