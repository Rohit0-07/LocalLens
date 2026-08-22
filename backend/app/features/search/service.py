import re
from datetime import UTC, datetime

from sqlalchemy import Select, or_, select
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


_GEO_OVERFETCH_FACTOR = 6


async def _ward_labels(
    session: AsyncSession, ward: str
) -> tuple[list[str], list[str]]:
    """Stored ward labels matching [ward] under the historical contract.
    Returns (exact_labels, contained_labels):

    - exact_labels: stored labels whose punctuation-insensitive (alnum) form
      equals or contains the alnum query — matched in Python once per query
      over the low-cardinality distinct set instead of per-row REPLACEs.
    - contained_labels: canonical ward-table name/code/slug values that may
      appear as substrings inside stored labels."""
    normalized_ward = _alnum(ward)
    labels = (await session.execute(select(Issue.ward).distinct())).scalars()
    matched = [
        label
        for label in labels
        if label
        and (
            _alnum(label) == normalized_ward or normalized_ward in _alnum(label)
        )
    ]
    contained: list[str] = []
    ward_row = await session.scalar(
        select(Ward).where(or_(Ward.slug == ward, Ward.name == ward, Ward.code == ward))
    )
    if ward_row is not None:
        for label in (ward_row.name, ward_row.code, ward_row.slug):
            if label and label not in contained:
                contained.append(label)
    return matched, contained


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
    geo = latitude is not None and longitude is not None

    visibility = or_(Issue.is_shielded.is_(False), Issue.status == "resolved")

    statement: Select[tuple[Issue]] = (
        select(Issue)
        .outerjoin(User, Issue.reporter_id == User.id)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
        )
        .where(Issue.is_hidden.is_(False), visibility)
    )

    if latitude is not None and longitude is not None:
        statement = await bbox_statement(latitude, longitude, radius_km)
        statement = (
            statement.outerjoin(User, Issue.reporter_id == User.id)
            .options(
                selectinload(Issue.reporter),
                selectinload(Issue.assigned_representative).selectinload(
                    RepresentativeProfile.user
                ),
            )
            .where(Issue.is_hidden.is_(False), visibility)
        )

    if query:
        pattern = f"%{_escape_like(query)}%"
        clean_handle = query.lstrip("@")
        text_match = or_(
            # search_blob covers title/description/category/ward in one
            # lowercased column maintained on write (see build_search_blob).
            Issue.search_blob.ilike(pattern, escape="\\"),
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
        labels, contained_labels = await _ward_labels(session, ward.strip())
        conditions = [Issue.ward.ilike(f"%{_escape_like(ward)}%", escape="\\")]
        if labels:
            conditions.append(Issue.ward.in_(labels))
        conditions.extend(
            Issue.ward.ilike(f"%{_escape_like(label)}%", escape="\\")
            for label in contained_labels
        )
        statement = statement.where(or_(*conditions))
    if created_after is not None:
        statement = statement.where(Issue.created_at >= created_after)
    if created_before is not None:
        statement = statement.where(Issue.created_at <= created_before)

    statement = statement.order_by(Issue.created_at.desc(), Issue.id.desc())

    if geo:
        # The bbox is a superset of the radius circle; fetch a bounded
        # over-fetch window, apply the exact haversine check in Python, then
        # slice the page — so LIMIT/OFFSET never lands on rows that would be
        # discarded afterwards.
        result = await session.execute(statement.limit((offset + limit) * _GEO_OVERFETCH_FACTOR))
        issues = list(result.scalars().all())
        now = _utc_now()
        modified = False
        page: list[Issue] = []
        assert latitude is not None and longitude is not None
        for issue in issues:
            if evaluate_escalation(issue, now):
                modified = True
            if haversine_km(latitude, longitude, issue.latitude, issue.longitude) <= radius_km:
                page.append(issue)
        if modified:
            await session.commit()
        return page[offset : offset + limit]

    statement = statement.limit(limit).offset(offset)
    result = await session.execute(statement)
    issues = list(result.scalars().all())

    now = _utc_now()
    modified = False
    for issue in issues:
        if evaluate_escalation(issue, now):
            modified = True

    if modified:
        await session.commit()

    return issues
