# Plan — F-B: Map auto-refresh + area-fill heatmap + ward boundaries

**Feature ID:** F-B (`map_heatmap_boundaries`)
**Inputs consumed:** `docs/1_spec.md`, `docs/2_tech_spec.md` (map/geo/ward sections); verified source state from code exploration.
**Scope boundary:** Frontend map feature + backend geo/wards boundary data. Compose/feed/search/profile and ward-DETAIL remain untouched (see §1.2).

---

## 1. Scope & ownership

### 1.1 Files CREATED

| File | Purpose |
|---|---|
| `backend/alembic/versions/<new_rev>_add_ward_boundary.py` | Adds nullable `boundary` TEXT column to `wards` (batch_alter_table; `down_revision` = head of current chain, verify with `alembic heads`). |
| `seed/data/wards.json` | 2 ward records incl. `boundary` polygon rings (concrete coordinates in §2.1). |
| `backend/tests/features/geo/test_ward_boundaries.py` | Backend E2E tests (written by test agent per §4.1). |
| `app/lib/features/map/presentation/widgets/ward_boundary_layer.dart` | Reusable `WardBoundaryLayer` widget + `derivedWardRing(...)` helper (self-contained; consumable later by ward-detail feature). |
| `app/test/features/map/heatmap_area_fill_test.dart` | Heatmap polygon rendering tests (test agent). |
| `app/test/features/map/map_refresh_test.dart` | Auto-refresh tests (test agent). |
| `app/test/features/map/ward_boundaries_test.dart` | Ward-boundary polygon tests (test agent). |

### 1.2 Files MODIFIED

