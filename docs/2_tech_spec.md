# Technical Specification: F-03 — Ward Awareness (Reverse Geocoding & Ward Boundary Lookup)

**Feature ID:** `F-03` (subset: `reverse-geocode_2026-08-10`)
**Status:** DRAFT (pending approval — do not implement until locked)
**Source of truth:** `docs/1_spec.md` (business spec, locked) + repo index `docs/0_repo_index.json`
**Consumed by:** Phase 5 coder (sole input). Test engineer does NOT read this file; testing boundaries are derived from the locked acceptance criteria (AC-1..AC-10) and restated here only to bound the implementation surface.

---

## 1. Scope & Architectural Overview

F-03 adds a guest-friendly, read-only "which ward am I in?" capability:

- **Backend**: one new read-only endpoint `GET /api/v1/geo/reverse-geocode` that resolves a latitude/longitude to the nearest known ward center (haversine distance, within a configurable coverage ceiling) and returns a human-readable place label.
- **Frontend**: a small `app/lib/features/geo/` feature (data / domain / presentation) that resolves the device location once per session, looks up the ward, and renders an informational chip in two surfaces — the issue-compose screen and the feed/home app bar. Location resolution is fully injectable so widget tests never need real GPS.

Explicitly out of scope (per spec §6): no maps, no geofencing, no external geocoding providers, no street addresses, no boundary polygons, no DB writes, no auth changes, no per-user location history, no changes to ward detail pages (other than being reachable via tap).

### 1.1 High-level data flow

```
Compose screen / Feed app bar
        │ watch
        ▼
wardLocationProvider (sealed state: loading | unavailable | success)
        │ 1. deviceLocationProvider.getCurrentCoordinates()   ← injectable, mockable (may throw)
        │ 2. updates currentCoordinatesProvider
        │ 3. geoApiProvider.reverseGeocode(lat, lng, radiusKm)
        ▼
GeoApi → ApiClient → GET /api/v1/geo/reverse-geocode
        ▼
geo router (no auth) → geo service (read-only SELECT on wards) → haversine_km (issues.geo)
```

---

## 2. Module Boundaries & Dependency Direction

### 2.1 Backend dependency graph (new edges only)

```
backend/app/api/router.py ──include──▶ backend/app/features/geo/router.py
                                              │
                                              ▼
backend/app/features/geo/router.py ──imports──▶ app.api.deps (SessionDep)
                                              │
                                              ▼
backend/app/features/geo/service.py ──imports──▶ app.features.issues.geo (haversine_km)
                                              │   app.features.wards.models (Ward)
                                              │   app.core.logging (get_logger)
                                              │   app.features.geo.schemas
                                              ▼
backend/app/features/geo/schemas.py (Pydantic only — no app imports)
```

Dependency rules (enforced, not aspirational):

- `app.features.geo` may import from `app.features.issues.geo`, `app.features.wards.models`, `app.core.*`, `app.api.deps`. It must NOT import from `app.api.router`, `app.main`, or any other feature package.
- `app.features.issues.geo` and `app.features.wards.models` must NOT import from `app.features.geo` (no cycle).
- `schemas.py` contains Pydantic models only; it must not import SQLAlchemy models or services.
- The geo package adds **zero** new rows/tables/columns; it only reads the existing `wards` table via the `Ward` ORM model.

### 2.2 Frontend dependency graph (new edges only)

```
app/lib/features/geo/presentation/widgets/ward_location_chip.dart
        │ watch
        ▼
app/lib/features/geo/presentation/providers/geo_providers.dart
        │            │              │
        ▼            ▼              ▼
data/geo_api.dart  domain/device_location_service.dart
        │                 │
        ▼                 ▼
core/network/api_client  (platform GPS — isolated behind abstract service)
        ▲
app/lib/features/geo/... ←── consumed by: Compose screen, Feed/Home screen (existing screens
                              depend on geo; geo never depends on screens)
```

- Frontend geo deps allowed: `core/network/api_client` (ApiClient), `core/router/route_paths` (RoutePaths.wardDetailFor), Riverpod, Flutter SDK.
- `data/geo_api.dart` (GeoApi + ReverseGeocode model) and `domain/device_location_service.dart` are pure Dart (no Flutter imports) so they are trivially unit-testable.
- No circular dependencies: `data/` never imports `presentation/`; `presentation/` imports `data/` + `domain/`; widgets import providers; screens import widgets. The geo feature must not import any screen.
- The device location source is hidden behind `DeviceLocationService` (abstract) so production GPS and widget-test fakes are interchangeable by overriding `deviceLocationProvider`.

