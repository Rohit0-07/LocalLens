import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.fields import UTCDateTime
from app.features.issues.schemas import IssueOut
from app.features.representatives.schemas import RepresentativeMetricsOut


class AssignedRepresentativeOut(RepresentativeMetricsOut):
    model_config = ConfigDict(from_attributes=True)

    id: str = Field(default="", description="Representative profile ID")
    user_id: int = Field(default=0, description="User account ID of the representative")
    ward: str = Field(default="", description="Assigned ward of the representative")
    official_name: str = Field(..., description="Official name of the representative")
    title: str = Field(..., description="Designated title, e.g. Ward Representative")
    verified_at: UTCDateTime | None = Field(None, description="Verification timestamp")


class WardSummaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    slug: str = Field(..., description="Canonical URL slug for the ward")
    name: str = Field(..., description="Official display name of the ward")
    code: str = Field(..., description="Short code identifier, e.g. W-45")
    center_latitude: float = Field(..., description="Geographic center latitude")
    center_longitude: float = Field(..., description="Geographic center longitude")
    total_issues: int = Field(..., ge=0, description="Total reported civic issues count")
    active_issues: int = Field(..., ge=0, description="Active/open civic issues count")
    escalated_issues: int = Field(..., ge=0, description="Escalated civic issues count")
    resolved_issues: int = Field(..., ge=0, description="Resolved civic issues count")
    resolution_rate_pct: float = Field(
        ..., ge=0.0, le=100.0, description="Resolution percentage rounded to 2 decimals"
    )


class WardDetailOut(WardSummaryOut):
    top_categories: list[str] = Field(
        default_factory=list, description="Top categories by issue frequency"
    )
    assigned_representative: AssignedRepresentativeOut | None = Field(
        None, description="Assigned ward representative details"
    )
    recent_issues: list[IssueOut] = Field(
        default_factory=list, description="Recent public non-shielded issues"
    )
    updated_at: UTCDateTime = Field(..., description="Last updated timestamp")


class WardListResponse(BaseModel):
    items: list[WardSummaryOut] = Field(
        default_factory=list, description="Array of ward summary items"
    )
    total: int = Field(..., ge=0, description="Total count of active wards")
    limit: int = Field(..., ge=1, le=100, description="Pagination limit")
    offset: int = Field(..., ge=0, description="Pagination offset")


class LocalTalkPostCreate(BaseModel):
    title: str = Field(min_length=3, max_length=255)
    body: str = Field(min_length=5, max_length=2000)
    topic: str = Field(default="General", max_length=64)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class LocalTalkPostOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    ward_slug: str
    author_name: str
    title: str
    body: str
    topic: str
    replies_count: int
    latitude: float | None = None
    longitude: float | None = None
    created_at: UTCDateTime


class NoticeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    official_header: str
    valid_until: UTCDateTime | None = None
    ward: str
    latitude: float
    longitude: float
    geohash: str | None = None
    created_at: UTCDateTime
