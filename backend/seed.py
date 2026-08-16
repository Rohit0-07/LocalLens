"""Seed the LocalLens database with realistic demo data.

Data lives in the repository-level ``seed/data/*.json`` files (one file per
record type), ``seed/images/**``, and ``seed/media/**``. This script loads
those files and inserts the rows in foreign-key order, deriving geohashes,
anonymous identities, and denormalised counters so the database stays
internally consistent with what the API would compute.

Run from the ``backend`` directory:

    uv run python seed.py             # wipe seed tables, then insert
    uv run python seed.py --no-clear  # idempotent: skip records already present
    uv run python seed.py --db sqlite+aiosqlite:///./other.db
"""

from __future__ import annotations

import argparse
import asyncio
import json
import shutil
from collections import Counter
from datetime import date, datetime
from pathlib import Path
from typing import Any

from app.core.config import Settings
from app.core.database import Database
from app.core.security import derive_anonymous_identity
from app.features.auth.models import OtpCode, User
from app.features.gamification.models import UserBadge, UserGamification
from app.features.issues.geohash import encode_geohash
from app.features.issues.models import (
    Comment,
    Flag,
    Issue,
    ModerationAudit,
    QuorumVote,
    Upvote,
    UpvoteRateLimit,
    Win,
)
from app.features.media.models import Media
from app.features.notifications.models import Notification
from app.features.representatives.models import OfficialResponse, RepresentativeProfile
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

#: tables touched by the seeder (deleted first when --clear is used, children first)
_TABLES: list[Any] = [
    Win,
    Media,
    Notification,
    OfficialResponse,
    QuorumVote,
    Upvote,
    UpvoteRateLimit,
    Flag,
    ModerationAudit,
    Comment,
    UserBadge,
    UserGamification,
    RepresentativeProfile,
    Issue,
    OtpCode,
    User,
]

#: record types consumed by the seeder, in foreign-key-safe load order
_DATA_FILES = [
    "users",
    "media",
    "issues",
    "representatives",
    "comments",
    "upvotes",
    "notifications",
    "flags",
    "moderation_audits",
    "gamification",
    "official_responses",
    "quorum_votes",
]

_REPO_ROOT = Path(__file__).resolve().parent.parent


def _load_data() -> dict[str, list[dict[str, Any]]]:
    data_dir = _REPO_ROOT / "seed" / "data"
    payload: dict[str, list[dict[str, Any]]] = {}
    for name in _DATA_FILES:
        path = data_dir / f"{name}.json"
        if not path.exists():
            raise FileNotFoundError(f"Missing seed data file: {path}")
        with path.open(encoding="utf-8") as fh:
            payload[name] = json.load(fh)
    return payload


def _parse_dt(value: str | None) -> datetime | None:
    return datetime.fromisoformat(value) if value else None


def _parse_date(value: str | None) -> date | None:
    return date.fromisoformat(value) if value else None


async def _keys(session: AsyncSession, *columns: Any) -> set[Any]:
    """Return a set of existing keys for dedup; composite keys become tuples."""
    result = await session.execute(select(*columns))
    rows = result.all()
    if len(columns) == 1:
        return {r[0] for r in rows}
    return {tuple(r) for r in rows}


def _dedup(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any], key: Any, factory: Any
) -> None:
    """Add rows whose dedup key is not already present."""
    for row in rows:
        if key(row) in existing:
            continue
        session.add(factory(row))


