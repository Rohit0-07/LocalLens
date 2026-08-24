from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request

from app.api.deps import OptionalUser, SessionDep, SettingsDep
from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.issues import service as issues_service
from app.features.issues.schemas import IssueOut
from app.features.search import service

router = APIRouter()

_ALLOWED_STATUSES = {
    "unacknowledged",
    "open",
    "under_review",
    "acknowledged",
    "escalating",
    "forwarded",
    "pending_quorum",
    "resolved",
    "disputed",
}


async def _rate_limit_search(request: Request, user: OptionalUser = None) -> None:
    limiter: SlidingWindowRateLimiter = request.app.state.search_rate_limiter
    if user is not None and not getattr(user, "is_guest", False):
        key = str(user.id)
    else:
        client_ip = request.client.host if request.client else "unknown"
        key = f"anon:{client_ip}"
    if not limiter.allow(key):
        raise AppError("Search rate limit exceeded", status_code=429, code="rate_limited")


@router.get("", response_model=list[IssueOut])
async def search_issues_endpoint(
    session: SessionDep,
    settings: SettingsDep,
    q: Annotated[str | None, Query()] = None,
    account: Annotated[str | None, Query()] = None,
    user: OptionalUser = None,
    _rate_limited: Annotated[None, Depends(_rate_limit_search)] = None,
    latitude: Annotated[float | None, Query(ge=-90, le=90)] = None,
    longitude: Annotated[float | None, Query(ge=-180, le=180)] = None,
    radius_km: Annotated[float, Query(ge=0.1, le=50)] = 5.0,
    status: Annotated[str | None, Query()] = None,
    category: Annotated[str | None, Query()] = None,
    categories: Annotated[list[str] | None, Query()] = None,
    ward: Annotated[str | None, Query()] = None,
    created_after: Annotated[str | None, Query()] = None,
    created_before: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[IssueOut]:
    query = (q or "").strip()
    has_filters = any([
        latitude is not None and longitude is not None,
        status is not None and status.strip() and status.lower() != "all",
        category is not None and category.strip() and category.lower() != "all",
        bool(categories),
        ward is not None and ward.strip() and ward.lower() != "all",
        account is not None and account.strip(),
        created_after is not None,
        created_before is not None,
    ])
    if not query and not has_filters:
        raise AppError("Search query cannot be empty", status_code=422, code="empty_query")
    if len(query) > 100:
        raise AppError(
            "Search query must be at most 100 characters", status_code=422, code="query_too_long"
        )
    if (latitude is None) != (longitude is None):
        raise AppError(
            "Provide both latitude and longitude together",
            status_code=400,
            code="both_coordinates_required",
        )
    if status is not None and status.strip() and status.lower() != "all" and status not in _ALLOWED_STATUSES:
        raise AppError("Invalid status filter", status_code=422, code="invalid_status")
    if category is not None and len(category) > 32:
        raise AppError(
            "category must be at most 32 characters", status_code=422, code="invalid_category"
        )
    if categories is not None and (
        len(categories) > 20 or any(len(item) > 32 for item in categories)
    ):
        raise AppError(
            "categories must contain at most 20 items of at most 32 characters each",
            status_code=422,
            code="invalid_category",
        )
    if ward is not None and len(ward) > 64:
        raise AppError(
            "ward must be at most 64 characters", status_code=422, code="invalid_ward"
        )
    if account is not None and len(account) > 64:
        raise AppError(
            "account must be at most 64 characters", status_code=422, code="invalid_account"
        )
    parsed_created_after = (
        service.parse_iso_datetime(created_after) if created_after is not None else None
    )
    parsed_created_before = (
        service.parse_iso_datetime(created_before) if created_before is not None else None
    )
    if (
        parsed_created_after is not None
        and parsed_created_before is not None
        and parsed_created_after > parsed_created_before
    ):
        raise AppError(
            "created_after must not be later than created_before",
            status_code=422,
            code="invalid_date_range",
        )

    issues = await service.search_issues(
        session,
        q=query,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        status=status,
        category=category,
        categories=categories,
        ward=ward,
        account=account,
        created_after=parsed_created_after,
        created_before=parsed_created_before,
        limit=limit,
        offset=offset,
    )
    user_upvoted_ids: set[int] = set()
    if user is not None and not getattr(user, "is_guest", False):
        user_upvoted_ids = await issues_service.get_user_upvoted_issue_ids(
            session, user.id, [issue.id for issue in issues]
        )
    return [
        issues_service.to_issue_out(
            issue,
            settings.anon_hmac_secret,
            user_id=user.id if user else None,
            user_upvoted_ids=user_upvoted_ids,
        )
        for issue in issues
    ]
