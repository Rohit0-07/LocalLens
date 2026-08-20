# LocalLens — Consolidated Bug Register

Consolidated, prioritized list of bugs found during codebase analysis and manual testing.
Tag legend: `[U]` = reported during manual testing, `[M]` = found during code analysis.
Every entry carries a **Fix** (what changed) and **Files** (the file(s) touched). Files are
listed once under their primary bug; shared files are cross-referenced (e.g. "see #18") so the
register stays clean while remaining traceable. `[FIXED]` marks the bug as resolved in code.

---

## CRITICAL — breaks core flows / loses data / security

1. `[U]` **[FIXED] Home feed never shows your new issue, refresh doesn't help** — `PlatformDeviceLocationService.getCurrentCoordinates()` is a stub that always returns Mumbai (`device_location_service.dart:16-23`); the feed caches that forever (`geo_providers.dart:57-64`, `feed_providers.dart:55-61,101-104`) so it always queries Mumbai + 5 km, while compose creates an issue at photo-GPS/draft coords (`compose_providers.dart:33-46`). Real location > 5 km from Mumbai → invisible.
   - **Fix:** Wired real Geolocator GPS (permission check/request, 15s fix timeout, Mumbai fallback); feed `refresh()` now invalidates `feedCoordinatesProvider` so a new publish falls inside the query radius.
   - **Files:** `app/lib/features/geo/domain/device_location_service.dart`, `app/lib/features/feed/presentation/feed_providers.dart`
2. `[M]` **[FIXED] Notifications / Inbox navigate to a route that doesn't exist** — push `/issues/$id` (`notifications_screen.dart:267`, `inbox_screen.dart:263`) but only `/issue/:id` is registered (`route_paths.dart:28`) → GoRouter error/black screen on tap.
   - **Fix:** Both surfaces now navigate via `RoutePaths.issueDetailFor(issueId)` instead of a hand-built path.
   - **Files:** `app/lib/features/notifications/presentation/notifications_screen.dart`, `app/lib/features/inbox/presentation/inbox_screen.dart`
