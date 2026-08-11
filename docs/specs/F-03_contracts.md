# F-03 Spatial & Geofencing Engine — Reverse Geocoding & Ward Boundary Lookup

**Feature ID:** F-03 (subset: `reverse-geocode_2026-08-10`)
**Status:** DRAFT (contract is the single binding artifact between test-writer and coder)
**Created:** 2026-08-10

> This document is the ONLY binding artifact. Any drift between backend/frontend/tests is
> resolved by editing THIS file, never by silently diverging in code.

---

## 1. Scope

Deliver the **Reverse Geocoding & Ward Boundary Lookup** engine:

- **Backend:** a new `geo` feature module exposing `GET /api/v1/geo/reverse-geocode` that maps a
  lat/lng pair to the enclosing ward (from the `wards` table) plus a structured, human-readable
  place label. Reuses the existing `Ward` model and `haversine_km` primitive.
- **Frontend:** a reusable **`WardLocationChip`** widget + Riverpod state (`wardLocationProvider`)
  that resolves the current device/default location once, shows the ward place name and a
  "Locating…" / "Location unavailable" state, and is surfaced on the **Compose screen** (before
  publish) and on the **Feed app bar** (nearby-area label). No map SDK work in this subset.
- **Testable:** full backend pytest + frontend Flutter test coverage on both tiers.

## 2. Non-Goals (explicit)

- No map rendering, clustering, custom pins, or tile SDK.
- No camera/media pipeline.
- No polygon (shapefile) ward boundaries — nearest-center + 50 km ceiling as today.
- No changes to `POST /issues` location fuzzing semantics.
- No new auth endpoints; guest and authenticated users both call reverse-geocode.
- No external geocoding provider (Google/Mapbox); purely internal ward lookup.
- No background geofence monitoring / geofence triggers.

---

## 3. Backend Contract

### 3.1 New feature module

- Python package: `backend/app/features/geo/` containing `router.py`, `service.py`, `schemas.py`.
- Mounted in `backend/app/api/router.py`:
  `api_router.include_router(geo_router, prefix="/geo", tags=["geo"])`.
- Final wire path prefix: **`/api/v1/geo`**.

### 3.2 Endpoint

#### `GET /api/v1/geo/reverse-geocode`

**Query params (all required unless noted):**

| Param       | Type  | Required | Constraints        | Notes                              |
|-------------|-------|----------|--------------------|------------------------------------|
| `latitude`  | float | yes      | `ge=-90, le=90`    |                                    |
| `longitude` | float | yes      | `ge=-180, le=180`  |                                    |
| `radius_km` | float | no       | `ge=0.1, le=50`    | default `50.0`; match ceiling      |

**Auth:** none required. `OptionalUser` accepted but unused. No rate limit for MVP (perf note below).

**Success — `200 OK`** returns `ReverseGeocodeOut`:

```json
{
  "latitude": 19.1136,
  "longitude": 72.8697,
  "place": "Ward 45, Urban Central",
  "ward": {
    "slug": "ward-45-urban-central",
    "name": "Ward 45, Urban Central",
    "code": "W-45",
    "center_latitude": 19.1136,
    "center_longitude": 72.8697
  },
  "distance_km": 0.4,
  "found": true
}
```

**Response schema (`ReverseGeocodeOut`)** — exact field order/types:

| Field              | Type               | Notes                                              |
|--------------------|--------------------|----------------------------------------------------|
| `latitude`         | `float`            | echoed request lat                                 |
| `longitude`        | `float`            | echoed request lng                                 |
| `place`            | `str`              | ward `name` when found, else `"Outside coverage"`  |
| `ward`             | `ReverseGeocodeWardOut \| None` | `null` when not found                    |
| `distance_km`      | `float`            | haversine distance to ward center, `round(...,1)`; `0.0` when not found |
| `found`            | `bool`             | `true` iff a ward exists within `radius_km`        |

**`ReverseGeocodeWardOut`** (reuse pattern from `WardSummaryOut`, flattened):

| Field              | Type     | Notes                         |
|--------------------|----------|-------------------------------|
| `slug`             | `str`    | canonical ward slug           |
| `name`             | `str`    | display name                  |
| `code`             | `str`    | e.g. `W-45`                   |
| `center_latitude`  | `float`  | ward center lat               |
| `center_longitude` | `float`  | ward center lng               |

### 3.3 Error codes

