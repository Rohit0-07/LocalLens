import datetime
import re
import urllib.parse

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.auth.models import User
from app.features.issues.geo import haversine_km
from app.features.issues.models import Issue
from app.features.issues.service import to_issue_out
from app.features.representatives.models import RepresentativeProfile
from app.features.representatives.service import compute_rep_metrics
from app.features.wards.models import LocalTalkPost, Notice, Ward
from app.features.wards.schemas import (
    AssignedRepresentativeOut,
    LocalTalkPostCreate,
    LocalTalkPostOut,
    NoticeOut,
    WardDetailOut,
    WardListResponse,
    WardSummaryOut,
)

talk_rate_limiter = SlidingWindowRateLimiter(max_requests=10, window_seconds=300)

PROFANITY_WORDS = {
    "badword",
    "abuse",
    "slur",
    "hate",
    "toxic",
    "scam",
}


def sanitize_text(text: str) -> str:
    cleaned = text
    for word in PROFANITY_WORDS:
        pattern = re.compile(re.escape(word), re.IGNORECASE)
        cleaned = pattern.sub("*" * len(word), cleaned)
    return cleaned


def slugify_ward_name(raw_name: str) -> str:
    s = raw_name.lower()
    s = re.sub(r"[^\w\s-]", "", s)
    s = re.sub(r"[\s,]+", "-", s)
    return s.strip("-")


def calculate_resolution_rate(total_issues: int, resolved_issues: int) -> float:
    if total_issues <= 0:
        return 0.0
    return round((resolved_issues / total_issues) * 100.0, 2)


async def _get_ward_metrics(session: AsyncSession, ward: Ward) -> tuple[int, int, int, int, float]:
    where_clause = (
        (Issue.ward == ward.name)
        | (Issue.ward == ward.slug)
        | (Issue.ward == ward.code)
        | (Issue.ward.ilike(f"%{ward.name}%"))
        | (Issue.ward.ilike(f"%{ward.code}%"))
    )

    total_issues = (
        await session.execute(select(func.count(Issue.id)).where(where_clause))
    ).scalar_one()

    resolved_issues = (
        await session.execute(
            select(func.count(Issue.id)).where(where_clause & (Issue.status == "resolved"))
        )
    ).scalar_one()

    escalated_issues = (
        await session.execute(
            select(func.count(Issue.id)).where(
                where_clause
                & (
                    (Issue.status.in_(["escalated", "escalating", "forwarded"]))
                    | (Issue.escalated_at.isnot(None))
                )
            )
        )
    ).scalar_one()

    active_issues = (
        await session.execute(
            select(func.count(Issue.id)).where(
                where_clause
                & Issue.status.in_(
                    [
                        "open",
                        "acknowledged",
                        "in_progress",
                        "under_review",
                        "unacknowledged",
                        "pending_quorum",
                    ]
                )
            )
        )
    ).scalar_one()

    resolution_rate_pct = calculate_resolution_rate(total_issues, resolved_issues)

    return total_issues, active_issues, escalated_issues, resolved_issues, resolution_rate_pct