---

## 3. Backend Design

### 3.1 New feature package layout

```
backend/app/features/geo/
├── __init__.py      # package marker (empty, mirroring sibling features)
├── schemas.py       # Pydantic response models
├── service.py       # reverse_geocode(session, latitude, longitude, radius_km)
└── router.py        # APIRouter(prefix="/geo", tags=["geo"]); GET /reverse-geocode
```

### 3.2 Schemas (`backend/app/features/geo/schemas.py`)

Pydantic v2 models, `model_config = ConfigDict(from_attributes=False)` (plain DTOs):

```python
class ReverseGeocodeWardOut(BaseModel):
    slug: str
    name: str
    code: str              # serialized as string (see §8 Assumptions)
    center_latitude: float
    center_longitude: float

class ReverseGeocodeOut(BaseModel):
    latitude: float        # echoes the request latitude
    longitude: float       # echoes the request longitude
    place: str             # ward.name when found, else "Outside coverage"
    ward: ReverseGeocodeWardOut | None   # None exactly when found is False
    distance_km: float     # rounded to 1 decimal place when found; 0.0 when not found
    found: bool
```

### 3.3 Service (`backend/app/features/geo/service.py`)

```python
async def reverse_geocode(
    session: AsyncSession,
    latitude: float,
    longitude: float,
    radius_km: float,
) -> ReverseGeocodeOut
```

Algorithm (read-only, deterministic):

1. `SELECT` all wards (`Ward.id`, `Ward.slug`, `Ward.name`, `Ward.code`, `Ward.center_latitude`, `Ward.center_longitude`). One query, no joins, no writes.
2. For each ward compute `d = haversine_km(latitude, longitude, ward.center_latitude, ward.center_longitude)` — reuse the existing `app.features.issues.geo.haversine_km`; do NOT reimplement haversine.
3. Track the minimum distance and its ward.
4. If `min_distance <= radius_km` (coverage ceiling): `found=True`, `ward=ReverseGeocodeWardOut(...)`, `distance_km=round(min_distance, 1)`, `place=ward.name`.
5. Else: `found=False`, `ward=None`, `distance_km=0.0`, `place="Outside coverage"`.
6. Both branches echo the request `latitude`/`longitude` unchanged.

Semantics to document in the function docstring (interface extractor will capture it):

