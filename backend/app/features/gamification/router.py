from fastapi import APIRouter, Depends, Request, status

from app.api.deps import CurrentUser, OptionalUser, SessionDep
from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.gamification.schemas import (
    BadgeMetadataOut,
    GamificationProfileOut,
    StreakClaimOut,
)
from app.features.gamification.service import (
    claim_user_streak,
    get_all_badge_metadata,
    get_my_gamification_profile,
)

router = APIRouter()


async def _rate_limit_claim_streak(request: Request, user: CurrentUser) -> None:
    limiter: SlidingWindowRateLimiter = request.app.state.gamification_rate_limiter
    key = str(user.id)
    if not limiter.allow(key):
        raise AppError("Too many requests", status_code=429, code="rate_limited")


@router.get("/me", response_model=GamificationProfileOut, status_code=status.HTTP_200_OK)
async def get_profile_endpoint(
    session: SessionDep,
    user: OptionalUser = None,
) -> GamificationProfileOut:
    return await get_my_gamification_profile(session, user)


@router.post(
    "/claim-daily-streak",
    response_model=StreakClaimOut,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(_rate_limit_claim_streak)],
)
async def claim_daily_streak_endpoint(
    session: SessionDep,
    user: CurrentUser,
) -> StreakClaimOut:
    return await claim_user_streak(session, user)


@router.get("/badges", response_model=list[BadgeMetadataOut], status_code=status.HTTP_200_OK)
async def get_badges_endpoint() -> list[BadgeMetadataOut]:
    return get_all_badge_metadata()