async def get_ward_detail(
    session: AsyncSession, ward_slug: str, issues_limit: int = 10
) -> WardDetailOut:
    unquoted = urllib.parse.unquote(ward_slug)
    computed_slug = slugify_ward_name(unquoted)

    stmt = select(Ward).where(
        (Ward.slug == ward_slug)
        | (Ward.slug == computed_slug)
        | (Ward.name == unquoted)
        | (Ward.name == ward_slug)
    )
    result = await session.execute(stmt)
    ward = result.scalars().first()

    if ward is None:
        raise AppError(status_code=404, detail="Ward not found", code="ward_not_found")

    (
        total_issues,
        active_issues,
        escalated_issues,
        resolved_issues,
        resolution_rate_pct,
    ) = await _get_ward_metrics(session, ward)

    where_clause = (Issue.ward == ward.name) | (Issue.ward == ward.slug)

    # Top categories
    top_cat_stmt = (
        select(Issue.category, func.count(Issue.id).label("cnt"))
        .where(where_clause)
        .group_by(Issue.category)
        .order_by(func.count(Issue.id).desc())
        .limit(5)
    )
    top_cat_res = await session.execute(top_cat_stmt)
    top_categories = [row[0] for row in top_cat_res.all()]

    # Representative
    rep_stmt = select(RepresentativeProfile).where(
        (RepresentativeProfile.ward == ward.name) | (RepresentativeProfile.ward == ward.slug)
    )
    rep = (await session.execute(rep_stmt)).scalars().first()
    assigned_rep = None
    if rep:
        rep_metrics = await compute_rep_metrics(session, rep)
        assigned_rep = AssignedRepresentativeOut(
            id=rep.id,
            user_id=rep.user_id,
            ward=rep.ward,
            official_name=rep.official_name,
            title=rep.title,
            verified_at=rep.verified_at,
            **rep_metrics.model_dump(),
        )

    # Recent issues (exclude shielded unresolved)
    recent_stmt = (
        select(Issue)
        .where(where_clause & ~((Issue.is_shielded.is_(True)) & (Issue.status != "resolved")))
        .order_by(Issue.created_at.desc())
        .limit(issues_limit)
    )
    recent_res = await session.execute(recent_stmt)
    recent_issues_objs = list(recent_res.scalars().all())
    recent_issues = [to_issue_out(i, secret="secret") for i in recent_issues_objs]

    return WardDetailOut(
        slug=ward.slug,
        name=ward.name,
        code=ward.code,
        center_latitude=ward.center_latitude,
        center_longitude=ward.center_longitude,
        total_issues=total_issues,
        active_issues=active_issues,
        escalated_issues=escalated_issues,
        resolved_issues=resolved_issues,
        resolution_rate_pct=resolution_rate_pct,
        top_categories=top_categories,
        assigned_representative=assigned_rep,
        recent_issues=recent_issues,
        updated_at=ward.updated_at or datetime.datetime.utcnow(),
    )


get_ward_by_slug = get_ward_detail


async def list_wards(session: AsyncSession, limit: int = 20, offset: int = 0) -> WardListResponse:
    total_res = await session.execute(select(func.count(Ward.id)))
    total = total_res.scalar_one()

    wards_stmt = select(Ward).order_by(Ward.id.asc()).limit(limit).offset(offset)
    wards_res = await session.execute(wards_stmt)
    wards = list(wards_res.scalars().all())

    items: list[WardSummaryOut] = []
    for w in wards:
        total_i, active_i, esc_i, res_i, rate = await _get_ward_metrics(session, w)
        items.append(
            WardSummaryOut(
                slug=w.slug,
                name=w.name,
                code=w.code,
                center_latitude=w.center_latitude,
                center_longitude=w.center_longitude,
                total_issues=total_i,
                active_issues=active_i,
                escalated_issues=esc_i,
                resolved_issues=res_i,
                resolution_rate_pct=rate,
            )
        )

    return WardListResponse(items=items, total=total, limit=limit, offset=offset)


list_active_wards = list_wards


async def get_ward_by_location(
    session: AsyncSession, latitude: float, longitude: float
) -> WardSummaryOut:
    if not (-90.0 <= latitude <= 90.0):
        raise AppError(
            status_code=400,
            detail="Latitude must be between -90 and 90",
            code="invalid_coordinates",
        )
    if not (-180.0 <= longitude <= 180.0):
        raise AppError(
            status_code=400,
            detail="Longitude must be between -180 and 180",
            code="invalid_coordinates",
        )

    wards_res = await session.execute(select(Ward))
    wards = list(wards_res.scalars().all())

    if not wards:
        raise AppError(status_code=404, detail="Ward not found", code="ward_not_found")

    nearest_ward: Ward | None = None
    min_dist = float("inf")

    for w in wards:
        dist = haversine_km(latitude, longitude, w.center_latitude, w.center_longitude)
        if dist < min_dist:
            min_dist = dist
            nearest_ward = w

    if nearest_ward is None or min_dist > 50.0:
        raise AppError(status_code=404, detail="Ward not found", code="ward_not_found")

    total_i, active_i, esc_i, res_i, rate = await _get_ward_metrics(session, nearest_ward)
    return WardSummaryOut(
        slug=nearest_ward.slug,
        name=nearest_ward.name,
        code=nearest_ward.code,
        center_latitude=nearest_ward.center_latitude,
        center_longitude=nearest_ward.center_longitude,
        total_issues=total_i,
        active_issues=active_i,
        escalated_issues=esc_i,
        resolved_issues=res_i,
        resolution_rate_pct=rate,
    )


