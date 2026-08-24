# Offline-First LocalLens — Implementation Plan (Hive-aligned, Free Stack)

> **Stack:** Flutter (`hive_ce: ^2.19.3` + `hive_ce_flutter` + `connectivity_plus` + `dio` + `flutter_riverpod` + `geolocator`) · FastAPI (`SQLAlchemy 2 async` + `Alembic` + `aiosqlite`) · **Zero paid services.** Hive is free (MIT) and already in `app/pubspec.yaml:19`; Drift is intentionally **not** used — keep Hive to avoid new dep + migrations. This plan’s local “tables” are **Hive Box<String> JSON** mirroring the real backend schema column-for-column, so no future mismatches.

## 1. Feature Goal

- Make the app feel fast even with slow internet (read Local Hive first, refresh in background).
- Allow users to continue performing important actions when offline and see them immediately (optimistic UI).
- Store application data locally on device in Hive (free) — issues, votes, comments, wards, media refs, user session.
- Make Home / Profile / Reels usable offline showing last-fetched data with “showing cached data · offline” banner.
- Synchronize pending actions with backend when internet returns, in order, with single-flight lock.
- Prevent duplicate actions during retries via `client_action_id → X-Idempotency-Key` (backend `idempotency_keys` table).
- Handle images for issue posts while offline (copy to app storage, enqueue media upload, dedupe).
- Keep architecture simple and completely free to operate (no Firebase, no Drift).

---

## 2. Core Architecture

```text
┌──────────────────────────────────────────────┐
│                  Flutter App                 │
│                                              │
│  ┌──────────────┐       ┌─────────────────┐  │
│  │     UI       │       │ OfflineSyncWorker│ │
│  │ (Riverpod)   │       │ + SyncManager   │  │
│  └──────┬───────┘       └────────┬────────┘  │
│         │                        │           │
│         ▼                        ▼           │
│  ┌────────────────────────────────────────┐  │
│  │          Repository Layer              │  │
│  │  FeedRepository / IssueRepository      │  │
│  └───────────────┬────────────────────────┘  │
│                  │                           │
│          ┌───────┴────────┐                  │
│          ▼                ▼                  │
│   ┌─────────────┐  ┌──────────────┐         │
│   │ Local Cache │  │ Local Outbox │         │
│   │ Hive Boxes  │  │ Hive Queue   │         │
│   │  (JSON)     │  │  (JSON list) │         │
│   └─────────────┘  └──────┬───────┘         │
│                           │                  │
│         core/storage/local_store.dart        │
│         core/network/api_client.dart (dio)   │
│                           │                  │
└───────────────────────────┼──────────────────┘
                            │
                       Internet Available (connectivity_plus trigger + HTTP ping)
                            │
                            ▼
                     ┌─────────────┐
                     │   FastAPI   │
                     │   Backend   │
                     │ SQLAlchemy  │
                     └─────────────┘
```

Existing files reused: `app/lib/core/storage/local_store.dart:10` (5 `Box<String>`), `app/lib/features/compose/data/offline_outbox_queue.dart:39` (`locallens_outbox_queue_v1`), `app/lib/core/network/offline_sync_worker.dart:22` (recovered trigger), `app/lib/features/feed/data/feed_api.dart` (Dio).

---

## 3. Recommended Technology Stack — Hive (Free)

### hive_ce

Use `hive_ce` + `hive_ce_flutter` (already in `pubspec.yaml`).

```text
Flutter
   ↓
hive_ce
   ↓
Hive Boxes (JSON)
```

**Why Hive, not Drift for LocalLens** (both free, but Hive wins here):
- Hive already persists `session`, `drafts`, `rep_cache`, `flagged_issues`, `ward_cache` (`local_store.dart:10`) with zero migrations.
- LocalLens relations (Issues ↔ Comments ↔ Upvotes ↔ Wards) are server-side `SQLAlchemy` joins; client only needs key-value cache + queue — no client-side `JOIN`/`WHERE pincode` required.
- Drift would add `drift` + `sqlite3` + codegen + ~8 new files (`app_database.dart/tables/daos`) and a local migration history for ~30 rows — over-engineering for Ward 45 seed + 7 categories `road/water/power/lighting/waste/sewage/other`.

**Backend** stays `SQLAlchemy 2 async + Alembic` (`aiosqlite`); no change.

