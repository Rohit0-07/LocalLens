# FIX_NEED.md — Audit Fix Tracker

Findings from bug/performance/security audit. One checkbox per fix.
Status legend: `[ ]` pending · `[~]` in progress · `[x]` done · `[-]` skipped (reason noted)

---

## CRITICAL — Security

- [x] **S-C1** Prod boot guard for default JWT secret (`jwt_secret`, `anon_hmac_secret`) — refuse to start in production if secret matches defaults or <32 bytes (`backend/app/core/config.py:24,28`)
- [x] **S-C2** Master OTP backdoor guard — refuse to boot with `otp_master_code` set when environment == production (`backend/app/features/auth/service.py:48,124`)

## HIGH — Security

- [x] **S-H1** OTP brute-force protection: per-phone/per-IP rate limit on request-otp and verify-otp; max 5 failed attempts invalidates the code (`auth/router.py:28-64`, `auth/service.py:101-120`)
- [x] **S-H2** Media upload hardening: require auth, max size (~10MB streamed in chunks), magic-byte / Pillow re-encode validation, reject non-images instead of writing raw bytes (`media/router.py:38-68`, `media/service.py:160-178`) — DONE batch 3
- [x] **S-H3** Global exception handler leaks internals — only pass through AppError; log everything else server-side and return generic 500 (`backend/app/core/exceptions.py:26-31`)

## HIGH — Bugs

- [x] **B-H1** MissingGreenlet 500 on acknowledge/resolve for non-reporter users — eagerly load `User.representative_profile` in `get_current_user` or check `role` instead of the lazy property (`issues/router.py:205`, `api/deps.py:58`, `auth/models.py:46`)
- [x] **B-H2** Client sends issue's own coords as voter location — use device location with explicit failure state when unavailable (quorum vote + upvote) (`app/lib/features/issue_detail/presentation/screens/issue_detail_screen.dart:476`, `feed/presentation/widgets/issue_card.dart:483`, `win_card.dart:396`)
- [x] **B-H3** Duplicate votes possible — add UniqueConstraint(issue_id, user_id) on Upvote + QuorumVote with Alembic migration; atomic counter increment instead of read-modify-write (`issues/models.py:157-178`, `issues/service.py:546,786`) — DONE: constraints in `models.py:170,185` + migration `f0a1b2c3d4e5`, atomic `UPDATE ... SET count+1` + `IntegrityError->400` in `service.py:562,829`, tests `test_vote_dedup.py` 4/4 green
- [x] **B-H4** Double-offset pagination skips rows in GET /issues — fetch (offset+limit)*overfetch with offset=0, filter, slice once (mirror search pattern) (`issues/service.py:392-413`)

## HIGH — Performance

- [x] **P-B1** Add composite index (latitude, longitude) on Issue via Alembic migration (`issues/models.py:33-34`) — DONE in migration f0a1b2c3d4e5, marking after final verify
- [x] **P-B3** Offload blocking work off the event loop: Pillow encode/thumbnail, bcrypt hash/check, file writes via asyncio.to_thread (`media/service.py:166-178`, `core/security.py:16,21`)
- [x] **P-B4** Replace evaluate_all_escalations row hydration with set-based bulk UPDATEs; remove inline escalation evaluation + mid-GET commits from read paths (`issues/service.py:396-411,740-756`, `search/service.py:181-205`, `auth/service.py:252-258`)

## MEDIUM — Security

- [x] **S-M1** Check is_banned in get_current_user so banned users lose access immediately (`api/deps.py:58`)
- [x] **S-M2** Use dedicated anon_hmac_secret for anon ID derivation instead of jwt_secret — done across auth, issues, representatives, search, feed
- [x] **S-M3** Require admin/moderator auth on POST /issues/evaluate-escalations and POST /issues/{id}/check-quorum-status (`issues/router.py:92,272`)
- [x] **S-M4** Restrict rep acknowledge/resolve to their own ward (`issues/router.py:189-205`)

## MEDIUM — Bugs

