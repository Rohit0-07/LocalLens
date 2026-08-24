import json
from datetime import UTC, datetime, timedelta
from typing import Any, cast

from sqlalchemy import delete, func, or_, select, update
from sqlalchemy.engine import CursorResult
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.core.security import derive_anonymous_identity
from app.features.auth.models import User
from app.features.issues.geo import bbox_statement, haversine_km
from app.features.issues.geohash import encode_geohash
from app.features.issues.models import (
    Comment,
    Flag,
    Issue,
    ModerationAudit,
    QuorumVote,
    Upvote,
    UpvoteRateLimit,
    Win,
    WrongAssignmentReport,
)
from app.features.issues.schemas import (
    AssignedAuthorityOut,
    CommentCreate,
    CommentResponse,
    FlagCategory,
    FlagCreate,
    FlaggedIssueItem,
    FlaggedQueueResponse,
    FlagOut,
    IssueCreate,
    IssueOut,
    IssueTimelineEventOut,
    IssueTimelineResponse,
    ModerationAction,
    ModerationActionRequest,
    ModerationResultOut,
    NearDuplicateOut,
    QuorumVoterOut,
    WinOut,
)
from app.features.representatives.models import OfficialResponse, RepresentativeProfile
from app.features.wards.models import Ward

flag_rate_limiter = SlidingWindowRateLimiter(max_requests=5, window_seconds=600)

#: Over-fetch multiplier for radius-filtered listings: fetch a bounded
#: superset, apply the exact haversine/shield checks in Python, then slice
#: the page once (see search/service.py for the same pattern).
_GEO_OVERFETCH_FACTOR = 6

#: Default cap for the threaded comments list so payloads stay bounded.
_MAX_COMMENTS_PER_REQUEST = 200


def _utc_now() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


def build_search_blob(
    *, title: str, description: str, category: str, ward: str
) -> str:
    """Lowercased, space-joined text indexed by `/search` (F-08)."""
    return " ".join(
        part for part in (title, description, category, ward) if part
    ).lower()


def _loaded_reporter(issue: Issue) -> User | None:
    """Return the eager-loaded reporter if present, without triggering a lazy load.

    The `reporter` relationship must be eagerly loaded (selectinload) at the
    query site; in async contexts, touching an unloaded lazy relationship
    would raise MissingGreenlet.
    """
    if "reporter" in issue.__dict__ and issue.__dict__.get("reporter") is not None:
        return issue.__dict__["reporter"]
    return None


def _masked_identity(issue: Issue) -> str | None:
    """Return a masked fallback label for a real reporter with no profile name."""
    reporter = _loaded_reporter(issue)
    if reporter is None:
        return None
    phone = getattr(reporter, "phone", None)
    if phone:
        digits = "".join(ch for ch in phone if ch.isdigit())
        if len(digits) >= 4:
            return f"Citizen ••••{digits[-4:]}"
    email = getattr(reporter, "email", None)
    if email:
        local = email.split("@")[0]
        if len(local) >= 2:
            return f"{local[0]}•••"
    return None


async def _reloaded_issue(session: AsyncSession, issue_id: int) -> Issue:
    """Re-select an issue with the relationships ``to_issue_out`` needs eagerly loaded.

    Mutation endpoints must not return issues whose ``reporter`` relationship was
    never loaded: ``to_issue_out`` deliberately avoids lazy loads (see
    ``_loaded_reporter``) and would otherwise fall back to generic labels such as
    "Verified citizen".
    """
    result = await session.execute(
        select(Issue)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
        )
        .where(Issue.id == issue_id)
        # Refresh identity-mapped instances so atomically-updated counter
        # columns (UPDATE ... SET x = x + 1) are reflected in-memory.
        .execution_options(populate_existing=True)
    )
    return result.scalar_one()


def reporter_label_for(issue: Issue) -> str:
    if issue.is_anonymous:
        return "Anonymous"
    reporter = _loaded_reporter(issue)
    if reporter is not None:
        display = getattr(reporter, "display_name", None) or getattr(reporter, "username", None)
        if display:
            return display
        masked = _masked_identity(issue)
        if masked:
            return masked
    return "Verified citizen"


def reporter_identity_for(issue: Issue) -> tuple[str | None, str | None]:
    """Return (reporter_name, reporter_photo_url) for non-anonymous issues."""
    if issue.is_anonymous:
        return None, None
    reporter = _loaded_reporter(issue)
    if reporter is None:
        return None, None
    name = getattr(reporter, "display_name", None) or getattr(reporter, "username", None) or _masked_identity(issue)
    photo = getattr(reporter, "photo_url", None)
    return (name or None, photo or None)


