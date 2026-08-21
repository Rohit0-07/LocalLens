# LocalLens

A hyper-local civic issues platform. Residents report potholes, streetlights, and
public services from their phone; the feed is filtered to the user's own neighbourhood,
authorities are notified, and issues move through an escalation ladder until resolved.

This repository is a **monorepo** with a Python/FastAPI backend and a Flutter app, both
kept small and feature-first. Code changes are driven by **one ticket per task** in
`docs/tickets/` — see `AGENTS.md` for the workflow and `docs/CODEBASE_MAP.md` for where
everything lives.

## Repo layout

```
LocalLens/
├── backend/            FastAPI + SQLAlchemy 2 (async) API, managed by uv
│   ├── app/
│   │   ├── api/        transport: router aggregation, deps, health
│   │   ├── core/       config, database, security, exceptions, logging
│   │   └── features/   auth (OTP + JWT), issues (geo-anchored reports)
│   ├── seed.py         loads seed/data into the database (see seed/)
│   └── tests/          pytest suite mirroring features/
├── app/                Flutter client (org in.locallens)
│   ├── lib/
│   │   ├── core/       config, storage, theme, network, router
│   │   └── features/   auth, feed, compose, map, inbox, profile, ...
│   └── test/           flutter_test + Riverpod container tests
└── seed/               demo data (JSON per type) + issue images
```

## Quickstart

### Backend (uv)

```sh
cd backend
cp .env.example .env
# For local dev, add one line to backend/.env:
#   LOCALLENS_OTP_MASTER_CODE=000000
# That lets you verify OTP with code 000000 for any phone number.
uv sync
uv run alembic upgrade head
uv run python seed.py             # or `make seed`: load demo data + images
uv run uvicorn app.main:app --reload    # API on :8000
```

### App (Flutter)

```sh
cd app
flutter pub get
dart run build_runner build             # freezed / json_serializable codegen
flutter run
```

`AppConfig.dev` already points at the real local backend (`http://127.0.0.1:8000/api/v1`)
with mock auth **disabled**, so the app boots straight into the live feed.

- **iOS simulator / macOS / desktop**: use `127.0.0.1:8000` as above.
- **Android emulator**: the host is `10.0.2.2`, not `127.0.0.1`. Edit
  `app/lib/core/config/app_config.dart` (`apiBaseUrl`) accordingly.

### Demo flow

1. Open the app → feed loads seeded issues around Ward 45, Mumbai.
2. Tap **Map** tab → pins for the seeded issues (default view spans all of India).
3. Tap the green **+** dock button → “Report an issue” or “Start a ward discussion”.
4. Compose is camera/gallery enabled; if the backend is unreachable the report is
   queued to the **Offline Outbox** (visible via the tray icon on the feed, or from
   Profile → Outbox).
5. Sign in: enter any phone number, request OTP, and use code **`000000`**.
6. Language/theme: Profile → Settings (English, हिन्दी, मराठी, தமிழ், తెలుగు).

## Checks

```sh
make check          # backend ruff+mypy+pytest and app analyze+test
```

Backend details: `backend/README.md`. App details: `app/README.md`.
Design docs: `LocalLens_App_Info.md`, `LocalLens_Feature_Checklist.md`.

## Troubleshooting

- **`sqlite3.OperationalError: no such column: users.display_name`** (or any "no
  such column" on `/api/v1/feed` or `/issues`): the local database is stale and
  behind the latest Alembic migration. Fix by running `cd backend && uv run alembic
  upgrade head` (or just restart with `make backend`, which now runs migrations
  automatically before starting the server).

## Status

- **Backend**: FastAPI (async SQLAlchemy 2 + Alembic), 262/262 pytest tests green, ruff + mypy strict clean. Features shipped: Auth (OTP + JWT + Guest + HMAC Anon-ID), Issues & Near-Duplicate Guard, Escalation Ladder & Dual-Verification Quorum Resolution with Auto-Win Post Generation, Camera & Media Upload Pipeline, Multi-Type Feed & Ward Talk Channels, Search & Advanced Filters, Map Pins Engine, Notifications, Representative Dashboard, Gamification Engine, and Admin Flagging/Moderation Queue.
- **App**: Flutter client with Riverpod 2.6 & go_router 17. Features shipped: Onboarding Carousel, Live Auth & GuestGuard, Social Feed Cards (Issues, Wins, Notices, Local Talk), Interactive Map Canvas & Pins, Compose Wizard with Offline Outbox & Camera/Gallery Capture, Threaded Comments, Ward Place Pages, Notifications Center & Inbox Digest, Representative Dashboard, Gamification Screen (Impact Score & Badges), Profile & 5-Language i18n (`en`, `hi`, `mr`, `ta`, `te`), Admin Moderation Queue, Toast Overlay, Offline Banner, Error Boundary, and Deep Linking (`locallens://`). `flutter analyze` clean.

## Next steps

- Production SMS gateway & FCM/APNS external push notification service integration.
- Refresh token rotation & secure OS keychain/keystore token persistence.
- Auto-suggest merge-link flow for duplicate reports & mini-map pin selector in compose.
- Live ticking countdown renderers on escalation timeline & dispute photo uploads.
- Vector pin clustering SDK for high-density spatial map rendering.
- Offline sync conflict resolution strategy & image vector similarity for duplicate detection.