### connectivity_plus

Used to detect changes in network connectivity. **Trigger only** — always verify real backend reachability with a lightweight `GET /health` ping before flushing.

### dio

Already in stack. Add `X-Client-Action-Id` header interceptor for idempotency.

---

## 4. Data Architecture

Local Hive mirrors backend tables column-for-column + sync metadata (`client_action_id`, `sync_status`). Two categories:

```text
LOCAL HIVE BOXES (JSON)
│
├── Application Cache (read-first)
│   ├── users/me.json  ← mirrors backend users
│   ├── issues/cache_<bbox>_<hash>.json  ← mirrors backend issues
│   ├── comments/<issueId>.json          ← mirrors backend comments
│   ├── upvotes/<userId>.json / quorum_votes
│   ├── wards/cache.json + ward_detail_<slug>.json  ← mirrors backend wards
│   ├── media/<capturedId>.json         ← mirrors backend media
│   ├── wins/notices/local_talk cache
│   └── cache_meta.json { lastFetchedAt, ttl, isStale }
│
└── Synchronization (write queue)
    ├── outbox_queue (locallens_outbox_queue_v1) — ordered JSON list
    ├── outbox_attempts (retry_count map)
    ├── media_uploads (_uploads_v1 dedupe cache)
    ├── captured_media (locallens_captured_media_v1)
    └── cache_meta + sync_status per item (pending/syncing/synced/failed)
```

---

## 5. Local Database — Mirroring Real Backend Schema (No Mismatches)

All fields below are **exactly** `backend/app/features/*/models.py` columns. Local Hive stores JSON with same keys; backend is source of truth.

### 5.1 Users — `backend/app/features/auth/models.py:13` `users`

```text
users
--------------------------
id                  int PK
phone               String(20) unique, nullable, index
email               String(255) unique, nullable, index
display_name        String(120) nullable
username            String(40) unique, nullable, index
date_of_birth       Date nullable
photo_url           String(500) nullable
bio                 String(200) nullable
display_name_changes_count  int default 0
display_name_updated_at     DateTime nullable
bio_updated_at              DateTime nullable
photo_updated_at            DateTime nullable
is_admin            bool default false
role                String(32) default "citizen"  // citizen | admin | moderator
is_verified         bool nullable default true
ward                String(64) nullable default "Ward 45, Urban Central"
is_banned           bool default false
created_at          DateTime server_default now()
-- derived, not stored: is_representative (via representative_profile join), anon_id (HMAC derive_anonymous_identity)
```

Local cache key: `users/me.json` via `GET /auth/me`. Do **not** invent `name/profile_image/pincode` — they don’t exist. `OtpCodes` table (`otp_codes: id/phone/email/code_hash/failed_attempts/expires_at/created_at`) is server-only, never cached.

### 5.2 Issues — `backend/app/features/issues/models.py:26` `issues` (Main table)

```text
issues
--------------------------
id                      int PK
title                   String(100)
description             Text default ""
category                String(32) default "other" index  // road/water/power/lighting/waste/sewage/other (no downvote)
status                  String(32) default "unacknowledged" index  // unacknowledged | under_review | escalating | forwarded | pending_quorum | resolved | disputed
latitude                Float not null
longitude               Float not null
geohash                 String(12) nullable index
ward                    String(64) default "Ward 45, Urban Central" index  // string, not ward_id FK
search_blob             Text nullable index  // lower(title+description+category+ward)
is_anonymous            bool default false
fuzz_location           bool default false
is_fuzzed               bool default false
is_shielded             bool default false
is_hidden               bool default false
flag_count              int default 0
reporter_id             int nullable FK users.id index
media_url               String(500) nullable
video_url               String(500) nullable
media_urls              Text nullable (JSON list)
created_at              DateTime server_default now() index
acknowledged_at         DateTime nullable
resolved_at             DateTime nullable
escalated_at            DateTime nullable
upvotes_count           int default 0  // no downvotes column
comments_count          int default 0
resolution_proof        String(255) nullable
resolution_notes        Text nullable
confirmations_count     int default 0
disputes_count          int default 0
quorum_expires_at       DateTime nullable
assigned_representative_id  String(255) nullable FK representative_profiles.id index
resolved_by             String(100) nullable
resolution_type         String(32) nullable
-- local-only sync fields (not in backend): client_action_id UUID, sync_status (pending/syncing/synced/failed), local_image_path, is_deleted (soft delete via is_hidden server-side)
```

