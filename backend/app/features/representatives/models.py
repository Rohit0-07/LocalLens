from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.features.auth.models import User
    from app.features.issues.models import Issue


class RepresentativeProfile(Base):
    __tablename__ = "representative_profiles"

    id: Mapped[str] = mapped_column(String(255), primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True
    )
    official_name: Mapped[str] = mapped_column(String(255), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    ward: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    verified_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="representative_profile")
    official_responses: Mapped[list["OfficialResponse"]] = relationship(
        "OfficialResponse", back_populates="representative", cascade="all, delete-orphan"
    )


class OfficialResponse(Base):
    __tablename__ = "official_responses"

    id: Mapped[str] = mapped_column(String(255), primary_key=True, index=True)
    issue_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("issues.id", ondelete="CASCADE"), nullable=False, index=True
    )
    representative_id: Mapped[str] = mapped_column(
        String(255),
        ForeignKey("representative_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    message: Mapped[str] = mapped_column(String(1000), nullable=False)
    estimated_resolution_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status_update: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=datetime.utcnow)

    issue: Mapped["Issue"] = relationship("Issue", back_populates="official_responses")
    representative: Mapped["RepresentativeProfile"] = relationship(
        "RepresentativeProfile", back_populates="official_responses"
    )
