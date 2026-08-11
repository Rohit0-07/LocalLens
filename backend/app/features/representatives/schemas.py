from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.features.issues.schemas import IssueOut


class RepresentativeProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: int
    official_name: str
    title: str
    ward: str
    verified_at: datetime
    total_ward_issues: int
    escalated_ward_issues: int
    responded_ward_issues: int
    pending_response_ward_issues: int


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
    created_at: datetime


class WardIssuesResponse(BaseModel):
    items: list[IssueOut]
    total: int