**Do not use:** `pincode, address, ward_id, created_by, image_path, remote_image_url, downvotes, server_id` — they don’t exist. Backend uses `reporter_id`, `media_urls` JSON, `ward` string, `upvotes_count` only.

### 5.3 Comments — `backend/app/features/issues/models.py:146` `comments`

```text
comments
--------------------------
id          String(36) PK default uuid4()
issue_id    int FK issues.id index
parent_id   String(36) nullable FK comments.id index  // threaded replies
author_id   int FK users.id index
anon_id     String(64) not null  // HMAC derived
content     Text not null
created_at  DateTime server_default now() index
-- no server_id, no sync_status, no is_deleted, no updated_at, no user_id alias (author_id is real column)
```

Delete is hard bulk `DELETE ... WHERE id IN (descendants)` (`service.py:1038`).

### 5.4 Votes — Upvote-only + QuorumVote (No DOWNVOTE)

**Do not create** a generic `votes(vote_type UPVOTE/DOWNVOTE/NONE, sync_status)` table — LocalLens is **upvote-only**.

```text
upvotes
--------------------------
id          int PK
issue_id    int FK issues.id index  UNIQUE(issue_id,user_id) uq_upvotes_issue_user
user_id     int FK users.id index
created_at  DateTime server_default now()

quorum_votes
--------------------------
id          int PK
issue_id    int FK issues.id index  UNIQUE(issue_id,user_id) uq_quorum_votes_issue_user
user_id     int FK users.id index
vote        String(16)  // "confirm" or "dispute" only
reason      String(255) nullable
created_at  DateTime server_default now()
```

Counters live on `issues` (`upvotes_count`, `confirmations_count`, `disputes_count`) — updated via atomic `UPDATE issues SET count = count + 1`, not local vote flips. There is no `DOWNVOTE`/`NONE` flow.

### 5.5 Wards — `backend/app/features/wards/models.py:9` `wards`

```text
wards
--------------------------
id                  int PK autoincrement
name                String(255) not null index
slug                String(255) not null unique index
code                String(50) not null index
center_latitude     Float not null
center_longitude    Float not null
boundary            Text nullable  // GeoJSON outer ring JSON, not boundary_data
created_at          DateTime server_default now()
updated_at          DateTime server_default now() onupdate
-- no pincode, no area, no latitude/longitude (use center_*), no boundary_data
```

Related local tables (separate, same schema as backend):

```text
local_talk_posts
--------------------------
id              int PK autoincrement
ward_slug       String(255) not null index
author_id       int FK users.id index
author_name     String(100) default "Local Citizen"
title           String(255)
body            String(2000)
topic           String(64) default "General"
replies_count   int default 0
latitude        Float nullable
longitude       Float nullable
created_at      DateTime server_default now() index

notices
--------------------------
id              int PK autoincrement
title           String(255)
description     String(2000)
official_header String(255) default "Official Notice"
valid_until     DateTime nullable
ward            String(64) default "Ward 45, Urban Central"
latitude        Float not null
longitude       Float not null
geohash         String(12) nullable index
created_at      DateTime server_default now() index
```

Other backend tables (server-only or cached as JSON, not separately migrated locally):

```text
media
--------------------------
id              String PK default uuid4()
user_id         String nullable
url             String not null
thumbnail_url   String not null
is_verified     bool default false
watermark_label String not null  // "LocalLens Verified" vs "User Uploaded - Unverified"
derived_hash    String not null
latitude        Float nullable
longitude       Float nullable
is_fuzzed       bool default false
is_in_app_camera bool default false
issue_id        int nullable FK issues.id index
deleted_at      DateTime(timezone) nullable
captured_at     DateTime(timezone) nullable
created_at      DateTime(timezone) default now(UTC)

notifications
--------------------------
id              String(36) PK default uuid4()
user_id         String(64) FK users.id index
title           String(255)
body            Text
type            String(64) index  // escalation|quorum_request|upvote_milestone|comment_reply|system_notice
reference_id    String(255) nullable
is_read         bool default false
created_at      DateTime server_default now() index  // + composite ix_notifications_user_id_is_read

representative_profiles
--------------------------
id              String(255) PK
user_id         int FK users.id unique index NOT NULL
official_name   String(255)
title           String(255)
ward            String(255) index
department      String(64) nullable default "all"
is_unclaimed    bool default false
contact_email   String(255) nullable
contact_phone   String(50) nullable
verified_at     DateTime default utcnow()

user_gamifications + user_badges
--------------------------
user_gamifications: id PK, user_id FK unique index, streak_days, last_streak_date, impact_score, created_at, updated_at, badges (relation)
user_badges: id PK, user_id FK index, badge_id String(50), unlocked_at, UNIQUE(user_id,badge_id) uq_user_badge
```

