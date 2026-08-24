from datetime import UTC, datetime
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.features.issues import service as issues_service
from app.features.wards import service as wards_service


def _parse_cursor(cursor: str | None) -> tuple[datetime, int] | None:
    """Parses a cursor into (naive-UTC datetime, tiebreaker id).

    Accepts either a bare ISO-8601 datetime or an extended
    ``<iso>|<last_item_id>`` form; the id lets items sharing the cursor
    timestamp paginate without being skipped or duplicated. Returns None for
    empty/unparseable cursors.
    """
    if not cursor:
        return None
    value, _, raw_id = cursor.partition("|")
    if value.endswith("Z"):
        value = f"{value[:-1]}+00:00"
    try:
        parsed = datetime.fromisoformat(value)
    except ValueError:
        return None
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(UTC).replace(tzinfo=None)
    try:
        last_id = int(raw_id)
    except ValueError:
        last_id = -1
    return parsed, last_id


#: Half the Earth's circumference plus a margin: a radius that no point on
#: Earth exceeds, so geo-scoping with it matches every issue/win/notice/post.
_GLOBAL_RADIUS_KM = 20100.0


async def get_multi_type_feed(
    session: AsyncSession,
    *,
    latitude: float | None = None,
    longitude: float | None = None,
    radius_km: float = 5.0,
    feed_type: str = "all",
    cursor: str | None = None,
    limit: int = 20,
    anon_hmac_secret: str = "secret",
    user_id: int | None = None,
) -> list[dict[str, Any]]:
    # No coordinates means "all wards": scope the query to the whole planet
    # instead of filtering by distance.
    if latitude is None or longitude is None:
        latitude, longitude = 0.0, 0.0
        radius_km = _GLOBAL_RADIUS_KM

    parsed_cursor = _parse_cursor(cursor)
    # Fetch a superset per type so cursor pages advance past earlier per-type
    # windows instead of silently dropping items on later pages.
    per_type_limit = max(limit * 5, 40)

    items: list[dict[str, Any]] = []

    # 1. Fetch Issues if type in ("all", "issue")
    if feed_type in ("all", "issue"):
        issues = await issues_service.list_issues_near(
            session,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            status_filter=None,
            limit=per_type_limit,
            offset=0,
            created_before=parsed_cursor[0] if parsed_cursor else None,
        )
        user_upvoted_ids = set()
        if user_id is not None and issues:
            user_upvoted_ids = await issues_service.get_user_upvoted_issue_ids(
                session, user_id, [i.id for i in issues]
            )
        for issue in issues:
            issue_out: Any = issues_service.to_issue_out(
                issue,
                anon_hmac_secret,
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
            limit=per_type_limit,
            offset=0,
            created_before=parsed_cursor[0] if parsed_cursor else None,
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
            limit=per_type_limit,
            offset=0,
            created_before=parsed_cursor[0] if parsed_cursor else None,
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
            limit=per_type_limit,
            offset=0,
            created_before=parsed_cursor[0] if parsed_cursor else None,
        )
        for post in talk_posts:
            post_out: Any = wards_service.to_local_talk_post_out(post)
            item_dict = post_out.model_dump(mode="json")
            item_dict["item_type"] = "local_talk"
            items.append(item_dict)

    # Sort items by created_at descending
    _SORT_MIN = datetime.min

    def get_sort_key(item: dict[str, Any]) -> datetime:
        val = item.get("created_at")
        if not isinstance(val, str):
            return _SORT_MIN
        try:
            parsed = datetime.fromisoformat(val.replace("Z", "+00:00"))
        except ValueError:
            return _SORT_MIN
        if parsed.tzinfo is not None:
            parsed = parsed.astimezone(UTC).replace(tzinfo=None)
        return parsed

    items.sort(key=get_sort_key, reverse=True)

    # Apply cursor pagination as a safety net (per-type queries already
    # advanced past the cursor). Compare (created_at, id) tuples so items
    # sharing the cursor timestamp are neither skipped nor re-served; a bare
    # ISO cursor (no "|id") keeps strict less-than for compatibility.
    if parsed_cursor is not None:
        cursor_dt, cursor_id = parsed_cursor

        def before_cursor(item: dict[str, Any]) -> bool:
            key = get_sort_key(item)
            if key != cursor_dt:
                return key < cursor_dt
            item_id = item.get("id")
            return isinstance(item_id, int) and item_id < cursor_id

        items = [i for i in items if before_cursor(i)]

    return items[:limit]