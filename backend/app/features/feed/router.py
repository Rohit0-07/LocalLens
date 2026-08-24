from typing import Annotated, Any

from fastapi import APIRouter, Query

from app.api.deps import OptionalUser, SessionDep, SettingsDep
from app.features.feed.service import get_multi_type_feed

router = APIRouter(tags=["feed"])


@router.get("", response_model=list[dict[str, Any]])
async def get_feed_endpoint(
    session: SessionDep,
    settings: SettingsDep,
    latitude: Annotated[float | None, Query()] = None,
    longitude: Annotated[float | None, Query()] = None,
    radius_km: Annotated[float, Query(ge=0.1, le=50)] = 5.0,
    type: Annotated[str, Query(alias="type")] = "all",
    cursor: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    user: OptionalUser = None,
) -> list[dict[str, Any]]:
    user_id = user.id if (user and not getattr(user, "is_guest", False)) else None
    return await get_multi_type_feed(
        session,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        feed_type=type,
        cursor=cursor,
        limit=limit,
        anon_hmac_secret=settings.anon_hmac_secret,
        user_id=user_id,
    )