Local Hive never re-creates these as SQLite tables; they are cached as `rep_cache`, `gamification_cache`, `notifications` JSON via `local_store.dart:132`.

---

## 6. Outbox — Hive Queue (Not Drift Table)

Extend the **existing** Hive outbox (`app/lib/features/compose/data/offline_outbox_queue.dart:39`):

```text
Hive keys
--------------------------
locallens_outbox_queue_v1   JSON list<ComposeDraft|GenericAction>
locallens_outbox_attempts_v1  Map<actionId, retry_count>
locallens_uploads_v1          Map<localMediaKey, _UploadedMedia(id,url)>
locallens_captured_media_v1   JSON array<CapturedMedia>
```

Generic action stored (for votes/comments/quorum too, not just issues):

```text
outbox action JSON
--------------------------
id                  String UUID  // client_action_id, reused on retry — idempotency key
action_type         String  // ISSUE_CREATE | UPVOTE | COMMENT | QUORUM_VOTE | MEDIA_UPLOAD
entity_type         String  // ISSUE | COMMENT | VOTE
entity_id           String|int  // local_id (draft_<microseconds> or issue id)
payload             JSON  // { title, description, category, latitude, longitude, is_anonymous, media_urls, latitude, longitude, vote, content, ... }
client_action_id    String UUID  // same as id, sent as X-Client-Action-Id header
created_at          ISO8601
status              String  // pending | syncing | synced | failed
retry_count         int
last_attempt_at     ISO8601 nullable
error_message       String nullable
depends_on          String nullable  // localId of parent action (e.g., comment depends on issue-create server_id)
```

Example (upvote):
```json
{
  "id": "action-550e8400-e29b-41d4-a716-446655440000",
  "action_type": "UPVOTE",
  "entity_type": "VOTE",
  "entity_id": "issue-456",
  "client_action_id": "action-550e8400-e29b-41d4-a716-446655440000",
  "payload": { "issue_id": 456, "latitude": 19.1136, "longitude": 72.8697 }
}
```

---

## 7. Client-Generated IDs

Every action gets `UUID v4` on device. Same `client_action_id` is reused on retries and sent as `X-Client-Action-Id` header. Backend `idempotency_keys` table dedupes.

## 8. Idempotency (Now — Not Deferred)

Backend new table (Alembic migration):

```text
idempotency_keys
--------------------------
client_action_id  String PK
user_id           int FK users.id index
action_type       String(32)
response_json     Text  // previous success response
created_at        DateTime server_default now()
```

Flow:
```text
Flutter (X-Client-Action-Id: ABC123) → FastAPI
  ├── Already processed ABC123 for this user?
  │     ├── YES → return stored response_json (200, no side effect)
  │     └── NO  → process, store response, return
```

Prevents: duplicate issue-create, duplicate votes/comments/media when response is lost. Upvote/Quorum already have `UniqueConstraint(issue_id,user_id)` as second guard, but issue-create needs idempotency.

---

## 9. Optimistic UI

```text
User taps Upvote
  → update Hive vote state (has_upvoted=true, upvotes_count+1) + UI immediately
  → enqueue outbox action with client_action_id
  → SyncManager tries Dio POST with X-Client-Action-Id
  → on 200: confirm Hive + mark synced
  → on 4xx permanent: rollback Hive + show “sign-in/proximity” error (existing friendlyErrorMessage)
```

Same for `Comment` (append to `comments/<issueId>.json` Hive), `Create Issue` (insert into `issues/cache` Hive with `sync_status=pending` and local `draft_<id>`).

---

## 10. Upvote Example (Upvote-only)

