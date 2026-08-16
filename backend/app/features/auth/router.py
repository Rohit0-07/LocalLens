import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated

import jwt
from fastapi import APIRouter, Query, Response, status

from app.api.deps import CurrentUser, SessionDep, SettingsDep
from app.core.security import create_access_token, derive_anonymous_identity
from app.features.auth import service
from app.features.auth.schemas import (
    EmailOtpRequest,
    EmailOtpVerify,
    OtpRequest,
    OtpVerify,
    PublicUserProfileOut,
    TokenResponse,
    UserOut,
)
from app.features.issues import service as issues_service
from app.features.issues.schemas import IssueOut

router = APIRouter()


@router.post("/otp/request", status_code=status.HTTP_204_NO_CONTENT)
async def request_otp(payload: OtpRequest, session: SessionDep, settings: SettingsDep) -> Response:
    await service.request_otp(session, settings, payload.phone)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/email/request-otp", status_code=status.HTTP_204_NO_CONTENT)
async def request_email_otp(
    payload: EmailOtpRequest, session: SessionDep, settings: SettingsDep
) -> Response:
    await service.request_email_otp(session, settings, payload.email)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/otp/verify", response_model=TokenResponse)
@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(
    payload: OtpVerify, session: SessionDep, settings: SettingsDep
) -> TokenResponse:
    user = await service.verify_otp(session, settings, payload.phone, payload.code)
    token = create_access_token(str(user.id), settings)
    anon = derive_anonymous_identity(user.id, settings.jwt_secret)
    return TokenResponse(
        access_token=token, user_id=user.id, anonymous_identity=anon, anon_id=anon, is_guest=False
    )


@router.post("/email/verify-otp", response_model=TokenResponse)
async def verify_email_otp(
    payload: EmailOtpVerify, session: SessionDep, settings: SettingsDep
) -> TokenResponse:
    user = await service.verify_email_otp(session, settings, payload.email, payload.code)
    token = create_access_token(str(user.id), settings)
    anon = derive_anonymous_identity(user.id, settings.jwt_secret)
    return TokenResponse(
        access_token=token, user_id=user.id, anonymous_identity=anon, anon_id=anon, is_guest=False
    )


@router.post("/guest", response_model=TokenResponse)
async def login_as_guest(settings: SettingsDep) -> TokenResponse:
    guest_uuid = str(uuid.uuid4())
    guest_id = f"guest:{guest_uuid}"
    now = datetime.now(UTC)
    payload = {
        "sub": guest_id,
        "is_guest": True,
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_ttl_minutes),
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return TokenResponse(
        access_token=token,
        user_id=guest_id,
        anonymous_identity="guest_anon",
        anon_id="guest_anon",
        is_guest=True,
    )


@router.get("/me", response_model=UserOut)
async def get_current_user_profile(
    user: CurrentUser, session: SessionDep, settings: SettingsDep
) -> UserOut:
    if getattr(user, "is_guest", False):
        return UserOut(
            id=str(user.id),
            phone=None,
            email=None,
            anonymous_identity="guest_anon",
            anon_id="guest_anon",
            role="guest",
            is_verified=False,
            ward=None,
            is_guest=True,
            issues_count=0,
            upvotes_count=0,
            quorum_votes_count=0,
        )
    stats = await service.get_user_stats(session, user.id)
    anon = derive_anonymous_identity(user.id, settings.jwt_secret)
    return UserOut(
        id=user.id,
        phone=user.phone,
        email=user.email,
        anonymous_identity=anon,
        anon_id=anon,
        role=user.role,
        is_verified=user.is_verified,
        ward=user.ward,
        created_at=user.created_at,
        is_guest=False,
        issues_count=stats["issues_count"],
        upvotes_count=stats["upvotes_count"],
        quorum_votes_count=stats["quorum_votes_count"],
    )


@router.get("/me/issues", response_model=list[IssueOut])
async def get_my_issues(
    user: CurrentUser,
    session: SessionDep,
    settings: SettingsDep,
    status_filter: Annotated[str | None, Query(alias="status")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[IssueOut]:
    if getattr(user, "is_guest", False):
        return []
    issues = await service.get_user_issues(
        session,
        user_id=user.id,
        status_filter=status_filter,
        limit=limit,
        offset=offset,
    )
    user_upvoted_ids = await issues_service.get_user_upvoted_issue_ids(
        session, user.id, [i.id for i in issues]
    )
    return [
        issues_service.to_issue_out(
            issue,
            settings.jwt_secret,
            user_id=user.id,
            user_upvoted_ids=user_upvoted_ids,
        )
        for issue in issues
    ]


@router.get("/users/{user_id}", response_model=PublicUserProfileOut)
async def get_public_user_profile(
    user_id: int,
    session: SessionDep,
    settings: SettingsDep,
) -> PublicUserProfileOut:
    return await service.get_public_user_profile(
        session,
        user_id=user_id,
        secret=settings.jwt_secret,
    )