def to_issue_out(
    issue: Issue,
    secret: str | None = None,
    user_id: int | None = None,
    user_upvoted_ids: set[int] | None = None,
    official_responded_issue_ids: set[int] | None = None,
) -> IssueOut:
    label = reporter_label_for(issue)
    reporter_name, reporter_photo_url = reporter_identity_for(issue)
    anon_id = (
        derive_anonymous_identity(issue.reporter_id, secret)
        if (secret and issue.is_anonymous and issue.reporter_id is not None)
        else None
    )

    has_upvoted = False
    if user_upvoted_ids is not None:
        has_upvoted = issue.id in user_upvoted_ids
    elif user_id is not None:
        upvotes = getattr(issue, "upvotes", None)
        if upvotes:
            has_upvoted = any(u.user_id == user_id for u in upvotes)

    has_official_response = False
    if official_responded_issue_ids is not None:
        has_official_response = issue.id in official_responded_issue_ids
    elif "official_responses" in issue.__dict__:
        official_resps = issue.__dict__["official_responses"]
        if official_resps:
            has_official_response = len(official_resps) > 0

    media_urls_list: list[str] = []
    raw_urls = getattr(issue, "media_urls", None)
    if raw_urls:
        try:
            parsed = json.loads(raw_urls)
            if isinstance(parsed, list):
                media_urls_list = [str(u) for u in parsed]
            elif isinstance(parsed, str):
                media_urls_list = [parsed]
        except Exception:
            media_urls_list = [raw_urls]

    media_url = getattr(issue, "media_url", None) or (media_urls_list[0] if media_urls_list else None)
    video_url = getattr(issue, "video_url", None)
    if media_url and media_url not in media_urls_list:
        media_urls_list.insert(0, media_url)
    if video_url and video_url not in media_urls_list:
        media_urls_list.append(video_url)

    reporter_id_val = None
    if not issue.is_anonymous or (user_id is not None and user_id == issue.reporter_id):
        reporter_id_val = issue.reporter_id

    assigned_rep_out = None
    if "assigned_representative" in issue.__dict__ and issue.__dict__["assigned_representative"] is not None:
        rep_obj = issue.__dict__["assigned_representative"]
        user_handle = None
        if "user" in rep_obj.__dict__ and rep_obj.__dict__["user"] is not None:
            user_handle = rep_obj.__dict__["user"].username
        assigned_rep_out = AssignedAuthorityOut(
            id=rep_obj.id,
            official_name=rep_obj.official_name,
            title=rep_obj.title,
            ward=rep_obj.ward,
            department=getattr(rep_obj, "department", "all"),
            handle=user_handle,
            is_unclaimed=getattr(rep_obj, "is_unclaimed", False),
            is_verified=not getattr(rep_obj, "is_unclaimed", False),
            contact_email=getattr(rep_obj, "contact_email", None),
            contact_phone=getattr(rep_obj, "contact_phone", None),
        )

    return IssueOut(
        id=issue.id,
        title=issue.title,
        description=issue.description,
        category=issue.category,
        status=issue.status,
        latitude=issue.latitude,
        longitude=issue.longitude,
        geohash=issue.geohash,
        ward=issue.ward or "Ward 45, Urban Central",
        is_anonymous=issue.is_anonymous,
        fuzz_location=issue.fuzz_location or issue.is_fuzzed,
        is_fuzzed=issue.is_fuzzed or issue.fuzz_location,
        is_shielded=issue.is_shielded,
        reporter_id=reporter_id_val,
        reporter_label=label,
        reporter_name=reporter_name,
        reporter_photo_url=reporter_photo_url,
        anonymous_identity=anon_id,
        media_url=media_url,
        video_url=video_url,
        media_urls=media_urls_list,
        created_at=issue.created_at,
        acknowledged_at=issue.acknowledged_at,
        resolved_at=issue.resolved_at,
        upvotes_count=issue.upvotes_count,
        comments_count=issue.comments_count or 0,
        confirmations_count=issue.confirmations_count,
        disputes_count=issue.disputes_count,
        resolution_proof=issue.resolution_proof,
        resolution_notes=issue.resolution_notes,
        has_upvoted=has_upvoted,
        has_official_response=has_official_response,
        assigned_representative=assigned_rep_out,
        resolved_by=issue.resolved_by,
        resolution_type=issue.resolution_type,
    )


async def _link_media_to_issue(
    session: AsyncSession,
    issue: Issue,
    media_urls: list[str],
) -> None:
    """Link uploaded Media rows to the created issue by URL match.

    Media rows whose ``url`` or ``thumbnail_url`` matches one of the issue's
    media URLs get ``issue_id`` set so the media library can enforce
    delete-after-publish semantics. Lazy-imports ``Media`` to match the
    existing style in this module.
    """
    urls = set(media_urls)
    if not urls:
        return
    from app.features.media.models import Media

    stmt = select(Media).where(or_(Media.url.in_(urls), Media.thumbnail_url.in_(urls)))
    result = await session.execute(stmt)
    media_rows = list(result.scalars().all())
    for media in media_rows:
        if media.issue_id is None:
            media.issue_id = issue.id
    if media_rows:
        await session.commit()


