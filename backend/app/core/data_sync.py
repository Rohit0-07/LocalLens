"""Team database data sync engine.

Syncs the *content* of local SQLite dev databases between team members
(schema stays under Alembic; this module moves rows). Workflow is strict
turn-taking:

1. ``export`` writes one idempotent snapshot file (``data_migrations/sync.sql``)
   containing every tracked table as ``INSERT ... ON CONFLICT DO UPDATE``
   statements in foreign-key-safe order, plus bundles any uploaded media files
   into ``data_migrations/media/``.
2. The file is committed and pushed to git.
3. Each teammate pulls, and the snapshot is applied automatically at backend
   startup (or via ``make sync-db``). Application is transactional: on the
   first error the whole snapshot rolls back and the file is *not* deleted so
   the reason can be inspected.
4. On success the snapshot file and the bundled media are deleted, keeping the
   folder clean for the next hand-off.

Because every export is a full snapshot and every apply is a per-row upsert,
applying the same file twice is harmless.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import math
import shutil
from pathlib import Path
from typing import Any

from app.core.config import Settings
from app.core.database import Database
from sqlalchemy import text

logger = logging.getLogger("locallens.data_sync")

#: repo/backend/data_migrations/ — the transient snapshot lives here.
MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "data_migrations"
SYNC_FILE = MIGRATIONS_DIR / "sync.sql"
MEDIA_DIR = MIGRATIONS_DIR / "media"

#: Tables exported/imported by the sync, in foreign-key-safe insertion order.
#: Transient/tracking tables (otp_codes, upvote_rate_limits internals, etc.)
#: are intentionally excluded.
TRACKED_TABLES: list[str] = [
    "wards",
    "users",
    "representative_profiles",
    "issues",
    "media",
    "wrong_assignment_reports",
    "comments",
    "upvotes",
    "flags",
    "moderation_audits",
    "quorum_votes",
    "notifications",
    "official_responses",
    "wins",
    "user_gamifications",
    "user_badges",
    "local_talk_posts",
    "notices",
]

#: Columns that reference uploaded media files (url or JSON list of urls).
_MEDIA_REF_COLUMNS: dict[str, list[str]] = {
    "media": ["url", "thumbnail_url"],
    "issues": ["media_url", "video_url", "media_urls", "resolution_proof"],
    "wins": ["before_image_url", "after_image_url"],
    "users": ["photo_url"],
}


def default_media_dirs() -> list[Path]:
    """Resolve the candidate upload folders media may live in.

    Mirrors the fallback resolution used by ``app.features.media.service``.
    """
    repo_root = Path(__file__).resolve().parent.parent.parent.parent
    return [
        Path("uploads/media"),
        Path("backend/uploads/media"),
        repo_root / "uploads" / "media",
        repo_root / "backend" / "uploads" / "media",
        repo_root / "seed" / "media",
    ]


def _sql_literal(value: Any) -> str:
    """Render a raw DB driver value as a SQLite literal."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError(f"Cannot export non-finite float value: {value!r}")
        return format(value, ".17g")
    if isinstance(value, bytes):
        return "X'" + value.hex() + "'"
    return "'" + str(value).replace("'", "''") + "'"


async def _table_exists(conn: Any, table: str) -> bool:
    result = await conn.execute(
        text("SELECT name FROM sqlite_master WHERE type = 'table' AND name = :t"), {"t": table}
    )
    return result.scalar() is not None


async def _table_info(conn: Any, table: str) -> tuple[list[str], list[str]]:
    """Return (ordered columns, primary key columns) for a table via PRAGMA."""
    result = await conn.execute(text(f'PRAGMA table_info("{table}")'))
    columns: list[str] = []
    primary_keys: list[str] = []
    for row in result.mappings():
        columns.append(row["name"])
        if row["pk"]:
            primary_keys.append(row["name"])
    return columns, primary_keys


def _upsert_statement(table: str, columns: list[str], primary_keys: list[str], row: Any) -> str:
    quoted_cols = ", ".join(f'"{c}"' for c in columns)
    values = ", ".join(_sql_literal(row[c]) for c in columns)
    target = ", ".join(f'"{p}"' for p in primary_keys)
    conflicts = [c for c in columns if c not in set(primary_keys)]
    sets = ", ".join(f'"{c}" = excluded."{c}"' for c in conflicts)
    if not sets:  # every column is part of the primary key
        sets = f'"{primary_keys[0]}" = excluded."{primary_keys[0]}"'
    return (
        f'INSERT INTO "{table}" ({quoted_cols}) VALUES ({values}) '
        f'ON CONFLICT ({target}) DO UPDATE SET {sets};'
    )


