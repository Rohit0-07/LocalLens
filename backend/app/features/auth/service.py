from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.exceptions import AppError
from app.core.logging import get_logger
from app.core.security import generate_otp, hash_secret, verify_secret
from app.features.auth.models import OtpCode, User
from app.features.issues.models import Issue, QuorumVote, Upvote

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