1. Local Hive: `has_upvoted=true`, `upvotes_count 125→126`
2. UI reflects immediately (optimistic).
3. Enqueue `UPVOTE` with `client_action_id`.
4. Dio `POST /issues/{id}/upvote` with `X-Client-Action-Id`, include `latitude/longitude` for `5km` proximity check.
5. Backend validates proximity + `5/10min` rate limit + `UniqueConstraint` → `200` or `400 already_upvoted`/`403 guest_restricted`.
6. On `200`: Hive confirmed. On `4xx` permanent: rollback Hive and surface error; on `5xx/timeout`: keep pending, retry with same `client_action_id`.

No `DOWNVOTE` step — LocalLens uses `toggleUpvote (upvote ↔ removeUpvote)` only.

---

## 11. Offline Behaviour

When offline ( `connectivity_plus` → `offline` + `GET /health` ping fails):

```text
User action → Hive (optimistic) → UI updated → Outbox (pending) → WAIT
```

Allowed offline (now extended to votes/comments, not just issue-create):
```text
✓ Upvote (toggle) — optimistic, queued
✓ Comment / Reply — optimistic, queued (parent_id preserved)
✓ Quorum vote (confirm/dispute) — optimistic, queued (5km check deferred to server, show “will verify when online”)
✓ Create issue with media — stored with local file path, queued
✓ View cached feed/issues/comments/profile/ward detail/reels — from Hive
✓ Search recent (Hive) — no live search offline
```

---

## 12. Connectivity Listener

```text
connectivity_plus onConnectivityChanged
  → No connection → Mobile/WiFi
      → connectivity_plus event (trigger, not proof)
          → HTTP GET /health ping (actual reachability)
              → if reachable → SyncManager.start()
```

Existing `app/lib/core/network/offline_sync_worker.dart:22` already listens for `initialOnline || recovered`; add the `GET /health` ping gate before `flush()`.

---

## 13. SyncManager (Hive-based, Free)

Dedicated `SyncManager` (extends existing `OfflineSyncWorker` + `OfflineOutboxQueue`):

```text
1. isSyncing guard (single flight, existing _inFlight future chain offline_outbox_queue.dart:46)
2. Order by created_at ASC (chronological)
3. Respect depends_on (issue-create → media upload → server_id → dependent votes/comments)
4. For each action: set syncing → Dio with X-Client-Action-Id → on 2xx remove from queue + update Hive cache → on 429/500/timeout → retry_count++ + backoff → keep pending
5. Upload pending media via MediaService._UploadedMedia dedupe cache before dependent issue-create
6. Remove successful outbox items, persist failed with error_message for UI
```

---

## 14. Queue Ordering

```text
10:01 Create Issue (local_draft_1)
10:02 Upvote Issue 42
10:03 Comment on 42
→ Process in order; if 10:02 depends on 10:01 server_id, hold until 10:01 synced.
```

---

## 15. Handling Dependencies

```text
Create Issue (local_draft_abc)
  → local media copied to app storage issues/local_draft_abc/img.jpg
  → outbox ISSUE_CREATE with client_action_id
  → SyncManager uploads media → receives remote url → stores in _uploads cache
  → POST /issues with media_urls + client_action_id → receives server_id
  → update Hive: draft_<abc>.server_id = serverId, sync_status=synced
  → dependent COMMENT/UPVOTE actions now can use server_id
```

Field `depends_on` points to parent `client_action_id`.

---

## 16. Retry Strategy — Exponential Backoff (Free)

```text
retry 1 → 2s, retry 2 → 5s, retry 3 → 15s, retry 4 → 30s, retry 5 → 60s
After 5 → status=failed (keep for manual retry, don’t auto-drop)
```

Current `OfflineOutboxQueue` drops after 5 immediately; change to `failed` retention with user-visible retry button (`OutboxScreen`).

---

## 17. Permanent vs Temporary Errors

Temporary (retry same `client_action_id`): `Timeout, Dio 429/500/502/503, SocketException, Connection reset`
Permanent (mark failed, rollback optimistic, show error): `400 invalid payload/category, 401/403 guest_restricted/is_banned, 404 not_found, 422 validation, 409 already_upvoted/duplicate_flag` — do not retry.

---

## 18. Media Handling — App Storage (Free)

