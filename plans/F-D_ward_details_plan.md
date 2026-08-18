# F-D — Ward Details Page (complete civic page + reachability)

Owner feature: **ward**. Delivers a real, complete, reachable ward details page and the
backend/seed support it needs, without touching any parallel-agent files.

---

## 1. Scope & ownership

### 1.1 Files to CREATE

| File | Purpose |
|------|---------|
| `app/lib/features/ward/presentation/widgets/ward_boundary_mini_map.dart` | New `WardBoundaryMiniMap` (flutter_map tile layer + center marker + optional polygon layer + graceful fallback). |
| `app/lib/features/ward/presentation/widgets/ward_rep_performance_strip.dart` | New `WardRepPerformanceStrip` — public rep-performance strip rendered by the ward page (in-scope fallback until the rep feature renders metrics in `WardRepCard`). |
| `backend/app/features/wards/seed.py` | New `seed_wards(session)` — idempotent upsert of the 2 known wards, reading `seed/data/wards.json`. |
| `seed/data/wards.json` | Shared seed data for the 2 wards (single source of truth, coordinated with the map feature). |

### 1.2 Files to MODIFY (in-scope)

| File | Change |
|------|--------|
| `app/lib/features/ward/domain/ward_representative_out.dart` | Add performance + identity fields (see §3.1). |
| `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` | Full page rework (hero→metrics→rep+performance→mini-map→issues→nearby wards). Preserve existing Keys. |
| `app/lib/features/ward/presentation/widgets/ward_hero_banner.dart` | Add top-categories chips, updated-at caption, optional "View map" action. Preserve key `wardHeroBanner`. |
| `app/lib/features/ward/presentation/widgets/ward_recent_issues_list.dart` | Add `showHeader` (default `true`) and optional `emptyMessage` params so the page can reuse it under its own search/filter header. Preserve key `wardRecentIssuesList`. |
| `app/lib/features/ward/presentation/widgets/ward_chip.dart` | No behavior change needed (already pushes `RoutePaths.wardDetailFor(slug)` when `slug` provided). Keep as-is; it becomes reachable via the new nearby-wards section. |
| `app/lib/features/ward/presentation/providers/ward_providers.dart` | Add `wardBoundaryProvider` (returns `const <List<LatLng>>[]` today — the boundary feature's seam). |
| `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with identity + performance fields (§2.1). |
| `backend/app/features/wards/service.py` | Compute rep performance in `get_ward_detail` (§2.2). |
| `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, and a `_seed_wards(session, rows)` loader reading `seed/data/wards.json`. |
| `backend/app/main.py` | (Coordination-flagged, see §1.4) call `seed_wards` in `lifespan` for `environment == "development"` so the page works live without a manual `make seed`. |

### 1.3 Files / dirs to NOT touch (parallel-agent conflicts)

Frontend: `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`,
`app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/rep_dashboard/**`,
`app/lib/features/geo/**`. **Also do not edit `app/lib/features/ward/presentation/widgets/ward_rep_card.dart`**
(owned by the rep-accountability feature) — consume its documented interface only
(`WardRepCard({representative, onTap})`; keep calling it unchanged from the screen).

Backend: `backend/app/features/representatives/**`, `backend/app/features/media/**`,
`backend/app/features/search/**`, `backend/app/features/issues/**`.

Backend boundary polygons are another feature's scope — do NOT add polygon data to the wards
model/response. The mini-map's polygon seam (`wardBoundaryProvider`) returns `[]` until then.

### 1.4 Router & reachability — no edits required, but document

- `app/lib/core/router/app_router.dart` already registers `/ward/:slug` → `WardDetailScreen(wardSlug: slug)`.
- `app/lib/core/router/route_paths.dart` already has `RoutePaths.wardDetailFor(slug)`.
- **Feed header chip**: `app/lib/features/geo/.../ward_location_chip.dart:41` already pushes
  `wardDetailFor(wardSlug)` (geo-owned, off-limits — already wired, no change).
- **Map ward preview**: `app/lib/features/map/.../map_screen.dart:867` already pushes
  `wardDetailFor(ward.slug)` (map-owned, off-limits — already wired, no change).
- **`backend/app/main.py`**: not owned by a parallel agent, but confirm before editing; if any
  feature is reworking lifespan, prefer calling `seed_wards` there and share the call.

Net effect: reachability wiring already exists at every entry surface. The real reachability
gap is the **empty `wards` table** — with it empty, the feed chip's reverse-geocode returns
`found=False` (chip disabled). Seeding the 2 wards (§2.3) is what makes the feed chip and
ward lists live. This plan adds one new in-scope reachability loop: a **nearby-wards section**
on the ward page (uses the currently-unused `WardChip`).

---

## 2. Backend design

### 2.1 `backend/app/features/wards/schemas.py` — extend `AssignedRepresentativeOut`

```python
class AssignedRepresentativeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str | None = None
    user_id: int | None = None
    official_name: str
    title: str
    verified_at: datetime.datetime | None = None
    total_ward_issues: int = 0
    escalated_ward_issues: int = 0
    responded_ward_issues: int = 0
    pending_response_ward_issues: int = 0
    response_rate_pct: float = 0.0
```

This is **backward compatible**: existing `test_ward_place_page.py` asserts
`assigned_representative["official_name"]` / `["title"]` only.

**Contract note (align with rep-accountability feature):** this mirrors the rep feature's
`RepresentativeProfileOut` field-for-field (`total/escalated/responded/pending_ward_issues`)
plus `response_rate_pct` and `id`/`user_id`, minus `ward`. The rep feature may enrich
`WardRepCard` to render these fields; our page renders them independently via
`WardRepPerformanceStrip` so the two do not conflict.

### 2.2 `backend/app/features/wards/service.py` — rep performance in `get_ward_detail`

Replace the `assigned_rep` construction (currently lines ~152–163) so that when a rep matches
the ward, it is enriched. Add a private helper:

```python
async def _get_rep_performance(session, rep: RepresentativeProfile) -> tuple[int, int, int, int, float]
```

Queries (must EXACTLY mirror `representatives/service.py::get_representative_profile_out` to
stay consistent with the rep dashboard numbers):

- `total_ward_issues` = `count(Issue.id)` where `Issue.ward == rep.ward`
- `escalated_ward_issues` = `count` where `Issue.ward == rep.ward` and `status == "escalated"`
- `responded_ward_issues` = `count(distinct Issue.id)` via join on `OfficialResponse`
  (issue_id) where `Issue.ward == rep.ward`
- `pending_response_ward_issues` = `max(0, total - responded)`
- `response_rate_pct` = `round(responded / total * 100, 2)` when `total > 0`, else `0.0`

Return `AssignedRepresentativeOut` with the existing name/title/verified_at plus `id`, `user_id`
and the five performance fields.

### 2.3 Seeding the 2 known wards (shared, coordinated with map feature)

`seed/data/wards.json` (new, single source of truth):

```json
[
  {"slug": "ward-45-urban-central", "name": "Ward 45, Urban Central", "code": "W-45",
   "center_latitude": 19.1136, "center_longitude": 72.8697},
  {"slug": "ward-12-metro-corridor", "name": "Ward 12, Metro Corridor", "code": "W-12",
   "center_latitude": 19.0760, "center_longitude": 72.8777}
]
```

- `backend/app/features/wards/seed.py` — `SEED_WARDS` loaded from the JSON + `seed_wards(session)`
  that does an idempotent upsert keyed on `slug` (insert-or-replace by unique slug), setting
  `updated_at = datetime.utcnow()`.
- `backend/seed.py` — add `Ward` to `_TABLES` (deletion list, no FK concerns), `"wards"` to
  `_DATA_FILES` (first entry), and `_seed_wards(session, rows)` that delegates to
  `app.features.wards.seed.seed_wards`.
- `backend/app/main.py` `lifespan` (development env only): after `create_all()`, open a session
  and call `seed_wards(session)`. Flag in PR: confirm no parallel agent is touching lifespan.

Map feature coordinates by using these exact slugs/coords (they already match the hardcoded
fallback in `map_screen.dart` and the search test seed).

---

## 3. Frontend design

### 3.1 Domain: `app/lib/features/ward/domain/ward_representative_out.dart`

Add fields (keep existing `officialName`, `title`, `verifiedAt`):

```dart
final String? id;
final int? userId;
final int totalWardIssues;          // default 0
final int escalatedWardIssues;      // default 0
final int respondedWardIssues;      // default 0
final int pendingResponseWardIssues;// default 0
final double responseRatePct;       // default 0.0
```

`fromJson`: use tolerant reads (`json['total_ward_issues'] as num? ?? 0`, etc.) so **older
cached `WardDetailOut` JSON without these fields still parses** (provider caches raw JSON in
`LocalStore` — critical edge case). `toJson`: emit snake_case keys.

`WardDetailOut` and `WardSummaryOut` are **unchanged**.

### 3.2 Providers: `app/lib/features/ward/presentation/providers/ward_providers.dart`

Add one seam provider (boundary feature's scope):

```dart
final wardBoundaryProvider =
    FutureProvider.family<List<List<LatLng>>, String>((ref, slug) async {
  return const []; // boundary polygons owned by the map/boundary feature — renders fallback today
});
```

`wardDetailNotifierProvider` / `wardListNotifierProvider` unchanged (detail already carries rep
performance via the extended model).

### 3.3 Page layout (`ward_detail_screen.dart`) — top to bottom

1. **AppBar** — title `context.tr('ward_details')`; leading back button key `wardDetailBackButton`.
2. **Hero** (`WardHeroBanner`, key `wardHeroBanner`) — ward name + code chip; center coords;
   new top-categories chips (one per `topCategories`, key `wardTopCategoryChip_<cat>`); updated-at
   caption; optional trailing action `wardHeroViewMapButton` → `context.go(RoutePaths.map)`.
3. **Metrics** (`WardMetricsGrid`) — unchanged, preserves `wardMetricTotal` / `wardMetricActive` /
   `wardMetricEscalated` / `wardMetricResolved` / `wardMetricResolutionRate`.
4. **Representative section** — header row key `wardRepSectionHeader` ("Ward Representative").
   - If `assignedRepresentative != null`: `WardRepCard(representative: rep, onTap: rep.userId != null ? () => context.push(RoutePaths.publicProfileFor(rep.userId!)) : null)` (fixes the no-op; chevron auto-hides when `onTap` null). Followed by `WardRepPerformanceStrip(rep: rep)` (key `wardRepPerformanceStrip`).
   - Else: keep the "No representative assigned yet" card, add key `wardNoRepPlaceholder`.
5. **Boundary mini-map** — `WardBoundaryMiniMap(ward: wardDetail)` (key `wardBoundaryMiniMap`).
6. **Issues** — keep the search field (`wardIssueSearchField`), the 4 filter tabs
   (Active/Escalated/Resolved/All, `_IssueFilterChip`), the "Ward Issues" header + `N found`
   count, and the existing empty-state card. Render the list via the now-used
   `WardRecentIssuesList(issues: filteredIssues, showHeader: false)` (key `wardRecentIssuesList`).
   Filtering logic `_filterIssues` unchanged.
7. **Nearby wards** (new, reachability loop) — section key `wardNearbyWardsSection` watching
   `wardListNotifierProvider`; horizontal row of `WardChip(key: Key('wardChip_<slug>'),
   wardName: w.name, slug: w.slug)` excluding the current slug. Hides when the list errors/loads
   with ≤1 item.

### 3.4 `WardBoundaryMiniMap` (new widget)

```dart
class WardBoundaryMiniMap extends ConsumerWidget {
  const WardBoundaryMiniMap({super.key, required this.ward, this.tileProvider});
  final WardDetailOut ward;
  final TileProvider? tileProvider; // test seam; defaults to NetworkTileProvider
}
```

- `FlutterMap` fixed height ~180, `InteractionOptions(flags: InteractiveFlag.none)`, centered on
  `(ward.centerLatitude, ward.centerLongitude)`, zoom 13.
- `TileLayer` (OSM urlTemplate identical to `map_screen.dart:214`), `TileProvider` from
  `tileProvider ?? NetworkTileProvider()`.
- `MarkerLayer`: one center marker, key `wardBoundaryCenterMarker`.
- Watches `wardBoundaryProvider(ward.slug)`:
  - non-empty rings → `PolygonLayer` with `Polygon(points: ring, color: AppColors.brand.withValues(alpha: 0.15), borderColor: AppColors.brand)` per ring;
  - empty → graceful fallback: a small overlay pill key `wardBoundaryFallback` ("Boundary map coming soon"). The map itself always renders (still civic value: centre + location).
- No imports from `features/map/**`. `latlong2` for `LatLng`.

### 3.5 `WardRepPerformanceStrip` (new widget)

```dart
class WardRepPerformanceStrip extends StatelessWidget {
  const WardRepPerformanceStrip({super.key, required this.rep});
  final WardRepresentativeOut rep;
}
```

- Renders 4 stat tiles (mirrors the rep dashboard's metric vocabulary):
  Total / Responded / Escalated / Pending, plus response-rate.
  Keys: `wardRepMetricTotal`, `wardRepMetricResponded`, `wardRepMetricEscalated`,
  `wardRepMetricPending`, `wardRepResponseRate`.
- When `rep.totalWardIssues == 0` → inline empty note key `wardRepPerformanceEmpty`
  ("No performance data yet").

### 3.6 Exact Keys summary

Preserved: `wardDetailScreen`, `wardDetailBackButton`, `wardIssueSearchField`, `wardHeroBanner`,
`wardMetricTotal`, `wardMetricActive`, `wardMetricEscalated`, `wardMetricResolved`,
`wardMetricResolutionRate`, `wardRepCard`, `wardRecentIssuesList`.

New: `wardRepSectionHeader`, `wardNoRepPlaceholder`, `wardRepPerformanceStrip`,
`wardRepPerformanceEmpty`, `wardRepMetricTotal/Responded/Escalated/Pending`, `wardRepResponseRate`,
`wardBoundaryMiniMap`, `wardBoundaryCenterMarker`, `wardBoundaryFallback`,
`wardTopCategoryChip_<cat>`, `wardNearbyWardsSection`, `wardChip_<slug>`, `wardHeroViewMapButton`.

New providers/domain: `wardBoundaryProvider`; extended `WardRepresentativeOut`.

---

## 4. User-journey E2E test plan

### 4.1 Backend (pytest-asyncio) — new `backend/tests/features/wards/test_ward_detail_v2.py`

Reuse the `_seed_ward` / `_seed_representative` / `_seed_issue` helper style already in
`backend/tests/features/issues/test_ward_place_page.py` (copy, don't import across test files).

- `test_be_ward_v2_01_rep_performance_fields`: seed ward + rep + open/escalated/resolved issues +
  `OfficialResponse` rows → `GET /api/v1/wards/ward-45-urban-central` → assert
  `assigned_representative.total_ward_issues / escalated_ward_issues / responded_ward_issues /
  pending_response_ward_issues / response_rate_pct` and `id`/`user_id`.
- `test_be_ward_v2_02_no_rep_edge`: ward with no representative → `assigned_representative is None`;
  metrics still correct.
- `test_be_ward_v2_03_empty_ward_edge`: empty ward → `total_issues == 0`, `resolution_rate_pct == 0.0`,
  `recent_issues == []`, `top_categories == []`, `assigned_representative is None`.
- `test_be_ward_v2_04_rep_zero_division`: rep assigned, 0 issues → `response_rate_pct == 0.0`,
  all perf counts 0.
- `test_be_ward_v2_05_seed_idempotent_and_coordinates`: run `seed_wards` twice → exactly 2 rows
  (`ward-45-urban-central` @ 19.1136/72.8697, `ward-12-metro-corridor` @ 19.0760/72.8777),
  no duplicates.
- `test_be_ward_v2_06_issues_limit_still_respected`: `?issues_limit=3` returns ≤3 recent issues.
- **Regression guard:** existing `test_ward_place_page.py` (all 20 tests) must pass unchanged.

### 4.2 Frontend (flutter widget tests) — extend `app/test/features/ward/ward_detail_screen_test.dart`

Extend `FakeWardRepository` / `sampleRepresentative` with the new fields (keep existing tests
passing — FE-WARD-01..11 unchanged).

- `FE-WARD-12` rep card tap → navigates to `/users/42` when `rep.userId == 42`; when `userId` null
  the card shows no chevron and tap is a no-op (onTap null).
- `FE-WARD-13` rep performance strip renders counts + rate (keys `wardRepPerformanceStrip`,
  `wardRepMetricTotal`, ...); total 0 → `wardRepPerformanceEmpty` shown.
- `FE-WARD-14` no-rep placeholder (key `wardNoRepPlaceholder`) when `assignedRepresentative` null.
- `FE-WARD-15` boundary mini-map renders `wardBoundaryMiniMap` + `wardBoundaryFallback` pill when
  `wardBoundaryProvider` returns `[]` (override provider; inject a no-op `TileProvider` seam).
- `FE-WARD-16` boundary mini-map renders a `PolygonLayer` when `wardBoundaryProvider` returns rings.
- `FE-WARD-17` search+filter combination: type query → list narrows; "All" tab shows everything;
  empty-result card text shown.
- `FE-WARD-18` nearby-wards section: chips keyed `wardChip_<slug>` rendered; tapping a chip pushes
  the sibling ward (assert `WardDetailScreen` re-opened with new slug).
- `FE-WARD-19` tolerant parse: old cached JSON (no perf fields) still decodes into
  `WardRepresentativeOut` with defaults.
- `FE-WARD-20` journey: simulate feed-chip tap (existing FE-WARD-01 pattern: key `wardChip_<id>`
  push) → ward page shows metrics, rep + performance, mini-map, and searchable issue list.

---

## 5. Edge cases

- **Empty `wards` table (pre-seed)**: page 404s; seeding §2.3 fixes live reachability; empty-ward
  test covers the 200-with-zeros shape once the row exists.
- **Old cached `WardDetailOut`** without rep perf fields: tolerant `fromJson` defaults (§3.1).
- **No rep assigned**: placeholder card, no performance strip, no chevron.
- **Rep assigned, zero issues**: `response_rate_pct 0.0`, strip shows "No performance data yet".
- **Boundary feature not landed**: `wardBoundaryProvider` returns `[]` → fallback pill; map tiles
  still render. Widget tests inject a non-network `TileProvider` to stay hermetic.
- **Search/filter**: case-insensitive; empty-result card; clear (suffix icon) resets query.
- **Network failure / offline**: existing cache-first provider fallback; no cache → error state.
- **Unknown slug**: backend 404 `ward_not_found` → "Ward not found" error UI (existing FE-WARD-11).
- **Rate limit 429**: surfaces as provider error → error state.
- **`issues_limit` bounds**: backend clamps 1–50; repository always requests 10.
- **SQLi / URL-encoded raw ward names**: existing parameterization + slugify path unchanged.

## 6. Ordering & dependencies

1. **Backend first** (schema → service → seed → seed.py/main.py) so the API returns perf fields
   and the 2 wards exist. Frontend parse of new fields tolerates absence, so no hard deadlock.
2. **Rep metrics**: computed in the **wards** feature (mirroring the rep feature's queries) so the
   public page does NOT depend on the auth-gated `repProfileProvider` (`/representatives/me`,
   current-user-only — unusable for public display). Contract = extended `AssignedRepresentativeOut`.
   If the rep-accountability feature later renders metrics inside `WardRepCard`, keep our
   `WardRepPerformanceStrip` (remove only if duplication is confirmed by that feature's owner).
3. **Boundary polygons**: owned by the map/boundary feature. Interface we code against:
   `wardBoundaryProvider(slug) → List<List<LatLng>>` (empty = fallback). When that feature ships
   data it fills this provider (or the wards router returns rings) without touching our widgets.
4. **Seeding**: single data source `seed/data/wards.json`; map feature must use identical slugs/
   coords (`ward-45-urban-central`, `ward-12-metro-corridor`). Confirm `backend/app/main.py`
   lifespan is uncontested before editing.
5. **WardRepCard**: owned by rep feature; we only consume `WardRepCard({representative, onTap})`.
   If its rework changes that constructor, adapt the screen call site only.
6. **Feed/map/geo reachability**: already wired (off-limits files) — verified in §1.4. Do not edit.
7. **No application code in this plan file** — coder implements per §2–§3; test agent implements §4.