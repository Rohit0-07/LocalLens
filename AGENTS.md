# AGENTS.md — LocalLens Working Rules

LocalLens is a hyper-local civic issues platform (report potholes/streetlights in your
ward; feed is neighbourhood-filtered; issues escalate until resolved). It is a **monorepo**:
a Python/FastAPI backend and a Flutter app. Everything here was written by AI agents and is
loosely structured; your job is to make **small, scoped, correct changes** — never to
"improve", refactor, or redesign code you weren't asked to touch.

> Read `docs/CODEBASE_MAP.md` once when you start a task. It tells you exactly which files
> belong to which feature so you never have to explore.

---

## 1. Repo layout (compact)

```
backend/            FastAPI + SQLAlchemy 2 (async), managed by uv
  app/main.py           app factory, middleware, rate limiters, routers
  app/api/              router aggregation (router.py), deps, health
  app/core/             config, database, security, exceptions, logging, ratelimit, data_sync
  app/features/<name>/  one folder per feature: router.py, service.py, schemas.py, models.py
  tests/                pytest, mirrors features/ + core
  alembic/              DB migrations
  seed.py + seed/       demo data loader
app/                Flutter client (org in.locallens)
  lib/main.dart, lib/app.dart
  lib/core/             config, router, theme, l10n, network (Dio), storage (Hive), feedback
  lib/features/<name>/  data/ (api + repo) | domain/ (models) | presentation/ (providers + screens + widgets)
  lib/shared/           reusable widgets
  test/                 flutter_test (widget + unit), mirrors lib/features/
seed/               demo data (JSON per type) + media
```

Feature folder exists in BOTH `backend/app/features/<name>` and `app/lib/features/<name>`.
Full file-level map: `docs/CODEBASE_MAP.md`.

## 2. Stack

- **Backend**: Python 3.12, FastAPI, SQLAlchemy 2 async + Alembic, Pydantic v2, JWT + bcrypt,
  pytest, ruff + mypy (strict). SQLite for local dev.
- **App**: Flutter, Riverpod 2, go_router, Dio, Hive (local cache/outbox), freezed +
  json_serializable (codegen), flutter_map + OpenStreetMap, camera/geolocator/image_picker.

## 3. How to run

```sh
make check      # everything: ruff + mypy + pytest + flutter analyze + flutter test
make backend    # run migrations + start API on :8000
make app        # run the Flutter app
make seed       # wipe + reseed demo data
make gen        # regenerate freezed/json_serializable code (after changing *_models.dart)
```

- Backend env: copy `backend/.env.example` → `backend/.env`. Add
  `LOCALLENS_OTP_MASTER_CODE=000000` so any OTP verifies with `000000`.
- Android emulator reaches the API at `http://10.0.2.2:8000`; iOS/macOS/desktop at
  `http://127.0.0.1:8000` (see `app/lib/core/config/app_config.dart`).
- On "no such column" errors: the DB is stale → `cd backend && uv run alembic upgrade head`.

## 4. THE WORKFLOW — follow this on every task

This repo is governed by **one ticket per task** in `docs/tickets/NNN-slug.md`. You
never guess what to build — the ticket defines it. A task goes through exactly these steps:

1. **Read the ticket.** `docs/tickets/NNN-slug.md` states the goal, the exact allowed files,
   the acceptance criteria, and the verify command. If there is no ticket for what you were
   asked to do, stop and tell the user to create one (or ask them for the goal, scope, and
   acceptance criteria inline).
2. **Read only the scoped files.** Open the ticket's "Files to touch" plus
   `docs/CODEBASE_MAP.md`. Do NOT read the rest of the repo. If a file you need is missing
   from the scope, ask — don't go browsing.
3. **Plan (only if the task is non-trivial).** Write 2–4 lines: the exact files you will
   change and how. Stop and let the user approve before editing if the ticket says so or if
   you are unsure.
4. **Implement.** Smallest possible diff. Match the existing style (see §6). Touch nothing
   outside the ticket's file list.
5. **Verify.** Run the ticket's verify command (usually `make check`, or the targeted test
   file when the ticket says so). Fix only what that run reveals.
6. **Report.** Summarize: what changed (file → one line), what you verified, and any
   deviation from the ticket. If something blocked you, say so instead of working around it.

## 5. Golden rules 

1. **Never change code outside the ticket's scope.** No drive-by fixes, no "while I'm here"
   cleanup, no renaming, no reformatting unrelated files.
2. **Never refactor or "improve" working code.** If it works, leave it alone.
3. **Never add new dependencies** (pubspec.yaml / pyproject.toml) unless the ticket
   explicitly requires it.
4. **Never rearchitect.** Don't extract abstractions, don't split files, don't "modernize".
5. **Never add features, screens, or endpoints that weren't asked for.** The ticket is the
   contract.
6. **Don't touch DB migrations unless adding a column/table is in the ticket.** For a pure
   bug fix, the schema already exists.
7. **Fix one problem, verify it, report. Then the user decides the next ticket.**
8. **If you see other bugs while working, note them to the user in your report.** Do NOT fix
   them in this task.

## 6. Conventions (match these exactly)

- **Backend**: one `features/<name>/` folder with `router.py` (endpoints),
  `service.py` (business logic), `schemas.py` (Pydantic in/out), `models.py` (SQLAlchemy).
  Async everywhere; `SessionDep`/`SettingsDep` from `app/api/deps.py`. Errors raised via
  `AppError` (handled globally → JSON envelope). Tests in `tests/features/<name>/test_*.py`.
- **App**: `features/<name>/data|domain|presentation`. Riverpod providers + controllers
  own state; screens are widgets; API calls go through `data/*_api.dart` repositories.
  Domain models use freezed (`.freezed.dart`/`.g.dart` generated — run `make gen` after
  editing model files). Routes are declared in `app/lib/core/router/app_router.dart` using
  `RoutePaths` constants.
- **Both**: snake_case for Python, lowerCamelCase for Dart, `flutter analyze` clean,
  `ruff`/`mypy` clean.

## 7. Testing expectations

- Backend: `uv run pytest` (or `cd backend && uv run pytest tests/features/<name>`).
- App: `flutter test` (or a single file: `flutter test test/features/<name>/..._test.dart`).
- `make check` runs the full suite. Prefer it when a ticket says "verify with make check".
- A change that isn't verified = not done.

## 8. Dev gotchas

- The app has an **offline outbox**: if the API is unreachable, reports queue locally and
  sync later. A backend call failing may look like an app bug — check the API is running.
- Guest sessions get 403 on writes (GuestGuard) and are force-signed-out on 401.
- Feed is bounded to ~5 km around the user's location (Mumbai 19.1136/72.8697 fallback).
  If an issue isn't visible, it's usually a location/radius problem, not the feed.
- Media has a "LocalLens Verified" vs "User Uploaded - Unverified" watermark based on EXIF
  GPS — missing EXIF GPS is expected for gallery picks.

## 9. Optional deep-dive docs (do NOT read by default)

`LocalLens_App_Info.md` (product overview), `LocalLens_Feature_Checklist.md` (long-form
feature history), `docs/BUGS.md` (past fixed bugs register). The old heavy SDD/teamwork
harness is archived under `.archive/` for reference only — never follow it.