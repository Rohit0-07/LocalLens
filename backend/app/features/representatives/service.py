import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.features.auth.models import User
from app.features.issues.models import Issue
from app.features.issues.service import to_issue_out
from app.features.representatives.models import OfficialResponse, RepresentativeProfile
from app.features.representatives.schemas import (
    OfficialResponseCreate,
    OfficialResponseOut,
    PublicRepresentativeProfileOut,
    RepresentativeMetricsOut,
    RepresentativeProfileOut,
    WardIssuesResponse,
)


async def get_representative_profile(
    session: AsyncSession, user_id: int
) -> RepresentativeProfile | None:
    stmt = select(RepresentativeProfile).where(RepresentativeProfile.user_id == user_id)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def compute_rep_metrics(
    session: AsyncSession, profile: RepresentativeProfile
) -> RepresentativeMetricsOut:
    """Compute the representative's ward performance metrics.

    All queries are scoped to ``Issue.ward == profile.ward``. Response-time
    arithmetic is done in Python so the results are portable across SQLite and
    Postgres (no SQLite-only datetime functions).
    """
    total_stmt = select(func.count(Issue.id)).where(Issue.ward == profile.ward)
    total_res = await session.execute(total_stmt)
    total_ward_issues = total_res.scalar() or 0

    esc_stmt = select(func.count(Issue.id)).where(
        Issue.ward == profile.ward,
        (Issue.status.in_(["escalated", "escalating", "forwarded"]))
        | (Issue.escalated_at.isnot(None)),
    )
    esc_res = await session.execute(esc_stmt)
    escalated_ward_issues = esc_res.scalar() or 0

    resp_stmt = (
        select(func.count(func.distinct(Issue.id)))
        .select_from(Issue)
        .join(OfficialResponse, OfficialResponse.issue_id == Issue.id)
        .where(Issue.ward == profile.ward)
    )
    resp_res = await session.execute(resp_stmt)
    responded_ward_issues = resp_res.scalar() or 0

    pending_response_ward_issues = max(0, total_ward_issues - responded_ward_issues)

    # Resolved issues the rep personally responded to (rep-attributable).
    resolved_stmt = (
        select(func.count(func.distinct(Issue.id)))
        .select_from(Issue)
        .join(OfficialResponse, OfficialResponse.issue_id == Issue.id)
        .where(
            Issue.ward == profile.ward,
            OfficialResponse.representative_id == profile.id,
            Issue.status == "resolved",
        )
    )
    resolved_res = await session.execute(resolved_stmt)
    resolved_ward_issues = resolved_res.scalar() or 0

    # Latest response per issue (newest first, deterministic id tiebreak),
    # bucketed by its status_update.
    latest_stmt = (
        select(Issue.id, OfficialResponse.status_update)
        .join(Issue, Issue.id == OfficialResponse.issue_id)
        .where(Issue.ward == profile.ward, OfficialResponse.representative_id == profile.id)
        .order_by(OfficialResponse.created_at.desc(), OfficialResponse.id.desc())
    )
    latest_res = await session.execute(latest_stmt)
    seen_issue_ids: set[int] = set()
    acknowledged_ward_issues = 0
    in_progress_ward_issues = 0
    for issue_id, status_update in latest_res.all():
        if issue_id in seen_issue_ids:
            continue
        seen_issue_ids.add(issue_id)
        if status_update == "acknowledged":
            acknowledged_ward_issues += 1
        elif status_update == "in_progress":
            in_progress_ward_issues += 1

    response_rate_pct = (
        round(responded_ward_issues / total_ward_issues * 100.0, 2)
        if total_ward_issues > 0
        else 0.0
    )

    # Average time from issue creation to the rep's first response, in hours.
    first_resp = (
        select(OfficialResponse.issue_id, func.min(OfficialResponse.created_at))
        .where(OfficialResponse.representative_id == profile.id)
        .group_by(OfficialResponse.issue_id)
        .subquery()
    )
    avg_stmt = (
        select(Issue.created_at, first_resp.c[1])
        .join(Issue, Issue.id == first_resp.c[0])
        .where(Issue.ward == profile.ward)
    )
    avg_res = await session.execute(avg_stmt)
    deltas_hours: list[float] = []
    for issue_created_at, resp_created_at in avg_res.all():
        if issue_created_at is None or resp_created_at is None:
            continue
        delta_hours = (resp_created_at - issue_created_at).total_seconds() / 3600.0
        deltas_hours.append(max(0.0, delta_hours))
    avg_response_time_hours = (
        round(sum(deltas_hours) / len(deltas_hours), 1) if deltas_hours else 0.0
    )

    return RepresentativeMetricsOut(
        total_ward_issues=total_ward_issues,
        escalated_ward_issues=escalated_ward_issues,
        responded_ward_issues=responded_ward_issues,
        pending_response_ward_issues=pending_response_ward_issues,
        resolved_ward_issues=resolved_ward_issues,
        in_progress_ward_issues=in_progress_ward_issues,
        acknowledged_ward_issues=acknowledged_ward_issues,
        response_rate_pct=response_rate_pct,
        avg_response_time_hours=avg_response_time_hours,
    )


