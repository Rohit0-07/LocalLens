from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, OptionalUser, SessionDep, SettingsDep
from app.core.exceptions import AppError
from app.features.issues import service
from app.features.issues.models import Issue
from app.features.issues.schemas import (
    CommentCreate,
    CommentResponse,
    FlagCreate,
    FlaggedQueueResponse,
    FlaggedQueueStatusFilter,
    FlagOut,
    IssueCreate,
    IssueOut,
    ModerationActionRequest,
    ModerationResultOut,
    NearDuplicateOut,
    QuorumVoteRequest,
    ResolutionSubmit,
    UpvoteRequest,
    WinOut,
)

router = APIRouter()
wins_router = APIRouter(prefix="/wins", tags=["wins"])
admin_router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("", response_model=list[IssueOut])
async def list_nearby_issues(
    session: SessionDep,
    settings: SettingsDep,
    latitude: Annotated[float, Query()],
    longitude: Annotated[float, Query()],
    radius_km: Annotated[float, Query(ge=0.1, le=50)] = 5.0,
    status_filter: Annotated[str | None, Query(alias="status")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
    user: OptionalUser = None,
) -> list[IssueOut]:
    issues = await service.list_issues_near(
        session,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        status_filter=status_filter,
        limit=limit,
        offset=offset,
    )
    user_upvoted_ids = set()
    if user is not None and not getattr(user, "is_guest", False):
        user_upvoted_ids = await service.get_user_upvoted_issue_ids(
            session, user.id, [i.id for i in issues]
        )
    return [
        service.to_issue_out(
            issue,
            settings.jwt_secret,
            user_id=user.id if user else None,
            user_upvoted_ids=user_upvoted_ids,
        )
        for issue in issues
    ]


@router.get("/near-duplicate", response_model=list[NearDuplicateOut])
async def get_near_duplicates(
    session: SessionDep,
    latitude: Annotated[float, Query()],
    longitude: Annotated[float, Query()],
    radius_km: Annotated[float, Query(ge=0.01, le=10)] = 0.5,
    limit: Annotated[int, Query(ge=1, le=50)] = 10,
) -> list[NearDuplicateOut]:
    return await service.detect_near_duplicates(
        session,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        limit=limit,
    )


@router.post("/evaluate-escalations", status_code=status.HTTP_200_OK)
async def trigger_escalation_evaluation(session: SessionDep) -> dict[str, int]:
    updated_count = await service.evaluate_all_escalations(session)
    return {"updated": updated_count}


@router.get("/my", response_model=list[IssueOut])
async def get_my_issues_endpoint(
    user: CurrentUser,
    session: SessionDep,
    settings: SettingsDep,
    status_filter: Annotated[str | None, Query(alias="status")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[IssueOut]:
    if getattr(user, "is_guest", False):
        return []
    from app.features.auth import service as auth_service

    issues = await auth_service.get_user_issues(
        session,
        user_id=user.id,
        status_filter=status_filter,
        limit=limit,
        offset=offset,
    )
    user_upvoted_ids = await service.get_user_upvoted_issue_ids(
        session, user.id, [i.id for i in issues]
    )
    return [
        service.to_issue_out(
            issue,
            settings.jwt_secret,
            user_id=user.id,
            user_upvoted_ids=user_upvoted_ids,
        )
        for issue in issues
    ]


@router.post("", response_model=IssueOut, status_code=status.HTTP_201_CREATED)
async def create_issue(
    payload: IssueCreate, session: SessionDep, user: CurrentUser, settings: SettingsDep
) -> IssueOut:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to create issues", status_code=403, code="guest_restricted"
        )
    issue = await service.create_issue(session, payload, reporter_id=user.id)
    return service.to_issue_out(issue, settings.jwt_secret, user_id=user.id)


@router.get("/{issue_id}", response_model=IssueOut)
async def get_single_issue(
    issue_id: int,
    session: SessionDep,
    settings: SettingsDep,
    user: OptionalUser = None,
) -> IssueOut:
    issue = await service.get_issue(session, issue_id)
    if issue is None:
        raise HTTPException(status_code=404, detail="Issue not found")
    user_upvoted_ids = set()
    if user is not None and not getattr(user, "is_guest", False):
        user_upvoted_ids = await service.get_user_upvoted_issue_ids(session, user.id, [issue.id])
    return service.to_issue_out(
        issue,
        settings.jwt_secret,
        user_id=user.id if user else None,
        user_upvoted_ids=user_upvoted_ids,
    )


@router.delete("/{issue_id}", response_model=dict[str, bool])
async def delete_issue_endpoint(
    issue_id: int,
    session: SessionDep,
    user: CurrentUser,
) -> dict[str, bool]:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to delete issues", status_code=403, code="guest_restricted"
        )
    issue = await session.get(Issue, issue_id)
    if issue is None or getattr(issue, "is_hidden", False):
        raise HTTPException(status_code=404, detail="Issue not found")
    is_moderator = getattr(user, "is_admin", False) or getattr(
        user, "role", ""
    ) in ("admin", "moderator")
    if issue.reporter_id != user.id and not is_moderator:
        raise AppError(
            "Not authorized to delete this issue", status_code=403, code="forbidden"
        )
    await service.delete_issue(session, issue_id, issue.reporter_id or user.id)
    return {"success": True}


@router.post("/{issue_id}/acknowledge", response_model=IssueOut)
async def acknowledge_issue(
    issue_id: int, session: SessionDep, user: CurrentUser, settings: SettingsDep
) -> IssueOut:
    issue = await service.acknowledge_issue(session, issue_id)
    return service.to_issue_out(issue, settings.jwt_secret)


@router.post("/{issue_id}/resolve", response_model=IssueOut)
async def submit_resolution(
    issue_id: int,
    payload: ResolutionSubmit,
    session: SessionDep,
    user: CurrentUser,
    settings: SettingsDep,
) -> IssueOut:
    issue = await service.submit_resolution(
        session, issue_id, proof_url=payload.resolution_proof, notes=payload.notes
    )
    return service.to_issue_out(issue, settings.jwt_secret)


@router.post("/{issue_id}/quorum-vote", response_model=IssueOut)
async def vote_quorum(
    issue_id: int,
    payload: QuorumVoteRequest,
    session: SessionDep,
    user: CurrentUser,
    settings: SettingsDep,
) -> IssueOut:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to vote on quorum", status_code=403, code="guest_restricted"
        )
    issue = await service.vote_quorum(
        session,
        issue_id=issue_id,
        user_id=user.id,
        vote=payload.vote,
        latitude=payload.latitude,
        longitude=payload.longitude,
        reason=payload.reason,
    )
    return service.to_issue_out(issue, settings.jwt_secret)