async def create_issue(
    session: AsyncSession, payload: IssueCreate, reporter_id: int | None = None
) -> Issue:
    effective_reporter_id = reporter_id
    is_fuzzed = payload.is_fuzzed or payload.fuzz_location
    if is_fuzzed:
        lat = round(payload.latitude, 2)
        lng = round(payload.longitude, 2)
    else:
        lat = payload.latitude
        lng = payload.longitude

    gh = encode_geohash(lat, lng)

    media_urls_list = list(payload.media_urls) if payload.media_urls else []
    if payload.media_url and payload.media_url not in media_urls_list:
        media_urls_list.insert(0, payload.media_url)
    if payload.video_url and payload.video_url not in media_urls_list:
        media_urls_list.append(payload.video_url)

    first_media = payload.media_url or (media_urls_list[0] if media_urls_list else None)

    # Dynamic ward resolution
    ward_stmt = select(Ward)
    ward_rows = (await session.execute(ward_stmt)).scalars().all()
    assigned_ward_name = "Ward 45, Urban Central"
    min_distance = float("inf")
    for w in ward_rows:
        dist = haversine_km(lat, lng, w.center_latitude, w.center_longitude)
        if dist < min_distance:
            min_distance = dist
            assigned_ward_name = w.name

    # Auto-assign representative based on ward and category
    assigned_rep_id = None
    rep_stmt = select(RepresentativeProfile).where(
        (RepresentativeProfile.ward == assigned_ward_name)
        | (RepresentativeProfile.ward.ilike(f"%{assigned_ward_name}%"))
    )
    rep_rows = list((await session.execute(rep_stmt)).scalars().all())
    if rep_rows:
        matched_rep = next(
            (r for r in rep_rows if r.department and r.department.lower() == payload.category.lower()),
            None,
        )
        if not matched_rep:
            matched_rep = next(
                (r for r in rep_rows if r.department in ("all", "general", None)),
                rep_rows[0],
            )
        assigned_rep_id = matched_rep.id

    issue = Issue(
        title=payload.title,
        description=payload.description,
        category=payload.category,
        latitude=lat,
        longitude=lng,
        geohash=gh,
        ward=assigned_ward_name,
        assigned_representative_id=assigned_rep_id,
        is_anonymous=payload.is_anonymous,
        fuzz_location=is_fuzzed,
        is_fuzzed=is_fuzzed,
        is_shielded=payload.is_shielded,
        reporter_id=effective_reporter_id,
        media_url=first_media,
        video_url=payload.video_url,
        media_urls=json.dumps(media_urls_list) if media_urls_list else None,
        search_blob=build_search_blob(
            title=payload.title,
            description=payload.description,
            category=payload.category,
            ward=assigned_ward_name,
        ),
        status="unacknowledged",
    )
    session.add(issue)
    await session.commit()
    issue = await session.scalar(
        select(Issue)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
        )
        .where(Issue.id == issue.id)
    )
    await _link_media_to_issue(session, issue, media_urls_list)
    return issue  # type: ignore[return-value]


async def list_issues_near(
    session: AsyncSession,
    *,
    latitude: float,
    longitude: float,
    radius_km: float,
    status_filter: str | None,
    limit: int,
    offset: int,
    created_before: datetime | None = None,
) -> list[Issue]:
    statement = await bbox_statement(latitude, longitude, radius_km)
    statement = statement.where(Issue.is_hidden.is_(False))
    if status_filter:
        statement = statement.where(Issue.status == status_filter)
    if created_before is not None:
        statement = statement.where(Issue.created_at <= created_before)
    statement = statement.options(
        selectinload(Issue.reporter),
        selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
    )
    statement = statement.order_by(Issue.created_at.desc()).limit(
        (offset + limit) * _GEO_OVERFETCH_FACTOR
    )
    result = await session.execute(statement)
    issues = list(result.scalars().all())

    # Filter out shielded issues unless resolved, then apply the exact radius.
    filtered_issues: list[Issue] = []
    for issue in issues:
        if issue.is_shielded and issue.status != "resolved":
            continue
        if haversine_km(latitude, longitude, issue.latitude, issue.longitude) <= radius_km:
            filtered_issues.append(issue)

    return filtered_issues[offset : offset + limit]


async def get_issue(session: AsyncSession, issue_id: int) -> Issue | None:
    result = await session.execute(
        select(Issue)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
            selectinload(Issue.official_responses),
        )
        .where(Issue.id == issue_id)
    )
    issue = result.scalar_one_or_none()
    return issue


async def delete_issue(
    session: AsyncSession,
    issue_id: int,
    user_id: int,
) -> Issue | None:
    """Soft-delete an issue owned by the given user.

    Returns the soft-deleted issue, or None if it does not exist.
    """
    issue = await session.get(Issue, issue_id)
    if issue is None:
        return None
    if issue.reporter_id != user_id:
        raise AppError(
            "Not authorized to delete this issue", status_code=403, code="forbidden"
        )
    issue.is_hidden = True
    await session.commit()
    await session.refresh(issue)
    return issue


async def detect_near_duplicates(
    session: AsyncSession,
    *,
    latitude: float,
    longitude: float,
    category: str | None = None,
    radius_km: float = 0.030,
    limit: int = 10,
) -> list[NearDuplicateOut]:
    statement = await bbox_statement(latitude, longitude, max(radius_km, 0.05))
    statement = statement.order_by(Issue.created_at.desc()).limit(limit * 4)
    result = await session.execute(statement)
    candidates = list(result.scalars().all())

    duplicates: list[NearDuplicateOut] = []
    for issue in candidates:
        if category and category.strip():
            if issue.category.strip().lower() != category.strip().lower():
                continue

        dist_km = haversine_km(latitude, longitude, issue.latitude, issue.longitude)
        if dist_km <= radius_km:
            duplicates.append(
                NearDuplicateOut(
                    id=issue.id,
                    title=issue.title,
                    category=issue.category,
                    status=issue.status,
                    latitude=issue.latitude,
                    longitude=issue.longitude,
                    geohash=issue.geohash,
                    distance_meters=round(dist_km * 1000.0, 1),
                    created_at=issue.created_at,
                )
            )
            if len(duplicates) >= limit:
                break
    return duplicates


async def acknowledge_issue(session: AsyncSession, issue_id: int) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")
    issue.acknowledged_at = _utc_now()
    issue.status = "under_review"
    await session.commit()
    return await _reloaded_issue(session, issue_id)


async def submit_resolution(
    session: AsyncSession, issue_id: int, proof_url: str, notes: str | None = None
) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")
    issue.resolution_proof = proof_url
    issue.resolution_notes = notes
    issue.status = "pending_quorum"
    issue.quorum_expires_at = _utc_now() + timedelta(days=7)
    await session.commit()
    return await _reloaded_issue(session, issue_id)


