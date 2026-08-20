import re
from datetime import UTC, datetime

from sqlalchemy import Select, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppError
from app.features.auth.models import User
from app.features.issues.geo import bbox_statement, haversine_km
from app.features.issues.models import Issue
from app.features.issues.service import evaluate_escalation
from app.features.representatives.models import RepresentativeProfile
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
    q: str = "",
    latitude: float | None = None,
    longitude: float | None = None,
    radius_km: float = 5.0,
    status: str | None = None,
    category: str | None = None,
    categories: list[str] | None = None,
    created_after: datetime | None = None,
    created_before: datetime | None = None,
    ward: str | None = None,
    account: str | None = None,
    limit: int = 20,
    offset: int = 0,
) -> list[Issue]:
    query = (q or "").strip()

    statement: Select[tuple[Issue]] = (
        select(Issue)
        .outerjoin(User, Issue.reporter_id == User.id)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
        )
    )

    if latitude is not None and longitude is not None:
        statement = await bbox_statement(latitude, longitude, radius_km)
        statement = (
            statement.outerjoin(User, Issue.reporter_id == User.id)
            .options(
                selectinload(Issue.reporter),
                selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
            )
        )

    if query:
        pattern = f"%{_escape_like(query)}%"
        clean_handle = query.lstrip("@")
        text_match = or_(
            Issue.title.ilike(pattern, escape="\\"),
            Issue.description.ilike(pattern, escape="\\"),
            Issue.category.ilike(pattern, escape="\\"),
            Issue.ward.ilike(pattern, escape="\\"),
            User.username.ilike(f"%{_escape_like(clean_handle)}%", escape="\\"),
            User.display_name.ilike(pattern, escape="\\"),
        )
        statement = statement.where(text_match)

    if account:
        clean_acc = account.strip().lstrip("@")
        if clean_acc:
            acc_pattern = f"%{_escape_like(clean_acc)}%"
            statement = statement.where(
                or_(
                    User.username.ilike(acc_pattern, escape="\\"),
                    User.display_name.ilike(acc_pattern, escape="\\"),
                )
            )

    if status is not None and status.strip() and status.lower() != "all":
        statement = statement.where(Issue.status == status)
    if category is not None and category.strip() and category.lower() != "all":
        statement = statement.where(Issue.category == category)
    if categories:
        valid_cats = [c for c in categories if c.lower() != "all"]
        if valid_cats:
            statement = statement.where(Issue.category.in_(valid_cats))
    if ward is not None and ward.strip() and ward.lower() != "all":
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
        if issue.is_hidden:
            continue
        if issue.is_shielded and issue.status != "resolved":
            continue
        if latitude is not None and longitude is not None:
            if haversine_km(latitude, longitude, issue.latitude, issue.longitude) > radius_km:
                continue
        filtered_issues.append(issue)

    if modified:
        await session.commit()

    return filtered_issues
