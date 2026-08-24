from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from app.core.fields import UTCDateTime


class ActivityCountsOut(BaseModel):
    issues_created: int = 0
    upvotes_cast: int = 0
    quorum_votes_cast: int = 0
    comments_posted: int = 0


ActivityCounts = ActivityCountsOut


class UserBadgeOut(BaseModel):
    badge_id: str
    key: str
    badge_key: str
    name: str
    description: str
    icon_name: str
    category: str
    unlocked_at: UTCDateTime

    model_config = ConfigDict(from_attributes=True)


class GamificationProfileOut(BaseModel):
    user_id: int | None = None
    is_guest: bool = False
    impact_score: int = 0
    level: int = 1
    level_name: str = "Civic Rookie"
    next_level_score: int | None = 100
    streak_days: int = 0
    last_streak_date: date | None = None
    can_claim_streak: bool = False
    badges: list[UserBadgeOut] = Field(default_factory=list)
    activity_counts: ActivityCountsOut = Field(default_factory=ActivityCountsOut)

    model_config = ConfigDict(from_attributes=True)


class StreakClaimOut(BaseModel):
    streak_days: int
    points_earned: int = 15
    impact_score: int
    message: str = "Daily streak claimed! +15 Impact Points"


class BadgeMetadataOut(BaseModel):
    id: str
    key: str
    badge_key: str
    name: str
    description: str
    icon_name: str
    category: str
    threshold: int
