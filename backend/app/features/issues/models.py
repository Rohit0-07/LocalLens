import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.features.auth.models import User
    from app.features.representatives.models import OfficialResponse, RepresentativeProfile


class Issue(Base):
    __tablename__ = "issues"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text, default="")
    category: Mapped[str] = mapped_column(String(32), default="other", index=True)
    status: Mapped[str] = mapped_column(String(32), default="unacknowledged", index=True)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    geohash: Mapped[str | None] = mapped_column(String(12), index=True, nullable=True)
    ward: Mapped[str] = mapped_column(String(64), default="Ward 45, Urban Central", index=True)
    search_blob: Mapped[str | None] = mapped_column(Text, nullable=True, index=True)
    is_anonymous: Mapped[bool] = mapped_column(default=False)
    fuzz_location: Mapped[bool] = mapped_column(default=False)
    is_fuzzed: Mapped[bool] = mapped_column(default=False)
    is_shielded: Mapped[bool] = mapped_column(default=False)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    flag_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    reporter_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), index=True, nullable=True)
    media_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    video_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    media_urls: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False, index=True
    )
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    escalated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    upvotes_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    comments_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    resolution_proof: Mapped[str | None] = mapped_column(String(255), nullable=True)
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    confirmations_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    disputes_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    quorum_expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    assigned_representative_id: Mapped[str | None] = mapped_column(
        String(255), ForeignKey("representative_profiles.id", ondelete="SET NULL"), nullable=True, index=True
    )
    resolved_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    resolution_type: Mapped[str | None] = mapped_column(String(32), nullable=True)

    reporter: Mapped["User | None"] = relationship(foreign_keys=[reporter_id])
    assigned_representative: Mapped["RepresentativeProfile | None"] = relationship(
        "RepresentativeProfile", foreign_keys=[assigned_representative_id]
    )
    official_responses: Mapped[list["OfficialResponse"]] = relationship(
        "OfficialResponse", back_populates="issue", cascade="all, delete-orphan"
    )
    wrong_assignment_reports: Mapped[list["WrongAssignmentReport"]] = relationship(
        "WrongAssignmentReport", back_populates="issue", cascade="all, delete-orphan"
    )


class WrongAssignmentReport(Base):
    __tablename__ = "wrong_assignment_reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    issue_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("issues.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    suggested_ward: Mapped[str | None] = mapped_column(String(255), nullable=True)
    suggested_category: Mapped[str | None] = mapped_column(String(64), nullable=True)
    reason: Mapped[str] = mapped_column(String(500), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    issue: Mapped["Issue"] = relationship("Issue", back_populates="wrong_assignment_reports")


class Flag(Base):
    __tablename__ = "flags"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    issue_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("issues.id", ondelete="CASCADE"), nullable=False, index=True
    )
    reporter_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    anon_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    details: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        UniqueConstraint("issue_id", "reporter_id", name="uq_flags_issue_reporter"),
        UniqueConstraint("issue_id", "anon_id", name="uq_flags_issue_anon"),
    )


class ModerationAudit(Base):
    __tablename__ = "moderation_audits"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    issue_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("issues.id", ondelete="CASCADE"), nullable=False, index=True
    )
    action: Mapped[str] = mapped_column(String(32), nullable=False)
    reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    moderated_by: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class Comment(Base):
    __tablename__ = "comments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    issue_id: Mapped[int] = mapped_column(ForeignKey("issues.id"), index=True)
    parent_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("comments.id"), index=True, nullable=True
    )
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    anon_id: Mapped[str] = mapped_column(String(64), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False, index=True
    )


class Upvote(Base):
    __tablename__ = "upvotes"

    id: Mapped[int] = mapped_column(primary_key=True)
    issue_id: Mapped[int] = mapped_column(ForeignKey("issues.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )


class QuorumVote(Base):
    __tablename__ = "quorum_votes"

    id: Mapped[int] = mapped_column(primary_key=True)
    issue_id: Mapped[int] = mapped_column(ForeignKey("issues.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    vote: Mapped[str] = mapped_column(String(16))  # "confirm" or "dispute"
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User | None"] = relationship(foreign_keys=[user_id])


class UpvoteRateLimit(Base):
    __tablename__ = "upvote_rate_limits"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )


class Win(Base):
    __tablename__ = "wins"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    issue_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("issues.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    category: Mapped[str] = mapped_column(String(64), nullable=False, default="other")
    ward: Mapped[str] = mapped_column(String(64), nullable=False, default="Ward 45, Urban Central")
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    geohash: Mapped[str | None] = mapped_column(String(12), nullable=True, index=True)
    before_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    after_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    contributor_credits: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False, index=True
    )
