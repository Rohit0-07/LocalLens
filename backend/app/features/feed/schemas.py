from typing import Any, Literal

from pydantic import BaseModel

from app.core.fields import UTCDateTime


class FeedItemOut(BaseModel):
    item_type: Literal["issue", "win", "notice", "local_talk"]
    id: str | int
    created_at: UTCDateTime
    data: dict[str, Any]


class FeedResponse(BaseModel):
    items: list[dict[str, Any]]
    next_cursor: str | None = None
    has_more: bool = False