- Rounding: Python `round(x, 1)` (banker's rounding). The value is guaranteed accurate to one decimal place, i.e. `abs(returned - true) <= 0.05`.
- Radius is inclusive: a location exactly `radius_km` from a ward center IS found.
- Tie-break (two wards equidistant): the first ward in table order wins (stable, deterministic).
- Performance note (optional, not required for correctness): the existing `bbox_statement` helper from `app.features.issues.geo` may be used to pre-filter candidate wards by bounding box before the exact haversine pass; the ward registry is small so a full scan is acceptable.

Logging: use `get_logger(__name__)` from `app.core.logging`. Log only the outcome — `ward slug` + `found` boolean — at INFO. **Never log the input coordinates** (privacy requirement, spec §5). Errors at ERROR with no coordinates.

### 3.4 Router (`backend/app/features/geo/router.py`)

```python
router = APIRouter(prefix="/geo", tags=["geo"])

@router.get("/reverse-geocode", response_model=ReverseGeocodeOut)
async def reverse_geocode_endpoint(
    session: SessionDep,
    latitude: float = Query(..., ge=-90.0, le=90.0),
    longitude: float = Query(..., ge=-180.0, le=180.0),
    radius_km: float = Query(50.0, ge=0.1, le=50.0),
) -> ReverseGeocodeOut: ...
```

Rules:

- **No auth dependency** (no `get_current_user`, no `get_optional_current_user`): guests and anonymous visitors must succeed exactly as signed-in users (AC-4). The handler receives no user object and never touches identity.
- Validation is declarative via `Query` constraints; out-of-range values and non-numeric/missing values both surface as `RequestValidationError` → HTTP 422 (see §3.6 for the error body contract).
- Thin endpoint: no business logic here; delegate to `reverse_geocode(session, ...)`.

### 3.5 Mounting (`backend/app/api/router.py`)

Add to the existing aggregator:

```python
from app.features.geo.router import router as geo_router
# ...
api_router.include_router(geo_router)   # prefix "/geo" already on geo_router
```

The existing `api_router` is mounted under `/api/v1` in `app/main.py` (existing convention — the full external path must be `GET /api/v1/geo/reverse-geocode`; verify the mount prefix chain yields exactly this and adjust nothing else).

### 3.6 Error/exception contract (backend)

| Condition | HTTP status | Error code in body envelope |
|---|---|---|
| latitude outside [-90, 90] | 422 | `invalid_coordinates` |
| longitude outside [-180, 180] | 422 | `invalid_coordinates` |
| radius_km outside [0.1, 50] | 422 | `invalid_coordinates` |
| non-numeric / missing / extra-text params | 422 | `invalid_coordinates` |
| Ward not found within radius (valid input) | 200 | — (normal `found=false` response, NOT an error) |
| Unknown resource path under geo prefix | 404 | framework default (allowed; "no 404" in the contract means the happy-path lookup never 404s) |
| Unexpected internal failure | 500 | framework default; must never leak stack traces or coordinates |

Implementation:

- Add one new export to `backend/app/core/exceptions.py`: `validation_error_handler(request, exc: RequestValidationError) -> JSONResponse`, producing the same envelope shape as the existing `app_error_handler` (`{"detail": <human-readable>, "code": "invalid_coordinates", "error_code": "invalid_coordinates"}`). The test accepts the code under either the `code` or `error_code` key (the existing AppError model carries both). When the request path does NOT contain `/geo/`, the handler must reproduce FastAPI's default 422 body (`{"detail": [...]}`) so existing endpoints are unaffected.
- Register it in `app/main.py` (`app.add_exception_handler(RequestValidationError, validation_error_handler)`) next to the existing `app_error_handler` registration.
- No `AppError` subclass is needed for this feature; the geo service never raises application-level errors by design.

---

## 4. Frontend Design

### 4.1 New feature package layout

```
app/lib/features/geo/
├── domain/
│   └── device_location_service.dart  # DeviceLocationService (abstract) + production impl
├── data/
│   └── geo_api.dart                  # GeoApi (HTTP wrapper) + ReverseGeocode model + fromJson
└── presentation/
    ├── providers/
    │   └── geo_providers.dart        # providers + WardLocationState sealed hierarchy
    └── widgets/
        └── ward_location_chip.dart   # WardLocationChip widget
```

### 4.2 Domain layer

`domain/device_location_service.dart` — the injectable GPS abstraction (the "no real GPS in widget tests" requirement):

```dart
abstract class DeviceLocationService {
  /// Resolves the current device coordinates.
  ///
  /// THROWS when the location cannot be determined (permission denied, GPS
  /// off, network failure). It does NOT return null on failure — callers
  /// catch exceptions and map them to WardLocationUnavailable.
  Future<({double lat, double lng})> getCurrentCoordinates();
}

class PlatformDeviceLocationService implements DeviceLocationService {
  // Production impl: wraps the app's platform location source (permission-aware).
  // Throws on permission-denied / GPS-unavailable. If no platform GPS source is
  // available in this build, returns the reference coordinates (19.1136, 72.8697).
}
```

### 4.3 Data layer

`data/geo_api.dart` — exposes BOTH `GeoApi` and the `ReverseGeocode` model (tests import both from this single library):

```dart
class ReverseGeocode {
  const ReverseGeocode({...});
  final double latitude;
  final double longitude;
  final String place;
  final String? wardSlug;   // null when not found (ward == null)
  final String? wardName;   // null when not found
  final String? wardCode;   // null when not found
  final double distanceKm;  // 0.0 when not found
  final bool found;
  factory ReverseGeocode.fromJson(Map<String, Object?> json);
  // JSON keys: latitude, longitude, place, ward, distance_km, found.
  //   ward: null or ABSENT -> wardSlug/wardName/wardCode all null (null-safe).
  //   Required scalars (latitude, longitude, place, distance_km, found) missing
  //   -> throw FormatException (controlled, never a raw crash).
  //   Extra unknown keys (email/phone/anon_id/device_id/etc.) are ignored.
}

class GeoApi {
  GeoApi(this._client);
  final ApiClient _client;   // from core/network/api_client

  Future<ReverseGeocode> reverseGeocode({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,   // non-null default -> radius_km is ALWAYS in the query
  });
  // GET /geo/reverse-geocode?latitude=..&longitude=..&radius_km=..
  // via _client.getJson('/geo/reverse-geocode', query: {...})
  // (ApiClient owns the /api/v1 base prefix per existing convention).
  // Parses the JSON body with ReverseGeocode.fromJson.
  // Non-2xx responses propagate per ApiClient's existing error convention.
}
```

### 4.4 Providers (`presentation/providers/geo_providers.dart`)

```dart
/// Sealed state machine consumed by both surfaces.
sealed class WardLocationState { const WardLocationState(); }
class WardLocationLoading extends WardLocationState { const WardLocationLoading(); }
class WardLocationUnavailable extends WardLocationState { const WardLocationUnavailable(); }
class WardLocationSuccess extends WardLocationState {
  const WardLocationSuccess({
    required this.place,
    this.wardSlug,
    this.code = '',
  });
  final String place;        // ward place text; "Outside coverage" when found=false
  final String? wardSlug;    // null when found=false
  final String code;         // ward code (e.g. "W-45"); '' when found=false
}
```

Providers (Riverpod):

1. `geoApiProvider` — `Provider<GeoApi>`; builds `GeoApi` with the app-wide `ApiClient` (core/network/api_client). Overridable in tests via `.overrideWithValue`.
2. `deviceLocationProvider` — `Provider<DeviceLocationService>`; default `PlatformDeviceLocationService`. **This is the mock seam for widget tests** (override with a fake that returns fixed coordinates or throws).
3. `currentCoordinatesProvider` — `Provider<({double lat, double lng})>`; **default value `(lat: 19.1136, lng: 72.8697)`** (reference/city-center point). Deterministic, non-null initial value so rendering and widget tests never deal with null coordinates. The default value alone never produces a `success` label — the state machine in `wardLocationProvider` gates every `success` on the device location service actually resolving (see below), preserving AC-7.
4. `wardLocationProvider` — `NotifierProvider<WardLocationController, WardLocationState>`:

```
build() → state = WardLocationLoading()
  try:
    coords = await deviceLocationProvider.getCurrentCoordinates()   // may throw
  catch (_):
    state = WardLocationUnavailable()   // AC-7: permission/GPS/network
    return
  try:
    result = await geoApiProvider.reverseGeocode(
               latitude: coords.lat, longitude: coords.lng, radiusKm: 50.0)
    if result.found:
      state = WardLocationSuccess(
        place: result.place,
        wardSlug: result.wardSlug,
        code: result.wardCode ?? '',
      )                                   // AC-1 / FE-10
    else:
      state = WardLocationSuccess(
        place: 'Outside coverage',
        wardSlug: null,
        code: '',
      )                                   // AC-2 / FE-11 — NOT unavailable
  catch (_):
    state = WardLocationUnavailable()     // network problem (AC-7)
```

Rules:

- Resolution happens **once per provider lifetime** (Business Rule "Resolved once"): both the compose surface and the feed surface watch the SAME `wardLocationProvider`, so a single resolution serves both. No per-widget fetches, no refresh loop.
- All failures (location source failure or API/network failure) collapse to `WardLocationUnavailable`. Only a completed HTTP 200 with a parseable body can produce `WardLocationSuccess`. Out-of-coverage (`found=false`) is a `WardLocationSuccess` with `place == "Outside coverage"` — NOT `unavailable`.
- The notifier never throws; exceptions are caught and mapped to states. Non-blocking guarantee (AC-7).

### 4.5 Widget (`presentation/widgets/ward_location_chip.dart`)

`WardLocationChip` is a **presentational** widget that takes the resolved state via constructor — it does NOT watch the provider itself. The surfaces (Compose, Feed) watch `wardLocationProvider` and pass the state in: `WardLocationChip({required WardLocationState state})`.

| State | Rendered | Widget key | Behavior |
|---|---|---|---|
| `WardLocationLoading` | text "Locating…" | `Key('wardLocationLoading')` | non-interactive |
| `WardLocationUnavailable` | `Icons.location_off_outlined` + "Location unavailable" | `Key('wardLocationUnavailable')` | non-interactive |
| `WardLocationSuccess` with `place == "Outside coverage"` | "Outside coverage" | `Key('wardLocationOutsideCoverage')` | non-interactive |
| `WardLocationSuccess` otherwise | `Icons.place_outlined` + place text + ward code (e.g. "Ward 45, Urban Central · W-45") | `Key('wardLocationChip')` | tap → navigate to ward detail |

Key rules:

- The success chip carries `Key('wardLocationChip')` and renders BOTH the place text and the ward code (tests assert both `textContaining('Ward 45, Urban Central')` and `textContaining('W-45')`). A single `Chip` label containing both substrings satisfies this.
- **Navigation (AC-8):** only in the success (found) case, `onTap` navigates to `RoutePaths.wardDetailFor(state.wardSlug)` via the app's existing routing mechanism (RoutePaths lives in `core/router/route_paths`). No navigation in any other state. Tests drive this via a `GoRouter` with a `/ward/:slug` route.
- Distance display is optional (the chip is informational); if shown it must not disrupt the key/text assertions above.
- The widget is a passive, informational row: it never blocks, throws, or disables surrounding UI (Non-blocking, AC-7).

### 4.6 Integration points (minimal edits to existing screens)

1. **Compose screen (issue reporting)**: render `WardLocationChip` above the report draft, wrapped with `Key('composeLocationChip')` (AC-5). Placement must not affect the publish flow — the chip is informational only.
2. **Feed/Home screen app bar**: render a compact nearby-area label using the same `WardLocationChip`, wrapped with `Key('feedAreaLabel')` (AC-6). The feed continues to function regardless of chip state.
3. `RoutePaths.wardDetailFor` already exists in `core/router/route_paths`; it is used as-is — no changes to the wards detail page or its routes (per spec §6).

Both surfaces watch the shared `wardLocationProvider`, satisfying "Resolved once" with zero extra network calls.

---

## 5. Database Schema Changes

**None.** The geo feature:

- Adds no tables, no columns, no indexes, no migrations.
- Performs read-only `SELECT`s against the existing `wards` table through the existing `Ward` ORM model (`app.features.wards.models`).
- Never writes, fuzzes, or alters any citizen/report data (spec §5 Read-only).

---

## 6. File-by-File Implementation Plan

### 6.1 Backend (new/modified)

| # | File | Action | Responsibility |
|---|---|---|---|
| B1 | `backend/app/features/geo/__init__.py` | create | Package marker (empty, matching sibling features). |
| B2 | `backend/app/features/geo/schemas.py` | create | `ReverseGeocodeOut`, `ReverseGeocodeWardOut` per §3.2. |
| B3 | `backend/app/features/geo/service.py` | create | `reverse_geocode(...)` per §3.3; uses `haversine_km` from `app.features.issues.geo` and `Ward` from `app.features.wards.models`; read-only; outcome-only logging. |
| B4 | `backend/app/features/geo/router.py` | create | `APIRouter(prefix="/geo")`, `GET /reverse-geocode` with the §3.1 query contract, `SessionDep`, no auth, delegates to service. |
| B5 | `backend/app/api/router.py` | modify | Import and `include_router(geo_router)` per §3.5. |
| B6 | `backend/app/core/exceptions.py` | modify | Add `validation_error_handler` export per §3.6 (envelope code `invalid_coordinates` for `/geo/` paths; passthrough default 422 elsewhere). |
| B7 | `backend/app/main.py` | modify | Register `RequestValidationError` handler next to existing exception handlers. |

### 6.2 Frontend (new/modified)

| # | File | Action | Responsibility |
|---|---|---|---|
| F1 | `app/lib/features/geo/domain/device_location_service.dart` | create | `DeviceLocationService` abstract (`getCurrentCoordinates()`, may throw) + `PlatformDeviceLocationService` (§4.2). |
| F2 | `app/lib/features/geo/data/geo_api.dart` | create | `GeoApi.reverseGeocode(...)` + `ReverseGeocode` model + `fromJson` (§4.3). |
| F3 | `app/lib/features/geo/presentation/providers/geo_providers.dart` | create | `geoApiProvider`, `deviceLocationProvider`, `currentCoordinatesProvider` (default 19.1136/72.8697), `wardLocationProvider` + sealed `WardLocationState` (§4.4). |
| F4 | `app/lib/features/geo/presentation/widgets/ward_location_chip.dart` | create | `WardLocationChip` (presentational, `state` via constructor) + keys + tap-to-detail navigation (§4.5). |
| F5 | Compose screen (issue reporting, existing file) | modify | Insert `WardLocationChip` with `Key('composeLocationChip')` (§4.6). |
| F6 | Feed/Home screen app bar (existing file) | modify | Insert compact `WardLocationChip` with `Key('feedAreaLabel')` (§4.6). |

No changes to: `RoutePaths` (`wardDetailFor` already exists), ward detail pages, auth flows, issue storage/fuzzing, pubspec dependencies (no new packages required; if the platform GPS source needs a plugin it must already be present in the app — the abstract service isolates it either way).

---

## 7. Testing Boundaries (what the test engineer verifies per module — derived from AC-1..AC-10)

The test engineer works from the test plan + extracted interfaces; this section defines the verification surface so the implementation is test-shaped.

### 7.1 Backend — service (`service.py`)

- AC-1: known coordinate inside coverage of a seeded ward → returns that ward; `found=true`; `ward.slug/name/code` match; `place == ward.name`.
- AC-9: `distance_km` equals the true haversine distance rounded to one decimal (`abs(returned - true) <= 0.05`).
- AC-2: coordinate beyond `radius_km` of every ward → `found=false`, `ward=null`, `place="Outside coverage"`, `distance_km=0.0`.
- Boundary: coordinate exactly at `radius_km` → found (inclusive ceiling).
- Echo: response `latitude`/`longitude` equal the request values.
- Read-only: the service issues SELECTs only; with a spy/fake session, no INSERT/UPDATE/DELETE is ever issued.

### 7.2 Backend — API (`router.py` + mounted path)

- AC-1: `GET /api/v1/geo/reverse-geocode?latitude=..&longitude=..` → 200 with the full `ReverseGeocodeOut` shape.
- AC-2: out-of-coverage input → 200, `found=false`, `place="Outside coverage"`, `ward=null`.
- AC-3: `latitude=91` / `latitude=-91` / `longitude=181` / `longitude=-181` → 422 with body envelope code `invalid_coordinates`.
- AC-10: `latitude=abc`, missing params, extra text appended (`latitude=19.11junk`) → 422 `invalid_coordinates`; never 500, never a crash.
- AC-4: request with NO Authorization header and NO user context → 200 (guest-friendly); endpoint succeeds identically with and without auth headers.
- Radius bounds: `radius_km=0` and `radius_km=60` → 422 `invalid_coordinates`; `radius_km=0.1`, `radius_km=50` → accepted.
- Default: omitted `radius_km` behaves as 50.0.
- Validation-error handler scoping: a validation failure on a NON-geo endpoint retains the pre-existing 422 behavior (no regression).

### 7.3 Frontend — data (`geo_api.dart`)

- `ReverseGeocode.fromJson`: full snake_case payload parses to the correct camelCase fields (`wardSlug`/`wardName`/`wardCode`); `ward: null` or ABSENT → all three ward fields null (null-safe); `found=false` + `distance_km=0.0` preserved; extra unknown keys ignored (PII hygiene).
- `ReverseGeocode.fromJson` raises a controlled `FormatException` when a required scalar (`latitude`, `longitude`, `place`, `distance_km`, `found`) is missing.
- `GeoApi.reverseGeocode`: builds the correct relative path (`/geo/reverse-geocode`) and query params (`latitude`, `longitude`, `radius_km` — `radius_km` ALWAYS present because `radiusKm` has a non-null 50.0 default); parses a 200 body; propagates ApiClient errors.

### 7.4 Frontend — providers (injectable location is the mandatory seam)

- Fake location service returns coordinates → state sequence `loading → success`, `WardLocationSuccess.place/wardSlug/code` populated from the API result.
- Fake location service THROWS (permission denied / GPS off) → `unavailable` (AC-7); no API call is made.
- Fake location service returns coordinates but the API call fails (network) → `unavailable` (AC-7).
- API returns `found=false` → `WardLocationSuccess(place: "Outside coverage", wardSlug: null, code: '')` (AC-2) — NOT `unavailable`.
- Both surfaces read the SAME provider instance — resolution happens once (Business Rule "Resolved once"): watching the provider twice triggers a single location lookup + a single API call.

### 7.5 Frontend — widgets & screen integration

- `WardLocationChip` (presentational, constructed with `WardLocationChip(state: state)`) renders each state with the correct key and text: `Key('wardLocationLoading')` → "Locating…"; `Key('wardLocationUnavailable')` → `Icons.location_off_outlined` + "Location unavailable" (AC-7); `Key('wardLocationOutsideCoverage')` → "Outside coverage" (AC-2); `Key('wardLocationChip')` → place label + ward code (e.g. "Ward 45, Urban Central" and "W-45" both present) (AC-1).
- AC-8: tapping the chip in the success (found) state navigates to the ward detail route for `state.wardSlug` (via `RoutePaths.wardDetailFor`); tapping in any other state does nothing.
- AC-5: compose screen renders the chip with `Key('composeLocationChip')` above the draft, and the publish flow still works in every chip state.
- AC-6: feed app bar renders the nearby-area label with `Key('feedAreaLabel')`, and the feed still works when the label is `unavailable`/`outside coverage`.
- Widget tests inject fakes via `deviceLocationProvider` / `geoApiProvider` overrides — no real GPS anywhere (mandatory seam).

---

## 8. Non-Functional Constraints

### 8.1 Auth & identity

- **No authentication** on `GET /api/v1/geo/reverse-geocode` (AC-4). No Authorization header required, no user object injected, no identity touched.
- Response contains ward place data only; **zero PII** — no user id, device id, account data, contact info, or precise-location metadata beyond the echoed coordinates (spec §5; coordinates are the caller's own input).

### 8.2 Validation & stability

- Declarative `Query` bounds: lat ∈ [-90, 90], lng ∈ [-180, 180], radius ∈ [0.1, 50] default 50.0.
- Every malformed/out-of-range/missing input → HTTP 422 `invalid_coordinates` (AC-3, AC-10). The feature never crashes, hangs, or surfaces an internal error.

### 8.3 Read-only & privacy

- Backend: SELECT-only against `wards`; no writes, no history, no analytics, no storage of location.
- Logging: outcome-only (ward slug + found); coordinates never logged.
- Frontend: location used solely for the ward label; not persisted, not shared, not tracked.

### 8.4 Performance

- Single query + O(n) haversine over the (small) ward registry; no N+1; no external services.
- Target: response well under 100 ms locally; the label is informational and never blocks compose/feed rendering (Non-blocking, AC-7).
- Frontend resolves once per provider lifetime (no repeated lookups while browsing).

### 8.5 Rate limiting & observability

- No rate limit is added in this subset; the existing `SlidingWindowRateLimiter` remains available for ops but is NOT part of this contract (the documented error surface is 422-only).
- Standard logging per §3.3; failures map to `WardLocationUnavailable` on the client, never to user-visible errors.

---

## 9. Assumptions (explicit, to be confirmed by the coder against the repo)

1. `api_router` is mounted under `/api/v1` in `app/main.py` so the full path is `GET /api/v1/geo/reverse-geocode`; only the `include_router` line is added — no other path changes.
2. `Ward` (`app.features.wards.models`) exposes at least: `slug`, `name`, `code`, `center_latitude`, `center_longitude` (fields match the `ReverseGeocodeWardOut` contract).
3. `place` is the ward `name` (e.g. AC-1 example "Ward 45, Urban Central"); `code` is serialized as a string in the API envelope (the `wards.code` ORM column is `String(50)`, no coerce needed).
4. `app.features.issues.geo.haversine_km(lat1, lng1, lat2, lng2) -> float` returns kilometers (existing behavior in issues/search).
5. `ApiClient` (frontend `core/network/api_client`) owns the `/api/v1` base prefix; `GeoApi` requests the relative path `/geo/reverse-geocode`.
6. `RoutePaths.wardDetailFor` exists in `core/router/route_paths` and accepts a ward slug (used as-is).
7. The default `currentCoordinatesProvider` value (19.1136, 72.8697) is a deterministic reference point for rendering/tests; it never by itself yields a `success` state — the injectable `DeviceLocationService` gates all success states (preserves AC-7).
