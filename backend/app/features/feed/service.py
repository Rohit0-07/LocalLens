from datetime import datetime
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.features.issues import service as issues_service
from app.features.wards import service as wards_service


async def get_multi_type_feed(
    session: AsyncSession,
    *,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    feed_type: str = "all",
    cursor: str | None = None,
    limit: int = 20,
    jwt_secret: str = "secret",
    user_id: int | None = None,
) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []

    # 1. Fetch Issues if type in ("all", "issue")
    if feed_type in ("all", "issue"):
        issues = await issues_service.list_issues_near(
            session,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            status_filter=None,
            limit=limit,
            offset=0,
        )
        user_upvoted_ids = set()
        if user_id is not None:
            user_upvoted_ids = await issues_service.get_user_upvoted_issue_ids(
                session, user_id, [i.id for i in issues]
            )
        for issue in issues:
            issue_out: Any = issues_service.to_issue_out(
                issue,
                jwt_secret,
                user_id=user_id,
                user_upvoted_ids=user_upvoted_ids,
            )
            item_dict = issue_out.model_dump(mode="json")
            item_dict["item_type"] = "issue"
            items.append(item_dict)

    # 2. Fetch Wins if type in ("all", "win")
    if feed_type in ("all", "win"):
        wins = await issues_service.list_wins_near(
            session,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            limit=limit,
            offset=0,
        )
        for win in wins:
            win_out: Any = issues_service.to_win_out(win)
            item_dict = win_out.model_dump(mode="json")
            item_dict["item_type"] = "win"
            items.append(item_dict)

    # 3. Fetch Notices if type in ("all", "notice")
    if feed_type in ("all", "notice"):
        notices = await wards_service.list_notices_near(
            session,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            limit=limit,
            offset=0,
        )
        for notice in notices:
            notice_out: Any = wards_service.to_notice_out(notice)
            item_dict = notice_out.model_dump(mode="json")
            item_dict["item_type"] = "notice"
            items.append(item_dict)

    # 4. Fetch Local Talk posts if type in ("all", "local_talk")
    if feed_type in ("all", "local_talk"):
        talk_posts = await wards_service.list_all_talk_posts_near(
            session,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            limit=limit,
            offset=0,
        )
        for post in talk_posts:
            post_out: Any = wards_service.to_local_talk_post_out(post)
            item_dict = post_out.model_dump(mode="json")
            item_dict["item_type"] = "local_talk"
            items.append(item_dict)

    # Sort items by created_at descending
    def get_sort_key(item: dict[str, Any]) -> str:
        val = item.get("created_at")
        if isinstance(val, datetime):
            return val.isoformat()
        return str(val or "")

    items.sort(key=get_sort_key, reverse=True)

    # Apply cursor pagination if cursor is provided
    if cursor:
        items = [i for i in items if get_sort_key(i) < cursor]

    return items[:limit]
