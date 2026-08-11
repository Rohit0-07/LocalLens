from datetime import datetime

from pydantic import BaseModel, Field

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


class UserOut(BaseModel):
    id: int | str
    phone: str | None = None
    email: str | None = None
    anonymous_identity: str
    anon_id: str | None = None
    created_at: datetime | None = None
    is_guest: bool = False
    issues_count: int = 0
    upvotes_count: int = 0
    quorum_votes_count: int = 0