async def vote_quorum(
    session: AsyncSession,
    issue_id: int,
    user_id: int,
    vote: str,
    latitude: float,
    longitude: float,
    reason: str | None = None,
) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    if issue.status != "pending_quorum":
        raise AppError(
            "Issue is not pending quorum verification", status_code=400, code="invalid_status"
        )

    # Proximity check
    dist_km = haversine_km(latitude, longitude, issue.latitude, issue.longitude)
    if dist_km > 5.0:
        raise AppError(
            "Must be within 5 km to vote on quorum", status_code=400, code="out_of_radius"
        )

    # Duplicate vote check
    existing_vote = await session.execute(
        select(QuorumVote).where(QuorumVote.issue_id == issue_id, QuorumVote.user_id == user_id)
    )
    if existing_vote.scalar_one_or_none() is not None:
        raise AppError("Already voted on this quorum", status_code=400, code="already_voted")

    quorum_vote = QuorumVote(
        issue_id=issue_id,
        user_id=user_id,
        vote=vote,
        reason=reason,
    )
    session.add(quorum_vote)

    if vote == "confirm":
        await session.execute(
            update(Issue)
            .where(Issue.id == issue_id)
            .values(confirmations_count=Issue.confirmations_count + 1)
            .execution_options(synchronize_session=False)
        )
        issue.confirmations_count += 1
        if issue.confirmations_count >= 3:
            issue.status = "resolved"
            issue.resolved_at = _utc_now()
            await create_win_for_issue(session, issue)
    elif vote == "dispute":
        await session.execute(
            update(Issue)
            .where(Issue.id == issue_id)
            .values(disputes_count=Issue.disputes_count + 1)
            .execution_options(synchronize_session=False)
        )
        if issue.disputes_count + 1 >= 1:
            issue.status = "disputed"

    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        raise AppError("Already voted on this quorum", status_code=400, code="already_voted") from None
    return await _reloaded_issue(session, issue_id)


cast_quorum_vote = vote_quorum


async def check_quorum_expiration(session: AsyncSession, issue_id: int) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    if issue.status == "pending_quorum" and issue.quorum_expires_at:
        if _utc_now() > issue.quorum_expires_at and issue.confirmations_count < 3:
            issue.status = "disputed"
            await session.commit()
            issue = await _reloaded_issue(session, issue_id)
        elif issue.confirmations_count >= 3 and issue.status != "resolved":
            issue.status = "resolved"
            issue.resolved_at = _utc_now()
            await create_win_for_issue(session, issue)
            await session.commit()
            issue = await _reloaded_issue(session, issue_id)
    return issue


check_quorum_status = check_quorum_expiration


async def create_win_for_issue(session: AsyncSession, issue: Issue) -> Win:
    stmt = select(Win).where(Win.issue_id == issue.id)
    res = await session.execute(stmt)
    existing_win = res.scalar_one_or_none()
    if existing_win:
        return existing_win

    credits_list = []
    if issue.is_anonymous:
        credits_list.append("Anonymous Citizen")
    else:
        credits_list.append("Verified Citizen")

    if issue.confirmations_count > 0:
        credits_list.append(f"{issue.confirmations_count} Community Verifiers")

    before_url = None
    from app.features.media.models import Media

    media_stmt = (
        select(Media)
        .where(Media.issue_id == issue.id)
        .order_by(Media.created_at.asc())
    )
    media_res = await session.execute(media_stmt)
    first_media = media_res.scalars().first()
    if first_media:
        before_url = first_media.url

    after_url = issue.resolution_proof

    win = Win(
        issue_id=issue.id,
        title=f"Resolved: {issue.title}",
        description=issue.resolution_notes or issue.description,
        category=issue.category,
        ward=issue.ward or "Ward 45, Urban Central",
        latitude=issue.latitude,
        longitude=issue.longitude,
        geohash=issue.geohash,
        before_image_url=before_url,
        after_image_url=after_url,
        contributor_credits=json.dumps(credits_list),
    )
    session.add(win)
    await session.flush()
    return win


def to_win_out(win: Win) -> WinOut:
    credits_list = []
    if win.contributor_credits:
        try:
            credits_list = json.loads(win.contributor_credits)
        except Exception:
            credits_list = [win.contributor_credits]
    return WinOut(
        id=win.id,
        issue_id=win.issue_id,
        title=win.title,
        description=win.description,
        category=win.category,
        ward=win.ward,
        latitude=win.latitude,
        longitude=win.longitude,
        geohash=win.geohash,
        before_image_url=win.before_image_url,
        after_image_url=win.after_image_url,
        contributor_credits=credits_list,
        created_at=win.created_at,
    )


async def list_wins_near(
    session: AsyncSession,
    *,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    limit: int = 20,
    offset: int = 0,
    created_before: datetime | None = None,
) -> list[Win]:
    stmt = select(Win)
    if created_before is not None:
        stmt = stmt.where(Win.created_at <= created_before)
    stmt = stmt.order_by(Win.created_at.desc()).limit(limit * 6)
    result = await session.execute(stmt)
    wins = list(result.scalars().all())

    filtered_wins: list[Win] = []
    for w in wins:
        if haversine_km(latitude, longitude, w.latitude, w.longitude) <= radius_km:
            filtered_wins.append(w)
            if len(filtered_wins) >= limit + offset:
                break
    return filtered_wins[offset : offset + limit]


async def get_win_by_id(session: AsyncSession, win_id: int) -> Win | None:
    return await session.get(Win, win_id)


