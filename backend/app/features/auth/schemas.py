from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.features.gamification.schemas import UserBadgeOut
from app.features.issues.schemas import IssueOut

_PHONE_PATTERN = r"^\+[1-9]\d{6,14}$"
_EMAIL_PATTERN = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"


class OtpRequest(BaseModel):
    phone: str = Field(pattern=_PHONE_PATTERN)


class EmailOtpRequest(BaseModel):
    email: str = Field(pattern=_EMAIL_PATTERN)


class EmailOtpVerify(BaseModel):
    email: str = Field(pattern=_EMAIL_PATTERN)
    code: str = Field(min_length=6, max_length=6)


class OtpVerify(BaseModel):
    phone: str = Field(pattern=_PHONE_PATTERN)
    code: str = Field(min_length=6, max_length=6)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int | str
    anonymous_identity: str
    anon_id: str
    is_guest: bool = False


class ProfileUpdate(BaseModel):
    display_name: str | None = Field(default=None, max_length=120)
    username: str | None = Field(default=None, min_length=3, max_length=40, pattern=r"^[a-zA-Z0-9_.]+$")
    date_of_birth: date | None = None
    photo_url: str | None = Field(default=None, max_length=500)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int | str
    phone: str | None = None
    email: str | None = None
    display_name: str | None = None
    username: str | None = None
    date_of_birth: date | None = None
    photo_url: str | None = None
    anonymous_identity: str
    anon_id: str | None = None
    role: str = "citizen"
    is_verified: bool = True
    ward: str | None = "Ward 45, Urban Central"
    created_at: datetime | None = None
    is_guest: bool = False
    issues_count: int = 0
    upvotes_count: int = 0
    quorum_votes_count: int = 0


class PublicUserProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    anon_id: str
    display_name: str | None = None
    username: str | None = None
    role: str = "citizen"
    is_verified: bool = True
    ward: str | None = "Ward 45, Urban Central"
    created_at: datetime
    issues_count: int = 0
    resolutions_count: int = 0
    upvotes_count: int = 0
    quorum_votes_count: int = 0
    level: int = 1
    impact_score: int = 0
    badges: list[UserBadgeOut] = Field(default_factory=list)
    public_issues: list[IssueOut] = Field(default_factory=list)
