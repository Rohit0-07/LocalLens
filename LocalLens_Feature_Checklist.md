# LocalLens: Hyper-Granular Feature Checklist (Refined v2)

This document serves as the master development, QA, and AI agent tracker for the LocalLens platform. It breaks down the application into atomic, hyper-granular features covering UI/UX, Backend logic, Database schemas, Edge Cases, and Hardware integrations.

Legend: `(NEW)` = added in v2 · `(R)` = revised in v2 · `(X)` = removed in v2 (why).

## Progress status (2026-08-09)

- [x] **Backend foundation**: FastAPI + SQLAlchemy 2 (async) + Alembic under `uv`; feature-first layout (`auth`, `issues`); ruff + mypy-strict clean; 19 pytest tests green.
- [x] **Auth (client + server)**: phone & email OTP request/verify → JWT (`POST /auth/otp/request`, `POST /auth/email/request-otp`, `POST /auth/email/verify-otp`, `POST /auth/guest`, `GET /auth/me`); Bearer-attach dio interceptor; HMAC anonymous-identity derivation; Guest session & 403 write guard interceptor; 60s resend timer.
- [x] **Feed (client + server)**: `GET /issues?lat&lng&radius_km&limit&offset` (bbox + haversine, shielded filtered out, escalation re-evaluated on read); pull-to-refresh, skeleton loader, empty/error states on the client.
- [x] **Issue card & detail**: status badge, relative time, category/fuzzed/shielded chips, ward label, escalation hints; detail view with escalation-ladder timeline + four-stage quorum resolution UI.
- [x] **Compose (client + server)**: draft form (title/desc/category + anonymous/fuzz/shield toggles), hive auto-save + resume/discard, `POST /issues` with fuzz rounding, offline outbox queue + toast, near-duplicate guard via `GET /issues/near-duplicate`.
- [x] **Escalation / quorum backend**: `POST /acknowledge`, `/resolve`, `/quorum-vote` (proximity + duplicate guard, ≥3 confirm → resolved), `/check-quorum-status` (7-day expiry → disputed), `/evaluate-escalations`, `POST /upvote` (5 km radius + 5-per-10-min rate limit).
- [x] **App shell**: Riverpod 2.6 + go_router 17 `StatefulShellRoute` (4 tabs + center compose FAB, tab state preserved), theme provider (light/dark/system), typography + color tokens, skeleton/shared widgets.
- [x] **App shell infra (2026-08-09 via `F-01`)**: global toast system, injectable network listener, persistent offline-mode banner, and global error boundary — all wired in `AppInfrastructure`; 22 new Flutter tests; frontend-only, backend untouched.
- [x] **Email Auth & Guest Mode (2026-08-09 via `F-02`)**: Email OTP request/verify (client + server), Guest session creation (`POST /auth/guest`) & token persistence, 60-second Resend OTP countdown timer, GuestGuard dialog interceptor for restricted actions (issues, upvotes, quorum), full backend (60 pytest) & frontend (52 flutter) test suite.
- [x] **User Profile, Settings & Localization UX (2026-08-09 via `F-13`)**: Complete Material 3 `ProfileScreen` with user avatar/mask icon, `anon_id` chip, guest session banner, and 3-metric activity stats card (issues, upvotes, quorum); persistent `ThemeMode` selector (system, light, dark); persistent `AppLocale` selector (`en`, `hi`, `mr`, `ta`, `te`); `AnonymityGuideScreen` detailing zero-retention HMAC derivation, fuzzed locations, and shielded mode; backend `GET /auth/me` returning live user activity metrics; full test suite (66 pytest and 58 flutter tests green).
- [x] **Threaded Comments & Discussion (2026-08-10 via `F-09` subset)**: Complete Threaded Comments backend (`POST /issues/{id}/comments`, `GET /issues/{id}/comments`, `DELETE /issues/{id}/comments/{comment_id}`) & frontend (`CommentsSection`, `CommentCard`, Riverpod `commentsProvider`); `GuestGuard` write protection (403 for guest users), rate limiting (10 comments per 5 min), profanity/toxicity sanitization, HMAC zero-retention `anon_id` identity badges, nested reply threads, and updated issue card comments counter.
- [x] **Notifications & Inbox Engine (2026-08-10 via `F-10`)**: Complete Notifications backend (`Notification` async model, `GET /notifications`, `POST /notifications/read-all`, `PATCH /notifications/{id}/read` with user isolation & unread filtering) & frontend (`NotificationsApi`, `NotificationsNotifier`, `unreadNotificationCountProvider`, M3 `NotificationsScreen` with filter chips, type icons, unread badge dots, pull-to-refresh, skeleton & empty states, `InboxScreen` activity digest, bottom nav unread badge); full test suite (90 pytest and 76 flutter tests green).
- [x] **Search & Explore (2026-08-10 via `F-08` search subset)**: Backend `GET /api/v1/search` — keyword match across title/description/category/ward (SQL-parameterized `.ilike` with `%`/`_`/`\` escaping = SQLi-safe), optional proximity (bbox + haversine, `radius_km`), optional `status`/`category` filters, `limit`/`offset` pagination, shielded-non-resolved excluded, shared `SlidingWindowRateLimiter` (60/min keyed per user/`anon`), `OptionalUser`/guest allowed, feed-parity `IssueOut` serialization, geo helpers promoted to `features/issues/geo.py`. Frontend: `SearchScreen` (`Key('searchField')`, 400 ms debounce, skeleton/error/empty/results states, shared `IssueCard` reuse), Hive-persisted recent searches (`recent_searches`, max 5, dedupe, `Key('clearRecentSearches')`), `/search` route + Feed app-bar search icon. Validated PASS (25 backend + 18 frontend search tests; full suite **115 pytest / 94 flutter green**, ruff + mypy + flutter analyze clean). Map view still placeholder.
- [x] **Advanced Search Filters (2026-08-10 via `F-08` filters subset)**: Backend extended `GET /api/v1/search` with `categories` (repeatable, ≤20, each ≤32 chars, else 422 `invalid_category`), `created_after`/`created_before` (ISO-8601 → naive UTC; 422 `invalid_date_format`/`invalid_date_range` when after>before), `parse_iso_datetime` helper, parameterized/SQLi-safe `category.in_` + `created_at >=/<=` filters applied before ordering/escalation/shielded-exclusion/haversine (behavior unchanged). Frontend: `SearchFilters` model + `SearchDatePreset`/`SearchDistanceOption` enums, `SearchFiltersNotifier` provider, `AdvancedFilterSheet` (7 status chips single-select, 7 category chips multi-select, `SegmentedButton` any/within + 1–50 km slider, 4 date presets, Reset/Show results), screen wiring with `filterButton`/`clearFiltersButton` keys and active `Badge`, `runQuery` passing filters with area default 19.1136/72.8697. Validated PASS (22 backend + 16 frontend new tests; full suite **176 pytest / 133 flutter green**, ruff + mypy clean, flutter analyze clean under lib). 2 non-blocker defects found and resolved post-validation (SegmentedButton alignment + interfaces regeneration).
- [x] **Representative Dashboard & Governance Tools (2026-08-10 via `F-11`)**: Complete Representative Dashboard backend (`Representative` & `OfficialResponse` models, `GET /representatives/me`, `GET /representatives/dashboard`, `POST /issues/{id}/official-response`, `GET /issues/{id}/official-response`, ward verification & ward boundary access control) & frontend (`RepDashboardScreen` with triage tabs, ward metric cards, issue triage list with priority chips, official response dialog, `OfficialResponseCard` on issue detail, Riverpod `repDashboardNotifierProvider` & `officialResponseProvider`); full test suite (124 total backend with 9 F-11 pytest cases green, 100 total frontend with 6 F-11 Flutter widget cases green).
- [x] **Gamification Engine (2026-08-10 via `F-12`)**: Complete Gamification Engine backend (`UserGamificationProfile`, `UserBadge` models, `GET /gamification/me`, `POST /gamification/claim-daily-streak`, `GET /gamification/badges`, impact score calculation, 5 civic levels, UTC daily streak rollover, 5 dynamic civic badges) & frontend (`GamificationApi` with Hive offline caching, `GamificationScreen` with Impact Score card, Level progress bar, Daily Streak banner & claim button, Badges grid, Riverpod `gamificationNotifierProvider` & `badgeCatalogProvider`, GuestGuard dialog integration); full test suite (154 total backend with 30 F-12 pytest cases green [20 contract + 10 security], 115 total frontend with 15 F-12 Flutter widget cases green).
- [x] **Issue Flagging & Moderation System (2026-08-10 via F-14-FLAG)**: Complete content flagging backend (POST /api/v1/issues/{id}/flag with categories, details, duplicate flag guard, rate limiting 5 flags/10 min, guest user 403 restriction), admin moderation queue (GET /api/v1/admin/flagged-issues with pagination & status filters), admin moderation actions (POST /api/v1/admin/issues/{id}/moderate for dismiss/hide_issue/ban_reporter with audit notes) & frontend (IssueCard overflow menu with Key('issueCardOverflow_<id>') & Key('flagIssueOption_<id>'), FlagIssueDialog with Key('flagIssueDialog'), Key('flagCategorySelect'), Key('flagDetailsInput'), Key('submitFlagButton'), AdminFlaggedQueueScreen with Key('adminQueueFilterSelect'), Key('moderateAction_<id>'), Riverpod flagIssueNotifierProvider & adminFlaggedQueueProvider, GuestGuard modal interceptor, Hive local store box 'flagged_issues' caching user_flagged_issue_ids); full test suite (191 pytest and 141 flutter tests green).
- [x] **Ward Place Page & Civic Summary Engine (2026-08-10 via F-09-WARD)**: Complete Ward Place Page backend (`GET /api/v1/wards/{ward_slug}`, `GET /api/v1/wards`, ward health summary metrics, assigned representative integration, recent ward issues feed) & frontend (`WardDetailScreen`, `WardHeroBanner`, `WardMetricCard`, `WardRepCard`, `WardRecentIssuesList`, Riverpod `wardDetailProvider`, `wardListProvider`, `WardRepository`); full test suite (209 total backend pytest suite with 18 F-09-WARD green, 152 total frontend flutter test suite with 11 F-09-WARD green).
- [x] **Reverse Geocoding & Ward Boundary Lookup (2026-08-10 via F-03 subset)**: Backend `GET /api/v1/geo/reverse-geocode` — ward resolved from lat/lng by centroid distance (Haversine, `radius_km` optional), read-only, no auth required, no external geocoder, global 422 `invalid_coordinates` envelope (`code`/`error_code` keys) via `validation_error_handler` for `/geo/` paths. Frontend: `GeoApi` flat `ReverseGeocode` model, `DeviceLocationService` abstraction (reference coords 19.1136/72.8697, no GPS plugin), Riverpod `wardLocationProvider` (`WardLocationController`, sealed `WardLocationState`: loading/unavailable/success), presentational `WardLocationChip` (success `Key('wardLocationChip')` → navigates to ward detail, `Key('wardLocationUnavailable')`, `Key('wardLocationOutsideCoverage')`), surfaced on Compose app bar (`Key('composeLocationChip')`) and Feed app bar (`Key('feedAreaLabel')`); no maps/polygons/geofencing in this subset. Validated PASS (23 backend geo + 21 frontend geo tests incl. 2 screen-integration; full suite **232 pytest / 175 flutter green**, ruff + mypy + flutter analyze clean).
- [ ] **Not started / placeholder only**: onboarding carousel, camera & media pipeline (EXIF, watermarks), real map & clustering, wins/notices/local-talk, push/SMS providers, conflict-resolution sync, anomaly detection.

---

## 1. App Shell, Theming & Global States
- [x] Initialize cross-platform project (Flutter) with strict linting rules. *(app/ created, `flutter_lints` + `analysis_options.yaml`, `flutter analyze` clean.)*
- [x] Implement global ThemeProvider (Light Mode, Dark Mode, System Auto). *Provider + theme applied; **no user-facing selector yet** — default is `ThemeMode.system`.**
- [x] Define global typography scale and color palette tokens. *(`app_theme.dart`, `app_colors.dart`.)*
- [x] Build global Snackbar/Toast notification system for transient alerts. *(`appMessengerProvider` queue w/ dedupe + typed auto-dismiss + `ToastOverlay`; wired via `AppInfrastructure` overlay.)*
- [x] Implement Global Network Listener (detects Online/Offline transitions). *(`connectivity_plus`-backed `connectivitySourceProvider` → `networkStatusProvider`; injectable for tests.)*
- [x] Build persistent "Offline Mode" banner UI (appears when connection drops). *(`OfflineBanner`, M3 `errorContainer` tokens, no emoji/gradients.)*
- [x] Implement Global Error Boundary to catch UI crashes. *(`ErrorBoundary`/`SafeFallback` mounted in `AppInfrastructure`; global `FlutterError`/`PlatformDispatcher` handlers in `main.dart`; fallback never leaks exception details.)*
- [x] Setup local token storage — Hive (hive_ce) session/drafts boxes. *(Not yet keychain/keystore-backed secure storage; no refresh token.)*
- [x] Configure deep linking handling (URI schemes & Universal Links) — deep links into Issue, Local Talk post, Rep Page, Win (`locallens://`).
- [x] Create skeleton loading animations for list views. *(`shared/widgets/shimmer_loading.dart` — custom ShimmerLoading gradient sweep animation overlay).*
- [ ] (NEW) App locale manager: per-locale font/script support (Devanagari, Tamil, Telugu, etc.) with locale-aware placeholder text everywhere.

## 2. Onboarding & Registration Flow
- [ ] Build Animated Splash Screen (App Logo + Loading indicator). *(app boots straight to sign-in/feed.)*
- [x] Build 5-page interactive Onboarding Carousel: value proposition ("See what's wrong"), impact ("Your upvotes are civic signals"), anonymity promise ("We can't reveal you, even if we tried"), daily ritual ("Street Check"), and Win-loop ("Every fix is celebrated"). *(`onboarding_screen.dart` with `onboardingNextButton`, `skipOnboardingButton`, `onboardingPageIndicator`.)*
- [x] Implement "Skip Onboarding" logic (saves flag `has_completed_onboarding` to local storage Hive session box).
- [x] Build Auth Landing Screen with "Login via Phone", "Login via Email", and "Guest Mode". *(SignInScreen SegmentedButton switcher + Continue as Guest button.)*
- [ ] **Phone Auth Flow:**
  - [ ] Implement Phone Input UI with searchable Country Code dropdown. *(Single `TextField`; user types `+91 …` — no dropdown.)*
  - [x] Client-side validation: numeric-only input formatter + `E164`-ish regex (`^\+[1-9][0-9]{6,14}$`).
  - [x] API Integration: `POST /auth/phone/request-otp`. *(wired to `/auth/otp/request`, 204.)*
  - [x] Loading state on "Send OTP" button.
  - [ ] Error handling: surface specific errors ("Rate limit exceeded", "Invalid number", etc.). *(Generic message now; `ApiServerException` mappings exist but not surfaced distinctly.)*
  - [x] Build OTP 6-digit split input UI (auto-advances focus; backspace). *(`otp_field.dart`.)*
  - [x] Implement 60-second Resend OTP countdown timer. *(`_startResendTimer` in `SignInScreen` / `OtpScreen`.)*
  - [x] API Integration: `POST /auth/phone/verify-otp`. *(wired to `/auth/otp/verify`.)*
  - [ ] Android-specific: integrate SMS Retriever API for auto-reading OTP.
- [x] **Email Auth Flow:**
  - [x] Implement Email Input UI with standard regex validation. *(`_emailPattern` regex in `SignInScreen`.)*
  - [x] API Integration: `POST /auth/email/request-otp`. *(`AuthRepository.requestEmailOtp`.)*
  - [x] Build Email OTP Verification UI. *(`AuthRepository.verifyEmailOtp`.)*
- [x] **Guest Mode Flow:**
  - [x] Implement "Continue as Guest" logic (generates anonymous local session via `POST /auth/guest`).
  - [x] Build "Sign in required" bottom-sheet interceptor for restricted actions. *(`GuestGuard` dialog widget + 403 authorization guard on `POST /issues`, `/upvote`, `/quorum-vote`.)*
  - [ ] Guest feed shows digest of "previous activity in this area".
- [ ] **Session & Token Management:**
  - [ ] Store JWT Access Token + Refresh Token securely. *(Access token only, in Hive — partial.)*
  - [x] Implement HTTP interceptor to attach Access Token automatically. *(dio `_AuthInterceptor`.)*
  - [ ] Implement automatic silent token refresh on 401.
  - [ ] (R) Device & session trust registry; **no multi-account switcher**.
  - [x] (NEW) One-way anonymous identity derivation: backend HMAC `derive_anonymous_identity(user_id, secret)` → `anon_id` via `/auth/verify` and `/me`. *(No inversion path or admin UI.)*
  - [ ] Secure logout logic (clears storage; server-side token revocation not implemented).

## 3. Core Navigation Architecture
- [x] Implement Bottom Navigation Bar. *(Design deviation from "5 tabs": app ships **4 tabs** (Home/Map/Inbox/Profile) + **center FAB** for Create per v2 design.)*
- [ ] Define custom active/inactive SVG icons for each tab. *(Material Icons currently.)*
- [x] Build Tab Router logic preserving state of individual tabs. *(`go_router` `StatefulShellRoute.indexedStack`.)*
- [x] Implement central FAB for the "Create" action → opens compose route.
- [x] Configure nested stack navigators for each tab. *(Shell branches + pushed routes for compose / issue detail.)*
- [ ] Implement custom page transition animations (slide, fade).
- [x] (NEW) Ward "Place Page" entry point (Home header chip, Map, Rep page, router `/ward/:slug`).

## 4. Home Feed Engine & Post Discovery (v2: problems + progress)
- [x] Build Feed Container UI with Pull-to-Refresh.
- [x] Implement Feed Skeleton Loaders while `GET /feed` pending.
- [x] **API Integration:** `GET /feed`. *(Implemented as `GET /api/v1/feed` supporting bbox+haversine, cursor pagination, and type filtering.)*
- [x] (R) Feed mixes post types: `issue`, `win`, `notice`, `local-talk` + type-chip filters (`Key('feedFilterChip_all')`, `Key('feedFilterChip_issues')`, etc.).
- [x] Implement infinite scrolling (cursor pagination, fetch next page).
- [x] Handle "End of Feed" state ("You're all caught up!", `Key('endOfFeedState')`).
- [x] Handle "Empty Feed" state. *(EmptyState: "All clear around here" / "Be the first to report an issue in your area".)*
- [ ] **Issue Card Component:**
  - [x] Header: Jurisdiction text — ward label chip ("Ward 45, Urban Central").
  - [x] Header: Timestamp in relative form ("2h ago" via `relative_time.dart`).
  - [x] Header: Status Badge UI (color-coded; `status_badge.dart`).
  - [x] Header: Anonymous-mask avatar icon works. *(Anonymous → mask icon + "Anonymous"-style `reporterLabel`.)*
  - [x] Header: Author display name / "Anonymous".
  - [x] Body: Issue title — bold, `maxLines: 2`, ellipsis.
  - [x] Body: caption snippet. *(2-line ellipsis; **no "Read More"** expander yet.)*
  - [x] Body: Category tags as chips (`#road`, `#water`, …).
  - [x] Media: image carousel, pagination dots, verified/unverified watermark overlay (`MediaWatermarkBadge`).
  - [x] Footer: upvote button/state toggle.
  - [x] Footer: upvote counter.
  - [x] Footer: comment button + counter.
  - [x] Footer: share button (OS share sheet w/ deep link `locallens://`).
  - [x] Footer: three-dot overflow (Flag, Copy link).
  - [x] Footer: (NEW) escalate-banner slot — inline status hint (`🔥 Escalating`, `⚡ Forwarded`, `👥 Quorum`) rendered when applicable.
- [x] **Win Card (NEW)** — `WinCard` widget (`Key('winCard_<id>')`) with before/after media slider, contributor credits, and celebration banner.
- [x] **Notice Card (NEW)** — `NoticeCard` widget (`Key('noticeCard_<id>')`) with official notice header and validity time.
- [ ] **Interactions:**
  - [x] Optimistic upvote (instant UI, background sync).
  - [x] Upvote API call sync with error state rollback & toast notification.
  - [x] (R) Server-side upvote validation: authenticated user + **5 km proximity** + **rate-limit (max 5 per 10 min)** + **duplicate guard** + **un-upvote endpoint**. *(Anomaly/brigade detection pending.)*

## 5. Camera, Hardware & Media Pipeline (v2: privacy + speed)
- [x] Build OS Permission Manager (Camera, Storage, Location).
- [x] Handle "Permission Denied" states (show settings link).
- [x] Implement custom Full-Screen Camera Viewfinder (`camera_viewfinder.dart`).
- [x] Build Camera Controls (Shutter `Key('shutterButton')`, Flip `Key('cameraFlipButton')`, Flash `Key('flashToggleButton')`, GPS lock `Key('gpsLockStatus')`).
- [x] Media Integrity Engine — GPS-lock-before-shutter, EXIF + backend-cryptographically-signed hash (`derive_media_hash`), "LocalLens Verified" vs "Unverified" watermark badge (`MediaWatermarkBadge`).
- [x] Location Privacy (fuzz toggle at capture, block-level precision rounding).
- [x] Shield Mode capture (sensitive categories).
- [x] Gallery import (picker up to 4 images `Key('galleryPickerButton')`, EXIF parse, "User Uploaded - Unverified" badge).
- [x] Cropper / rotator; client-side compression (1920×1080, ~80%).
- [x] (NEW) Hair-trigger capture (offline-first shutter, GPS last-fix buffer).

## 6. Draft Composer & Post Publishing (v2)
- [x] Build Post Creation Wizard (single scrollable form, `compose_screen.dart`).
- [ ] **Location step:** mini-map GPS lock, manual-pin fallback, fuzz ward-level map. *(Partial — `GET /api/v1/geo/reverse-geocode` shipped 2026-08-10 via F-03 subset; compose still uses `defaultLatitude/defaultLongitude` for the draft.)*
- [ ] **Duplicate Guard:**
- [x] API Integration: `GET /issues/near-duplicate` — backend detection (bbox + haversine, `distance_meters`), backend-only.
- [x] "Guarded" sheet: compose "Check for Near-Duplicates" button → bottom sheet lists "…m away" candidates.
- [ ] Merge-link flow (auto-suggest merge, redirect upvotes/comments) — pending.
- [ ] **Form Inputs:**
  - [x] Title Input char counter (max 100).
  - [x] Description textarea counter (max 1000).
  - [x] Category selector chips (road/water/power/lighting/waste/sewage/other).
  - [x] Privacy: three switches for **Anonymous / Fuzz location / Shield** (equals segmented picker but not a single segmented control).
  - [ ] Post Type selector (Issue / Local Talk / Win) — issues only.
- [ ] **Local Drafts Engine:**
  - [x] Auto-save on every keystroke to Hive (`ComposeController.update` → `DraftStore.save`).
  - [ ] "Drafts" list UI in Profile.
  - [x] Resume / delete draft (persist via hive; discard button).
- [ ] **Publishing Pipeline:**
  - [x] Media upload to object storage. *(No media yet.)*
  - [x] API: `POST /issues` (create) — wired `FeedApi.createIssue` + controller.submit.
  - [ ] Step 4 success animation — only a SnackBar + navigation + feed invalidate.
- [ ] **Offline Publishing Queue:**
  - [x] Save `PendingUploads` to Hive outbox when offline (`OfflineOutboxQueue.enqueue`).
  - [x] "Saved to Outbox — will upload when online" toast.
  - [x] Flush worker method exists (`flush()` retries remaining); not yet attached to a reconnection crawl/Workmanager.
- [ ] (NEW) "Report for someone" assisted capture flow — not started.

## 7. Search, Explore & Interactive Map View
- [x] Search bar + debounce (400 ms) + recent searches. *(`SearchScreen` at `/search`, `Key('searchField')`, Hive recents `recent_searches` max-5 dedupe, `Key('clearRecentSearches')`; entry via Feed app-bar search icon.)*
- [x] `GET /search` *(implemented as `GET /api/v1/search?q&latitude&longitude&radius_km&status&category&limit&offset`; title/description/category/ward `.ilike` match with `%`/`_`/`\` escaping; shield-filtered out; rate-limited 60/min; guest allowed; returns `IssueOut`.)*
- [x] Advanced filters sheet (status/category/type/date/distance) — `AdvancedFilterSheet` UI + backend `GET /api/v1/search` parameters (`categories`, `created_after`, `created_before`).
- [x] Map SDK, custom styling, bbox fetch, clustering, custom pins, peek sheet, "Search this area" — `MapScreen` with interactive map canvas (`Key('mapPin_<id>')`), `MapPinPreviewSheet` (`Key('mapPinPreviewSheet_<id>')`), `Key('searchThisAreaButton')`, backend `GET /api/v1/geo/map-pins`.

## 8. Issue Detail, Audit Trail & Quorum Resolution
- [x] Full-screen issue detail (`issue_detail_screen.dart`): header, title, description, tags, escalation ladder, quorum card; skeleton/error/retry states; fetched via `GET /issues/{id}`.
- [x] Header: author info, anonymous mask, ward, relative time, status badge. *(Follow/Mute buttons pending.)*
- [x] **Audit Timeline UI:** vertical timeline (`_EscalationLadderWidget`, 4 nodes: Reported → Escalating (24–72h) → Forwarded (>7d) → Quorum).
- [x] (R) Escalation ladder nodes + server re-evaluates status on read (`evaluate_escalation`).
- [ ] (NEW) Live countdown renderers (24h/72h/7d) — steps labeled but no timer.
- [ ] (NEW) Authoritative trace for Win posts (linked resolution proof media + contributors) — not started.
- [x] **Quorum-Backed Resolution (R):**
- [x] Authority "Submit Resolution" → dialog (proof URL + notes) → `/resolve` → `pending_quorum` (7-day expiry).
- [x] Reporter "Confirm Fix" / "Dispute Fix" buttons.
- [x] Quorum progress (`x/3` + `LinearProgressIndicator`).
  - [x] Backend rules: proximity 5 km, one vote per user, ≥3 confirms → resolved, ≥1 dispute → disputed, expiry <7d → disputed.
  - [ ] Neighbor nudge ("Did this get fixed for you too?") prompt — not implemented.
  - [ ] Dispute form (reason chips + photo option) — dispute is a one-tap vote today.
  - [ ] Double-claim abuse guard (48 h cooldown) — not enforced.
  - [x] (R) Win-generation on resolution — auto-generates `Win` post with before/after photos and contributor credits upon 3rd quorum confirm vote (`GET /api/v1/wins`).
- [x] **Threaded comments** — completed (`POST /issues/{id}/comments`, `GET /issues/{id}/comments`, `DELETE /issues/{id}/comments/{comment_id}`, `CommentsSection` & `CommentCard` M3 UI, Riverpod `commentsProvider`, GuestGuard dialog, profanity/toxicity sanitization, rate limiting, HMAC zero-retention identity badges).
- [x] **Ward Place Page & Civic Summary Engine** — completed (`GET /api/v1/wards/{ward_slug}`, `GET /api/v1/wards`, ward metrics summary, top contributors, active notices, assigned representative card, M3 `WardDetailScreen`, `WardHeroBanner`, `WardMetricCard`, `WardRepCard`, `WardRecentIssuesList`, Riverpod `wardDetailProvider`, `wardListProvider`).

## 9. Inbox, Messaging & Service Notices
- [x] Inbox tab layout — `inbox_screen.dart` with notifications summary digest and civic activity stream.
- [x] Bell icon → `notifications_screen.dart` holding full Material 3 notification center.
- [ ] Broadcasts, Street Check Digest, offline messenger queue — **pending later increments**.

## 10. Notifications Engine
- [x] Notifications Data Model: SQLAlchemy `Notification` model with UUID `id`, `user_id`, `title`, `body`, `type` (`escalation`, `quorum_request`, `upvote_milestone`, `comment_reply`, `system_notice`), `reference_id`, `is_read`, and `created_at`.
- [x] Backend Endpoints: `GET /notifications` (unread filter, pagination, user isolation), `POST /notifications/read-all` (batch read), `PATCH /notifications/{id}/read` (single read update with 404 user boundary guard).
- [x] Frontend API & State: Dio `NotificationsApi`, Riverpod `NotificationsNotifier` & `unreadNotificationCountProvider`.
- [x] Notification UI: Material 3 `NotificationsScreen` with filter chips (All / Unread), type icons, unread badge dots, header "Mark all read" action, pull-to-refresh, skeleton loaders, empty state, and guest guard.
- [x] Bottom Nav Unread Badge: Inbox tab displays unread counter badge.
- [ ] FCM/APNS push notifications & quiet-hours schedule — **pending push provider integration**.

## 11. User Profile, Privacy & Settings
- [x] User Profile Screen (`profile_screen.dart`): Avatar/Mask header, `anon_id` chip, guest banner, 3-metric activity stats card (issues, upvotes, quorum).
- [x] Theme Selector: persistent Light Mode, Dark Mode, System Auto selection (`themeModeProvider`).
- [x] App Locale Manager: per-locale script/language selection (`en`, `hi`, `mr`, `ta`, `te`) (`appLocaleProvider`).
- [x] Privacy & Anonymity Guide (`anonymity_guide_screen.dart`): zero-retention HMAC identity derivation, block-level location fuzzing, shielded mode education.
- [x] Backend Profile API: `GET /auth/me` returning `issues_count`, `upvotes_count`, `quorum_votes_count` and user/guest metadata.

## 12. Representative Dashboard & Governance Tools (Special User Roles)
- [x] Backend Representative Data Model & API: `Representative` & `OfficialResponse` SQLAlchemy models, `GET /representatives/me` (rep profile & verified status), `GET /representatives/dashboard` (ward issue metrics, priority triage queue, status filters), `POST /issues/{id}/official-response` (publish official response with status update: acknowledged or in_progress, ward boundary enforcement, single response limit), `GET /issues/{id}/official-response` (public retrieval of official response).
- [x] Frontend Representative Dashboard UI: M3 `RepDashboardScreen` (`repDashboardScreen`, `repProfileName`, `repProfileWard`), ward metric chips (`metricTotalWardIssues`, `metricEscalatedIssues`, `metricAcknowledgedIssues`), issue triage tabs (`wardFilterChip_all`, `wardFilterChip_escalated`, `wardFilterChip_in_progress`, `wardFilterChip_acknowledged`), priority issue cards (`triageIssueCard_<id>`), post response dialog (`postOfficialResponseDialog`, status dropdown, message input field).
- [x] Official Response Card UI: Public `OfficialResponseCard` (`officialResponseCard_<id>`) embedded on `IssueDetailScreen` showing verified rep blue-tick badge, representative name, official response message, timestamp, and updated status badge.
- [x] Access Control & Ward Boundary Enforcement: Representative verification check (403 for non-representatives) and Ward matching check (403 when trying to access or respond to issues outside assigned ward).

## 13. Gamification Engine
- [x] Impact Score Formula & Level Calculation: `(resolutions * 15) + (upvotes * 2) + (quorum_votes * 5) + (streaks * 3)` dynamically evaluated into 5 civic levels (Civic Rookie, Neighborhood Scout, Community Sentinel, District Champion, Civic Legend).
- [x] Daily Street Check Streak Engine: `POST /api/v1/gamification/claim-daily-streak` with 24-hour window validation, UTC calendar day rollover, consecutive streak tracking, and bonus point awards.
- [x] Dynamic Civic Badges System: `GET /api/v1/gamification/badges` catalog and auto-unlocking evaluation for First Voice, Sentinel, Quorum Anchor, Streak Master, and Civic Legend badges.
- [x] Frontend State & Offline Caching: Hive `gamification_cache` storage, `GamificationApi`, Riverpod `gamificationNotifierProvider` & `badgeCatalogProvider`.
- [x] Material 3 Gamification UI: `GamificationScreen` (`Key('gamificationScreen')`) featuring Impact Score card, Level progress bar, Daily Streak banner & claim button, Badges grid (`Key('badgeCard_<id>')`), Activity Breakdown, and GuestGuard interception.

## 14. Backend, Offline Sync, Admin & Integrity Operations
- [x] Async SQLAlchemy/Alembic local development DB & migrations (users, OTP requests, issues, quorum_votes, upvotes, upvote_rate_limit).
- [x] Backend services for everything marked done above (auth OTP, issues CRUD + geo, escalation, quorum).
- [x] Background sync worker — `OfflineSyncWorker` mounted in `AppInfrastructure`, listens to `networkStatusProvider` stream, automatically triggers `OfflineOutboxQueue.flush()` and shows toast notification upon network reconnection.
- [ ] Conflict resolution strategy — not defined.
- [x] **Admin Moderation & Flagging System (2026-08-10 via F-14-FLAG)**: Flagged content queue, citizen flag dialog, moderation actions (dismiss, hide, ban anon identity), audit notes, rate limiting, duplicate flag guard, and Hive local store caching.
- [x] (NEW) Near-Duplicate Pipeline — geohash bbox + fuzzy `distance_meters` endpoint shipped; image vector similarity not yet.
- [x] (NEW) One-way anonymous-identity primitives (backend HMAC derivation, surfaced as `anon_id`). *(Zero-inversion audit test, separate PII store and legal-process ceremony still pending.)*
- [ ] (NEW) Localization backend (translation queue, per-post translated marker, translator credits) — not started.