def _to_naive_utc(dt: datetime) -> datetime:
    if dt.tzinfo is not None:
        return dt.astimezone(UTC).replace(tzinfo=None)
    return dt


def evaluate_escalation(issue: Issue, now: datetime | None = None) -> bool:
    now_dt = _to_naive_utc(now or _utc_now())
    if issue.status in ("resolved", "forwarded", "pending_quorum", "disputed"):
        return False

    modified = False

    ref_time = _to_naive_utc(issue.acknowledged_at or issue.created_at)
    created_time = _to_naive_utc(issue.created_at)

    # Check 7d escalation (from acknowledged_at or created_at)
    if (now_dt - ref_time).total_seconds() >= 7 * 86400:
        if issue.status != "forwarded":
            issue.status = "forwarded"
            modified = True
            return modified

    # Check 24h escalation for unacknowledged issues
    if not issue.acknowledged_at and issue.status in ("unacknowledged", "open"):
        if (now_dt - created_time).total_seconds() >= 24 * 3600:
            if issue.status != "escalating":
                issue.status = "escalating"
                issue.escalated_at = issue.escalated_at or now_dt
                modified = True

    return modified


async def evaluate_all_escalations(session: AsyncSession) -> int:
    """Set-based escalation sweep (same semantics as evaluate_escalation).

    Two bulk UPDATEs replace per-row hydration:
    1. forwarded: active issues whose acknowledged_at-or-created_at is older
       than 7 days (checked first, matching the early-return order).
    2. escalating: unacknowledged issues older than 24 hours, preserving the
       original escalated_at side effect via COALESCE.
    """
    now = _utc_now()
    forward_res = await session.execute(
        update(Issue)
        .where(
            Issue.status.in_(
                ["unacknowledged", "open", "under_review", "acknowledged", "escalating"]
            ),
            func.coalesce(Issue.acknowledged_at, Issue.created_at)
            <= now - timedelta(days=7),
        )
        .values(status="forwarded")
        .execution_options(synchronize_session=False)
    )
    escalate_res = await session.execute(
        update(Issue)
        .where(
            Issue.status.in_(["unacknowledged", "open"]),
            Issue.acknowledged_at.is_(None),
            Issue.created_at <= now - timedelta(hours=24),
        )
        .values(status="escalating", escalated_at=func.coalesce(Issue.escalated_at, now))
        .execution_options(synchronize_session=False)
    )
    count = cast(CursorResult[Any], forward_res).rowcount + cast(
        CursorResult[Any], escalate_res
    ).rowcount
    if count > 0:
        await session.commit()
    return int(count)


async def upvote_issue(
    session: AsyncSession,
    issue_id: int,
    user_id: int,
    latitude: float,
    longitude: float,
) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    # Proximity check
    dist_km = haversine_km(latitude, longitude, issue.latitude, issue.longitude)
    if dist_km > 5.0:
        raise AppError("Must be within 5 km to upvote", status_code=400, code="out_of_radius")

    # Rate limiting check: max 5 upvotes per 10 minutes
    ten_mins_ago = _utc_now() - timedelta(minutes=10)
    count_stmt = select(func.count(UpvoteRateLimit.id)).where(
        UpvoteRateLimit.user_id == user_id,
        UpvoteRateLimit.created_at >= ten_mins_ago,
    )
    count_res = await session.execute(count_stmt)
    upvote_attempts = count_res.scalar_one()
    if upvote_attempts >= 5:
        raise AppError("Rate limit exceeded for upvoting", status_code=429, code="rate_limited")

    # Duplicate upvote check
    existing = await session.execute(
        select(Upvote).where(Upvote.issue_id == issue_id, Upvote.user_id == user_id)
    )
    if existing.scalar_one_or_none() is not None:
        raise AppError("Already upvoted this issue", status_code=400, code="already_upvoted")

    session.add(Upvote(issue_id=issue_id, user_id=user_id))
    session.add(UpvoteRateLimit(user_id=user_id))
    await session.execute(
        update(Issue)
        .where(Issue.id == issue_id)
        .values(upvotes_count=Issue.upvotes_count + 1)
        .execution_options(synchronize_session=False)
    )
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        raise AppError("Already upvoted this issue", status_code=400, code="already_upvoted") from None
    return await _reloaded_issue(session, issue_id)


async def get_user_upvoted_issue_ids(
    session: AsyncSession, user_id: int, issue_ids: list[int]
) -> set[int]:
    if not issue_ids:
        return set()
    result = await session.execute(
        select(Upvote.issue_id).where(Upvote.user_id == user_id, Upvote.issue_id.in_(issue_ids))
    )
    return set(result.scalars().all())


async def remove_upvote_issue(
    session: AsyncSession,
    issue_id: int,
    user_id: int,
) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    existing = await session.execute(
        select(Upvote).where(Upvote.issue_id == issue_id, Upvote.user_id == user_id)
    )
    upvote = existing.scalar_one_or_none()
    if upvote is None:
        raise AppError("Have not upvoted this issue", status_code=400, code="not_upvoted")

    await session.delete(upvote)
    issue.upvotes_count = max(0, issue.upvotes_count - 1)
    await session.commit()
    return await _reloaded_issue(session, issue_id)


