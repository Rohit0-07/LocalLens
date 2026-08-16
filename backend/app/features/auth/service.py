from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.exceptions import AppError
from app.core.logging import get_logger
from app.core.security import derive_anonymous_identity, generate_otp, hash_secret, verify_secret
from app.features.auth.models import OtpCode, User
from app.features.auth.schemas import PublicUserProfileOut
from app.features.gamification.service import (
    calculate_impact_score,
    evaluate_and_unlock_badges,
    fetch_activity_counts,
    get_level_info,
    get_or_create_user_gamification,
)
from app.features.issues.models import Issue, QuorumVote, Upvote
from app.features.issues.service import evaluate_escalation, to_issue_out

logger = get_logger("locallens.auth")


def _utc_now() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


async def get_user_stats(session: AsyncSession, user_id: int) -> dict[str, int]:
    issues_res = await session.execute(
        select(func.count(Issue.id)).where(Issue.reporter_id == user_id)
    )
    upvotes_res = await session.execute(
        select(func.count(Upvote.id)).where(Upvote.user_id == user_id)
    )
    quorum_res = await session.execute(
        select(func.count(QuorumVote.id)).where(QuorumVote.user_id == user_id)
    )
    return {
        "issues_count": issues_res.scalar() or 0,
        "upvotes_count": upvotes_res.scalar() or 0,
        "quorum_votes_count": quorum_res.scalar() or 0,
    }


async def request_otp(session: AsyncSession, settings: Settings, phone: str) -> None:
    code = settings.otp_master_code or generate_otp()
    await session.execute(delete(OtpCode).where(OtpCode.phone == phone))
    session.add(
        OtpCode(
            phone=phone,
            code_hash=hash_secret(code),
            expires_at=_utc_now() + timedelta(minutes=settings.otp_ttl_minutes),
        )
    )
    await session.commit()
    if settings.environment != "production":
        logger.info("otp for %s is %s", phone, code)


async def verify_otp(session: AsyncSession, settings: Settings, phone: str, code: str) -> User:
    otp_result = await session.execute(
        select(OtpCode).where(OtpCode.phone == phone).order_by(OtpCode.created_at.desc()).limit(1)
    )
    otp = otp_result.scalar_one_or_none()
    if otp is None or otp.expires_at < _utc_now():
        raise AppError("OTP is invalid or expired", code="otp_invalid")
    if not verify_secret(code, otp.code_hash):
        raise AppError("OTP is invalid or expired", code="otp_invalid")
    await session.execute(delete(OtpCode).where(OtpCode.id == otp.id))

    user_result = await session.execute(select(User).where(User.phone == phone))
    user = user_result.scalar_one_or_none()
    if user is None:
        user = User(phone=phone)
        session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def request_email_otp(session: AsyncSession, settings: Settings, email: str) -> None:
    code = settings.otp_master_code or generate_otp()
    await session.execute(delete(OtpCode).where(OtpCode.email == email))
    session.add(
        OtpCode(
            email=email,
            code_hash=hash_secret(code),
            expires_at=_utc_now() + timedelta(minutes=settings.otp_ttl_minutes),
        )
    )
    await session.commit()
    if settings.environment != "production":
        logger.info("otp for %s is %s", email, code)


async def verify_email_otp(
    session: AsyncSession, settings: Settings, email: str, code: str
) -> User:
    otp_result = await session.execute(
        select(OtpCode).where(OtpCode.email == email).order_by(OtpCode.created_at.desc()).limit(1)
    )
    otp = otp_result.scalar_one_or_none()
    if otp is None or otp.expires_at < _utc_now():
        raise AppError("OTP is invalid or expired", code="otp_invalid")
    if not verify_secret(code, otp.code_hash):
        raise AppError("OTP is invalid or expired", code="otp_invalid")
    await session.execute(delete(OtpCode).where(OtpCode.id == otp.id))

    user_result = await session.execute(select(User).where(User.email == email))
    user = user_result.scalar_one_or_none()
    if user is None:
        user = User(email=email)
        session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def get_user_issues(
    session: AsyncSession,
    user_id: int,
    status_filter: str | None = None,
    limit: int = 50,
    offset: int = 0,
) -> list[Issue]:
    stmt = select(Issue).where(Issue.reporter_id == user_id)
    if status_filter:
        stmt = stmt.where(Issue.status == status_filter)
    stmt = stmt.order_by(Issue.created_at.desc(), Issue.id.desc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    issues = list(result.scalars().all())

    now = _utc_now()
    modified = False
    for issue in issues:
        if evaluate_escalation(issue, now):
            modified = True
    if modified:
        await session.commit()

    return issues


async def get_public_user_profile(
    session: AsyncSession,
    user_id: int,
    secret: str | None = None,
) -> PublicUserProfileOut:
    user = await session.get(User, user_id)
    if user is None or user.is_banned:
        raise AppError("User not found", status_code=404, code="not_found")

    issues_res = await session.execute(
        select(func.count(Issue.id)).where(Issue.reporter_id == user_id, Issue.is_hidden.is_(False))
    )
    resolutions_res = await session.execute(
        select(func.count(Issue.id)).where(
            Issue.reporter_id == user_id, Issue.status == "resolved", Issue.is_hidden.is_(False)
        )
    )
    upvotes_res = await session.execute(
        select(func.count(Upvote.id)).where(Upvote.user_id == user_id)
    )
    quorum_res = await session.execute(
        select(func.count(QuorumVote.id)).where(QuorumVote.user_id == user_id)
    )
    issues_count = issues_res.scalar() or 0
    resolutions_count = resolutions_res.scalar() or 0
    upvotes_count = upvotes_res.scalar() or 0
    quorum_votes_count = quorum_res.scalar() or 0

    counts = await fetch_activity_counts(session, user_id)
    gamif = await get_or_create_user_gamification(session, user_id)
    streak_days = gamif.streak_days if gamif else 0
    impact_score = calculate_impact_score(counts, streak_days)
    level, _level_name, _ = get_level_info(impact_score)
    badges = await evaluate_and_unlock_badges(session, user_id, counts, streak_days)

    public_issues_stmt = (
        select(Issue)
        .where(
            Issue.reporter_id == user_id,
            Issue.is_anonymous.is_(False),
            Issue.is_hidden.is_(False),
        )
        .order_by(Issue.created_at.desc(), Issue.id.desc())
    )
    public_issues_res = await session.execute(public_issues_stmt)
    public_issues = list(public_issues_res.scalars().all())

    public_issues_out = [
        to_issue_out(issue, secret=secret, user_id=None) for issue in public_issues
    ]

    anon_id = derive_anonymous_identity(user.id, secret) if secret else f"anon_{user.id}"
    ward = getattr(user, "ward", None) or "Ward 45, Urban Central"
    is_verified = getattr(user, "is_verified", True)

    return PublicUserProfileOut(
        id=user.id,
        anon_id=anon_id,
        role=user.role,
        is_verified=is_verified,
        ward=ward,
        created_at=user.created_at,
        issues_count=issues_count,
        resolutions_count=resolutions_count,
        upvotes_count=upvotes_count,
        quorum_votes_count=quorum_votes_count,
        level=level,
        impact_score=impact_score,
        badges=badges,
        public_issues=public_issues_out,
    )
