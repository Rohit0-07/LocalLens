# F-C — Representative Accountability & Public Performance Plan

Feature: separate representative accounts with a performance-focused dashboard + publicly
visible rep-performance data (ward page and public profile).

## 1. Scope & ownership

### Files to CREATE
| File | Purpose |
|---|---|
| `app/lib/features/rep_dashboard/domain/public_representative_profile.dart` | Public rep model (mirrors backend `PublicRepresentativeProfileOut`). |
| `backend/tests/features/representatives/test_rep_accountability.py` | New backend pytest module (or extend existing file — see §4). |
| `app/test/features/rep_accountability/rep_accountability_test.dart` | New widget-test module. |

### Files to MODIFY
| File | Change |
|---|---|
| `backend/app/features/representatives/schemas.py` | Add `RepresentativeMetricsOut` base; extend `RepresentativeProfileOut`; add `PublicRepresentativeProfileOut`. |
| `backend/app/features/representatives/service.py` | Add `compute_rep_metrics`, `get_public_rep_by_user`, refactor `get_representative_profile_out`. |
| `backend/app/features/representatives/router.py` | Add public `GET /representatives/by-user/{user_id}`; add public IP rate limiter. |
| `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with `id`, `user_id`, `ward`, and metrics (reuse `RepresentativeMetricsOut`). |
| `backend/app/features/wards/service.py` | Populate the new `AssignedRepresentativeOut` fields via `compute_rep_metrics`. |
| `seed/data/users.json` | Set user `id: 2` role `citizen` → `representative` (seeded rep Meera Iyer). |
| `seed/data/official_responses.json` | Add one `official_response` row pointing at a `resolved` ward issue (issue 7 or 15) so the demo rep has a non-zero `resolved_ward_issues`. |
| `app/lib/features/rep_dashboard/domain/representative_profile.dart` | Add `resolvedWardIssues`, `inProgressWardIssues`, `acknowledgedWardIssues`, `responseRatePct`, `avgResponseTimeHours` (optional, default 0). |
| `app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart` | Add `publicRepProfileProvider` (family, keyed by `user_id`) + repository wiring. |
| `app/lib/features/rep_dashboard/data/repositories/rep_dashboard_repository.dart` | Add `fetchPublicRepByUser(int userId)`. |
| `app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart` | Add Resolved / Responded / In-progress / Acknowledged metric cards + "Performance" section. |
| `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` | Render resolved/pending/response-rate metrics; `onTap` → rep public profile. |
| `app/lib/features/profile/presentation/screens/public_profile_screen.dart` | Render rep performance section when target user is a rep. |
| `app/lib/features/ward/domain/ward_representative_out.dart` | **Documented exception** — additive fields `id`, `userId`, `ward` (defaulted). |

### Files to NOT touch (parallel-agent conflicts)
- `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`,
  `app/lib/features/feed/**`
- `app/lib/features/profile/presentation/screens/profile_screen.dart`,
  `app/lib/features/profile/domain/user_profile.dart`,
  `app/lib/features/profile/presentation/profile_providers.dart` (OWN profile page = another feature)
- `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`,
  `app/lib/features/ward/presentation/providers/**`, `app/lib/features/ward/domain/ward_detail_out.dart`,
  `app/lib/features/ward/data/**` (ward detail screen/providers/domain/data = another feature)
- `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/search/**`

**Exception rationale for `ward_representative_out.dart`:** requirement #2 mandates rep
performance on the ward detail page, and `WardRepCard` (allowed) must know the rep `user_id`
to fetch metrics (via the shared rep_dashboard provider) and to navigate to `/users/{id}`.
`WardDetailOut`/`AssignedRepresentativeOut` already flow through `WardRepresentativeOut.fromJson`,
so the change is purely additive (new defaulted fields, existing parsing untouched). The
alternative — changing `WardDetailScreen`'s constructor — is forbidden. Keep it minimal and
additive; do NOT touch `ward_detail_screen.dart`, ward providers, or ward data layer.

### Provider ownership decision
Public rep-metrics provider lives in `app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart`
(`publicRepProfileProvider`). `public_profile_screen.dart` and `ward_rep_card.dart` watch it.
`profile_providers.dart` is NOT edited.

## 2. Backend design

### 2a. Schema (`backend/app/features/representatives/schemas.py`)

New base model (flat fields, all defaulted so it is embeddable everywhere):

```python
class RepresentativeMetricsOut(BaseModel):
    total_ward_issues: int = 0
    escalated_ward_issues: int = 0
    responded_ward_issues: int = 0
    pending_response_ward_issues: int = 0
    resolved_ward_issues: int = 0
    in_progress_ward_issues: int = 0
    acknowledged_ward_issues: int = 0
    response_rate_pct: float = 0.0
    avg_response_time_hours: float = 0.0
```

`RepresentativeProfileOut(RepresentativeMetricsOut)` keeps its existing fields
(`id, user_id, official_name, title, ward, verified_at`) — flat keys preserved, so the existing
frontend parser and the 9 existing tests remain valid. New fields are the 5 additions
(`resolved_ward_issues`, `in_progress_ward_issues`, `acknowledged_ward_issues`,
`response_rate_pct`, `avg_response_time_hours`).

New public schema (no auth needed to read):

```python
class PublicRepresentativeProfileOut(RepresentativeMetricsOut):
    id: str
    user_id: int
    official_name: str
    title: str
    ward: str
    verified_at: datetime | None = None
```

`backend/app/features/wards/schemas.py` — `AssignedRepresentativeOut` becomes
`AssignedRepresentativeOut(RepresentativeMetricsOut)` with `id: str`, `user_id: int`,
`ward: str`, `official_name`, `title`, `verified_at`. This keeps the ward-detail JSON
self-sufficient and mirrors the public schema.

### 2b. Metrics computation (`backend/app/features/representatives/service.py`)

`async def compute_rep_metrics(session: AsyncSession, profile: RepresentativeProfile) -> RepresentativeMetricsOut`
runs these exact queries (all against `Issue.ward == profile.ward`):

1. **total** — `select(func.count(Issue.id)).where(Issue.ward == profile.ward)`
2. **escalated** — same + `Issue.status == "escalated"` (unchanged semantics)
3. **responded** (distinct issues with ≥1 `OfficialResponse`, any rep — unchanged):
   `select(func.count(func.distinct(Issue.id))).select_from(Issue).join(OfficialResponse, OfficialResponse.issue_id == Issue.id).where(Issue.ward == profile.ward)`
4. **pending** — `max(0, total - responded)`
5. **resolved (rep-attributable)**:
   `select(func.count(func.distinct(Issue.id))).select_from(Issue).join(OfficialResponse, OfficialResponse.issue_id == Issue.id).where(Issue.ward == profile.ward, OfficialResponse.representative_id == profile.id, Issue.status == "resolved")`
6. **acknowledged / in_progress** — latest response per issue, then bucket by its
   `status_update`. One query, portable, deterministic:
   ```python
   stmt = (
       select(Issue.id, OfficialResponse.status_update)
       .join(Issue, Issue.id == OfficialResponse.issue_id)
       .where(Issue.ward == profile.ward, OfficialResponse.representative_id == profile.id)
       .order_by(OfficialResponse.created_at.desc(), OfficialResponse.id.desc())
   )
   rows = (await session.execute(stmt)).all()
   # first-seen issue_id wins (already newest-first) → latest response per issue
   # count status_update == "acknowledged" / == "in_progress"; NULL status_update is counted in neither bucket.
   ```
7. **response_rate_pct** — `round(responded / total * 100, 2)`; `0.0` if `total == 0`.
8. **avg_response_time_hours** — first response per issue, computed in Python (portable across
   SQLite/Postgres; avoid SQLite-only `julianday`):
   ```python
   first_resp = (
       select(OfficialResponse.issue_id, func.min(OfficialResponse.created_at))
       .where(OfficialResponse.representative_id == profile.id)
       .group_by(OfficialResponse.issue_id)
   )
   rows = (await session.execute(
       select(Issue.created_at, first_resp.c[1]).join(Issue, Issue.id == first_resp.c[0])
       .where(Issue.ward == profile.ward)
   )).all()
   # avg of (resp_created - issue_created).total_seconds()/3600 over rows with both timestamps non-null;
   # clamp negatives to 0.0; 0.0 if no rows. Round to 1 decimal.
   ```

`get_representative_profile_out` is refactored to call `compute_rep_metrics` and return
`RepresentativeProfileOut` with the existing fields + new metrics.

New public service fn: `async def get_public_rep_by_user(session, user_id) -> PublicRepresentativeProfileOut`
— look up `RepresentativeProfile.user_id == user_id`; `None` → `AppError("Representative not found", 404, "rep_not_found")`; else compute metrics and return.

### 2c. Endpoints (`backend/app/features/representatives/router.py`)

New **public** endpoint (no `CurrentUser`/`RepProfileDep`):

```python
@router.get("/representatives/by-user/{user_id}", response_model=PublicRepresentativeProfileOut)
async def get_public_rep_profile(user_id: int, request: Request, session: SessionDep) -> PublicRepresentativeProfileOut:
    # IP-based rate limit via lazy request.app.state.public_rep_rate_limiter
    # (mirror wards._check_rate_limit pattern; 60 req / 60s per IP)
    return await service.get_public_rep_by_user(session, user_id)
```

- Declared AFTER `/representatives/me` and `/representatives/ward-issues` (literal paths win by
  declaration order; no `{rep_id}` dynamic route is added, so no shadowing risk).
- Public response exposes only public data (`user_id` is already public via
  `/users/{user_id}` → `PublicUserProfileOut.id`).
- `/representatives/me` continues to require a rep token and now returns the extended schema.

`backend/app/features/wards/service.py` — in `get_ward_detail`, build
`AssignedRepresentativeOut` with `id=rep.id, user_id=rep.user_id, ward=rep.ward` plus
`**compute_rep_metrics(...).model_dump()` (import the fn from representatives.service).

### 2d. Seed

- Reps are already provisioned via `seed.py` + `seed/data/representatives.json`
  (`rep_ward45_urban_central`, user 2). **Yes, keep the seeded demo rep** — but:
  - `seed/data/users.json`: user `id: 2` `role` → `"representative"` (currently `"citizen"`),
    so the public-profile role badge and any role checks are correct.
  - `seed/data/official_responses.json`: add a row for a `resolved` ward issue (issue 7 or 15,
    `representative_id: "rep_ward45_urban_central"`, `status_update: "acknowledged"`) so the demo
    rep has non-zero `resolved_ward_issues`; today none of the 5 responded issues are resolved.
  - No code change to `seed.py` needed (its factories already pass `role` and `official_responses`).

## 3. Frontend design

### 3a. Models

`app/lib/features/rep_dashboard/domain/representative_profile.dart` — add optional defaulted
fields: `resolvedWardIssues = 0`, `inProgressWardIssues = 0`, `acknowledgedWardIssues = 0`,
`responseRatePct = 0.0`, `avgResponseTimeHours = 0.0`. `fromJson` parses
`resolved_ward_issues`, `in_progress_ward_issues`, `acknowledged_ward_issues` as
`(json[...] as num?)?.toInt() ?? 0`; the two floats as `(json[...] as num?)?.toDouble() ?? 0.0`.
Update `toJson`. Keep all existing fields/keys.

`app/lib/features/rep_dashboard/domain/public_representative_profile.dart` (new) —
`PublicRepresentativeProfile` with `id, userId, officialName, title, ward, verifiedAt` and the
same 9 metric fields; `fromJson`/`toJson` matching `PublicRepresentativeProfileOut` snake_case keys.

`app/lib/features/ward/domain/ward_representative_out.dart` — ADD (defaulted so the 2 existing
test constructions at `ward_detail_screen_test.dart:78` and `offline_sync_onboarding_extended_test.dart:138`
still compile): `id = ''`, `userId = 0`, `ward = ''`. Parse `json['id']`, `json['user_id']`,
`json['ward']`. Do NOT change existing fields.

### 3b. Repository + providers

`rep_dashboard_repository.dart` — add:
```dart
Future<PublicRepresentativeProfile?> fetchPublicRepByUser(int userId) async {
  try {
    final json = await _apiClient.getJson('/representatives/by-user/$userId');
    return PublicRepresentativeProfile.fromJson(json as Map<String, dynamic>);
  } on ApiServerException catch (e) {   // 404 → not a rep
    if (e.statusCode == 404) return null;
    rethrow;
  }
}
```

`rep_dashboard_providers.dart` — add:
```dart
final publicRepProfileProvider =
    FutureProvider.family<PublicRepresentativeProfile?, int>((ref, userId) async {
  if (userId <= 0) return null;                 // guards ward tests w/ default userId=0
  return ref.watch(repDashboardRepositoryProvider).fetchPublicRepByUser(userId);
});
```
Shared by `ward_rep_card.dart` and `public_profile_screen.dart`. No edits to `profile_providers.dart`.

### 3c. Rep dashboard screen (`rep_dashboard_screen.dart`)

Keep existing keys/`_MetricCard`. Restructure the metric row into a `Wrap` (two rows of cards)
and add, preserving all existing keys:
- `metricRespondedWardIssues` → `profile.respondedWardIssues` (parsed but never shown today)
- `metricResolvedWardIssues` → `profile.resolvedWardIssues`
- `metricInProgressWardIssues` → `profile.inProgressWardIssues`
- `metricAcknowledgedWardIssues` → `profile.acknowledgedWardIssues`

Add a "Performance" card after the metrics wrap:
- `repPerformanceCard` (Card) with
  - `repResponseRateValue` → `'${profile.responseRatePct.toStringAsFixed(1)}%'` (guard 0.0)
  - `repAvgResponseTimeValue` → `'${profile.avgResponseTimeHours.toStringAsFixed(1)}h'`
- Label the section `context.tr('rep_performance_title')` (add a string or reuse existing
  l10n pattern; hardcoded English matches current file style).

### 3d. Ward rep card (`ward_rep_card.dart`)

Convert `WardRepCard` to a `ConsumerWidget`. Keep `wardRepCard` key, header layout, and the
existing constructor signature (`representative`, optional `onTap`). Render a metrics row
(when `representative.userId > 0` and provider data != null):
- `wardRepResolvedMetric` → `'${rep.resolvedWardIssues}'`
- `wardRepPendingMetric` → `'${rep.pendingResponseWardIssues}'`
- `wardRepResponseRateMetric` → `'${rep.responseRatePct.toStringAsFixed(1)}%'`

`onTap` → `context.push(RoutePaths.publicProfileFor(representative.userId))` (guard
`userId > 0`; keep supplied `onTap` fallback when provided). Watch
`publicRepProfileProvider(representative.userId)`; render header only while loading/error/null
(never crash; provider returns null for userId ≤ 0 so existing ward tests stay green).

### 3e. Public profile screen (`public_profile_screen.dart`)

After the `publicImpactStatsCard` section (before badges), when
`publicRepProfileProvider(profile.userId)` resolves non-null, render:
- Card key `publicRepPerformanceCard`, title "Representative Performance".
- Keys: `publicRepResolvedCount`, `publicRepPendingCount`, `publicRepInProgressCount`,
  `publicRepAcknowledgedCount`, `publicRepResponseRate`, `publicRepAvgResponseTime`.
Hide the section entirely for citizens (provider → null). Import from
`features/rep_dashboard/presentation/rep_dashboard_providers.dart`. Keep all existing keys.

### 3f. Route linkage (documentation-only hook)

`/rep-dashboard` route already exists in `app_router.dart`. Reps currently have no dock/tab
entry; the OWN profile screen (`profile_screen.dart`, forbidden to edit) is the natural owner —
document the hook for that feature: in `profile_screen.dart`, when
`userProfile.role == 'representative'`, add a tile calling
`context.push(RoutePaths.repDashboard)`. No code change here.

## 4. User-journey E2E test plan

### Backend pytest (`backend/tests/features/representatives/test_rep_accountability.py`)

Reuse `_setup_representative` / `_create_issue` helpers (add a `_create_issue` variant that
takes `status` and direct-inserts `official_responses` rows with controlled `created_at` via
SQL, matching existing style).

- **BE-ACC-01** `/representatives/me` returns extended metrics: create 4 ward issues
  (`unacknowledged`, `acknowledged`, `in_progress`, `resolved`); post responses with
  `status_update` `acknowledged` / `in_progress`; assert `resolved_ward_issues`,
  `in_progress_ward_issues`, `acknowledged_ward_issues`, `response_rate_pct`,
  `avg_response_time_hours` values exactly. Existing 9 tests must still pass unchanged.
- **BE-ACC-02** Public `GET /representatives/by-user/{user_id}` — 200 **without auth**, returns
  `PublicRepresentativeProfileOut` with correct metrics + `user_id`.
- **BE-ACC-03** Security: citizen token → `/representatives/me` 403 (existing); `by-user` for a
  non-rep citizen → 404 `rep_not_found`; `by-user` for a nonexistent user id → 404; guest →
  `by-user` still 200 for a rep (public data).
- **BE-ACC-04** Ward boundary: rep in Ward A; resolved/responded issues in Ward B → those do NOT
  inflate rep A's metrics; `by-user` for rep A reflects only Ward A.
- **BE-ACC-05** Edge — zero responses: rep with issues but no responses → `responded=0`,
  `pending=total`, ack/in_progress/resolved `0`, `response_rate_pct=0.0`, `avg=0.0`.
- **BE-ACC-06** Edge — empty ward: rep with zero issues → all metrics 0; no division-by-zero.
- **BE-ACC-07** Edge — unresolved-only ward: no `resolved` status → `resolved_ward_issues=0`.
- **BE-ACC-08** Latest-response bucketing: respond to one issue twice (`acknowledged` then
  `in_progress`) → counts as in_progress only, still counts as `responded=1`.
- **BE-ACC-09** Rep-attributable resolved: a `resolved` issue the rep never responded to → NOT in
  `resolved_ward_issues`; a `resolved` issue the rep responded to → counted. Assert seed-data
  consistency (`resolved_ward_issues` uses `representative_id` filter).
- **BE-ACC-10** Avg response time: issue `created_at` + response `created_at` 24h later → `24.0`;
  multiple issues averaged; missing timestamp rows skipped.
- **BE-ACC-11** Ward detail: `GET /wards/{slug}` → `assigned_representative` includes
  `id`, `user_id`, `ward`, and all metric fields.

### Flutter widget tests (`app/test/features/rep_accountability/rep_accountability_test.dart`)

Override `repProfileProvider`, `wardIssuesProvider`, `publicRepProfileProvider` with fixed
fixtures (extend `sampleProfile` with new metric fields).

- **FE-ACC-01** RepDashboardScreen shows new cards: keys `metricResolvedWardIssues`,
  `metricRespondedWardIssues`, `metricInProgressWardIssues`, `metricAcknowledgedWardIssues`,
  `repPerformanceCard`, `repResponseRateValue`, `repAvgResponseTimeValue` with correct values;
  existing keys still present.
- **FE-ACC-02** WardRepCard: with `WardRepresentativeOut(userId: 42, ...)` + overridden
  `publicRepProfileProvider(42)` shows `wardRepResolvedMetric`, `wardRepPendingMetric`,
  `wardRepResponseRateMetric`; tapping navigates to `/users/42` (assert route/location).
- **FE-ACC-03** WardRepCard with `userId: 0` (default) renders header, no metrics, no crash
  (existing `ward_detail_screen_test.dart` remains green without new overrides).
- **FE-ACC-04** PublicProfileScreen: rep user (provider returns non-null) shows
  `publicRepPerformanceCard` + sub-keys; citizen user (provider null) hides the section; existing
  public-profile keys unchanged.
- **FE-ACC-05** Edge: all-zero metrics profile → cards render `0` / `0.0%` / `0.0h` without error.

### Full user journey
Citizen opens ward detail → `WardRepCard` shows Resolved / Pending / Response Rate → taps card →
`/users/{rep_user_id}` public profile shows "Representative Performance" stats → rep logs in →
`/rep-dashboard` shows Total / Escalated / Responded / Resolved / In-progress / Acknowledged /
Pending + Performance card. Rep posts an official response and a ward issue resolves → counts
increase on re-fetch (`ref.invalidate(repProfileProvider)` after posting, already wired in
`RepDashboardNotifier`).

## 5. Edge cases & ordering/dependencies

### Edge cases
- `total == 0` → `response_rate_pct = 0.0`, `avg = 0.0` (guard division by zero).
- Latest response has `status_update == NULL` → counted in `responded` but in neither ack nor
  in_progress bucket (documented; existing seeded rows all have status_update).
- Two responses with identical `created_at` → deterministic tiebreak by `id DESC`.
- Response created before issue (bad data) → negative avg clamped to `0.0`.
- Issue resolved without any rep response → not rep-attributable (semantic; ward-level resolved
  already shown separately on the ward page).
- `WardRepCard` with `userId == 0` → no fetch, no navigation, header-only (keeps legacy tests green).
- Cached `WardDetailOut` (`ward_detail_notifier` cache) may show stale `assigned_representative`
  fields — rep card metrics come from a live provider, so only the id/user_id/ward could be stale;
  acceptable (cache TTL behavior unchanged).
- `by-user` public endpoint must NOT return 401/403 for guests/citizens; 404 for non-reps.

### Ordering / dependencies
1. Backend schemas (`RepresentativeMetricsOut` + subclasses) — everything else depends on it.
2. Backend `compute_rep_metrics` + refactor `get_representative_profile_out` → keep 9 existing
   backend tests green before adding features.
3. Backend router `by-user` endpoint; wards `AssignedRepresentativeOut` + service population.
4. Backend new tests (BE-ACC-01..11); run `ruff`, `mypy`, full backend suite.
5. Seed data updates (`users.json` role, `official_responses.json` resolved-issue row).
6. Frontend models (RepresentativeProfile fields, new PublicRepresentativeProfile,
   WardRepresentativeOut additions).
7. Frontend repository `fetchPublicRepByUser` + `publicRepProfileProvider`.
8. Frontend UI: rep dashboard cards → ward_rep_card → public_profile_screen.
9. Frontend widget tests (FE-ACC-01..05); `flutter analyze` clean; run existing
   `rep_dashboard_test.dart` and `ward_detail_screen_test.dart` to confirm no regressions.
10. Manual `uv run python seed.py` to refresh demo data.

Route-ordering note: declare `/representatives/by-user/{user_id}` after the literal
`/representatives/me` and `/representatives/ward-issues` routes (FastAPI matches by declaration
order); no `{rep_id}` dynamic route is introduced, so no `/me` shadowing.