async def post_comment(
    session: AsyncSession,
    issue_id: int,
    user: User,
    payload: CommentCreate,
    secret: str,
) -> CommentResponse:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to post comments", status_code=403, code="guest_restricted"
        )

    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    # Rate limiting: max 10 comments per 5 minutes per author
    five_mins_ago = _utc_now() - timedelta(minutes=5)
    count_stmt = select(func.count(Comment.id)).where(
        Comment.author_id == user.id,
        Comment.created_at >= five_mins_ago,
    )
    count_res = await session.execute(count_stmt)
    if count_res.scalar_one() >= 10:
        raise AppError("Rate limit exceeded for commenting", status_code=429, code="rate_limited")

    # Check parent_id if provided
    if payload.parent_id is not None:
        parent = await session.get(Comment, payload.parent_id)
        if parent is None or parent.issue_id != issue_id:
            raise AppError("Parent comment not found", status_code=404, code="not_found")

    anon_id = derive_anonymous_identity(user.id, secret)

    comment = Comment(
        issue_id=issue_id,
        parent_id=payload.parent_id,
        author_id=user.id,
        anon_id=anon_id,
        content=payload.content,
    )
    session.add(comment)
    issue.comments_count = (issue.comments_count or 0) + 1
    await session.commit()
    await session.refresh(comment)

    return CommentResponse(
        id=comment.id,
        issue_id=comment.issue_id,
        parent_id=comment.parent_id,
        anon_id=comment.anon_id,
        content=comment.content,
        created_at=comment.created_at,
        is_author=True,
        replies=[],
    )


async def get_comments(
    session: AsyncSession,
    issue_id: int,
    user_id: int | None = None,
    limit: int = _MAX_COMMENTS_PER_REQUEST,
) -> list[CommentResponse]:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    stmt = (
        select(Comment)
        .where(Comment.issue_id == issue_id)
        .order_by(Comment.created_at.asc())
        .limit(limit)
    )
    res = await session.execute(stmt)
    comments = list(res.scalars().all())

    comments_map: dict[str, CommentResponse] = {}
    top_level: list[CommentResponse] = []

    for c in comments:
        is_author = user_id is not None and c.author_id == user_id
        c_resp = CommentResponse(
            id=c.id,
            issue_id=c.issue_id,
            parent_id=c.parent_id,
            anon_id=c.anon_id,
            content=c.content,
            created_at=c.created_at,
            is_author=is_author,
            replies=[],
        )
        comments_map[c.id] = c_resp

    for c in comments:
        c_resp = comments_map[c.id]
        if c.parent_id and c.parent_id in comments_map:
            comments_map[c.parent_id].replies.append(c_resp)
        else:
            top_level.append(c_resp)

    return top_level


async def delete_comment(
    session: AsyncSession,
    issue_id: int,
    comment_id: str,
    user: User,
) -> None:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to delete comments", status_code=403, code="guest_restricted"
        )

    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    comment = await session.get(Comment, comment_id)
    if comment is None or comment.issue_id != issue_id:
        raise AppError("Comment not found", status_code=404, code="not_found")

    if comment.author_id != user.id:
        raise AppError("Not authorized to delete this comment", status_code=403, code="forbidden")

    all_comments_res = await session.execute(select(Comment).where(Comment.issue_id == issue_id))
    all_comments = list(all_comments_res.scalars().all())

    # Single O(N) graph walk over a parent -> children index, then one bulk
    # DELETE instead of per-row deletes.
    child_ids_by_parent: dict[str | None, list[str]] = {}
    for c in all_comments:
        child_ids_by_parent.setdefault(c.parent_id, []).append(c.id)

    ids_to_delete = {comment_id}
    stack = [comment_id]
    while stack:
        for child_id in child_ids_by_parent.get(stack.pop(), []):
            if child_id not in ids_to_delete:
                ids_to_delete.add(child_id)
                stack.append(child_id)

    deleted_count = len(ids_to_delete)
    await session.execute(
        delete(Comment).where(Comment.id.in_(ids_to_delete)).execution_options(
            synchronize_session=False
        )
    )

    issue.comments_count = max(0, (issue.comments_count or 0) - deleted_count)
    await session.commit()


async def create_flag(
    db: AsyncSession,
    issue_id: int,
    flag_in: FlagCreate,
    current_user: User,
    secret: str | None = None,
) -> FlagOut:
    if getattr(current_user, "is_guest", False):
        raise AppError(
            status_code=403, error_code="guest_restricted", detail="Guest users cannot flag issues."
        )
    if getattr(current_user, "is_banned", False):
        raise AppError(
            status_code=403, error_code="user_banned", detail="Your account has been suspended."
        )

    rate_key = f"flag:{current_user.id}"
    if not flag_rate_limiter.allow(rate_key):
        raise AppError(
            status_code=429,
            error_code="rate_limit_exceeded",
            detail="Rate limit exceeded. Maximum 5 flags per 10 minutes.",
        )

    issue = await db.get(Issue, issue_id)
    if issue is None:
        raise AppError(status_code=404, error_code="not_found", detail="Issue not found.")

    anon_id_val = derive_anonymous_identity(current_user.id, secret or "secret")

    reporter_id_val = current_user.id if isinstance(current_user.id, int) else None
    dup_stmt = select(Flag).where(
        Flag.issue_id == issue_id,
        (Flag.reporter_id == reporter_id_val) | (Flag.anon_id == anon_id_val),
    )
    dup_res = await db.execute(dup_stmt)
    if dup_res.scalar_one_or_none() is not None:
        raise AppError(
            status_code=409,
            error_code="duplicate_flag",
            detail="You have already flagged this issue.",
        )

    category_val = (
        flag_in.category.value
        if isinstance(flag_in.category, FlagCategory)
        else str(flag_in.category)
    )
    flag = Flag(
        issue_id=issue_id,
        reporter_id=reporter_id_val,
        anon_id=anon_id_val,
        category=category_val,
        details=flag_in.details,
    )
    db.add(flag)
    issue.flag_count = (issue.flag_count or 0) + 1
    await db.commit()
    await db.refresh(flag)

    return FlagOut(
        id=flag.id,
        issue_id=flag.issue_id,
        category=flag.category,
        details=flag.details,
        created_at=flag.created_at,
    )


