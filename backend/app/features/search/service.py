import re
from datetime import UTC, datetime

from sqlalchemy import Select, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppError
from app.features.issues.geo import bbox_statement, haversine_km
from app.features.issues.models import Issue
from app.features.issues.service import evaluate_escalation
from app.features.wards.models import Ward


def _utc_now() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


def _escape_like(q: str) -> str:
    return q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _alnum_expr(column) -> object:
    """Lowercases [column] and strips punctuation so slug/name/code variants
    can be compared directly (e.g. 'ward-45-urban-central' == 'Ward 45, Urban Central')."""
    cleaned = func.lower(column)
    for ch in ",.-_' ":
        cleaned = func.replace(cleaned, ch, "")
    return cleaned


def _alnum(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


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
    ward: str | None,
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

    statement: Select[tuple[Issue]] = select(Issue).options(selectinload(Issue.reporter)).where(text_match)
    if latitude is not None and longitude is not None:
        statement = await bbox_statement(latitude, longitude, radius_km)
        statement = statement.where(text_match)
    if status is not None:
        statement = statement.where(Issue.status == status)
    if category is not None:
        statement = statement.where(Issue.category == category)
    if categories:
        statement = statement.where(Issue.category.in_(categories))
    if ward is not None:
        normalized_ward = _alnum(ward)
        ward_match = or_(
            Issue.ward == ward,
            Issue.ward.ilike(f"%{_escape_like(ward)}%"),
            _alnum_expr(Issue.ward) == normalized_ward,
            _alnum_expr(Issue.ward).like(f"%{normalized_ward}%"),
        )
        ward_row = await session.scalar(
            select(Ward).where(
                or_(Ward.slug == ward, Ward.name == ward, Ward.code == ward)
            )
        )
        if ward_row is not None:
            for label in (ward_row.name, ward_row.code, ward_row.slug):
                ward_match = or_(ward_match, Issue.ward == label)
                ward_match = or_(
                    ward_match, Issue.ward.ilike(f"%{_escape_like(label)}%")
                )
        statement = statement.where(ward_match)
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
