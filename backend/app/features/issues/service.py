import json
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
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
)
from app.features.issues.schemas import (
    CommentCreate,
    CommentResponse,
    FlagCategory,
    FlagCreate,
    FlaggedIssueItem,
    FlaggedQueueResponse,
    FlagOut,
    IssueCreate,
    IssueOut,
    ModerationAction,
    ModerationActionRequest,
    ModerationResultOut,
    NearDuplicateOut,
    WinOut,
)

flag_rate_limiter = SlidingWindowRateLimiter(max_requests=5, window_seconds=600)


def _utc_now() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


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
    )


async def create_issue(
    session: AsyncSession, payload: IssueCreate, reporter_id: int | None = None
) -> Issue:
    effective_reporter_id = payload.reporter_id if payload.reporter_id is not None else reporter_id
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

    issue = Issue(
        title=payload.title,
        description=payload.description,
        category=payload.category,
        latitude=lat,
        longitude=lng,
        geohash=gh,
        ward="Ward 45, Urban Central",
        is_anonymous=payload.is_anonymous,
        fuzz_location=is_fuzzed,
        is_fuzzed=is_fuzzed,
        is_shielded=payload.is_shielded,
        reporter_id=effective_reporter_id,
        media_url=first_media,
        video_url=payload.video_url,
        media_urls=json.dumps(media_urls_list) if media_urls_list else None,
        status="unacknowledged",
    )
    session.add(issue)
    await session.commit()
    issue = await session.scalar(
        select(Issue).options(selectinload(Issue.reporter)).where(Issue.id == issue.id)
    )
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
) -> list[Issue]:
    statement = await bbox_statement(latitude, longitude, radius_km)
    if status_filter:
        statement = statement.where(Issue.status == status_filter)
    statement = statement.order_by(Issue.created_at.desc()).limit(limit).offset(offset)
    result = await session.execute(statement)
    issues = list(result.scalars().all())

    # Evaluate escalation on fetched issues
    now = _utc_now()
    modified = False
    filtered_issues: list[Issue] = []

    for issue in issues:
        if evaluate_escalation(issue, now):
            modified = True
        # Filter out shielded issues unless resolved
        if issue.is_shielded and issue.status != "resolved":
            continue
        if haversine_km(latitude, longitude, issue.latitude, issue.longitude) <= radius_km:
            filtered_issues.append(issue)

    if modified:
        await session.commit()

    return filtered_issues


async def get_issue(session: AsyncSession, issue_id: int) -> Issue | None:
    result = await session.execute(
        select(Issue).options(selectinload(Issue.reporter)).where(Issue.id == issue_id)
    )
    issue = result.scalar_one_or_none()
    if issue is not None:
        if evaluate_escalation(issue, _utc_now()):
            await session.commit()
            await session.refresh(issue)
    return issue


async def detect_near_duplicates(
    session: AsyncSession,
    *,
    latitude: float,
    longitude: float,
    radius_km: float = 0.5,
    limit: int = 10,
) -> list[NearDuplicateOut]:
    statement = await bbox_statement(latitude, longitude, radius_km)
    statement = statement.order_by(Issue.created_at.desc()).limit(limit * 2)
    result = await session.execute(statement)
    candidates = list(result.scalars().all())

    duplicates: list[NearDuplicateOut] = []
    for issue in candidates:
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
    await session.refresh(issue)
    return issue


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
    await session.refresh(issue)
    return issue


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
        issue.confirmations_count += 1
        if issue.confirmations_count >= 3:
            issue.status = "resolved"
            issue.resolved_at = _utc_now()
            await create_win_for_issue(session, issue)
    elif vote == "dispute":
        issue.disputes_count += 1
        if issue.disputes_count >= 1:
            issue.status = "disputed"

    await session.commit()
    await session.refresh(issue)
    return issue


cast_quorum_vote = vote_quorum


async def check_quorum_expiration(session: AsyncSession, issue_id: int) -> Issue:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    if issue.status == "pending_quorum" and issue.quorum_expires_at:
        if _utc_now() > issue.quorum_expires_at and issue.confirmations_count < 3:
            issue.status = "disputed"
            await session.commit()
            await session.refresh(issue)
        elif issue.confirmations_count >= 3 and issue.status != "resolved":
            issue.status = "resolved"
            issue.resolved_at = _utc_now()
            await create_win_for_issue(session, issue)
            await session.commit()
            await session.refresh(issue)
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
    try:
        from app.features.media.models import Media

        media_stmt = (
            select(Media)
            .where(Media.user_id == str(issue.reporter_id))
            .order_by(Media.created_at.asc())
        )
        media_res = await session.execute(media_stmt)
        first_media = media_res.scalars().first()
        if first_media:
            before_url = first_media.url
    except Exception:
        pass

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
) -> list[Win]:
    statement = select(Win).order_by(Win.created_at.desc()).limit(limit * 2)
    result = await session.execute(statement)
    wins = list(result.scalars().all())

    filtered_wins: list[Win] = []
    for w in wins:
        if haversine_km(latitude, longitude, w.latitude, w.longitude) <= radius_km:
            filtered_wins.append(w)
            if len(filtered_wins) >= limit:
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
    now = _utc_now()
    result = await session.execute(
        select(Issue).where(
            Issue.status.in_(
                ["unacknowledged", "open", "under_review", "acknowledged", "escalating"]
            )
        )
    )
    issues = list(result.scalars().all())
    count = 0
    for issue in issues:
        if evaluate_escalation(issue, now):
            count += 1
    if count > 0:
        await session.commit()
    return count


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
    issue.upvotes_count += 1
    await session.commit()
    await session.refresh(issue)
    return issue


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
    await session.refresh(issue)
    return issue


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
) -> list[CommentResponse]:
    issue = await session.get(Issue, issue_id)
    if issue is None:
        raise AppError("Issue not found", status_code=404, code="not_found")

    stmt = select(Comment).where(Comment.issue_id == issue_id).order_by(Comment.created_at.asc())
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

    ids_to_delete = {comment_id}
    changed = True
    while changed:
        changed = False
        for c in all_comments:
            if c.parent_id in ids_to_delete and c.id not in ids_to_delete:
                ids_to_delete.add(c.id)
                changed = True

    deleted_count = len(ids_to_delete)
    for c in all_comments:
        if c.id in ids_to_delete:
            await session.delete(c)

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

    items: list[FlaggedIssueItem] = []
    for issue in issues:
        flags_stmt = select(Flag).where(Flag.issue_id == issue.id).order_by(Flag.created_at.desc())
        flags_res = await db.execute(flags_stmt)
        flags = list(flags_res.scalars().all())

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
        reporter = await db.get(User, issue.reporter_id)
        if reporter:
            reporter.is_banned = True
            reporter_banned = True
        msg = "Issue hidden and reporter banned."
    else:
        raise AppError(
            status_code=400, error_code="invalid_action", detail="Invalid moderation action."
        )

    moderated_by_id = admin_user.id if isinstance(admin_user.id, int) else 1
    audit = ModerationAudit(
        issue_id=issue_id,
        action=action_val,
        reason=action_in.reason,
        moderated_by=moderated_by_id,
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