| File | Change |
|---|---|
| `backend/app/features/wards/models.py` | Add `boundary: Mapped[str \| None] = mapped_column(Text, nullable=True)` to `Ward` (GeoJSON ring JSON-encoded as text, pattern-matches `media_urls`). |
| `backend/app/features/geo/schemas.py` | Add `WardBoundaryOut` (`ward_slug, name, code, boundary: list[list[float]]`). |
| `backend/app/features/geo/service.py` | Add `list_ward_boundaries(session)` + `parse_ward_boundary(raw)` + `derived_boundary_ring(lat, lng)` helpers. |
| `backend/app/features/geo/router.py` | Add `GET /geo/ward-boundaries` (rate-limited via existing `_check_rate_limit`, no auth). |
| `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, add `_seed_wards(...)` (dedup by slug), add wards to `_report`. |
| `app/lib/features/map/data/map_api.dart` | Add `WardBoundary` model + `MapApi.getWardBoundaries()`. |
| `app/lib/features/map/presentation/controllers/map_controller.dart` | `HeatmapCell` → polygon bounds; debounced auto-refetch in `updateBounds`; `refreshIfIdle()`; in-flight guard; `wardBoundariesProvider`. |
| `app/lib/features/map/presentation/screens/map_screen.dart` | Heatmap `PolygonLayer` (area fill, no `CircleLayer`); ward `PolygonLayer` via `WardBoundaryLayer`; poll timer + lifecycle resume refetch. |
| `app/test/features/map/map_modes_test.dart` | Extend (test agent): assert polygons not circles; boundaries present. |
| `app/test/features/map/map_pins_extended_test.dart` | Extend (test agent): pan → refetch. |

### 1.3 Files to NOT touch (parallel-agent conflict avoidance)

- `app/lib/features/compose/**` (incl. `offline_outbox_queue.dart`), `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`
- `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`, `app/lib/features/ward/presentation/providers/ward_providers.dart`, `app/lib/features/ward/domain/**`, `app/lib/features/ward/data/**` (ward-DETAIL page & list is another feature's scope)
- `backend/app/features/media/**`, `backend/app/features/representatives/**`, `backend/app/features/search/**`, `backend/app/features/issues/**` (no map-pins change needed — §2.2d)
- `backend/app/features/wards/schemas.py` changes are limited to adding nothing to `WardSummaryOut`/`WardDetailOut` (keep ward-detail contract stable). The `wards/models.py` column addition and `geo/schemas.py` are permitted per plan intro.

---

## 2. Backend design

### 2a. Ward boundary storage, migration, seed

- **Column:** `Ward.boundary` — SQLAlchemy `Text`, nullable. Value = JSON-encoded single outer ring `[[lat, lng], ...]` (no holes, ≥3 points). Nullable so existing raw-SQL test helpers (`backend/tests/features/geo/test_geo.py:_seed_ward` `CREATE TABLE IF NOT EXISTS wards (...)` without the new column) keep working untouched.
- **Migration:** new alembic revision, `batch_alter_table('wards') → add_column('boundary', sa.Text(), nullable=True)`. `downgrade` drops it. (Test DB uses `create_all`, so tests pick it up automatically; real DBs get it via `alembic upgrade head`.)
- **Seed `seed/data/wards.json`:**
  ```json
  {
    "wards": [
      {
        "slug": "ward-45-urban-central",
        "name": "Ward 45, Urban Central",
        "code": "W-45",
        "center_latitude": 19.1136,
        "center_longitude": 72.8697,
        "boundary": [
          [19.1336, 72.8697], [19.1277, 72.8847], [19.1136, 72.8909],
          [19.0995, 72.8847], [19.0936, 72.8697], [19.0995, 72.8547],
          [19.1136, 72.8485], [19.1277, 72.8547]
        ]
      },
      {
        "slug": "ward-12-metro-corridor",
        "name": "Ward 12, Metro Corridor",
        "code": "W-12",
        "center_latitude": 19.0760,
        "center_longitude": 72.8777,
        "boundary": [
          [19.0960, 72.8777], [19.0900, 72.8927], [19.0760, 72.8989],
          [19.0620, 72.8927], [19.0560, 72.8777], [19.0620, 72.8627],
          [19.0760, 72.8565], [19.0900, 72.8627]
        ]
      }
    ]
  }
  ```
  These are ~2.2 km octagons centred on the two known ward centres. **Internet sourcing:** the coder MAY optionally attempt an Overpass query (`[out:json]; area["name"="Mumbai"]; rel(area)["admin_level"~"8"|"9"]["boundary"="administrative"]; out geom;`) during implementation, but MUST NOT block on it — the two wards are fictional, so the synthesized rings above are the authoritative seed. Runtime never fetches from the internet.
- **`seed.py`:** `_seed_wards` builds `Ward(...)` from each JSON row incl. `boundary=json.dumps(row["boundary"])`; dedup key = `slug`; add `"wards"` to `_DATA_FILES` (after "users" — no FK, order irrelevant) and `Ward` to `_TABLES` (clear first). `_report` gains `"wards"`.

### 2b. Boundary endpoint (exact contract)

Choose a **standalone endpoint** on the map-facing geo router (NOT changes to `/wards` list/detail responses — keeps the ward-detail feature's contract and its tests stable):

```
GET /api/v1/geo/ward-boundaries
→ 200 list[WardBoundaryOut]
WardBoundaryOut = { ward_slug: str, name: str, code: str,
                    boundary: list[list[float]] }   // [[lat, lng], ...] outer ring, ≥3 pts
```

- `service.list_ward_boundaries(session)`: `select(Ward).order_by(Ward.id)`. For each row, `parse_ward_boundary(ward.boundary)`:
  - `None`/empty/non-JSON/not a list → fallback.
  - Each element must be `[lat, lng]` pair, `-90 ≤ lat ≤ 90`, `-180 ≤ lng ≤ 180`, ≥3 pairs, ring closed or open (client closes it).
  - Invalid → fallback = `derived_boundary_ring(center_latitude, center_longitude)` (8-point octagon, radius 0.02° lat / `0.02/cos(lat)` lng, same algorithm as frontend helper).
- Always returns 200 (empty list if no wards). No auth required (mirrors `/geo/reverse-geocode`), rate-limited, read-only.
- **Malformed-boundary policy:** never 5xx; a malformed row degrades to the derived ring so the map always shows a meaningful polygon.

### 2c. Heatmap density endpoint — NOT needed

Decision: **no new heatmap/density endpoint.** Client-side density shading from `GET /geo/map-pins` (already bbox-filtered, shielded-exclusion applied) is sufficient; pin counts are small, cells are computed client-side, and there is a single source of truth. Specify: heatmap density = count of `filteredPins` per fixed 0.003° grid cell, computed in `MapState.heatmapCells`.

### 2d. Map-pins changes for refresh — NONE

Decision: **`GET /geo/map-pins` is unchanged** (no `updated_since` param). Issues have no `updated_at` column and the issues feature is out of scope; full bbox refetch on pan + 30s poll is sufficient at this scale. If payload growth demands delta pulls later, add `updated_since` on `Issue.created_at` in a future feature.

---

## 3. Frontend design

### 3a. Heatmap: concentric circles → area-fill density shading

- **Model change** (`map_controller.dart`): `HeatmapCell` becomes an area cell:
  ```dart
  class HeatmapCell {
    final double minLat; final double maxLat;
    final double minLng; final double maxLng;
    final int density;
  }
  ```
- `MapState.heatmapCells` (keep name/role): fixed grid `cellSize = 0.003` (unchanged, ~330 m). For each pinned issue, cell key = `(lat/cellSize).floor()` / `(lng/cellSize).floor()`. Cell bounds = `floor*cellSize .. (floor+1)*cellSize`. Density = count per cell. (Fixed floor grid ⇒ cells do not jump when pins change.)
- **Rendering** (`map_screen.dart`): replace the `CircleLayer` + 3 nested `CircleMarker` block (currently lines 219-252) with:
  ```dart
  if (mapState.displayMode == MapDisplayMode.heatmap)
    PolygonLayer(
      polygons: [
        for (final cell in mapState.heatmapCells)
          Polygon(
            points: [ LatLng(cell.minLat, cell.minLng), LatLng(cell.maxLat, cell.minLng),
                      LatLng(cell.maxLat, cell.maxLng), LatLng(cell.minLat, cell.maxLng) ],
            color: _heatmapColor(cell.density, _heatmapOpacity(cell.density)),
            borderColor: Colors.black.withValues(alpha: 0.06),
            borderStrokeWidth: 1,
          ),
      ],
    ),
  ```
  - Delete `_heatmapRadius`; add `double _heatmapOpacity(int density)` = `0.18 + (min(density, 8) / 8.0) * 0.5` (0.18 → 0.68). Keep `_heatmapColor` ramp (green/yellow/orange/red). Keep the legend text "Density:/Low/Medium/High/Hotspot" (tests assert it).
  - Grid cells are non-overlapping, so no alpha-blend artifacts; `PolygonLayer` culls off-screen polygons (`polygonCulling` default).
  - Keys: give each cell polygon `key: Key('heatmapCell_$latKey:$lngKey')` for testability.

### 3b. Ward boundaries (replaces per-ward circle)

- **Model** (`app/lib/features/map/data/map_api.dart`): `class WardBoundary { slug, name, code, List<LatLng> ring }` + `fromJson` (parse `boundary` list → `LatLng(lat, lng)`).
- **API:** `MapApi.getWardBoundaries()` → `GET /geo/ward-boundaries`, returns `List<WardBoundary>`.
- **Provider** (`map_controller.dart`): `final wardBoundariesProvider = FutureProvider<List<WardBoundary>>((ref) => ref.watch(mapApiProvider).getWardBoundaries());`
- **Widget** (`app/lib/features/map/presentation/widgets/ward_boundary_layer.dart`):
  - `WardBoundaryLayer({ required List<WardSummaryOut> wards, required List<WardBoundary> boundaries, Color fill = AppColors.brand, ... })` → builds `PolygonLayer`:
    - one `Polygon(points: b.ring, color: fill.withValues(alpha: 0.12), borderColor: fill, borderStrokeWidth: 2, label: TextSpan(b.code), labelPlacement: PolygonLabelPlacement.centroid)` per matched boundary;
    - for wards with no boundary in the fetched list (or fetch empty/failed), one `Polygon` from `derivedWardRing(ward.centerLatitude, ward.centerLongitude)` — deterministic octagon (same 0.02° algorithm as backend fallback) so every ward always shows a meaningful polygon, never a bare circle.
  - Public static `derivedWardRing(double lat, double lng)` so the ward-detail feature can reuse it later.
- **Map screen wards mode** (replace lines 298-312 `CircleLayer`): render `WardBoundaryLayer(wards: wards, boundaries: boundariesAsync.valueOrNull ?? const [])` where `boundariesAsync = ref.watch(wardBoundariesProvider)`. Keep the existing pill `MarkerLayer` with `Key('wardMarker_${ward.slug}')` (tests depend on it). Remove the 48 px `CircleMarker` per ward. Keep hardcoded `WardSummaryOut` fallback (lines 138-165) — it feeds the boundary-fallback rings, so the empty-wards-table case still draws polygons.

### 3c. Map auto-refresh

- **Viewport refetch (debounced):** `updateBounds(MapBounds)` keeps storing bounds + setting `isBoundsDirty: true`, and now also schedules a `Timer(const Duration(milliseconds: 800))` that calls `fetchPins()` when bounds actually changed (cancel/restart on each move). Guard against stacking: a `bool _fetching` flag set around the network call in `fetchPins()`; debounce/refresh no-ops while `_fetching` or while `pins.isLoading`.
- **Keep `searchThisAreaButton` + `searchThisArea()`** unchanged (manual fallback; key preserved; existing tests keep passing). After an auto-fetch the dirty flag clears, so the FAB is a short-lived fallback — that is acceptable per requirement 1.
- **Periodic poll:** `MapScreen.initState` starts `Timer.periodic(Duration(seconds: 30), (_) => mapNotifier.refreshIfIdle())`, cancelled in `dispose`. `refreshIfIdle()` = if `pins.hasValue && !_fetching` → `fetchPins()`. Covers issues added via compose/outbox flush without touching compose/feed.
- **App-resume hook:** `MapScreen` becomes a `WidgetsBindingObserver`; on `AppLifecycleState.resumed` call `mapNotifier.refreshIfIdle()`. (MapScreen lives in a `StatefulShellRoute.indexedStack`, so tab switches do not remount — resume + poll are the reliable triggers.)
- **Outbox-flush hook (documented, NOT wired):** compose's `OfflineOutboxQueue` is a plain `Provider` with no change-notification, and `app/lib/features/compose/**` is out of scope, so the map cannot observe flush completion directly. The durable hook is: a future feature adds a `mapInvalidatedProvider` (counter `Notifier<int>`) that compose bumps after `flush()`; this feature's `refreshIfIdle()` is the consumer contract. Until then, poll (30 s) + resume cover the gap. **Do not import compose providers from map code.**

### 3d. Exact Keys / providers / models summary

- Preserved keys: `mapPin_<id>`, `mapFilterChip_*`, `searchThisAreaButton`, `mapEmptyState`, `mapErrorRetryButton`, `wardMarker_<slug>`.
- New keys: `heatmapCell_<latIdx>_<lngIdx>` (e.g. `heatmapCell_6370_24289`), `wardBoundary_<slug>` (on each boundary `Polygon`/layer container).
- New providers: `wardBoundariesProvider` (`FutureProvider<List<WardBoundary>>`).
- New models: `HeatmapCell` (area bounds — modified), `WardBoundary` (new).
- No pubspec changes (flutter_map ^8 ships `PolygonLayer`/`Polygon`).

---

## 4. User-journey E2E test plan

### 4.1 Backend (pytest, `backend/tests/features/geo/test_ward_boundaries.py` + regression)

Contract: `GET /api/v1/geo/ward-boundaries`, no auth, rate-limited, read-only.

- **BE-WB-01** Seeded wards return polygons: insert 2 wards with `boundary` JSON (raw SQL incl. new column); assert 200, 2 items, each `{ward_slug,name,code,boundary}`; each `boundary` is a list of ≥3 `[lat,lng]` pairs in range; `ward_slug` matches.
- **BE-WB-02** Empty `wards` table → 200 `[]` (no crash).
- **BE-WB-03** NULL/malformed boundary (`'not json'`, `[["a"]]`, `[[91,0]]`, `[[19,72]]` 2-point ring) → 200; `boundary` replaced by a derived ring: ≥3 pts, centroid within ~0.03° of `center_latitude/longitude`, deterministic across calls.
- **BE-WB-04** Guest vs signed-in caller → identical 200 responses (no auth collected).
- **BE-WB-05** Read-only: snapshot `SELECT * FROM wards` + `sqlite_master` before/after a battery of calls → unchanged.
- **BE-WB-06** No PII in any response (markers from `test_geo.py` SEC-01 list).
- **BE-WB-07** Burst/rate-limit: repeated calls → all 200; no 5xx; limiter still applies at >60 req/60 s (429 allowed).
- **BE-MP regression** Existing `test_geo.py` map-pins tests still pass (endpoint untouched).

### 4.2 Frontend (flutter widget tests, `app/test/features/map/`)

Harness pattern: `ProviderScope` overriding `mapApiProvider`, `wardRepositoryProvider`, `locationServiceProvider` (mirror `map_modes_test.dart`).

- **FE-MAP-01** Pins mode unchanged: pins render as `mapPin_<id>`; existing tests pass.
- **FE-MAP-02** Heatmap = area fill, not circles: 3 pins in 3 distinct cells → `PolygonLayer` present, ≥3 `Polygon`s, `find.byType(CircleMarker)` findsNothing; `heatmapCell_*` keys present; legend "Density:"/"Hotspot" still rendered.
- **FE-MAP-03** Density color/opacity tiers: cells with 1 vs 5 pins render different fill colors (compare `Polygon.color`).
- **FE-MAP-04** Pan auto-refetch: `mapController.move(...)` + pump > 800 ms → `getMapPins` called with new bounds; within window (pump 400 ms) only 1 call (debounce).
- **FE-MAP-05** Poll: `tester.pump(Duration(seconds: 31))` → additional `getMapPins` call.
- **FE-MAP-06** App resume: send `AppLifecycleState.resumed` → refetch.
- **FE-MAP-07** Ward boundaries: mock `getWardBoundaries()` → ring per ward; ward mode shows `wardBoundary_<slug>` `Polygon`s, no per-ward `CircleMarker`; `wardMarker_<slug>` pill + "W-45" text still present.
- **FE-MAP-08** Boundary fallback: `getWardBoundaries()` throws / returns `[]` → `derivedWardRing` polygons rendered (≥3 pts) for the hardcoded/fallback wards; no crash.
- **FE-MAP-09** Empty state: no pins + pins mode → `mapEmptyState`; heatmap mode → zero polygons.
- **FE-MAP-10** Offline: `getMapPins` throws → `mapErrorRetryButton` banner; heatmap renders no polygons; retry works.
- **FE-MAP-11** Filters still work: `mapFilterChip_road` tap → `selectCategory('road')` + refetch; `filteredPins` subset drives heatmap density.
- **FE-MAP-12** Outbox gap: map does NOT import compose providers (assert no `offlineOutboxProvider` import in map files).

---

## 5. Edge cases

| Case | Handling |
|---|---|
| `wards` table empty (current prod state) | Hardcoded `WardSummaryOut` fallback stays; boundaries degrade to `derivedWardRing`; polygons render, no bare circles. |
| Malformed/`NULL` boundary in DB | Backend returns derived ring (BE-WB-03); frontend also falls back per ward. |
| No issues in viewport | Heatmap = 0 polygons; pins empty-state card shows; no crash. |
| Cell spanning grid boundary / negative coords | Integer floor grid — deterministic; bounds = `floor*cellSize..(floor+1)*cellSize`. |
| Rapid pan/zoom | 800 ms debounce + `_fetching` guard → 1 fetch, no stacked requests. |
| Poll fires while offline or mid-flight | `refreshIfIdle()` skips when loading/fetching; error banner already handled. |
| New issue added while map open | Picked up by 30 s poll and app-resume; outbox flush covered by poll (documented future hook). |
| Very dense single cell | Density capped at tier thresholds; opacity capped at 0.68. |
| Huge boundary ring / many wards | `PolygonLayer.polygonCulling` (default) culls off-screen; keep rings ≤ ~10 pts. |
| Raw-SQL ward seeding in existing tests | New column is nullable; their `CREATE TABLE`/`INSERT` untouched and still valid. |
| Heatmap circles regression | All `CircleMarker` heatmap code removed; only `MarkerLayer` markers remain elsewhere. |

## 6. Ordering & dependencies

1. **Backend first:** `wards/models.py` column → alembic migration → `seed/data/wards.json` + `seed.py` → `geo/schemas.py` + `geo/service.py` (fallback helpers) → `geo/router.py`. Verify `ruff`, `mypy strict`, existing `test_geo.py` green.
2. **Frontend data/controller:** `map_api.dart` (`WardBoundary` + `getWardBoundaries`) → `map_controller.dart` (heatmap cells, debounce/refresh, provider).
3. **Frontend rendering:** `ward_boundary_layer.dart` → `map_screen.dart` (heatmap `PolygonLayer`, ward `PolygonLayer`, timers/lifecycle). Verify `flutter analyze` clean and existing map tests green.
4. **Test agent:** runs §4 contract against backend, §4.2 widget suite against frontend.
- **Dependency on other features:** new-issue creation lives in the compose feature (out of scope). This feature consumes it reactively (poll + resume); it MUST NOT write to compose. Outbox-flush invalidation is a documented forward hook (`mapInvalidatedProvider`) — do not implement it in compose.
- **Do not** hand-edit `docs/*` SDD artifacts or `.sdd/**`/`logs/**`; `seed/data/wards.json` is the only new data asset.