| HTTP status | `error_code`         | Condition                                        |
|-------------|----------------------|--------------------------------------------------|
| 422         | `invalid_coordinates`| lat/lng out of range or non-numeric (Pydantic also returns 422) |
| 429         | `rate_limit_exceeded`| (reserved — not enforced in MVP; response shape reserved) |

> Note: 404 is NOT used — `found:false` with 200 is the contract for out-of-coverage.

### 3.4 Service behaviour (contract-level)

- Look up all wards; pick the ward minimizing `haversine_km(lat,lng, ward.center_latitude, ward.center_longitude)`.
- If `min_distance_km <= radius_km` → `found=True`, populate `ward` + `place=ward.name` + `distance_km=round(min,1)`.
- Else → `found=False`, `ward=None`, `place="Outside coverage"`, `distance_km=0.0`.
- No DB writes. Read-only. No escalation/shielded logic.

### 3.5 SQLi & security stance

- Only parameterized SQLAlchemy queries; no string-built SQL.
- Coordinates validated at schema/boundary level (Pydantic + FastAPI Query constraints).
- No PII in response (ward place names only).

---

## 4. Frontend Contract

### 4.1 Provider names

| Provider                             | Type                              | Notes                                      |
|--------------------------------------|-----------------------------------|--------------------------------------------|
| `geoApiProvider`                     | `Provider<GeoApi>`                | Dio-backed                                  |
| `deviceLocationProvider`             | `Provider<DeviceLocationService>` | abstract injectable seam; widget tests override it (no real GPS in tests). `DeviceLocationService` has `Future<({double lat, double lng})> getCurrentCoordinates()` and may throw on permission-denied / geo-unavailable |
| `wardLocationProvider`               | `NotifierProvider<WardLocationController, WardLocationState>` | resolves current location → `WardLocationState` |
| `currentCoordinatesProvider`         | `Provider<({double lat, double lng})>` | default `(19.1136, 72.8697)` when device location unavailable |

### 4.2 State shape (`WardLocationState`)

```dart
sealed class WardLocationState {
  const WardLocationState();
  // states:
  //  WardLocationLoading()
  //  WardLocationUnavailable()          // location permission denied or geo unavailable
  //  WardLocationSuccess({required String place, required String wardSlug, required String code})
  //    - place == "Outside coverage" when the API returned found=false (wardSlug == null, code == "")
}
```

### 4.3 Domain model (`ReverseGeocode`)

```dart
class ReverseGeocode {
  final double latitude;
  final double longitude;
  final String place;
  final String? wardSlug;
  final String? wardName;
  final String? wardCode;
  final double distanceKm;
  final bool found;
}
```

Factory `ReverseGeocode.fromJson(Map<String, Object?> json)`.

### 4.4 API class (`GeoApi`)

File: `app/lib/features/geo/data/geo_api.dart`

```dart
class GeoApi {
  GeoApi(this._client);
  final ApiClient _client;

  Future<ReverseGeocode> reverseGeocode({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  });
}
```

Wire path: `GET /geo/reverse-geocode`, query `{latitude, longitude, radius_km}` via
`_client.getJson('/geo/reverse-geocode', query: {...})`.

### 4.5 Widget: `WardLocationChip`

File: `app/lib/features/geo/presentation/widgets/ward_location_chip.dart`

- Renders the resolved ward place name in a Material 3 `Chip`/pill.
- States:
  - Loading → small `SizedBox` shimmer bar (`Key('wardLocationLoading')`).
  - Unavailable → chip with `Icons.location_off_outlined` + text `Location unavailable` (`Key('wardLocationUnavailable')`).
  - Success → chip with `Icons.place_outlined` + ward `place` text (`Key('wardLocationChip')`).
- Tapping a success chip navigates to `RoutePaths.wardDetailFor(slug)`.

### 4.6 Routes

| Route constant (`RoutePaths`)        | Path                  | Notes                       |
|--------------------------------------|-----------------------|-----------------------------|
| (existing) `wardDetail`              | `/ward/:slug`         | reused, no new route needed |

No new go_router route added in this subset.

### 4.7 UI strings (exact, used by tests)

| String                       | Where                       |
|------------------------------|-----------------------------|
| `Location unavailable`       | unavailable chip label      |
| `Ward 45, Urban Central`     | default place (via API)     |
| `Outside coverage`           | server `place` when unfound |
| `Locating…`                  | (a11y/label fallback)       |