def _sync_media_files(data: dict[str, list[dict[str, Any]]] | None = None) -> None:
    """Sync sample media assets (seed/media + seed/images) to the upload dirs."""
    seed_media = _REPO_ROOT / "seed" / "media"
    upload_dirs = [
        _REPO_ROOT / "uploads" / "media",
        _REPO_ROOT / "backend" / "uploads" / "media",
        Path("uploads/media"),
    ]

    def _copy_tracked(filename: str, src_paths: list[Path]) -> None:
        for src in src_paths:
            if not src.exists() or not src.is_file():
                continue
            for u_dir in upload_dirs:
                u_dir.mkdir(parents=True, exist_ok=True)
                dst_file = u_dir / filename
                if not dst_file.exists() or dst_file.stat().st_size != src.stat().st_size:
                    shutil.copy2(src, dst_file)
            break

    if seed_media.exists():
        for src_file in seed_media.glob("*"):
            if src_file.is_file():
                _copy_tracked(src_file.name, [src_file])

    if data is None:
        data = _load_data()

    _IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".webp", ".gif")

    # Map each seeded issue's media URLs to a sample image from
    # seed/images/<category>/ so the home feed actually shows photos.
    # Issues whose category has no sample folder fall back to any sample.
    issues = data.get("issues", [])
    images_root = _REPO_ROOT / "seed" / "images"
    all_category_dirs = sorted(p for p in images_root.iterdir() if p.is_dir()) if images_root.exists() else []

    def _sample_sources(category: str) -> list[Path]:
        cat_dir = images_root / category
        if cat_dir.is_dir():
            found = sorted(p for p in cat_dir.iterdir() if p.is_file())
            if found:
                return found
        # Fallback: any category with samples
        for fallback_dir in all_category_dirs:
            found = sorted(p for p in fallback_dir.iterdir() if p.is_file())
            if found:
                return found
        return []

    for issue_row in issues:
        category = issue_row.get("category", "other")
        refs = list(issue_row.get("media_urls") or [])
        if issue_row.get("media_url"):
            refs.insert(0, issue_row["media_url"])
        if issue_row.get("video_url"):
            refs.append(issue_row["video_url"])
        if issue_row.get("resolution_proof"):
            refs.append(issue_row["resolution_proof"])
        for ref in refs:
            if not ref or not ref.startswith("/"):
                continue
            filename = Path(ref).name
            if not filename.lower().endswith(_IMAGE_EXTS):
                continue
            _copy_tracked(filename, _sample_sources(category))
        # Ensure thumbnail URLs referenced by media rows exist (point at the sample image)
        for media_row in data.get("media", []):
            thumb = media_row.get("thumbnail_url", "")
            if thumb and thumb.startswith("/"):
                filename = Path(thumb).name
                if not filename.lower().endswith(_IMAGE_EXTS):
                    continue
                _copy_tracked(filename, _sample_sources(category))


