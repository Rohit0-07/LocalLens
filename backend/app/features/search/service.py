from datetime import UTC, datetime

from sqlalchemy import Select, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.features.issues.geo import bbox_statement, haversine_km
from app.features.issues.models import Issue
from app.features.issues.service import evaluate_escalation


def _utc_now() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


def _escape_like(q: str) -> str:
    return q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def parse_iso_datetime(value: str) -> datetime:
    """Parse an ISO-8601 datetime into a naive-UTC datetime.

    Accepts 'YYYY-MM-DD', 'YYYY-MM-DDTHH:MM:SS', 'YYYY-MM-DDTHH:MM:SS.ffffff',
    with optional trailing 'Z' or '+HH:MM' offset. On any parse failure raises
    AppError(message, status_code=422, code="invalid_date_format").
    """
    normalized = f"{value[:-1]}+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise AppError("Invalid date format", status_code=422, code="invalid_date_format") from exc
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(UTC).replace(tzinfo=None)
    return parsed


async def search_issues(
    session: AsyncSession,
    *,
    q: str,
    latitude: float | None,
    longitude: float | None,
    radius_km: float,
    status: str | None,
    category: str | None,
    categories: list[str] | None,
    created_after: datetime | None,
    created_before: datetime | None,
    limit: int,
    offset: int,
) -> list[Issue]:
    query = q.strip()
    if not query:
        raise AppError("Search query cannot be empty", status_code=422, code="empty_query")

    pattern = f"%{_escape_like(query)}%"
    text_match = or_(
        Issue.title.ilike(pattern, escape="\\"),
        Issue.description.ilike(pattern, escape="\\"),
        Issue.category.ilike(pattern, escape="\\"),
        Issue.ward.ilike(pattern, escape="\\"),
    )

    statement: Select[tuple[Issue]] = select(Issue).where(text_match)
    if latitude is not None and longitude is not None:
        statement = await bbox_statement(latitude, longitude, radius_km)
        statement = statement.where(text_match)
    if status is not None:
        statement = statement.where(Issue.status == status)
    if category is not None:
        statement = statement.where(Issue.category == category)
    if categories:
        statement = statement.where(Issue.category.in_(categories))
    if created_after is not None:
        statement = statement.where(Issue.created_at >= created_after)
    if created_before is not None:
        statement = statement.where(Issue.created_at <= created_before)
    statement = (
        statement.order_by(Issue.created_at.desc(), Issue.id.desc()).limit(limit).offset(offset)
    )

    result = await session.execute(statement)
    issues = list(result.scalars().all())

    now = _utc_now()
    modified = False
    filtered_issues: list[Issue] = []

    for issue in issues:
        if evaluate_escalation(issue, now):
            modified = True
        if issue.is_shielded and issue.status != "resolved":
            continue
        if latitude is not None and longitude is not None:
            if haversine_km(latitude, longitude, issue.latitude, issue.longitude) > radius_km:
                continue
        filtered_issues.append(issue)

    if modified:
        await session.commit()

    return filtered_issues