@router.post("/{issue_id}/check-quorum-status", response_model=IssueOut)
async def check_quorum_status(
    issue_id: int, session: SessionDep, settings: SettingsDep
) -> IssueOut:
    issue = await service.check_quorum_expiration(session, issue_id)
    return service.to_issue_out(issue, settings.jwt_secret)


@router.post("/{issue_id}/upvote", response_model=IssueOut)
async def upvote_issue(
    issue_id: int,
    session: SessionDep,
    user: CurrentUser,
    settings: SettingsDep,
    payload: UpvoteRequest | None = None,
) -> IssueOut:
    if getattr(user, "is_guest", False):
        raise AppError("Sign in required to upvote", status_code=403, code="guest_restricted")
    lat = payload.latitude if payload else 0.0
    lon = payload.longitude if payload else 0.0
    issue = await service.upvote_issue(
        session,
        issue_id=issue_id,
        user_id=user.id,
        latitude=lat,
        longitude=lon,
    )
    return service.to_issue_out(
        issue,
        settings.jwt_secret,
        user_id=user.id,
        user_upvoted_ids={issue.id},
    )


@router.delete("/{issue_id}/upvote", response_model=IssueOut)
async def remove_upvote_issue(
    issue_id: int,
    session: SessionDep,
    user: CurrentUser,
    settings: SettingsDep,
) -> IssueOut:
    if getattr(user, "is_guest", False):
        raise AppError("Sign in required to remove upvote", status_code=403, code="guest_restricted")
    issue = await service.remove_upvote_issue(
        session,
        issue_id=issue_id,
        user_id=user.id,
    )
    return service.to_issue_out(
        issue,
        settings.jwt_secret,
        user_id=user.id,
        user_upvoted_ids=set(),
    )


