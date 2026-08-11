import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.features.issues.models import Issue
from app.features.issues.service import to_issue_out
from app.features.representatives.models import OfficialResponse, RepresentativeProfile
from app.features.representatives.schemas import (
    OfficialResponseCreate,
    OfficialResponseOut,
    RepresentativeProfileOut,
    WardIssuesResponse,
)


async def get_representative_profile(
    session: AsyncSession, user_id: int
) -> RepresentativeProfile | None:
    stmt = select(RepresentativeProfile).where(RepresentativeProfile.user_id == user_id)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def get_representative_profile_out(
    session: AsyncSession, profile: RepresentativeProfile
) -> RepresentativeProfileOut:
    total_stmt = select(func.count(Issue.id)).where(Issue.ward == profile.ward)
    total_res = await session.execute(total_stmt)
    total_ward_issues = total_res.scalar() or 0

    esc_stmt = select(func.count(Issue.id)).where(
        Issue.ward == profile.ward, Issue.status == "escalated"
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

    return RepresentativeProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        official_name=profile.official_name,
        title=profile.title,
        ward=profile.ward,
        verified_at=profile.verified_at,
        total_ward_issues=total_ward_issues,
        escalated_ward_issues=escalated_ward_issues,
        responded_ward_issues=responded_ward_issues,
        pending_response_ward_issues=pending_response_ward_issues,
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
        stmt = stmt.where(Issue.status == "escalated")
        count_stmt = count_stmt.where(Issue.status == "escalated")
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
