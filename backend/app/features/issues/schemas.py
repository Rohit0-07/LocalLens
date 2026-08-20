from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.fields import UTCDateTime


class FlagCategory(StrEnum):
    SPAM = "spam"
    ABUSE = "abuse"
    PII = "pii"
    FAKE_REPORT = "fake_report"
    OTHER = "other"


class ModerationAction(StrEnum):
    DISMISS = "dismiss"
    HIDE_ISSUE = "hide_issue"
    BAN_REPORTER = "ban_reporter"


class FlaggedQueueStatusFilter(StrEnum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    DISMISSED = "dismissed"
    HIDDEN = "hidden"
    ALL = "all"


class FlagCreate(BaseModel):
    category: FlagCategory
    details: str | None = Field(None, max_length=500)


class FlagOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    issue_id: int
    category: str
    details: str | None = None
    created_at: UTCDateTime


class FlaggedIssueItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    issue_id: int
    title: str
    description: str
    reporter_id: int
    flag_count: int
    categories: list[str]
    is_hidden: bool
    latest_flag_at: UTCDateTime
    created_at: UTCDateTime


class FlaggedQueueResponse(BaseModel):
    items: list[FlaggedIssueItem]
    total: int
    limit: int
    offset: int


class ModerationActionRequest(BaseModel):
    action: ModerationAction
    reason: str | None = Field(None, max_length=500)


class ModerationResultOut(BaseModel):
    success: bool
    issue_id: int
    action: str
    is_hidden: bool
    reporter_banned: bool
    message: str


class AssignedAuthorityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    official_name: str
    title: str
    ward: str
    department: str | None = "all"
    handle: str | None = None
    is_unclaimed: bool = False
    is_verified: bool = True
    contact_email: str | None = None
    contact_phone: str | None = None


class IssueCreate(BaseModel):
    title: str = Field(min_length=5, max_length=100)
    description: str = Field(default="", max_length=1000)
    category: str = Field(default="other", max_length=32)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    is_anonymous: bool = False
    fuzz_location: bool = False
    is_fuzzed: bool = False
    is_shielded: bool = False
    media_url: str | None = None
    video_url: str | None = None
    media_urls: list[str] = Field(default_factory=list)


class IssueOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    category: str
    status: str
    latitude: float
    longitude: float
    geohash: str | None = None
    ward: str = "Ward 45, Urban Central"
    is_anonymous: bool
    fuzz_location: bool = False
    is_fuzzed: bool = False
    is_shielded: bool = False
    reporter_id: int | None = None
    reporter_label: str
    reporter_name: str | None = None
    reporter_photo_url: str | None = None
    anonymous_identity: str | None = None
    media_url: str | None = None
    video_url: str | None = None
    media_urls: list[str] = Field(default_factory=list)
    created_at: UTCDateTime
    acknowledged_at: UTCDateTime | None = None
    resolved_at: UTCDateTime | None = None
    upvotes_count: int = 0
    comments_count: int = 0
    confirmations_count: int = 0
    disputes_count: int = 0
    resolution_proof: str | None = None
    resolution_notes: str | None = None
    has_upvoted: bool = False
    has_official_response: bool = False
    assigned_representative: AssignedAuthorityOut | None = None
    resolved_by: str | None = None
    resolution_type: str | None = None


class WrongAssignmentReportCreate(BaseModel):
    suggested_ward: str | None = None
    suggested_category: str | None = None
    reason: str = Field(min_length=3, max_length=500)


class WrongAssignmentReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    issue_id: int
    user_id: int | None = None
    suggested_ward: str | None = None
    suggested_category: str | None = None
    reason: str
    created_at: UTCDateTime


class AdminReassignRequest(BaseModel):
    ward: str | None = None
    category: str | None = None
    assigned_representative_id: str | None = None
    reason: str | None = Field(None, max_length=500)


class QuorumVoterOut(BaseModel):
    user_id: int
    username: str | None = None
    display_name: str | None = None
    vote: str
    reason: str | None = None
    is_nearby: bool = True
    created_at: UTCDateTime


class IssueTimelineEventOut(BaseModel):
    event_type: str
    title: str
    description: str | None = None
    actor_name: str | None = None
    actor_handle: str | None = None
    actor_role: str | None = None
    is_unclaimed: bool = False
    media_url: str | None = None
    created_at: UTCDateTime


class IssueTimelineResponse(BaseModel):
    issue_id: int
    status: str
    resolution_type: str | None = None
    resolved_by: str | None = None
    events: list[IssueTimelineEventOut]
    confirmations: list[QuorumVoterOut] = Field(default_factory=list)
    disputes: list[QuorumVoterOut] = Field(default_factory=list)


class NearDuplicateOut(BaseModel):
    id: int
    title: str
    category: str
    status: str
    latitude: float
    longitude: float
    geohash: str | None = None
    distance_meters: float
    created_at: UTCDateTime


class NearDuplicateCheckResponse(BaseModel):
    is_duplicate_detected: bool
    candidates: list[NearDuplicateOut]


class ResolutionSubmit(BaseModel):
    resolution_proof: str = Field(min_length=5)
    notes: str | None = None


class QuorumVoteRequest(BaseModel):
    vote: str = Field(pattern="^(confirm|dispute)$")
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    reason: str | None = None


class UpvoteRequest(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


TOXIC_KEYWORDS = {
    "toxicprofanity",
    "abusive",
    "scam",
    "spam",
    "hate",
    "kill",
    "threat",
    "violence",
    "slur",
}


class CommentCreate(BaseModel):
    content: str = Field(min_length=1, max_length=500)
    parent_id: str | None = None

    @field_validator("content")
    @classmethod
    def validate_content(cls, v: str) -> str:
        stripped = v.strip()
        if not stripped:
            raise ValueError("Comment content cannot be empty or whitespace only")
        if len(stripped) > 500:
            raise ValueError("Comment content exceeds 500 characters")

        lower = stripped.lower()
        if any(tk in lower for tk in TOXIC_KEYWORDS):
            raise ValueError("Comment contains toxic or inappropriate language")
        return stripped


class CommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    issue_id: int
    parent_id: str | None = None
    anon_id: str
    content: str
    created_at: UTCDateTime
    is_author: bool = False
    replies: list["CommentResponse"] = Field(default_factory=list)


CommentResponse.model_rebuild()


class WinOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    issue_id: int
    title: str
    description: str
    category: str
    ward: str
    latitude: float
    longitude: float
    geohash: str | None = None
    before_image_url: str | None = None
    after_image_url: str | None = None
    contributor_credits: list[str] = Field(default_factory=list)
    created_at: UTCDateTime
