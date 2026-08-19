from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.core.fields import UTCDateTime


class NotificationOut(BaseModel):
    id: str
    user_id: str
    title: str
    body: str
    type: str
    reference_id: str | None = None
    is_read: bool
    created_at: UTCDateTime

    model_config = ConfigDict(from_attributes=True)


class NotificationListResponse(BaseModel):
    items: list[NotificationOut]
    unread_count: int


class NotificationCreate(BaseModel):
    user_id: str
    title: str
    body: str
    type: str
    reference_id: str | None = None
