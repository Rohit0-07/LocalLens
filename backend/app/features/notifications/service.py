from typing import Any, cast

from app.core.exceptions import AppError
from app.features.notifications.models import Notification
from sqlalchemy import func, select, update
from sqlalchemy.engine import CursorResult
from sqlalchemy.ext.asyncio import AsyncSession


async def get_user_notifications(
    session: AsyncSession,
    user_id: int | str,
    limit: int = 20,
    offset: int = 0,
    unread_only: bool = False,
) -> tuple[list[Notification], int]:
    str_user_id = str(user_id)

    # Get total unread count for user regardless of limit/offset/filter
    unread_stmt = select(func.count(Notification.id)).where(
        Notification.user_id == str_user_id,
        Notification.is_read.is_(False),
    )
    unread_res = await session.execute(unread_stmt)
    unread_count = unread_res.scalar_one()

    # Query notifications list
    stmt = select(Notification).where(Notification.user_id == str_user_id)
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))

    stmt = stmt.order_by(Notification.created_at.desc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    items = list(result.scalars().all())

    return items, unread_count


async def mark_notification_as_read(
    session: AsyncSession,
    notification_id: str,
    user_id: int | str,
) -> Notification:
    str_user_id = str(user_id)
    notification = await session.get(Notification, notification_id)

    if notification is None or notification.user_id != str_user_id:
        raise AppError("Notification not found", status_code=404, code="not_found")

    if not notification.is_read:
        notification.is_read = True
        await session.commit()
        await session.refresh(notification)

    return notification


async def mark_all_notifications_as_read(
    session: AsyncSession,
    user_id: int | str,
) -> int:
    str_user_id = str(user_id)
    stmt = (
        update(Notification)
        .where(
            Notification.user_id == str_user_id,
            Notification.is_read.is_(False),
        )
        .values(is_read=True)
    )
    result = await session.execute(stmt)
    await session.commit()
    cursor_res = cast(CursorResult[Any], result)
    return cursor_res.rowcount or 0


async def create_notification(
    session: AsyncSession,
    user_id: int | str,
    title: str,
    body: str,
    type: str,
    reference_id: str | None = None,
) -> Notification:
    notification = Notification(
        user_id=str(user_id),
        title=title,
        body=body,
        type=type,
        reference_id=reference_id,
        is_read=False,
    )
    session.add(notification)
    await session.commit()
    await session.refresh(notification)
    return notification