```text
User selects image → copy to getApplicationDocumentsDirectory()/issues/<localId>/img_<uuid>.jpg
→ store local_path in CapturedMedia + draft.media.local_path
→ show issue immediately from Hive (local_path)
→ enqueue MEDIA_UPLOAD action or piggyback on ISSUE_CREATE (media_urls)
```

Do not keep `bytesBase64` in Hive (memory heavy); store file path. Keep `is_fuzzed/is_in_app_camera/capturedAt` for server watermark `LocalLens Verified` vs `Unverified`.

---

## 19. Media Queue — Hive, Not SQLite

```text
Hive map locallens_media_uploads_v1
  key: local_path
  value: { status: pending|uploading|uploaded|failed, remote_url, retry_count, error }
```

Flow: `find pending → verify File.exists → Dio POST /media/upload → receive remote_url → update draft.media_urls → mark uploaded`. Only delete local file after issue synced and remote_url confirmed.

---

## 20. Image Synchronization

When online, `SyncManager` drains `locallens_media_uploads_v1` before dependent `ISSUE_CREATE` (mediaService per media). Same `X-Client-Action-Id` per file.

---

## 21. Local Cache Strategy — Hive TTL

Keep (with `cache_meta.json { lastFetchedAt, ttlHours }`):
```text
- Last 2 pages of GET /feed (all/mywars, 20 each)
- Last viewed ward_detail_<slug> + rep_cache
- User’s own issues (GET /auth/me/issues)
- Recent comments per viewed issue
- Notifications last 20 (optional)
```

Evict when `now - lastFetchedAt > ttlHours (24h for feed, 7d for ward)` and not pending. **Never evict** `pending outbox`, `pending media`, `locally created unsynced issues` (same as original §21 rule).

---

## 22. Feed Loading — Read Hive First

```text
Open Home → read Hive issue_cache immediately → display cached feed + StaleBanner (“showing cached data · offline” if isStale or offline)
  → background Dio GET /feed?cursor=<lastId> → diff → update Hive + Riverpod → UI auto-updates (no spinner)
```

Already done for `rep_cache/ward_cache`; extend to `issue_cache` via `FeedRepository` read-through: `Repository.getFeed() → if Hive has data return it, then async refresh`.

---

## 23. Nearby Issues — GPS + Hive

```text
GPS (19.1136,72.8697 default) → Hive nearby query (haversine filter on cached issues) → display immediately
When online → Dio GET /issues?lat&lng&radius → update Hive
```

---

## 24. Conflict Resolution — Last Write Wins (Vote), Append-Only (Comments)

- **Upvote:** last local `has_upvoted` boolean is desired state; server `UniqueConstraint + has_upvoted` wins. No counter blind increment — use `upvotes_count` from server response to correct optimistic +1/-1.
- **Quorum vote:** `confirm/dispute` last vote per `issue_id+user_id` (`UniqueConstraint`); if offline queued `confirm` then `dispute` before sync, collapse to last.
- **Comments:** append-only per `issue_id+parent_id`, no conflict — `UUID` id, server `parent_id` thread preserved.
- **Issues:** backend `status` is source of truth; local `sync_status` pending → resolved/rejected. Future editing would use `updated_at` version check (backend `DateTime`).

---

## 25. Local IDs vs Server IDs

```text
local_id:  draft_1714000000 or UUID (Hive key)
server_id: int (backend Issue.id)
Before sync: server_id = null, display local issue with “Waiting for connection…” badge
After sync: server_id = 87432, update Hive key, replace local_id references in dependent outbox actions
```

---

## 26. Repository Pattern — Hive + Dio

```dart
UI → Repository (FeedRepository / IssueRepository) → Hive Box / Dio ApiClient
```

Methods:
```text
getFeed({cursor, type, lat/lng}) → Hive read → Dio refresh → Hive write
createIssue(draft) → Hive pending insert + outbox enqueue (optimistic)
upvoteIssue(id, lat/lng) → Hive optimistic toggle → outbox UPVOTE
addComment(issueId, content, parent_id) → Hive append → outbox COMMENT
voteQuorum(issueId, vote) → Hive pending → outbox QUORUM_VOTE
refreshFeed() / syncPending() → SyncManager
```

UI never knows `offline/online/cached/synced` — repository hides it. Remove every `downvoteIssue()` reference (doesn’t exist).

---