resolve_ward_by_location = get_ward_by_location


async def create_local_talk_post(
    session: AsyncSession,
    ward_slug: str,
    user: User,
    payload: LocalTalkPostCreate,
) -> LocalTalkPost:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to create talk posts", status_code=403, code="guest_restricted"
        )

    rate_key = f"talk:{user.id}"
    if not talk_rate_limiter.allow(rate_key):
        raise AppError(
            "Rate limit exceeded. Maximum 10 talk posts per 5 minutes.",
            status_code=429,
            code="rate_limited",
        )

    sanitized_title = sanitize_text(payload.title)
    sanitized_body = sanitize_text(payload.body)

    author_name = "Verified Citizen"
    if getattr(user, "phone", None):
        author_name = f"User {user.id}"

    post = LocalTalkPost(
        ward_slug=ward_slug,
        author_id=user.id,
        author_name=author_name,
        title=sanitized_title,
        body=sanitized_body,
        topic=payload.topic or "General",
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    session.add(post)
    await session.commit()
    await session.refresh(post)
    return post


async def list_local_talk_posts(
    session: AsyncSession,
    ward_slug: str,
    limit: int = 20,
    offset: int = 0,
) -> list[LocalTalkPost]:
    stmt = (
        select(LocalTalkPost)
        .where(LocalTalkPost.ward_slug == ward_slug)
        .order_by(LocalTalkPost.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    res = await session.execute(stmt)
    return list(res.scalars().all())


async def list_all_talk_posts_near(
    session: AsyncSession,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    limit: int = 20,
    offset: int = 0,
) -> list[LocalTalkPost]:
    stmt = select(LocalTalkPost).order_by(LocalTalkPost.created_at.desc()).limit(limit * 2)
    res = await session.execute(stmt)
    posts = list(res.scalars().all())

    filtered: list[LocalTalkPost] = []
    for p in posts:
        if p.latitude is not None and p.longitude is not None:
            if haversine_km(latitude, longitude, p.latitude, p.longitude) <= radius_km:
                filtered.append(p)
        else:
            filtered.append(p)
        if len(filtered) >= limit + offset:
            break
    return filtered[offset : offset + limit]


async def list_notices_near(
    session: AsyncSession,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    limit: int = 20,
    offset: int = 0,
) -> list[Notice]:
    stmt = select(Notice).order_by(Notice.created_at.desc()).limit(limit * 2)
    res = await session.execute(stmt)
    notices = list(res.scalars().all())

    filtered: list[Notice] = []
    for n in notices:
        if haversine_km(latitude, longitude, n.latitude, n.longitude) <= radius_km:
            filtered.append(n)
            if len(filtered) >= limit + offset:
                break
    return filtered[offset : offset + limit]


def to_local_talk_post_out(post: LocalTalkPost) -> LocalTalkPostOut:
    return LocalTalkPostOut(
        id=post.id,
        ward_slug=post.ward_slug,
        author_name=post.author_name,
        title=post.title,
        body=post.body,
        topic=post.topic,
        replies_count=post.replies_count,
        latitude=post.latitude,
        longitude=post.longitude,
        created_at=post.created_at,
    )


def to_notice_out(notice: Notice) -> NoticeOut:
    return NoticeOut(
        id=notice.id,
        title=notice.title,
        description=notice.description,
        official_header=notice.official_header,
        valid_until=notice.valid_until,
        ward=notice.ward,
        latitude=notice.latitude,
        longitude=notice.longitude,
        geohash=notice.geohash,
        created_at=notice.created_at,
    )