3. `[M]` **[FIXED] Guest sessions are force-signed-out on launch** — the dock badge watches `unreadNotificationCountProvider` (`app_router.dart:349`), which fetches notifications as a guest → 401 → `onUnauthorized` → sign-out + "session expired" toast (`network_providers.dart:15-20`).
   - **Fix:** Notifications controller short-circuits for guests (skips `loadNotifications`, guards `setFilter`/`markAsRead`/`markAllAsRead`).
   - **Files:** `app/lib/features/notifications/presentation/controllers/notifications_controller.dart` (also #26)
4. `[M]` **[FIXED] Any signed-in user can acknowledge/resolve any issue** — no role check on `/issues/{id}/acknowledge` and `/issues/{id}/resolve` (`issues/router.py:185,193`) → anyone can change status or inject a fake resolution.
   - **Fix:** Added `_is_authorized_for_issue` — acknowledge/resolve now 404 hidden issues and 403 anyone who isn't the reporter or an admin/moderator/representative.
   - **Files:** `backend/app/features/issues/router.py`
5. `[M]` **[FIXED] Attribution spoofing on issue create** — backend honors a client-supplied `reporter_id` (`issues/service.py:224`, `schemas.py:89`).
   - **Fix:** Removed `reporter_id` from `IssueCreate`; `create_issue` now uses only the `reporter_id` passed in by the route.
   - **Files:** `backend/app/features/issues/schemas.py` (also #7)
6. `[M]` **[FIXED] Photo deletions are lossy** — Dio turns 4xx into exceptions (`media_service.dart:172-203`), so the server's 409 "photo linked to a published issue" never reaches the UI; the library deletes the local copy anyway (`media_library_providers.dart:53-63`). Same dead branch breaks the upload error path, silently shunting publishes into the outbox.
   - **Fix:** `uploadMedia`/`deleteMedia` use `Options(validateStatus: (_) => true)` so 4xx/5xx responses reach the business logic (e.g. `MediaDeleteException` with the server `code`) instead of throwing `DioException`.
   - **Files:** `app/lib/features/compose/data/media_service.dart`

---

## HIGH — visible breakage / wrong behavior

7. `[U]` **[FIXED] "5h ago" on a just-published issue** — timestamps are stored as naive UTC (`models.py:47-49`) and parsed as local IST (+5h30m) in the app. Affects issues, wins, notices, local talk, comments, notifications, rewards.
   - **Fix:** New `UTCDateTime` annotated type serializes naive UTC as ISO-8601 `...Z`; applied across all output schemas so the app parses them as UTC.
   - **Files:** `backend/app/core/fields.py` (new), `backend/app/features/feed/schemas.py`, `backend/app/features/geo/schemas.py`, `backend/app/features/notifications/schemas.py`, `backend/app/features/wards/schemas.py`, `backend/app/features/media/schemas.py`, `backend/app/features/gamification/schemas.py`, `backend/app/features/representatives/schemas.py` — `issues/schemas.py` see #5, `auth/schemas.py` see #16
8. `[M]` **[FIXED] Profile "Unresolved" tab is always empty** — sends `status=active`, which no issue ever has (`profile_providers.dart:125-131`).
   - **Fix:** `statusParam` is now `null` for `all`/`active` (fetches all statuses) and only filtered otherwise.
   - **Files:** `app/lib/features/profile/presentation/profile_providers.dart`
9. `[M]` **[FIXED] Feed upvote sends hardcoded Mumbai coords** (`issue_card.dart:484-485`) instead of the device/issue location → "You must be near this issue" everywhere except Mumbai.
   - **Fix:** Upvote now passes `activeIssue.latitude/longitude` rather than `defaultLatitude/defaultLongitude`.
   - **Files:** `app/lib/features/feed/presentation/widgets/issue_card.dart`
10. `[M]` **[FIXED] Flagging + admin queue are fakes** — flagging only writes to local storage (`flag_issue_provider.dart:58-74`); admin flagged-queue screen is a hard-coded mock with mismatched field names (`admin_flagged_queue_provider.dart:78-98`) — backend `flag_count` never changes.
    - **Fix:** Flag provider POSTs `/issues/{id}/flag` and parses the real `FlagOut`; admin queue calls `/admin/flagged-issues` and `/admin/issues/{id}/moderate` with proper `fromJson`.
    - **Files:** `app/lib/features/issues/presentation/providers/flag_issue_provider.dart`, `app/lib/features/admin/presentation/providers/admin_flagged_queue_provider.dart`
11. `[M]` **[FIXED] Offline outbox only syncs on an offline→online flap** (`offline_sync_worker.dart:20-49`) — a failed publish can sit forever; no app-start flush, and syncs never invalidate the feed/map.
    - **Fix:** Worker now flushes on app start when already online (plus every flap), invalidates `multiTypeFeedProvider` + `mapPinsNotifierProvider`, and toasts the sync count.
    - **Files:** `app/lib/core/network/offline_sync_worker.dart`
12. `[M]` **[FIXED] Compose uploads media before creating the issue** (`compose_providers.dart:160-196`) → orphaned uploads on failure, duplicate uploads on outbox retry.
    - **Fix:** On `createIssue` failure the just-uploaded media are deleted (rollback) before the draft is enqueued, so outbox retries don't duplicate.
    - **Files:** `app/lib/features/compose/presentation/compose_providers.dart` (also #29)
13. `[M]` **[FIXED] Hidden/deleted issues surface in search** — no `is_hidden` filter (`search/service.py:81`).
    - **Fix:** Search now skips `is_hidden` issues.
    - **Files:** `backend/app/features/search/service.py`
14. `[M]` **[FIXED] CapturedMediaStore race loses photos** — non-atomic read-modify-write on rapid captures (`captured_media_store.dart:46-58`).
    - **Fix:** All read-modify-write ops run through an in-class future-chain mutex so concurrent saves/deletes serialize.
    - **Files:** `app/lib/features/compose/data/captured_media_store.dart`
15. `[M]` **[FIXED] Camera unavailable fabricates a fake photo** — saves a 100-byte blob that can be uploaded (`camera_viewfinder.dart:167-175`).
    - **Fix:** Shutter tap with an uninitialized camera now retries initialization instead of emitting a dummy capture.
    - **Files:** `app/lib/features/compose/presentation/widgets/camera_viewfinder.dart`
16. `[M]` **[FIXED] Public profile level is wrong** — backend sends `level` as an int; the app expects a string and falls back to a *different* threshold scheme (`public_user_profile.dart:67-70` vs `auth/schemas.py:88`).
    - **Fix:** Backend now sends authoritative `level_name` (from `get_level_info`) on the public profile; the app keeps the int→name fallback for older payloads.
    - **Files:** `backend/app/features/auth/schemas.py` (also #7), `backend/app/features/auth/service.py`
17. `[M]` **[FIXED] Edit-Profile photo picker throws the image away** — shows "queued with next sync" but nothing is stored (`edit_profile_screen.dart:191-198`).
    - **Fix:** Picker uploads the bytes via `MediaService`, shows a live preview, and `_save` includes `photo_url` in the profile PATCH.
    - **Files:** `app/lib/features/profile/presentation/screens/edit_profile_screen.dart` (also #30)

---

## MEDIUM — incorrect counts / edge cases

18. `[M]` **[FIXED] Multi-type feed cursor pagination is broken** — each type fetched with `limit`, merged, then truncated; offset never applied, items silently dropped on later pages (`feed/service.py:25-112`).
    - **Fix:** Cursor parsed to naive UTC and pushed down to per-type queries via a new `created_before` param with a 5×limit superset; merge → filter → take `limit`.
    - **Files:** `backend/app/features/feed/service.py`, `backend/app/features/issues/service.py` (also #5, #22)
19. `[M]` **[FIXED] Outbox flush isn't concurrency-safe → duplicate issues; permanently-failing drafts retry forever** (`offline_outbox_queue.dart:66-100`).
    - **Fix:** `flush()` deferred behind an in-flight future (no concurrent double-publish); per-draft attempts persisted and a draft is dropped after 5 consecutive failures.
    - **Files:** `app/lib/features/compose/data/offline_outbox_queue.dart`
20. `[M]` **[FIXED] Rep dashboard counts only `status=="escalated"` while the ward list counts escalating/forwarded too** (`representatives/service.py:43`) → mismatched totals.
    - **Fix:** Escalated count and the "escalated" list filter now use `status IN (escalated, escalating, forwarded)` OR `escalated_at` set — matching ward metrics.
    - **Files:** `backend/app/features/representatives/service.py`
21. `[M]` **[FIXED] Ward metrics include hidden issues** (`wards/service.py:69-107`).
    - **Fix:** Ward metric queries add `Issue.is_hidden IS false`.
    - **Files:** `backend/app/features/wards/service.py` (also #18, #22)
22. `[M]` **[FIXED] Proximity list helpers fetch `limit*2` then radius-filter → sparse areas return fewer than requested** (wins/notices/talk).
    - **Fix:** Superset fetch raised to `limit*6` so radius-filtered sparse areas still return the requested count.
    - **Files:** `backend/app/features/issues/service.py` (see #18), `backend/app/features/wards/service.py` (see #21)
23. `[M]` **[FIXED] Gamification streak never resets on a missed day → badge trivially reachable** (`gamification/service.py:298-299`).
    - **Fix:** Claim now increments only when the last claim was yesterday; otherwise the streak resets to 1.
    - **Files:** `backend/app/features/gamification/service.py`
24. `[M]` **[FIXED] Reels can get stuck when a page returns zero media; refresh/loadMore read coordinates with `ref.watch` outside `build` → falls back to Mumbai** (`reels_providers.dart:45-74`).
    - **Fix:** Coordinates read via `ref.read` (valid outside build); a cursor-advance guard stops the pager when a page makes no progress.
    - **Files:** `app/lib/features/reels/presentation/reels_providers.dart`
25. `[M]` **[FIXED] Gamification claim button ignores `canClaimStreak`; no success feedback; activity breakdown omits streak points** (`gamification_screen.dart:182-207,339-365`).
    - **Fix:** Button disabled when `!canClaimStreak`, success snackbar shows `StreakClaimResult.message`, and a "Streak Days" row (×15 pts) was added to the breakdown.
    - **Files:** `app/lib/features/gamification/presentation/gamification_screen.dart`
26. `[M]` **[FIXED] Notifications "unread" filter still shows read items + count skew (badge vs list)** — needs re-verify.
    - **Fix:** Marking a notification read now removes it from the unread-only view (kept for the all view).
    - **Files:** `app/lib/features/notifications/presentation/controllers/notifications_controller.dart` (see #3)

---

## LOW — polish / minor

27. `[M]` **[FIXED] Nested reply deletion leaves ghost children** (`comments_section.dart:145-158`).
    - **Fix:** `_removeCommentDeep`/`_prunedReplies` recursively remove the comment and its whole reply subtree at any depth.
    - **Files:** `app/lib/features/issue_detail/presentation/widgets/comments_section.dart`
28. `[M]` **[FIXED] Drafts list returns oldest-first** (`local_store.dart:88`).
    - **Fix:** `loadAllDrafts` returns stored (newest-first) order — dropped the `.reversed`.
    - **Files:** `app/lib/core/storage/local_store.dart`
29. `[M]` **[FIXED] `saveAsDraft` → restart loses attachments** (`compose_providers.dart:97-104`); autosave clobbers fields with no debounce.
    - **Fix:** Autosave is debounced (500 ms) and persists media so restarts restore attachments; `saveAsDraft`/`discard`/`submit` cancel the pending timer.
    - **Files:** `app/lib/features/compose/presentation/compose_providers.dart` (see #12)
30. `[M]` **[FIXED] DOB picker accepts impossible dates rollover; stale "photo change allowed" timestamp in camera.**
    - **Fix:** `_parseDob` round-trip-validates the date (no 31/02 → 03/03 rollover); photo-change timestamp interpreted as UTC and only shown when in the future.
    - **Files:** `app/lib/features/profile/presentation/screens/edit_profile_screen.dart` (see #17), `app/lib/features/profile/presentation/screens/profile_screen.dart`
31. `[M]` **[FIXED] Notifications router mounted twice** — `/notifications` and `/api/v1/notifications` (`main.py` + `api/router.py`).
    - **Fix:** Removed the duplicate top-level `/notifications` mount in `main.py`; the `/api/v1/notifications` route (what the app calls) stays.
    - **Files:** `backend/app/main.py`
32. `[U]` **[FIXED] Feature request: tapping the LocalLens logo should refresh the feed** — AppBar title has no tap handler today (`feed_screen.dart:35-59`).
    - **Fix:** AppBar title wrapped in an `InkWell` that re-resolves coordinates and refreshes the feed.
    - **Files:** `app/lib/features/feed/presentation/feed_screen.dart`
33. `[M]` **[FIXED] Publish navigates before invalidating the feed** (`compose_screen.dart:346-348`) — fragile ordering.
    - **Fix:** Invalidates drafts/feed/map pins *before* `context.go(RoutePaths.feed)` so the feed rebuilds with the new issue visible.
    - **Files:** `app/lib/features/compose/presentation/compose_screen.dart`

---

## PHASE 2 — REMAINING AUDIT ISSUES & SYSTEM INTEGRATION (BUGS_REMAIN.MD)

34. `[U]` **[FIXED] Ward & Representative System, Auto-Assignment, Dummy/Unclaimed Authority Handles, Wrong Ward Flagging & Reallocation, Escalation Ladder Fix, Community Resolution Verification & Expandable Activity Timeline**
    - **Root Causes**:
      - Issues were created without automated routing to departmental authorities (e.g. Roads, Water, Power, Waste, Councillor).
      - Authority profiles had no concept of unclaimed placeholders vs verified civic officers with handles.
      - Users had no mechanism to report wrongly assigned wards or categories, and admins lacked reassignment endpoints.
      - Issue detail rendered an overwhelming, unstructured timeline rather than a concise summary with an expandable chronological audit log.
      - Authority resolutions and community quorum verifications were conflated into a single ambiguous status badge.
    - **Fix**:
      - *Backend*: Extended `RepresentativeProfile` with `department`, `is_unclaimed`, `contact_email`, `contact_phone`. Updated `create_issue` to auto-assign the departmental representative matching the issue's ward & category (or default ward councillor).
      - *Reassignment & Governance*: Added `POST /api/v1/issues/{id}/report-wrong-assignment` with `WrongAssignmentReport` model and `POST /api/v1/admin/issues/{id}/reassign` with notification dispatch.
      - *Timeline Endpoint*: Added `GET /api/v1/issues/{id}/timeline` returning full chronological audit trails with voter handles and "Verified Nearby" indicators.
      - *Frontend UI*: Built `AssignedAuthorityCard` displaying handle, claimed/unclaimed badge, and modal dialog to report wrong ward. Upgraded `AuditTimelineCard` to feature a concise progress header with an **Expand / Collapse Full Activity Timeline** toggle. Added `ResolutionBadge` distinguishing "Official Authority Resolution" from "Community Quorum Verified".
    - **Files**:
      - `backend/app/features/representatives/models.py`, `schemas.py`, `service.py`
      - `backend/app/features/issues/models.py`, `schemas.py`, `service.py`, `router.py`
      - `backend/app/features/wards/schemas.py`, `service.py`
      - `backend/tests/features/issues/test_wrong_assignment_and_timeline.py`
      - `app/lib/features/feed/domain/issue.dart`, `app/lib/features/issue_detail/data/issue_detail_api.dart`
      - `app/lib/features/issue_detail/presentation/widgets/assigned_authority_card.dart`
      - `app/lib/features/issue_detail/presentation/widgets/audit_timeline_card.dart`
      - `app/lib/features/issue_detail/presentation/screens/issue_detail_screen.dart`

35. `[U]` **[FIXED] Resolution Fix Media Upload Restricted to In-App Camera Only (No Gallery)**
    - **Root Causes**:
      - `ResolutionProofModal` allowed users to pick existing images from device storage gallery, breaking on-site GPS verification integrity.
    - **Fix**:
      - Removed gallery picker button entirely from `ResolutionProofModal`.
      - Enforced live viewfinder camera capture with GPS EXIF locking (`CameraViewfinder`) for all resolution proofs.
    - **Files**:
      - `app/lib/features/issue_detail/presentation/widgets/resolution_proof_modal.dart`
      - `app/test/features/issue_detail/issue_detail_camera_and_timeline_test.dart`

36. `[U]` **[FIXED] Public Directory / Explorer for Wards & Department Representatives**
    - **Root Causes**:
      - Ward detail screen only exposed a single representative and omitted other municipal department engineers.
      - There was no dedicated directory route to browse and search all wards across the city.
    - **Fix**:
      - Enhanced `WardDetailOut` and backend query to populate all departmental representatives (`representatives` list).
      - Updated `WardRepCard` to display department tag, `@handle`, and claimed / unclaimed badges.
      - Added `WardsListScreen` and registered `/wards` route in `RoutePaths` and `GoRouter` with real-time search filtering.
    - **Files**:
      - `backend/app/features/wards/schemas.py`, `service.py`
      - `app/lib/features/ward/domain/ward_representative_out.dart`, `ward_detail_out.dart`
      - `app/lib/features/ward/presentation/widgets/ward_rep_card.dart`
      - `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`
      - `app/lib/features/ward/presentation/screens/wards_list_screen.dart`
      - `app/lib/core/router/route_paths.dart`, `app_router.dart`

37. `[U]` **[FIXED] Search Section Fix & Granular Filter-Driven Map Search**
    - **Root Causes**:
      - `GET /api/v1/search` threw 422 Unprocessable Entity when `q` was empty even if filters (category, ward, status) were applied.
      - Search did not support searching by user account / citizen handle.
      - The Flutter app search results notifier did not trigger searches when only filters were active with an empty search query field.
    - **Fix**:
      - *Backend*: Made `q` optional in search router and service when any filter (`category`, `categories`, `status`, `ward`, `account`, `created_after`, `created_before`, `latitude/longitude`) is present. Added multi-field text search matching title, description, category, ward, and reporter username.
      - *Frontend*: Added `account` parameter and custom date range picker to `SearchFilters`, `SearchApi`, and `AdvancedFilterSheet`. Updated `SearchResultsNotifier` to execute filter-only queries seamlessly.
    - **Files**:
      - `backend/app/features/search/router.py`, `service.py`
      - `backend/tests/features/search/test_search.py`
      - `app/lib/features/search/domain/search_filters.dart`, `search_repository.dart`
      - `app/lib/features/search/data/search_api.dart`
      - `app/lib/features/search/presentation/search_providers.dart`
      - `app/lib/features/search/presentation/advanced_filter_sheet.dart`
      - `app/lib/features/search/presentation/search_screen.dart`

38. `[U]` **[FIXED] Localization & Display Formatting (Eliminated Raw Snake_Case Strings)**
    - **Root Causes**:
      - Category names and filter options were falling back to raw snake_case or unlocalized strings in the UI.
    - **Fix**:
      - Added translations across all 5 supported languages (English, Hindi, Marathi, Tamil, Telugu) for all category keys (`cat_road`, `cat_water`, `cat_power`, `cat_waste`, `cat_sewage`, `cat_lighting`, `cat_sanitation`, `cat_other`), search filters (`filter_by_ward`, `filter_by_account`, `filter_date_range`, `filter_within_radius`, etc.), and timeline labels.
      - Updated `AppStrings.tr()` to automatically convert missing keys into clean Title Case format (`_humanizeKeyFallback`), eliminating raw snake_case strings.
    - **Files**:
      - `app/lib/core/l10n/app_strings.dart`

39. `[U]` **[FIXED] Streamlined "Outside Coverage" Location Indicator**
    - **Root Causes**:
      - The outside-coverage indicator rendered an intrusive warning banner across screens.
    - **Fix**:
      - Replaced intrusive text banner with a sleek, non-blocking location chip (`WardLocationChip`) with an exploration icon (`Icons.explore_outlined`) that never blocks user interaction.
    - **Files**:
      - `app/lib/features/geo/presentation/widgets/ward_location_chip.dart`
      - `app/test/features/geo/geo_widget_test.dart`