def _referenced_filenames(table: str, rows: Any) -> set[str]:
    """Extract uploaded-media filenames referenced by a table's rows."""
    names: set[str] = set()
    for col in _MEDIA_REF_COLUMNS.get(table, []):
        for row in rows:
            value = row.get(col)
            if not value:
                continue
            candidates: list[str]
            if col == "media_urls":
                try:
                    candidates = json.loads(value) if isinstance(value, str) else list(value)
                except (TypeError, ValueError):
                    candidates = []
            else:
                candidates = [value]
            for ref in candidates:
                if not ref or not ref.startswith("/"):
                    continue
                names.add(Path(ref).name)
    return names


def _bundle_media(filenames: set[str], source_dirs: list[Path], bundle_dir: Path) -> list[str]:
    """Copy each wanted media file from any source dir into the bundle folder."""
    if bundle_dir.is_dir():
        for stale in bundle_dir.iterdir():
            if stale.is_file():
                stale.unlink(missing_ok=True)
    bundle_dir.mkdir(parents=True, exist_ok=True)
    written: list[str] = []
    for filename in sorted(filenames):
        clean = Path(filename).name
        for src in source_dirs:
            candidate = src / clean
            if candidate.is_file():
                shutil.copy2(candidate, bundle_dir / clean)
                written.append(clean)
                break
    return written


async def export_database(
    database: Database,
    out_path: Path | None = None,
    media_dirs: list[Path] | None = None,
    include_media: bool = True,
    bundle_dir: Path | None = None,
) -> dict[str, Any]:
    """Write a full idempotent snapshot of all tracked tables to ``out_path``.

    Returns a summary dict with per-table row counts and the list of bundled
    media filenames.
    """
    out_path = Path(out_path or SYNC_FILE)
    bundle = Path(bundle_dir) if bundle_dir is not None else MEDIA_DIR
    out_path.parent.mkdir(parents=True, exist_ok=True)

    statements: list[str] = []
    counts: dict[str, int] = {}
    media_filenames: set[str] = set()

    async with database.engine.begin() as conn:
        for table in TRACKED_TABLES:
            if not await _table_exists(conn, table):
                continue
            columns, primary_keys = await _table_info(conn, table)
            if not primary_keys:
                raise ValueError(
                    f"Cannot export table {table!r}: no primary key found — add a manual migration."
                )
            quoted = ", ".join(f'"{c}"' for c in columns)
            result = await conn.execute(text(f'SELECT {quoted} FROM "{table}"'))
            rows = result.mappings().all()
            counts[table] = len(rows)
            if rows:
                media_filenames |= _referenced_filenames(table, rows)
            for row in rows:
                statements.append(_upsert_statement(table, columns, primary_keys, row))

    body = "\n".join(statements)
    header = (
        "-- LocalLens team data snapshot (generated). Applying this file does an\n"
        "-- idempotent per-row upsert; it is safe to re-apply.\n"
    )
    out_path.write_text(header + body + "\n", encoding="utf-8")

    bundled: list[str] = []
    if include_media:
        dirs = media_dirs if media_dirs is not None else [d for d in default_media_dirs() if d.is_dir()]
        bundled = _bundle_media(media_filenames, dirs, bundle)

    logger.info("Exported %d rows across %d tables to %s", sum(counts.values()), len(counts), out_path)
    return {"tables": counts, "media": bundled}


async def _count_rows(conn: Any, table: str) -> int:
    result = await conn.execute(text(f'SELECT COUNT(*) FROM "{table}"'))
    return int(result.scalar() or 0)


def _parse_statements(sql: str) -> list[str]:
    """Split a snapshot file into individual SQL statements.

    The generator emits one statement per line ending in ``;``. Full-line
    comments and blank lines are skipped, so the header block and hand-added
    comments never leak into statements.
    """
    statements: list[str] = []
    current: list[str] = []
    for raw_line in sql.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("--"):
            if current:
                raise ValueError(
                    "Sync file has a comment inside a multi-line statement (missing ';')."
                )
            continue
        current.append(line)
        if line.endswith(";"):
            statements.append(" ".join(current))
            current = []
    if current:
        raise ValueError("Sync file ends mid-statement (missing ';').")
    return statements


def _restore_media(bundle_dir: Path, target_dirs: list[Path]) -> list[str]:
    """Copy every bundled media file back into the upload folders."""
    if not bundle_dir.is_dir():
        return []
    restored: list[str] = []
    for src_file in sorted(bundle_dir.iterdir()):
        if not src_file.is_file():
            continue
        for target in target_dirs:
            target.mkdir(parents=True, exist_ok=True)
            dst = target / src_file.name
            if not dst.exists() or dst.stat().st_size != src_file.stat().st_size:
                shutil.copy2(src_file, dst)
        restored.append(src_file.name)
    return restored


