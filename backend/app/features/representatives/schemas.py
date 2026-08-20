from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.fields import UTCDateTime
from app.features.issues.schemas import IssueOut


class RepresentativeMetricsOut(BaseModel):
    """Flat, all-defaulted metrics block embeddable in any rep-facing schema."""

    total_ward_issues: int = 0
    escalated_ward_issues: int = 0
    responded_ward_issues: int = 0
    pending_response_ward_issues: int = 0
    resolved_ward_issues: int = 0
    in_progress_ward_issues: int = 0
    acknowledged_ward_issues: int = 0
    response_rate_pct: float = 0.0
    avg_response_time_hours: float = 0.0


class RepresentativeProfileOut(RepresentativeMetricsOut):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: int
    official_name: str
    title: str
    ward: str
    department: str | None = "all"
    is_unclaimed: bool = False
    handle: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None
    verified_at: UTCDateTime


class PublicRepresentativeProfileOut(RepresentativeMetricsOut):
    """Public rep performance profile; readable without authentication."""

    id: str
    user_id: int
    official_name: str
    title: str
    ward: str
    department: str | None = "all"
    is_unclaimed: bool = False
    handle: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None
    verified_at: UTCDateTime | None = None


class OfficialResponseCreate(BaseModel):
    message: str = Field(min_length=5, max_length=1000)
    estimated_resolution_days: int | None = Field(default=None, ge=1, le=365)
    status_update: str | None = Field(default=None)

    @field_validator("status_update")
    @classmethod
    def validate_status_update(cls, v: str | None) -> str | None:
        if v is not None and v not in {"acknowledged", "in_progress"}:
            raise ValueError("status_update must be 'acknowledged' or 'in_progress'")
        return v


class OfficialResponseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    issue_id: int
    representative_id: str
    official_name: str
    title: str
    ward: str
    message: str
    estimated_resolution_days: int | None = None
    status_update: str | None = None
    created_at: UTCDateTime


class WardIssuesResponse(BaseModel):
    items: list[IssueOut]
    total: int