async def get_representative_profile_out(
    session: AsyncSession, profile: RepresentativeProfile
) -> RepresentativeProfileOut:
    metrics = await compute_rep_metrics(session, profile)
    user_stmt = select(User.username).where(User.id == profile.user_id)
    username = (await session.execute(user_stmt)).scalar_one_or_none()
    return RepresentativeProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        official_name=profile.official_name,
        title=profile.title,
        ward=profile.ward,
        department=getattr(profile, "department", "all"),
        is_unclaimed=getattr(profile, "is_unclaimed", False),
        handle=username,
        contact_email=getattr(profile, "contact_email", None),
        contact_phone=getattr(profile, "contact_phone", None),
        verified_at=profile.verified_at,
        **metrics.model_dump(),
    )


async def get_public_rep_by_user(
    session: AsyncSession, user_id: int
) -> PublicRepresentativeProfileOut:
    stmt = select(RepresentativeProfile).where(RepresentativeProfile.user_id == user_id)
    profile = (await session.execute(stmt)).scalar_one_or_none()
    if profile is None:
        raise AppError("Representative not found", status_code=404, code="rep_not_found")
    metrics = await compute_rep_metrics(session, profile)
    user_stmt = select(User.username).where(User.id == profile.user_id)
    username = (await session.execute(user_stmt)).scalar_one_or_none()
    return PublicRepresentativeProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        official_name=profile.official_name,
        title=profile.title,
        ward=profile.ward,
        department=getattr(profile, "department", "all"),
        is_unclaimed=getattr(profile, "is_unclaimed", False),
        handle=username,
        contact_email=getattr(profile, "contact_email", None),
        contact_phone=getattr(profile, "contact_phone", None),
        verified_at=profile.verified_at,
        **metrics.model_dump(),
    )


async def list_ward_issues(
    session: AsyncSession,
    profile: RepresentativeProfile,
    secret: str | None = None,
    filter: str = "all",
    limit: int = 20,
    offset: int = 0,
) -> WardIssuesResponse:
    responded_subquery = select(OfficialResponse.issue_id).distinct()

    stmt = select(Issue).where(Issue.ward == profile.ward)
    count_stmt = select(func.count(Issue.id)).where(Issue.ward == profile.ward)

    if filter == "escalated":
        esc_filter = (Issue.status.in_(["escalated", "escalating", "forwarded"])) | (
            Issue.escalated_at.isnot(None)
        )
        stmt = stmt.where(esc_filter)
        count_stmt = count_stmt.where(esc_filter)
    elif filter == "needs_response":
        stmt = stmt.where(Issue.id.not_in(responded_subquery))
        count_stmt = count_stmt.where(Issue.id.not_in(responded_subquery))

    total_res = await session.execute(count_stmt)
    total = total_res.scalar() or 0

    stmt = stmt.order_by(Issue.created_at.desc(), Issue.id.desc()).limit(limit).offset(offset)
    issues_res = await session.execute(stmt)
    issues = list(issues_res.scalars().all())

    issue_ids = [i.id for i in issues]
    responded_ids: set[int] = set()
    if issue_ids:
        resp_check_stmt = select(OfficialResponse.issue_id).where(
            OfficialResponse.issue_id.in_(issue_ids)
        )
        resp_check_res = await session.execute(resp_check_stmt)
        responded_ids = set(resp_check_res.scalars().all())

    items = [
        to_issue_out(
            issue,
            secret=secret,
            official_responded_issue_ids=responded_ids,
        )
        for issue in issues
    ]

    return WardIssuesResponse(items=items, total=total)


async def create_official_response(
    session: AsyncSession,
    profile: RepresentativeProfile,
    issue_id: int,
    payload: OfficialResponseCreate,
) -> OfficialResponseOut:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    if issue.ward != profile.ward:
        raise AppError(
            "Representative cannot respond to issues outside assigned ward",
            status_code=403,
            code="ward_mismatch",
        )

    response_id = f"off_resp_{uuid.uuid4().hex[:8]}"
    now = datetime.now(UTC).replace(tzinfo=None)
    official_resp = OfficialResponse(
        id=response_id,
        issue_id=issue.id,
        representative_id=profile.id,
        message=payload.message,
        estimated_resolution_days=payload.estimated_resolution_days,
        status_update=payload.status_update,
        created_at=now,
    )
    session.add(official_resp)
    await session.commit()
    await session.refresh(official_resp)

    return OfficialResponseOut(
        id=official_resp.id,
        issue_id=official_resp.issue_id,
        representative_id=profile.id,
        official_name=profile.official_name,
        title=profile.title,
        ward=profile.ward,
        message=official_resp.message,
        estimated_resolution_days=official_resp.estimated_resolution_days,
        status_update=official_resp.status_update,
        created_at=official_resp.created_at,
    )


async def get_official_responses(session: AsyncSession, issue_id: int) -> list[OfficialResponseOut]:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    stmt = (
        select(OfficialResponse, RepresentativeProfile)
        .join(
            RepresentativeProfile,
            RepresentativeProfile.id == OfficialResponse.representative_id,
        )
        .where(OfficialResponse.issue_id == issue_id)
        .order_by(OfficialResponse.created_at.asc())
    )
    res = await session.execute(stmt)
    rows = res.all()

    return [
        OfficialResponseOut(
            id=resp.id,
            issue_id=resp.issue_id,
            representative_id=resp.representative_id,
            official_name=rep.official_name,
            title=rep.title,
            ward=rep.ward,
            message=resp.message,
            estimated_resolution_days=resp.estimated_resolution_days,
            status_update=resp.status_update,
            created_at=resp.created_at,
        )
        for resp, rep in rows
    ]