def _clean_applied_file(file_path: Path) -> None:
    """Remove the applied snapshot file."""
    file_path.unlink(missing_ok=True)


def _clean_bundle(bundle_dir: Path) -> None:
    """Remove the applied media bundle folder."""
    if bundle_dir.is_dir():
        shutil.rmtree(bundle_dir, ignore_errors=True)


async def apply_sync_file(
    database: Database,
    file_path: Path | None = None,
    media_dirs: list[Path] | None = None,
    delete_on_success: bool = True,
    bundle_dir: Path | None = None,
) -> dict[str, Any]:
    """Apply a snapshot file transactionally.

    Runs inside a single transaction: any statement failure rolls the whole
    snapshot back. On success the file (and bundled media) are deleted when
    ``delete_on_success`` is true.
    """
    file_path = Path(file_path or SYNC_FILE)
    bundle = Path(bundle_dir) if bundle_dir is not None else MEDIA_DIR
    if not file_path.is_file():
        raise FileNotFoundError(
            f"No data sync file found at {file_path}. Run 'export' on the machine "
            "that has the data, commit './backend/data_migrations/sync.sql', and pull it here."
        )

    sql = file_path.read_text(encoding="utf-8")
    statements = _parse_statements(sql)

    if not statements:
        raise ValueError(f"Sync file {file_path} contains no statements.")

    counts: dict[str, Any] = {}
    async with database.engine.begin() as conn:
        for statement in statements:
            result = await conn.execute(text(statement))
            try:
                rowcount = result.rowcount
            except (AttributeError, NotImplementedError):
                rowcount = -1
            if rowcount and rowcount > 0:
                counts["rows_upserted"] = counts.get("rows_upserted", 0) + rowcount
        counts["statements"] = len(statements)
        for table in TRACKED_TABLES:
            if await _table_exists(conn, table):
                counts.setdefault("table_rows", {})[table] = await _count_rows(conn, table)

    restored: list[str] = []
    if bundle.is_dir():
        dirs = media_dirs if media_dirs is not None else [d for d in default_media_dirs()]
        restored = _restore_media(bundle, dirs)

    if delete_on_success:
        _clean_applied_file(file_path)
        _clean_bundle(bundle)

    logger.info(
        "Applied %d statements (%d upserts) from %s; restored %d media file(s)",
        counts["statements"],
        counts.get("rows_upserted", 0),
        file_path,
        len(restored),
    )
    return {"statements": counts["statements"], "rows_upserted": counts.get("rows_upserted", 0), "media": restored}


async def run_startup_sync(database: Database) -> dict[str, Any] | None:
    """Auto-apply a pending snapshot at dev startup, if one exists.

    Returns the apply summary, or ``None`` when no snapshot is waiting.
    """
    if not SYNC_FILE.is_file():
        return None
    logger.info("Found pending data snapshot %s — applying team data sync.", SYNC_FILE)
    return await apply_sync_file(database, SYNC_FILE)


async def _cli_main(args: argparse.Namespace) -> None:
    settings = Settings(database_url=args.db) if args.db else Settings()
    db = Database(settings.database_url)
    try:
        if args.command == "export":
            summary = await export_database(db, out_path=Path(args.out))
            print(f"Exported {sum(summary['tables'].values())} rows to {args.out}")
            for table, count in summary["tables"].items():
                print(f"  {table:<28} {count:>5}")
            if summary["media"]:
                print(f"Bundled {len(summary['media'])} media file(s) into {MEDIA_DIR}")
            return
        if args.command == "apply":
            result = await apply_sync_file(db, file_path=Path(args.file))
            print(
                f"Applied {result['statements']} statement(s), "
                f"{result['rows_upserted']} row(s) upserted, "
                f"{len(result['media'])} media file(s) restored."
            )
            return
        raise SystemExit(f"Unknown command: {args.command}")
    finally:
        await db.dispose()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    export_parser = sub.add_parser("export", help="Write a full data snapshot to sync.sql.")
    export_parser.add_argument(
        "--out", default=str(SYNC_FILE), help=f"Output SQL file (default: {SYNC_FILE})."
    )
    export_parser.add_argument("--db", default=None, help="Override database URL.")

    apply_parser = sub.add_parser("apply", help="Apply a data snapshot from sync.sql.")
    apply_parser.add_argument(
        "--file", default=str(SYNC_FILE), help=f"Snapshot file to apply (default: {SYNC_FILE})."
    )
    apply_parser.add_argument("--db", default=None, help="Override database URL.")

    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    asyncio.run(_cli_main(args))


if __name__ == "__main__":
    main()