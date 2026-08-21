# LocalLens — Codebase Map

One-page map of where everything lives. **Read this when starting a task, then open only
the files it points you to.** If a feature you need isn't listed here, ask — don't explore.

---

## Request flow (how to find code fast)

- **Backend** request → `app/main.py` (factory, rate limiters) → `app/api/router.py`
  (all routers under `/api/v1`) → `app/features/<name>/router.py` → `service.py`
  (business logic) → `models.py` (SQLAlchemy). Errors raised as `AppError` in
  `app/core/exceptions.py` → JSON envelope. Dependencies: `app/api/deps.py`
  (`SessionDep` = async DB session, `SettingsDep` = settings).
- **App** screen → declared in `app/lib/core/router/app_router.dart` using
  `RoutePaths` constants (`app/lib/core/router/route_paths.dart`) → the screen widget
  reads a Riverpod provider/controller in `features/<name>/presentation/` → which calls
  the repo/api in `features/<name>/data/`. Models live in `features/<name>/domain/`.
- **Shared plumbing**: Dio client `app/lib/core/network/api_client.dart` (auth header,
  401/403 handling), Hive storage `app/lib/core/storage/local_store.dart`, theme
  `app/lib/core/theme/`, i18n `app/lib/core/l10n/`.

## Features (folder exists on both sides unless noted)

| # | Feature | Backend `app/features/<name>/` | App `lib/features/<name>/` | Main endpoints (prefix `/api/v1`) |
|---|---------|-------------------------------|---------------------------|-----------------------------------|
| F-01 | Core shell & infra | `app/core/*`, `app/main.py` | `lib/core/*`, `lib/app.dart`, `lib/main.dart`, `lib/shared/` | `/health` |
| F-02 | Auth & anonymous ID | `auth/` (models, router, schemas, service) | `auth/` (data/auth_api.dart, auth_repository.dart, domain/session.dart, presentation/) | `/auth/otp/request`, `/auth/verify-otp`, `/auth/email/request-otp`, `/auth/email/verify-otp`, `/auth/guest`, `/auth/me`, `/users/{id}` |
| F-03 | Spatial & geo | `geo/` + `issues/geo.py` + `issues/geohash.py` + `wards/models.py` | `geo/` (geo_api.dart, device_location_service.dart, geo_providers.dart, ward_location_chip.dart) | `/geo/reverse-geocode`, `/geo/map-pins` |
| F-04 | Issue model & compose | `issues/` (models, service, schemas, router) | `compose/` (compose_screen.dart, compose_controller.dart, draft_store.dart, offline_outbox_queue.dart, media_library_screen.dart) | `POST /issues`, `GET /issues/near-duplicate`, `DELETE /issues/{id}` |
| F-05 | Camera & media integrity | `media/` (models, router, schemas, service) | `compose/presentation/widgets/camera_viewfinder.dart`, `compose/data/media_service.dart`, `media_watermark_badge.dart` | `POST /media/upload` (mounted at `/api/v1/media` in main.py) |
| F-06 | Feed & discovery | `feed/` (router, schemas, service) | `feed/` (feed_screen.dart, feed_providers.dart, feed_api.dart, issue_card.dart, win_card.dart, notice_card.dart, local_talk_card.dart) | `GET /feed` |
| F-07 | Escalation & quorum | `issues/service.py` (escalation/quorum fns) | `issue_detail/` (issue_detail_screen.dart, issue_detail_controller.dart, issue_detail_api.dart) | `POST /issues/{id}/acknowledge`, `/resolve`, `/quorum-vote`, `/check-quorum-status`, `/wins` |
| F-08 | Map & search | `search/` + `core/ratelimit.py` + `issues/geo.py` | `map/` (map_screen.dart, map_controller.dart, map_api.dart), `search/` (search_screen.dart, search_providers.dart, advanced_filter_sheet.dart) | `GET /search`, `GET /issues?lat&lng&radius_km` |
| F-09 | Local talk & wards | `wards/` (models, router, schemas, service) + `issues` comment code | `ward/` (ward_detail_screen.dart, wards_list_screen.dart, ward_providers.dart), `issue_detail/presentation/widgets/comments_*.dart` | `GET /wards`, `GET /wards/{slug}`, `POST/GET /wards/{slug}/talk`, `POST/GET/DELETE /issues/{id}/comments` |
| F-10 | Notifications & inbox | `notifications/` (models, router, schemas, service) | `notifications/` (notifications_screen.dart, notifications_controller.dart, notifications_api.dart), `inbox/presentation/inbox_screen.dart` | `GET /notifications`, `PATCH /notifications/{id}/read`, `POST /notifications/read-all` |
| F-11 | Representative dashboard | `representatives/` (models, router, schemas, service) | `rep_dashboard/` (rep_dashboard_screen.dart, rep_dashboard_providers.dart, rep_dashboard_repository.dart) | `GET/POST /representatives/...` |
| F-12 | Gamification | `gamification/` (models, router, schemas, service) | `gamification/` (gamification_screen.dart, gamification_providers.dart, gamification_api.dart) | `GET/POST /gamification/...` |
| F-13 | Profile, settings, i18n | `auth/router.py` (`GET /auth/me`) | `profile/` (profile_screen.dart, edit_profile_screen.dart, settings_screen.dart, public_profile_screen.dart), `core/l10n/`, `core/theme/` | — |
| F-14 | Flagging & moderation | `issues/` (flag/moderation code) + `auth/models.py` (`BannedAnonIdentity`) | `issues/presentation/widgets/flag_issue_dialog.dart`, `admin/` (admin_flagged_queue_screen.dart, admin_flagged_queue_provider.dart) | `POST /issues/{id}/flag`, `GET /admin/flagged-issues`, `POST /admin/issues/{id}/moderate` |

## Not in a feature folder (cross-cutting)

- **Offline outbox / sync**: `app/lib/features/compose/data/offline_outbox_queue.dart`,
  `app/lib/core/network/offline_sync_worker.dart`, `app/lib/features/outbox/presentation/outbox_screen.dart`.
- **Onboarding & reels**: `app/lib/features/onboarding/presentation/screens/onboarding_screen.dart`,
  `app/lib/features/reels/presentation/reels_screen.dart`.
- **Auth plumbing**: `app/lib/features/auth/presentation/widgets/guest_guard.dart`,
  `app/lib/features/auth/presentation/auth_providers.dart`.
- **Data seeding**: `backend/seed.py` reads `seed/data/*.json` + `seed/media/`. DB snapshot
  sync: `backend/app/core/data_sync.py` (apply/export via `make sync-db` / `make sync-export`).

## Tests

- Backend: `backend/tests/` — `test_<area>.py` at root + `backend/tests/features/<name>/`.
- App: `app/test/features/<name>/..._test.dart`, `app/test/core/`, `app/test/shared/`,
  helpers in `app/test/helpers.dart`.
- New backend code → test in `tests/features/<name>/test_*.py`. New app code → test in
  `test/features/<name>/`. Don't add tests for code you're not asked to touch.

## Seed data cheat-sheet (for debugging)

- Ward 45, Mumbai (fallback coords 19.1136/72.8697). 19 issues covering all 7 categories
  × statuses. Log in with any phone + OTP `000000`. Admin queue: seed includes flagged items.