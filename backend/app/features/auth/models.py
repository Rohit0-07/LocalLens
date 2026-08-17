from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.features.representatives.models import RepresentativeProfile


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, index=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True, index=True)
    display_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    username: Mapped[str | None] = mapped_column(String(40), unique=True, nullable=True, index=True)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    bio: Mapped[str | None] = mapped_column(String(200), nullable=True)
    display_name_changes_count: Mapped[int] = mapped_column(
        Integer, default=0, server_default="0", nullable=False
    )
    display_name_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    bio_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    photo_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    role: Mapped[str] = mapped_column(String(32), default="citizen", nullable=False)
    is_verified: Mapped[bool | None] = mapped_column(
        Boolean, default=True, server_default="1", nullable=True
    )
    ward: Mapped[str | None] = mapped_column(String(64), default="Ward 45, Urban Central", nullable=True)
    is_banned: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    representative_profile: Mapped["RepresentativeProfile | None"] = relationship(
        "RepresentativeProfile", uselist=False, back_populates="user"
    )

    @property
    def is_representative(self) -> bool:
        return getattr(self, "representative_profile", None) is not None


class OtpCode(Base):
    __tablename__ = "otp_codes"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone: Mapped[str | None] = mapped_column(String(20), index=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    code_hash: Mapped[str] = mapped_column(String(128))
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
