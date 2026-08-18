from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MediaUploadRequest(BaseModel):
    base64_payload: str | None = None
    is_in_app_camera: bool = False
    captured_lat: float | None = None
    captured_lng: float | None = None
    is_fuzzed: bool = False
    captured_at: datetime | None = None


class MediaUploadOut(BaseModel):
    id: str
    url: str
    thumbnail_url: str
    is_verified: bool
    watermark_label: str
    derived_hash: str
    latitude: float | None = None
    longitude: float | None = None
    is_fuzzed: bool = False
    issue_id: int | None = None
    deleted_at: datetime | None = None
    captured_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MediaDeleteOut(BaseModel):
    success: bool