async def _seed_users(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> User:
        return User(
            id=row["id"],
            phone=row.get("phone"),
            email=row.get("email"),
            display_name=row.get("display_name"),
            username=row.get("username"),
            date_of_birth=_parse_date(row.get("date_of_birth")),
            photo_url=row.get("photo_url"),
            is_admin=row.get("is_admin", False),
            role=row.get("role", "citizen"),
            is_verified=row.get("is_verified", True),
            ward=row.get("ward", "Ward 45, Urban Central"),
            is_banned=row.get("is_banned", False),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_media(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> Media:
        return Media(
            id=row["id"],
            user_id=str(row["user_id"]) if row.get("user_id") is not None else None,
            url=row["url"],
            thumbnail_url=row.get("thumbnail_url", row["url"]),
            is_verified=row.get("is_verified", False),
            watermark_label=row.get("watermark_label", "LocalLens Verified"),
            derived_hash=row.get("derived_hash", ""),
            latitude=row.get("latitude"),
            longitude=row.get("longitude"),
            is_fuzzed=row.get("is_fuzzed", False),
            is_in_app_camera=row.get("is_in_app_camera", False),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_issues(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> Issue:
        lat = float(row["latitude"])
        lng = float(row["longitude"])
        raw_urls = row.get("media_urls") or []
        return Issue(
            id=row["id"],
            title=row["title"],
            description=row["description"],
            category=row["category"],
            status=row["status"],
            latitude=lat,
            longitude=lng,
            geohash=encode_geohash(lat, lng),
            ward=row.get("ward", "Ward 45, Urban Central"),
            is_anonymous=row.get("is_anonymous", False),
            fuzz_location=row.get("fuzz_location", False),
            is_fuzzed=row.get("is_fuzzed", False),
            is_shielded=row.get("is_shielded", False),
            is_hidden=row.get("is_hidden", False),
            reporter_id=row["reporter_id"],
            media_url=row.get("media_url"),
            video_url=row.get("video_url"),
            media_urls=json.dumps(raw_urls) if raw_urls else None,
            created_at=_parse_dt(row.get("created_at")),
            acknowledged_at=_parse_dt(row.get("acknowledged_at")),
            resolved_at=_parse_dt(row.get("resolved_at")),
            escalated_at=_parse_dt(row.get("escalated_at")),
            resolution_proof=row.get("resolution_proof"),
            resolution_notes=row.get("resolution_notes"),
            quorum_expires_at=_parse_dt(row.get("quorum_expires_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_representatives(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> RepresentativeProfile:
        return RepresentativeProfile(
            id=row["id"],
            user_id=row["user_id"],
            official_name=row["official_name"],
            title=row["title"],
            ward=row["ward"],
            verified_at=_parse_dt(row.get("verified_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_comments(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any], secret: str
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> Comment:
        return Comment(
            id=row["id"],
            issue_id=row["issue_id"],
            parent_id=row.get("parent_id"),
            author_id=row["author_id"],
            anon_id=derive_anonymous_identity(row["author_id"], secret),
            content=row["content"],
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_upvotes(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return (row["issue_id"], row["user_id"])

    def factory(row: dict[str, Any]) -> Upvote:
        return Upvote(
            issue_id=row["issue_id"],
            user_id=row["user_id"],
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_notifications(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["id"]

    def factory(row: dict[str, Any]) -> Notification:
        return Notification(
            id=row["id"],
            user_id=str(row["user_id"]),
            title=row["title"],
            body=row["body"],
            type=row["type"],
            reference_id=row.get("reference_id"),
            is_read=row.get("is_read", False),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_flags(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any], secret: str
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return (row["issue_id"], row.get("reporter_id"))

    def factory(row: dict[str, Any]) -> Flag:
        return Flag(
            issue_id=row["issue_id"],
            reporter_id=row.get("reporter_id"),
            anon_id=(
                derive_anonymous_identity(row["reporter_id"], secret)
                if row.get("reporter_id") is not None
                else None
            ),
            category=row["category"],
            details=row.get("details"),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_moderation_audits(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return (row["issue_id"], row["action"], row.get("reason"))

    def factory(row: dict[str, Any]) -> ModerationAudit:
        return ModerationAudit(
            issue_id=row["issue_id"],
            action=row["action"],
            reason=row.get("reason"),
            moderated_by=row["moderated_by"],
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_gamification(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row["user_id"]

    def factory(row: dict[str, Any]) -> UserGamification:
        return UserGamification(
            user_id=row["user_id"],
            streak_days=row.get("streak_days", 0),
            last_streak_date=_parse_date(row.get("last_streak_date")),
            impact_score=row.get("impact_score", 0),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_gamification_badges(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return (row["user_id"], row["badge_id"])

    def factory(row: dict[str, Any]) -> UserBadge:
        return UserBadge(
            user_id=row["user_id"],
            badge_id=row["badge_id"],
            unlocked_at=_parse_dt(row.get("unlocked_at")),
        )

    for profile in rows:
        badges = [{"user_id": profile["user_id"], **b} for b in profile.get("badges", [])]
        _dedup(session, badges, existing, key, factory)
    await session.commit()


async def _seed_official_responses(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return row.get("id") or f"off_resp_seed_{row['issue_id']}"

    def factory(row: dict[str, Any]) -> OfficialResponse:
        return OfficialResponse(
            id=row.get("id") or f"off_resp_seed_{row['issue_id']}",
            issue_id=row["issue_id"],
            representative_id=row["representative_id"],
            message=row["message"],
            estimated_resolution_days=row.get("estimated_resolution_days"),
            status_update=row.get("status_update"),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_quorum_votes(
    session: AsyncSession, rows: list[dict[str, Any]], existing: set[Any]
) -> None:
    def key(row: dict[str, Any]) -> Any:
        return (row["issue_id"], row["user_id"])

    def factory(row: dict[str, Any]) -> QuorumVote:
        return QuorumVote(
            issue_id=row["issue_id"],
            user_id=row["user_id"],
            vote=row["vote"],
            reason=row.get("reason"),
            created_at=_parse_dt(row.get("created_at")),
        )

    _dedup(session, rows, existing, key, factory)
    await session.commit()


async def _seed_wins_for_resolved_issues(session: AsyncSession) -> None:
    """Ensure resolved issues have corresponding Win records with before/after photos and credits."""
    from app.features.issues.service import create_win_for_issue

    stmt = select(Issue).where(Issue.status == "resolved")
    res = await session.execute(stmt)
    resolved_issues = res.scalars().all()
    for issue in resolved_issues:
        await create_win_for_issue(session, issue)
    await session.commit()


async def _reconcile_counters(session: AsyncSession) -> None:
    """Make issues.flag_count/upvotes_count/comments_count and quorum tallies
    match the actual child rows, so the database is consistent with the API."""
    upvotes: Counter[int] = Counter()
    for (issue_id,) in (await session.execute(select(Upvote.issue_id))).all():
        upvotes[issue_id] += 1

    comments: Counter[int] = Counter()
    for (issue_id,) in (await session.execute(select(Comment.issue_id))).all():
        comments[issue_id] += 1

    flags: Counter[int] = Counter()
    for (issue_id,) in (await session.execute(select(Flag.issue_id))).all():
        flags[issue_id] += 1

    confirms: Counter[int] = Counter()
    disputes: Counter[int] = Counter()
    for issue_id, vote in (
        await session.execute(select(QuorumVote.issue_id, QuorumVote.vote))
    ).all():
        if vote == "confirm":
            confirms[issue_id] += 1
        elif vote == "dispute":
            disputes[issue_id] += 1

    issue_ids = (await session.execute(select(Issue.id))).scalars().all()
    for issue_id in issue_ids:
        issue = await session.get(Issue, issue_id)
        if issue is None:
            continue
        issue.upvotes_count = upvotes.get(issue_id, 0)
        issue.comments_count = comments.get(issue_id, 0)
        issue.flag_count = flags.get(issue_id, 0)
        issue.confirmations_count = confirms.get(issue_id, 0)
        issue.disputes_count = disputes.get(issue_id, 0)
    await session.commit()


async def _report(session: AsyncSession) -> None:
    async def count(model: Any, column: Any) -> int:
        return len((await session.execute(select(column))).scalars().all())

    counts = {
        "users": await count(User, User.id),
        "media": await count(Media, Media.id),
        "issues": await count(Issue, Issue.id),
        "representatives": await count(RepresentativeProfile, RepresentativeProfile.id),
        "comments": await count(Comment, Comment.id),
        "upvotes": await count(Upvote, Upvote.id),
        "notifications": await count(Notification, Notification.id),
        "flags": await count(Flag, Flag.id),
        "moderation_audits": await count(ModerationAudit, ModerationAudit.id),
        "user_gamifications": await count(UserGamification, UserGamification.id),
        "user_badges": await count(UserBadge, UserBadge.id),
        "official_responses": await count(OfficialResponse, OfficialResponse.id),
        "quorum_votes": await count(QuorumVote, QuorumVote.id),
        "wins": await count(Win, Win.id),
    }
    print("Seeded database summary:")
    for name, total in counts.items():
        print(f"  {name:<20} {total:>4}")


async def _main(args: argparse.Namespace) -> None:
    settings = Settings(database_url=args.db) if args.db else Settings()
    db = Database(settings.database_url)
    try:
        if args.clear:
            await db.drop_all()
        await db.create_all()
        async with db.session_factory() as session:
            if args.clear:
                existing: dict[str, set[Any]] = {}
            else:
                existing = {
                    "users": await _keys(session, User.id),
                    "media": await _keys(session, Media.id),
                    "issues": await _keys(session, Issue.id),
                    "representatives": await _keys(session, RepresentativeProfile.id),
                    "comments": await _keys(session, Comment.id),
                    "upvotes": await _keys(session, Upvote.issue_id, Upvote.user_id),
                    "notifications": await _keys(session, Notification.id),
                    "flags": await _keys(session, Flag.issue_id, Flag.reporter_id),
                    "moderation_audits": await _keys(
                        session,
                        ModerationAudit.issue_id,
                        ModerationAudit.action,
                        ModerationAudit.reason,
                    ),
                    "gamification": await _keys(session, UserGamification.user_id),
                    "badges": await _keys(session, UserBadge.user_id, UserBadge.badge_id),
                    "official_responses": await _keys(session, OfficialResponse.id),
                    "quorum_votes": await _keys(session, QuorumVote.issue_id, QuorumVote.user_id),
                }

            # Sync demo media and video files to upload directories
            data = _load_data()
            _sync_media_files(data)

            secret = settings.jwt_secret

            await _seed_users(session, data["users"], existing.get("users", set()))
            await _seed_media(session, data["media"], existing.get("media", set()))
            await _seed_issues(session, data["issues"], existing.get("issues", set()))
            await _seed_representatives(
                session, data["representatives"], existing.get("representatives", set())
            )
            await _seed_comments(session, data["comments"], existing.get("comments", set()), secret)
            await _seed_upvotes(session, data["upvotes"], existing.get("upvotes", set()))
            await _seed_notifications(
                session, data["notifications"], existing.get("notifications", set())
            )
            await _seed_flags(session, data["flags"], existing.get("flags", set()), secret)
            await _seed_moderation_audits(
                session, data["moderation_audits"], existing.get("moderation_audits", set())
            )
            await _seed_gamification(
                session, data["gamification"], existing.get("gamification", set())
            )
            await _seed_gamification_badges(
                session, data["gamification"], existing.get("badges", set())
            )
            await _seed_official_responses(
                session, data["official_responses"], existing.get("official_responses", set())
            )
            await _seed_quorum_votes(
                session, data["quorum_votes"], existing.get("quorum_votes", set())
            )
            await _seed_wins_for_resolved_issues(session)

            await _reconcile_counters(session)
            await _report(session)
    finally:
        await db.dispose()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--clear",
        action="store_true",
        default=True,
        help="Wipe seeded tables before inserting (default).",
    )
    parser.add_argument(
        "--no-clear",
        dest="clear",
        action="store_false",
        help="Idempotent: skip records whose key already exists.",
    )
    parser.add_argument("--db", default=None, help="Override database URL.")
    args = parser.parse_args()
    asyncio.run(_main(args))


if __name__ == "__main__":
    main()