async def get_flagged_queue(
    db: AsyncSession,
    status: str = "pending",
    category: str | None = None,
    limit: int = 20,
    offset: int = 0,
) -> FlaggedQueueResponse:
    stmt = select(Issue).where(Issue.flag_count > 0)
    if status == "pending":
        stmt = stmt.where(Issue.is_hidden.is_(False))
    elif status == "hidden":
        stmt = stmt.where(Issue.is_hidden.is_(True))
    elif status in ("dismissed", "reviewed"):
        sub_audit = select(ModerationAudit.issue_id).where(ModerationAudit.action == "dismiss")
        if status == "dismissed":
            stmt = stmt.where(Issue.id.in_(sub_audit))
        elif status == "reviewed":
            sub_rev = select(ModerationAudit.issue_id)
            stmt = stmt.where(Issue.id.in_(sub_rev))

    if category:
        sub_cat = select(Flag.issue_id).where(Flag.category == category)
        stmt = stmt.where(Issue.id.in_(sub_cat))

    stmt = stmt.order_by(Issue.flag_count.desc(), Issue.created_at.desc())

    total_res = await db.execute(select(func.count()).select_from(stmt.subquery()))
    total = total_res.scalar_one()

    stmt_paginated = stmt.limit(limit).offset(offset)
    result = await db.execute(stmt_paginated)
    issues = list(result.scalars().all())

    # One IN query for the page's flags instead of one query per issue.
    issue_ids = [issue.id for issue in issues]
    flags_by_issue: dict[int, list[Flag]] = {}
    if issue_ids:
        flags_stmt = (
            select(Flag)
            .where(Flag.issue_id.in_(issue_ids))
            .order_by(Flag.created_at.desc())
        )
        for flag in (await db.execute(flags_stmt)).scalars():
            flags_by_issue.setdefault(flag.issue_id, []).append(flag)

    items: list[FlaggedIssueItem] = []
    for issue in issues:
        flags = flags_by_issue.get(issue.id, [])

        categories = list({f.category for f in flags})
        latest_flag_at = flags[0].created_at if flags else issue.created_at

        items.append(
            FlaggedIssueItem(
                issue_id=issue.id,
                title=issue.title,
                description=issue.description,
                reporter_id=issue.reporter_id,
                flag_count=issue.flag_count,
                categories=categories,
                is_hidden=issue.is_hidden,
                latest_flag_at=latest_flag_at,
                created_at=issue.created_at,
            )
        )

    return FlaggedQueueResponse(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
    )


async def moderate_issue(
    db: AsyncSession,
    issue_id: int,
    action_in: ModerationActionRequest,
    admin_user: User,
) -> ModerationResultOut:
    issue = await db.get(Issue, issue_id)
    if issue is None:
        raise AppError(status_code=404, error_code="not_found", detail="Issue not found.")

    action_val = (
        action_in.action.value
        if isinstance(action_in.action, ModerationAction)
        else str(action_in.action)
    )
    reporter_banned = False

    if action_val == "dismiss":
        msg = "Flags dismissed for issue."
    elif action_val == "hide_issue":
        issue.is_hidden = True
        msg = "Issue hidden successfully."
    elif action_val == "ban_reporter":
        issue.is_hidden = True
        if issue.reporter_id is not None:
            reporter = await db.get(User, issue.reporter_id)
            if reporter:
                reporter.is_banned = True
                reporter_banned = True
        msg = "Issue hidden and reporter banned."
    else:
        raise AppError(
            status_code=400, error_code="invalid_action", detail="Invalid moderation action."
        )

    audit = ModerationAudit(
        issue_id=issue_id,
        action=action_val,
        reason=action_in.reason,
        moderated_by=admin_user.id,
    )
    db.add(audit)
    await db.commit()
    await db.refresh(issue)

    return ModerationResultOut(
        success=True,
        issue_id=issue_id,
        action=action_val,
        is_hidden=issue.is_hidden,
        reporter_banned=reporter_banned,
        message=msg,
    )


async def report_wrong_assignment(
    session: AsyncSession,
    issue_id: int,
    user_id: int | None,
    suggested_ward: str | None,
    suggested_category: str | None,
    reason: str,
) -> WrongAssignmentReport:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")
    report = WrongAssignmentReport(
        issue_id=issue_id,
        user_id=user_id,
        suggested_ward=suggested_ward,
        suggested_category=suggested_category,
        reason=reason,
    )
    session.add(report)
    await session.commit()
    await session.refresh(report)
    return report