### 4.8 Widget Keys (exact, used by tests)

| Key                                  | Widget                        |
|--------------------------------------|-------------------------------|
| `Key('wardLocationChip')`            | success chip                  |
| `Key('wardLocationLoading')`         | loading shimmer               |
| `Key('wardLocationUnavailable')`     | unavailable chip              |
| `Key('wardLocationOutsideCoverage')` | chip when place == "Outside coverage" (found=false) |
| `Key('composeLocationChip')`         | `WardLocationChip` in Compose |
| `Key('feedAreaLabel')`               | Feed app-bar area label       |

### 4.9 Hive keys

None new. `wardLocationProvider` is in-memory; compose draft continues to use existing draft
store keys (`current_draft`). No new LocalStore box.

---

## 5. Test Contract

### 5.1 Backend tests — `backend/tests/features/geo/test_geo.py`

| ID    | Case                                                       | Expected |
|-------|------------------------------------------------------------|----------|
| G-01  | reverse-geocode finds nearest ward inside radius            | 200, `found=true`, `ward.name` matches seeded ward |
| G-02  | reverse-geocode returns `found=false` when no ward within radius | 200, `found=false`, `ward=null`, `place="Outside coverage"` |
| G-03  | reverse-geocode echoes lat/lng back                        | 200, `latitude`/`longitude` equal request |
| G-04  | distance_km matches haversine to ward center               | 200, `distance_km == round(haversine,1)` |
| G-05  | invalid latitude (e.g. 91) rejected                         | 422 |
| G-06  | invalid longitude (e.g. 200) rejected                       | 422 |
| G-07  | missing latitude param rejected                             | 422 |
| G-08  | SQLi attempt in numeric fields yields 422 (not 500)         | 422 |
| G-09  | rate-limit reserved: no crash when called many times (smoke) | 200 |
| G-10  | SQLi attempt via query string `latitude=19.0 OR 1=1` rejected | 422 |
| G-11  | out-of-range radius_km rejected                             | 422 |
| G-12  | guest/no-auth call succeeds (no 401/403)                    | 200 |

### 5.2 Frontend tests — `app/test/features/geo/geo_test.dart` (or split)

| ID     | Case                                                              | Expected |
|--------|-------------------------------------------------------------------|----------|
| F-01   | `GeoApi.reverseGeocode` parses success response into `ReverseGeocode` | correct fields |
| F-02   | `GeoApi.reverseGeocode` handles `found:false`                      | `found=false`, `wardSlug=null` |
| F-03   | `ReverseGeocode.fromJson` null-safe with missing `ward`            | no throw |
| F-04   | `wardLocationProvider` initial state is `WardLocationLoading`      | loading state |
| F-05   | provider resolves to `WardLocationSuccess` with place text         | success state |
| F-06   | provider resolves to `WardLocationUnavailable` on API error        | unavailable state |
| F-07   | `WardLocationChip` shows place on success                          | `Key('wardLocationChip')` present, text matches |
| F-08   | `WardLocationChip` shows unavailable state on error                | `Key('wardLocationUnavailable')` present |
| F-09   | Compose screen shows `Key('composeLocationChip')`                  | present |
| F-10   | Feed screen shows `Key('feedAreaLabel')` with place                | present + text |
| F-11   | tapping success chip navigates to ward detail route                | route push observed |

---

## 6. Acceptance Criteria (traceable)

1. `GET /api/v1/geo/reverse-geocode` returns 200 with `found=true` + ward payload for a point inside
   a seeded ward.
2. The same endpoint returns 200 `found=false` with `place="Outside coverage"` for a faraway point.
3. Invalid/out-of-range coordinates return 422 (never 500).
4. Guest/anonymous callers can use the endpoint (no auth barrier).
5. Compose screen renders `WardLocationChip` and shows the resolved ward place.
6. Feed app bar renders the nearby-area label from the same resolved place.
7. No SQL injection: numeric params are typed; any string-injection attempt → 422.
8. No PII leaks: response contains ward place data only.

---

## 7. Definition of Done

- Backend: `GET /api/v1/geo/reverse-geocode` live, ruff + mypy-strict clean, pytest green (12 new cases).
- Frontend: `WardLocationChip` + provider live, `flutter analyze` clean, flutter test green (11 new cases).
- Full regression: existing 209+ pytest and 152+ flutter tests remain green.