## 27. Recommended Folder Structure — Actual LocalLens Layout (Free)

```text
app/lib/
├── core/
│   ├── storage/
│   │   ├── local_store.dart          // Box<String> session/drafts/rep_cache/flagged_issues/ward_cache + new issue_cache/cache_meta
│   │   └── storage_providers.dart    // localStoreProvider
│   ├── network/
│   │   ├── api_client.dart           // Dio + X-Client-Action-Id interceptor
│   │   ├── connectivity_service.dart // wrapped connectivity_plus
│   │   ├── network_providers.dart    // apiClientProvider, connectivitySourceProvider
│   │   └── offline_sync_worker.dart  // listens networkStatusProvider, triggers SyncManager
│   ├── sync/                         // NEW (free, no Drift)
│   │   ├── sync_manager.dart         // single-flight, ordered, depends_on, backoff
│   │   ├── sync_queue.dart           // Hive outbox helpers (wraps OfflineOutboxQueue)
│   │   └── retry_policy.dart         // 2/5/15/30/60 + failed retention
│   └── l10n/ theme/ router/
├── features/
│   ├── feed/data/feed_api.dart, feed_repository.dart
│   ├── compose/data/offline_outbox_queue.dart, hive_draft_store.dart, captured_media_store.dart, media_service.dart
│   ├── issues/presentation/  // IssueCard, comments
│   └── outbox/presentation/outbox_screen.dart  // shows pending/syncing/failed + retry
├── services/  // location_service.dart (already)
└── main.dart  // Hive.initFlutter + LocalStore.init + OfflineSyncWorker init
```

No `core/database/app_database.dart/tables/daos` (Drift) — Hive only.

---

## 28. Application Startup — Hive First

```text
App Start → Hive.initFlutter() → LocalStore.init() (open 7 Boxes) → Load cached user (users/me.json)
  → Load cached feed (issue_cache) → Display UI immediately → Init connectivity_plus listener
  → HTTP GET /health ping → if reachable → SyncManager.checkPendingOutbox()
```

**Do not wait for network before showing UI.**

---

## 29. Background Synchronization Order (Free)

```text
1. Pending media file uploads (oldest first, deduped via _uploads cache)
2. Create Issue (with resolved media_urls)
3. Upvote toggle
4. Comments (respect parent_id)
5. Quorum votes
6. Ward talk posts / Flags (if queued)
```

---

## 30. Sync Lock — Single Flight (Already Partially Done)

```text
SyncManager.isSyncing + _inFlight Future chain (existing offline_outbox_queue.dart:46)
  isSyncing=true → only one SyncManager.run() at a time
  Connectivity event while syncing → queued next run, not parallel
  isSyncing=false after completion
```

---

## 31. Error Handling — Per Action

Store per action:
```text
client_action_id, retry_count, last_attempt_at, error_message, status, http_status
```

Surface in `OutboxScreen`: `○ Waiting — retry 2/5`, `! Failed: Invalid category (won’t retry)`. Keep history for debugging.

---

## 32. UI Sync Indicators — Subtle, Not Noisy

```text
☁ Synced  ·  ⟳ Syncing  ·  ○ Waiting for internet  ·  ! Failed (tap to retry)
```

For locally created issue card: footer `Waiting for connection…` chip + `is_pending` badge; globally show `OfflineBanner` when `networkStatus==offline` or `cache_meta.isStale`.

---

## 33. Security Considerations — No Secrets in Hive

Do not store `jwt_secret`, `anon_hmac_secret`, `code_hash` in Hive. Store `access_token` only in `Box<String> session` (already `hive_ce`) — for production migrate to `flutter_secure_storage` (free, `keychain/keystore`) in follow-up. Never store `OtpCodes`.

---

## 34. Database Migrations — Hive Versioning (Free) + Backend Alembic

Local: Hive boxes are schemaless JSON — add `boxVersion = 2` in `local_store.dart` init; on version bump, migrate `issue_cache` JSON keys (e.g., rename `ward_id` → `ward` if old cache exists) without deleting pending outbox. Never `await Hive.deleteFromDisk()` casually. Backend: `Alembic` (`alembic revision --autogenerate`) for `idempotency_keys` table.

---

## 35. Testing Strategy

All tests use `Hive` in-memory (temp dir) + `mockito` Dio + `fake_async` for backoff.