@router.post(
    "/{issue_id}/comments",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def post_comment(
    issue_id: int,
    payload: CommentCreate,
    session: SessionDep,
    user: CurrentUser,
    settings: SettingsDep,
) -> CommentResponse:
    return await service.post_comment(
        session,
        issue_id=issue_id,
        user=user,
        payload=payload,
        secret=settings.jwt_secret,
    )


@router.get("/{issue_id}/comments", response_model=list[CommentResponse])
async def get_comments(
    issue_id: int,
    session: SessionDep,
    user: OptionalUser = None,
) -> list[CommentResponse]:
    user_id = user.id if (user and not getattr(user, "is_guest", False)) else None
    return await service.get_comments(session, issue_id=issue_id, user_id=user_id)


@router.delete("/{issue_id}/comments/{comment_id}", status_code=status.HTTP_200_OK)
@router.post("/{issue_id}/comments/{comment_id}/delete", status_code=status.HTTP_200_OK)
async def delete_comment(
    issue_id: int,
    comment_id: str,
    session: SessionDep,
    user: CurrentUser,
) -> dict[str, bool]:
    await service.delete_comment(session, issue_id=issue_id, comment_id=comment_id, user=user)
    return {"success": True}


@router.post("/{issue_id}/flag", response_model=FlagOut, status_code=status.HTTP_201_CREATED)
async def flag_issue_endpoint(
    issue_id: int,
    flag_in: FlagCreate,
    db: SessionDep,
    current_user: CurrentUser,
    settings: SettingsDep,
) -> FlagOut:
    return await service.create_flag(
        db=db,
        issue_id=issue_id,
        flag_in=flag_in,
        current_user=current_user,
        secret=settings.jwt_secret,
    )


@admin_router.get("/flagged-issues", response_model=FlaggedQueueResponse)
async def get_flagged_issues_endpoint(
    db: SessionDep,
    current_user: CurrentUser,
    status: FlaggedQueueStatusFilter = FlaggedQueueStatusFilter.PENDING,
    category: str | None = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status_filter: str | None = None,
) -> FlaggedQueueResponse:
    if not (
        getattr(current_user, "is_admin", False)
        or getattr(current_user, "role", "") in ("admin", "moderator")
    ):
        raise AppError(
            status_code=403,
            error_code="admin_required",
            detail="Administrative privileges required.",
        )
    effective_status = status_filter or status.value
    return await service.get_flagged_queue(
        db=db, status=effective_status, category=category, limit=limit, offset=offset
    )


@admin_router.post("/issues/{issue_id}/moderate", response_model=ModerationResultOut)
async def moderate_issue_endpoint(
    issue_id: int,
    action_in: ModerationActionRequest,
    db: SessionDep,
    current_user: CurrentUser,
) -> ModerationResultOut:
    if not (
        getattr(current_user, "is_admin", False)
        or getattr(current_user, "role", "") in ("admin", "moderator")
    ):
        raise AppError(
            status_code=403,
            error_code="admin_required",
            detail="Administrative privileges required.",
        )
    return await service.moderate_issue(
        db=db, issue_id=issue_id, action_in=action_in, admin_user=current_user
    )


@wins_router.get("", response_model=list[WinOut])
async def list_nearby_wins(
    session: SessionDep,
    latitude: Annotated[float, Query()],
    longitude: Annotated[float, Query()],
    radius_km: Annotated[float, Query(ge=0.1, le=50)] = 5.0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[WinOut]:
    wins = await service.list_wins_near(
        session,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        limit=limit,
        offset=offset,
    )
    return [service.to_win_out(w) for w in wins]


@wins_router.get("/{win_id}", response_model=WinOut)
async def get_single_win(
    win_id: int,
    session: SessionDep,
) -> WinOut:
    win = await service.get_win_by_id(session, win_id)
    if win is None:
        raise HTTPException(status_code=404, detail="Win not found")
    return service.to_win_out(win)