- [x] **B-M1** Gamification badge unlocks rolled back — commit after evaluate_and_unlock_badges or persist only in mutation paths (`gamification/service.py:172-173,232-238`)
- [x] **B-M2** Feed cursor strict `<` drops items sharing cursor timestamp — keyset on (created_at, id) (`feed/service.py:147-149`) — DONE: `feed/service.py:10` `_parse_cursor` with `|id` tie-breaker, `issues/service.py:399` + `wards/service.py:381,409` + `issues/service.py:699` keyset `or_(created_at < cursor, created_at==cursor & id<cursor_id)`, `feed/service.py:66` propagates `created_before_id`, `feed_item.dart:cursor` + `feed_providers.dart:loadMore()`, tests `test_feed_cursor.py` + `feed_cursor_test.dart` green
- [x] **B-M3** Outbox retry re-uploads media causing duplicate rows — reuse uploaded URLs on retry (`app/lib/features/compose/data/offline_outbox_queue.dart:50-56`)
- [x] **B-M4** Win before-image queries reporter's oldest media ever instead of issue's media (`issues/service.py:616-630`)
- [x] **B-M5** Timeline countdown constants contradict backend cadence (+3d vs 7d quorum, 72h vs 24h escalation) (`audit_timeline_card.dart:47-59`)
- [x] **B-M6** 61 i18n keys referenced but missing from string table across all 5 locales (flag_*, admin_*, near_dup_*, compose_location_*, etc.) — add all missing keys x en/hi/mr/ta/te (`app/lib/core/l10n/app_strings.dart`)
- [x] **B-M7** Broken dormant Dart models: is_verified_nearby vs is_nearby, timeline event field mismatch — align with backend schemas (`app/lib/features/feed/domain/issue.dart:33,46-52`)
- [x] **B-M8** FlaggedIssueItem.reporter_id non-nullable vs nullable column — make optional to avoid admin queue 500 (`issues/schemas.py:52`)

## MEDIUM — Performance

- [x] **P-B7** Geo pagination over-fetch/double-offset also in wins/talk/notices/search paths — push radius filter into SQL, single slice (`wards/service.py:377-415`, `search/service.py:179-192`)
- [x] **P-B8** Rate limiter memory leak + shared "anon" bucket — periodic sweep of stale keys, key anonymous users by IP (`core/ratelimit.py:11-29`, `search/router.py:29`)
- [x] **P-B9** Missing composite indexes: Upvote(issue_id,user_id), QuorumVote(issue_id,user_id), Notification(user_id,is_read), rate-limit count indexes — same Alembic migration as B-H3 where sensible
- [x] **P-B10** Admin flagged queue N+1 flag fetch — batch one IN query (`issues/service.py:1077-1080`)
- [x] **P-B11** delete_comment deletes replies row-by-row with O(N^2) descendant computation — collect ids, single IN delete (`issues/service.py:953-968`)
- [x] **P-B12** Unbounded result sets: comments list, public profile issues — add sane caps (`issues/service.py:900-902`, `auth/service.py:298-309`)

## LOW

- [x] **L-1** Make UpvoteRequest body required (lat/lng defaulting to 0.0 causes bogus radius errors) (`issues/router.py:286-297`)
- [-] **L-2** Expired quorum with zero disputes should not become "disputed" (`issues/service.py:583-586`) — SKIPPED: Flutter has no 'expired' status handling (string_formatters.dart:60-83); changing backend alone breaks UI expectations. Needs app-side follow-up first.
- [x] **L-3** Comment count mismatch card vs detail (top-level only vs includes replies) (`social_action.dart:75`)
- [x] **L-4** Notification unread count drifts on tapping already-read items; controller uses ref.read(sessionProvider) so it never rebuilds on sign-out (`notifications_controller.dart:60,106`)
- [x] **L-5** Guard db.get(User, None) in moderate_issue ban_reporter path; remove fallback moderated_by=1 (`issues/service.py:1131,1141`)
- [x] **L-6** OTP codes logged at INFO outside production — downgrade/gate (`auth/service.py:59,135`)
- [x] **L-7** Add security headers middleware + X-Content-Type-Options on media serving — nosniff middleware in main.py + media FileResponse header

## Skipped / deferred (with reason)

- Flutter cached_network_image adoption (F1): new dependency — needs separate ticket per golden rules
- Redis-backed rate limiting (M-6 infra): out of scope without infra decision
- HTTPS/cert pinning release config: deployment-level decision
