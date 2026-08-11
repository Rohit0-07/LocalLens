from typing import Any

from app.api.deps import CurrentUser, SessionDep
from app.features.notifications.schemas import NotificationListResponse, NotificationOut
from app.features.notifications.service import (
    get_user_notifications,
    mark_all_notifications_as_read,
    mark_notification_as_read,
)
from fastapi import APIRouter, HTTPException, Query, status

router = APIRouter()


@router.get("", response_model=NotificationListResponse)
@router.get("/", response_model=NotificationListResponse)
async def list_notifications(
    session: SessionDep,
    user: CurrentUser,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    unread_only: bool = Query(False),
) -> NotificationListResponse:
    if getattr(user, "is_guest", False):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    items, unread_count = await get_user_notifications(
        session=session,
        user_id=user.id,
        limit=limit,
        offset=offset,
        unread_only=unread_only,
    )
    return NotificationListResponse(
        items=[NotificationOut.model_validate(item) for item in items],
        unread_count=unread_count,
    )


@router.post("/read-all")
async def read_all_notifications(
    session: SessionDep,
    user: CurrentUser,
) -> dict[str, Any]:
    if getattr(user, "is_guest", False):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    updated_count = await mark_all_notifications_as_read(session=session, user_id=user.id)
    return {"status": "ok", "updated_count": updated_count}


@router.patch("/{notification_id}/read", response_model=NotificationOut)
async def read_single_notification(
    notification_id: str,
    session: SessionDep,
    user: CurrentUser,
) -> NotificationOut:
    if getattr(user, "is_guest", False):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    notification = await mark_notification_as_read(
        session=session,
        notification_id=notification_id,
        user_id=user.id,
    )
    return NotificationOut.model_validate(notification)