async def admin_reassign_issue(
    session: AsyncSession,
    issue_id: int,
    admin_user: User,
    ward: str | None = None,
    category: str | None = None,
    assigned_representative_id: str | None = None,
    reason: str | None = None,
) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")
    if ward is not None:
        issue.ward = ward
    if category is not None:
        issue.category = category
    if ward is not None or category is not None:
        issue.search_blob = build_search_blob(
            title=issue.title,
            description=issue.description,
            category=issue.category,
            ward=issue.ward,
        )
    if assigned_representative_id is not None:
        issue.assigned_representative_id = assigned_representative_id
    elif ward or category:
        rep_stmt = select(RepresentativeProfile).where(
            (RepresentativeProfile.ward == issue.ward)
            | (RepresentativeProfile.ward.ilike(f"%{issue.ward}%"))
        )
        rep_rows = list((await session.execute(rep_stmt)).scalars().all())
        if rep_rows:
            matched_rep = next(
                (r for r in rep_rows if r.department and r.department.lower() == issue.category.lower()),
                None,
            )
            if not matched_rep:
                matched_rep = next(
                    (r for r in rep_rows if r.department in ("all", "general", None)),
                    rep_rows[0],
                )
            issue.assigned_representative_id = matched_rep.id

    audit = ModerationAudit(
        issue_id=issue_id,
        action="reassign",
        reason=reason or f"Reassigned ward={issue.ward} category={issue.category}",
        moderated_by=admin_user.id,
    )
    session.add(audit)
    await session.commit()
    return await _reloaded_issue(session, issue_id)


async def get_issue_timeline(
    session: AsyncSession,
    issue_id: int,
) -> IssueTimelineResponse:
    stmt = (
        select(Issue)
        .options(
            selectinload(Issue.reporter),
            selectinload(Issue.assigned_representative).selectinload(RepresentativeProfile.user),
            selectinload(Issue.official_responses).selectinload(
                OfficialResponse.representative
            ).selectinload(RepresentativeProfile.user),
        )
        .where(Issue.id == issue_id)
    )
    issue = (await session.execute(stmt)).scalar_one_or_none()
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    events: list[IssueTimelineEventOut] = []

    # Event 1: Reported
    reporter_handle = None
    if not issue.is_anonymous and issue.reporter:
        reporter_handle = issue.reporter.username
    events.append(
        IssueTimelineEventOut(
            event_type="reported",
            title="Issue Reported",
            description=issue.description or issue.title,
            actor_name=reporter_label_for(issue),
            actor_handle=reporter_handle,
            actor_role="Reporter",
            media_url=issue.media_url,
            created_at=issue.created_at,
        )
    )

    # Event 2: Assigned
    if issue.assigned_representative:
        rep = issue.assigned_representative
        rep_user = (
            rep.user.username
            if rep.user
            else (
                await session.execute(select(User.username).where(User.id == rep.user_id))
            ).scalar_one_or_none()
        )
        events.append(
            IssueTimelineEventOut(
                event_type="assigned",
                title=f"Assigned to {rep.official_name}",
                description=f"Department: {(rep.department or 'general').capitalize()} | Ward: {issue.ward}",
                actor_name=rep.official_name,
                actor_handle=rep_user,
                actor_role=rep.title,
                is_unclaimed=getattr(rep, "is_unclaimed", False),
                created_at=issue.created_at,
            )
        )

    # Event 3: Official Responses / Acknowledgments
    for resp in issue.official_responses:
        rep_name = resp.representative.official_name if resp.representative else "Ward Authority"
        rep_handle = resp.representative.user.username if resp.representative and resp.representative.user else None
        events.append(
            IssueTimelineEventOut(
                event_type="acknowledged" if resp.status_update == "acknowledged" else "official_response",
                title="Official Response" if resp.status_update != "acknowledged" else "Acknowledged by Authority",
                description=resp.message,
                actor_name=rep_name,
                actor_handle=rep_handle,
                actor_role="Ward Representative",
                created_at=resp.created_at,
            )
        )
    if not issue.official_responses and issue.acknowledged_at:
        events.append(
            IssueTimelineEventOut(
                event_type="acknowledged",
                title="Acknowledged by Authority",
                description="Official review recorded and scheduled for field fix.",
                created_at=issue.acknowledged_at,
            )
        )

    # Event 4: Resolution Proof Submitted
    if issue.resolution_proof:
        events.append(
            IssueTimelineEventOut(
                event_type="proof_submitted",
                title="Resolution Proof Uploaded",
                description=issue.resolution_notes or "Photo proof submitted for verification.",
                media_url=issue.resolution_proof,
                created_at=issue.resolved_at or issue.created_at,
            )
        )

    # Event 5: Quorum Votes
    votes_stmt = (
        select(QuorumVote)
        .options(selectinload(QuorumVote.user))
        .where(QuorumVote.issue_id == issue_id)
        .order_by(QuorumVote.created_at.asc())
    )
    votes = list((await session.execute(votes_stmt)).scalars().all())
    confirmations_list: list[QuorumVoterOut] = []
    disputes_list: list[QuorumVoterOut] = []

    for v in votes:
        u_name = v.user.display_name if v.user else None
        u_handle = v.user.username if v.user else None
        voter_out = QuorumVoterOut(
            user_id=v.user_id,
            username=u_handle,
            display_name=u_name,
            vote=v.vote,
            reason=v.reason,
            is_nearby=True,
            created_at=v.created_at,
        )
        if v.vote == "confirm":
            confirmations_list.append(voter_out)
        else:
            disputes_list.append(voter_out)

    # Event 6: Final Resolved Win
    if issue.status == "resolved":
        events.append(
            IssueTimelineEventOut(
                event_type="resolved",
                title="Verified Civic Win",
                description=f"Resolution verified ({issue.resolution_type or 'community'}).",
                media_url=issue.resolution_proof,
                created_at=issue.resolved_at or issue.created_at,
            )
        )

    return IssueTimelineResponse(
        issue_id=issue.id,
        status=issue.status,
        resolution_type=issue.resolution_type,
        resolved_by=issue.resolved_by,
        events=events,
        confirmations=confirmations_list,
        disputes=disputes_list,
    )