- **Online:** mock Dio 200 → Hive confirmed, outbox removed.
- **Offline:** disconnect `connectivity_plus` → action enqueued, Hive optimistic shown.
- **Reconnect:** stub `GET /health 200` → `SyncManager` drains queue in order, media first.
- **Lost response:** `client_action_id` reused → second retry returns 200 with stored response, no duplicate.
- **Multiple actions:** offline create 3 issues + 2 comments + 1 upvote → reconnect → all sync in order, dependent comments wait for server_id.
- **Restart:** kill app mid-queue → `Hive` persists, on next launch `LocalStore.init()` reloads queue and resumes.
- Existing suites: `backend/tests/features/issues/test_vote_dedup.py 4/4` + `test_feed_cursor.py 2/2` remain green.

---

## 36. Recommended Implementation Order — Hive Phases (Free, Incremental)

### Phase 1 — Hive Cache Boxes (No Drift)

Add Hive boxes `issue_cache`, `cache_meta`, extend `local_store.dart` to read/write `issues/me/wards/media` JSON. Verify CRUD via `dart test`.

### Phase 2 — Local Feed Read-First

Repository `getFeed()` → Hive `issue_cache` → UI immediately → background `Dio GET /feed` → update Hive. Add `StaleBanner`.

### Phase 3 — Optimistic Upvote/Comment (Hive)

Upvote toggle + comment append optimistically in Hive before Dio. Add `loadMore` cursor already uses `(created_at,id)` tie-breaker (done in `bm2`).

### Phase 4 — Generic Hive Outbox

Extend `OfflineOutboxQueue` from issue-only to `UPVOTE/COMMENT/QUORUM_VOTE` with `client_action_id`. Keep Hive queue, not SQLite.

### Phase 5 — SyncManager + Connectivity Ping

Wrap `OfflineSyncWorker` + `OfflineOutboxQueue` into `SyncManager` with single-flight, ordered drain, `GET /health` gate, `isSyncing` lock.

### Phase 6 — Idempotency (Now)

Dio interceptor adds `X-Client-Action-Id` per action; backend `idempotency_keys` table + `Alembic migration`; test duplicate retry.

### Phase 7 — Retry with Backoff

Replace fixed 5-drop with `2/5/15/30/60s` + `failed` retention in Hive, manual retry in `OutboxScreen`.

### Phase 8 — Offline Issue Creation + Media File

Copy image to `appDocuments/issues/<localId>/img.jpg` (file path, not base64), store `local_path`, enqueue `ISSUE_CREATE` + `MEDIA_UPLOAD`, dedupe via `_uploads` map.

### Phase 9 — Media Synchronization

Drain `locallens_media_uploads_v1` before dependent issue, verify `File.exists`, upload, store `remote_url`.

### Phase 10 — Conflict Resolution & Cache Eviction

Last-write-wins for upvote, append-only comments, TTL eviction (24h feed, 7d ward) never deleting pending.

---

## 37. Final Data Flow

### Reading

```text
Flutter UI → Repository → Hive issue_cache → Immediate UI → Background Dio GET /feed → Hive update → UI
```

### Writing

```text
User Action → Repository → Hive optimistic → UI → Outbox (Hive, client_action_id) → SyncManager → Dio + X-Client-Action-Id → FastAPI (idempotency_keys) → 200 → Hive synced
```

### Offline

```text
User Action → Hive → UI → Outbox → WAIT (isSyncing=false, retry_count++ on ping fail)
```

### Reconnection

```text
connectivity_plus event → GET /health 200 → SyncManager oldest pending → Dio → 2xx remove, 4xx fail+rollback, 5xx retry later
```

---

## 38. Final Architecture Principle

```text
USER ACTION → Hive (local, optimistic) → UI → Outbox (Hive, client_action_id) → ONLINE? → Dio + Idempotency → FastAPI → CONFIRMATION → Hive synced
                                     ↘ OFFLINE → WAIT → connectivity_plus + health ping → retry
```

**Philosophy:** UI never waits for network. Hive makes it fast, Outbox makes it reliable, optimistic makes it feel instant, SyncManager + idempotency makes it eventually consistent — all free.

For initial implementation build **Hive Boxes + Repository read-through + Generic Outbox + SyncManager + Idempotency** first.
