from fastapi import APIRouter, Path, Query, Request

from app.api.deps import CurrentUser, SessionDep
from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.wards.schemas import (
    LocalTalkPostCreate,
    LocalTalkPostOut,
    WardDetailOut,
    WardListResponse,
    WardSummaryOut,
)
from app.features.wards.service import (
    create_local_talk_post as service_create_local_talk_post,
)
from app.features.wards.service import (
    get_ward_by_location as service_get_ward_by_location,
)
from app.features.wards.service import (
    get_ward_detail as service_get_ward_detail,
)
from app.features.wards.service import (
    list_local_talk_posts as service_list_local_talk_posts,
)
from app.features.wards.service import (
    list_wards as service_list_wards,
)
from app.features.wards.service import (
    to_local_talk_post_out,
)

router = APIRouter(tags=["wards"])


def _check_rate_limit(request: Request) -> None:
    if not hasattr(request.app.state, "ward_rate_limiter"):
        request.app.state.ward_rate_limiter = SlidingWindowRateLimiter(
            max_requests=60, window_seconds=60
        )
    limiter: SlidingWindowRateLimiter = request.app.state.ward_rate_limiter
    client_ip = request.client.host if request.client else "unknown"
    if not limiter.allow(client_ip):
        raise AppError(status_code=429, detail="Rate limit exceeded", code="rate_limit_exceeded")


@router.get("/by-location", response_model=WardSummaryOut)
async def get_ward_by_location(
    request: Request,
    session: SessionDep,
    latitude: float = Query(..., description="Latitude coordinate"),
    longitude: float = Query(..., description="Longitude coordinate"),
) -> WardSummaryOut:
    _check_rate_limit(request)
    return await service_get_ward_by_location(
        session=session, latitude=latitude, longitude=longitude
    )


@router.get("/{ward_slug}", response_model=WardDetailOut)
async def get_ward_detail(
    request: Request,
    session: SessionDep,
    ward_slug: str = Path(..., description="Slugified or exact name of the ward"),
    issues_limit: int = Query(10, ge=1, le=50, description="Max recent issues to return"),
) -> WardDetailOut:
    _check_rate_limit(request)
    return await service_get_ward_detail(
        session=session, ward_slug=ward_slug, issues_limit=issues_limit
    )


@router.get("", response_model=WardListResponse)
async def get_wards_list(
    request: Request,
    session: SessionDep,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> WardListResponse:
    _check_rate_limit(request)
    return await service_list_wards(session=session, limit=limit, offset=offset)


@router.post("/{ward_slug}/talk", response_model=LocalTalkPostOut)
async def create_local_talk_post(
    ward_slug: str,
    payload: LocalTalkPostCreate,
    session: SessionDep,
    user: CurrentUser,
) -> LocalTalkPostOut:
    post = await service_create_local_talk_post(
        session=session, ward_slug=ward_slug, user=user, payload=payload
    )
    return to_local_talk_post_out(post)


@router.get("/{ward_slug}/talk", response_model=list[LocalTalkPostOut])
async def list_local_talk_posts(
    ward_slug: str,
    session: SessionDep,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[LocalTalkPostOut]:
    posts = await service_list_local_talk_posts(
        session=session, ward_slug=ward_slug, limit=limit, offset=offset
    )
    return [to_local_talk_post_out(p) for p in posts]
