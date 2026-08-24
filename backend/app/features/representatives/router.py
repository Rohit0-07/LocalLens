from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, status

from app.api.deps import CurrentUser, SessionDep, SettingsDep
from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.representatives import service
from app.features.representatives.models import RepresentativeProfile
from app.features.representatives.schemas import (
    OfficialResponseCreate,
    OfficialResponseOut,
    PublicRepresentativeProfileOut,
    RepresentativeProfileOut,
    WardIssuesResponse,
)

router = APIRouter()


async def _rate_limit_rep(request: Request, user: CurrentUser) -> None:
    limiter: SlidingWindowRateLimiter = request.app.state.rep_rate_limiter
    key = str(user.id) if (user is not None and not getattr(user, "is_guest", False)) else "anon"
    if not limiter.allow(key):
        raise AppError("Rate limit exceeded", status_code=429, code="rate_limited")


def _check_public_rate_limit(request: Request) -> None:
    if not hasattr(request.app.state, "public_rep_rate_limiter"):
        request.app.state.public_rep_rate_limiter = SlidingWindowRateLimiter(
            max_requests=60, window_seconds=60
        )
    limiter: SlidingWindowRateLimiter = request.app.state.public_rep_rate_limiter
    client_ip = request.client.host if request.client else "unknown"
    if not limiter.allow(client_ip):
        raise AppError(status_code=429, detail="Rate limit exceeded", code="rate_limit_exceeded")


async def get_current_rep_profile(user: CurrentUser, session: SessionDep) -> RepresentativeProfile:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Forbidden: User is not a verified representative",
            status_code=403,
            code="not_representative",
        )
    profile = await service.get_representative_profile(session, user.id)
    if profile is None:
        raise AppError(
            "Forbidden: User is not a verified representative",
            status_code=403,
            code="not_representative",
        )
    return profile


RepProfileDep = Annotated[RepresentativeProfile, Depends(get_current_rep_profile)]
RateLimitDep = Annotated[None, Depends(_rate_limit_rep)]


@router.get("/representatives/me", response_model=RepresentativeProfileOut)
async def get_my_rep_profile(
    session: SessionDep,
    rep: RepProfileDep,
    _rl: RateLimitDep = None,
) -> RepresentativeProfileOut:
    return await service.get_representative_profile_out(session, rep)


@router.get("/representatives/ward-issues", response_model=WardIssuesResponse)
async def get_ward_issues(
    session: SessionDep,
    settings: SettingsDep,
    rep: RepProfileDep,
    _rl: RateLimitDep = None,
    filter: Annotated[str, Query(pattern="^(all|escalated|needs_response)$")] = "all",
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> WardIssuesResponse:
    return await service.list_ward_issues(
        session,
        rep,
        secret=settings.anon_hmac_secret,
        filter=filter,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/representatives/by-user/{user_id}", response_model=PublicRepresentativeProfileOut
)
async def get_public_rep_profile(
    user_id: int,
    request: Request,
    session: SessionDep,
) -> PublicRepresentativeProfileOut:
    """Public rep performance profile; no authentication required."""
    _check_public_rate_limit(request)
    return await service.get_public_rep_by_user(session, user_id)


@router.post(
    "/issues/{issue_id}/official-response",
    response_model=OfficialResponseOut,
    status_code=status.HTTP_201_CREATED,
)
async def post_official_response(
    issue_id: int,
    payload: OfficialResponseCreate,
    session: SessionDep,
    rep: RepProfileDep,
    _rl: RateLimitDep = None,
) -> OfficialResponseOut:
    return await service.create_official_response(session, rep, issue_id, payload)


@router.get("/issues/{issue_id}/official-responses", response_model=list[OfficialResponseOut])
async def get_official_responses_endpoint(
    issue_id: int,
    session: SessionDep,
) -> list[OfficialResponseOut]:
    return await service.get_official_responses(session, issue_id)
