# Feature Contract: F-09-WARD Ward Place Page & Civic Summary Engine

**ID:** `F-09-WARD`  
**Name:** Ward Place Page & Civic Summary Engine (Ward Profile, Multi-Metric Civic Digest, Representative Linkage, Location Resolution & Hive Caching)  
**Status:** BINDING_CONTRACT  
**Created:** 2026-08-10  

---

## 1. Overview & Scope

### 1.1 Goals
- Expose authoritative Ward Place Pages that aggregate localized civic health metrics (total, active, escalated, and resolved issues, plus resolution rate percentage).
- Link assigned local representatives (`RepresentativeProfile`) directly to their respective Ward Place Page.
- Provide location-based ward auto-resolution from lat/lng coordinates.
- Allow citizens to tap on any issue's ward chip (`Key('wardChip_<id>')`) across Home Feed and Issue Detail screens to immediately navigate to the corresponding Ward Place Page (`/ward/:slug`).
- Support offline browsing of Ward Place Pages via local Hive caching (`'ward_cache'`).

### 1.2 Non-Goals
- Full GeoJSON polygon boundary drawing on GIS maps (simple lat/lng center point is used).
- Ward financial budget or tax revenue tracking.
- Hierarchical multi-city or federal governance management.

---

## 2. REST API Endpoints & Contracts

Base URL prefix: `/api/v1`

### 2.1 `GET /api/v1/wards/{ward_slug}`
Retrieves detailed civic metrics, assigned representative summary, and recent issues for a specific ward by its slug (or raw ward name).

- **Auth Required:** None (Public / Guest accessible).
- **Path Parameters:**
  - `ward_slug`: `string` (Slugified or exact name of the ward, e.g. `"ward-45-urban-central"` or `"ward-45"`).
- **Query Parameters:**
  - `issues_limit`: `integer` (Optional, 1–50, default: `10`).

- **Responses & Status Codes:**
  - `200 OK`: Ward details and metrics retrieved successfully.
  - `400 Bad Request`: Invalid parameter formatting (`code: "validation_error"`).
  - `404 Not Found`: No ward found matching `ward_slug` (`detail: "Ward not found"`, `code: "ward_not_found"`).

#### Response Schema (`WardDetailOut`)
```json
{
  "slug": "ward-45-urban-central",
  "name": "Ward 45, Urban Central",
  "code": "W-45",
  "center_latitude": 19.1136,
  "center_longitude": 72.8697,
  "total_issues": 15,
  "active_issues": 8,
  "escalated_issues": 3,
  "resolved_issues": 4,
  "resolution_rate_pct": 26.67,
  "top_categories": ["road", "water", "lighting"],
  "assigned_representative": {
    "official_name": "Hon. Sarah Jenkins",
    "title": "Ward Representative",
    "verified_at": "2026-08-10T00:00:00Z"
  },
  "recent_issues": [
    {
      "id": 101,
      "title": "Deep Pothole on Main St",
      "description": "Hazardous crater near crosswalk",
      "category": "road",
      "status": "open",
      "latitude": 19.1136,
      "longitude": 72.8697,
      "geohash": "w75q1",
      "ward": "Ward 45, Urban Central",
      "is_anonymous": true,
      "fuzz_location": false,
      "is_fuzzed": false,
      "is_shielded": false,
      "reporter_label": "Citizen Sentinel",
      "anonymous_identity": "anon_a1b2c3d4",
      "created_at": "2026-08-10T10:00:00Z",
      "upvotes_count": 12,
      "comments_count": 3,
      "confirmations_count": 0,
      "disputes_count": 0,
      "has_upvoted": false,
      "has_official_response": true
    }
  ],
  "updated_at": "2026-08-10T12:00:00Z"
}
```

---

### 2.2 `GET /api/v1/wards`
Lists all active wards with aggregated summary statistics.

- **Auth Required:** None (Public / Guest accessible).
- **Query Parameters:**
  - `limit`: `integer` (Optional, 1–100, default: `20`).
  - `offset`: `integer` (Optional, ≥0, default: `0`).

- **Responses & Status Codes:**
  - `200 OK`: Wards summary list retrieved successfully.

#### Response Schema (`WardListResponse`)
```json
{
  "items": [
    {
      "slug": "ward-45-urban-central",
      "name": "Ward 45, Urban Central",
      "code": "W-45",
      "center_latitude": 19.1136,
      "center_longitude": 72.8697,
      "total_issues": 15,
      "active_issues": 8,
      "escalated_issues": 3,
      "resolved_issues": 4,
      "resolution_rate_pct": 26.67
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

---

### 2.3 `GET /api/v1/wards/by-location`
Resolves the nearest ward summary based on GPS latitude and longitude.

- **Auth Required:** None (Public / Guest accessible).
- **Query Parameters:**
  - `latitude`: `float` (Required, -90.0 to 90.0).
  - `longitude`: `float` (Required, -180.0 to 180.0).

- **Responses & Status Codes:**
  - `200 OK`: Nearest ward resolved.
  - `400 Bad Request`: Latitude or longitude out of range (`code: "invalid_coordinates"`).
  - `404 Not Found`: No ward within jurisdiction range (`code: "ward_not_found"`).

#### Response Schema (`WardSummaryOut`)
```json
{
  "slug": "ward-45-urban-central",
  "name": "Ward 45, Urban Central",
  "code": "W-45",
  "center_latitude": 19.1136,
  "center_longitude": 72.8697,
  "total_issues": 15,
  "active_issues": 8,
  "escalated_issues": 3,
  "resolved_issues": 4,
  "resolution_rate_pct": 26.67
}
```

---

## 3. Error Responses & Standard Status Codes

All API errors return standard JSON payloads:
```json
{
  "detail": "Error message description",
  "code": "error_code_identifier"
}
```

| HTTP Code | Error Code (`code`) | Cause / Condition | Response Example |
|---|---|---|---|
| **200 OK** | N/A | Successful query execution | `WardDetailOut` / `WardListResponse` |
| **400 Bad Request** | `validation_error` / `invalid_coordinates` | Latitude/longitude invalid or query parameter error | `{"detail": "Latitude must be between -90 and 90", "code": "invalid_coordinates"}` |
| **404 Not Found** | `ward_not_found` | Requested `ward_slug` does not exist in database | `{"detail": "Ward not found", "code": "ward_not_found"}` |
| **429 Too Many Requests** | `rate_limit_exceeded` | Exceeded 60 requests per minute limit | `{"detail": "Rate limit exceeded. Maximum 60 requests per minute.", "code": "rate_limit_exceeded"}` |

---

## 4. Business & Helper Rules

### 4.1 Slugification Standard
Ward names (e.g. `"Ward 45, Urban Central"`) are slugified via lowercase, stripping non-alphanumeric characters except hyphens and spaces, and replacing spaces/commas with single hyphens:
- `"Ward 45, Urban Central"` → `"ward-45-urban-central"`
- `"Ward 12"` → `"ward-12"`
Lookups must support matching both exact raw `ward` string and slugified `ward` string in database queries.

### 4.2 Resolution Rate Calculation
- Formula: `resolution_rate_pct = round((resolved_issues / total_issues) * 100, 2)` if `total_issues > 0` else `0.0`.

### 4.3 Shielded Exclusion
- Shielded issues (`is_shielded == True`) that are not resolved must be excluded from public `recent_issues` list on the Ward Place Page, matching home feed discovery rules.

---

## 5. Frontend State & Local Storage Contracts

### 5.1 Route Paths & Navigation
Add to `RoutePaths` in `app/lib/core/router/route_paths.dart`:
- `static const wardDetail = '/ward/:slug';`
- `static String wardDetailFor(String slug) => '/ward/$slug';`

In `app_router.dart`:
```dart
GoRoute(
  path: RoutePaths.wardDetail,
  builder: (context, state) => WardDetailScreen(
    wardSlug: state.pathParameters['slug']!,
  ),
),
```

### 5.2 Riverpod Providers
1. `wardDetailNotifierProvider`:
   - `AutoDisposeAsyncNotifierProviderFamily<WardDetailNotifier, WardDetailOut, String>`
   - State: `AsyncValue<WardDetailOut>`
   - Interacts with `LocalStore` to load offline cached data first, then fetches fresh data from `GET /api/v1/wards/{ward_slug}`.

2. `wardListNotifierProvider`:
   - `AutoDisposeAsyncNotifierProvider<WardListNotifier, WardListResponse>`
   - State: `AsyncValue<WardListResponse>`

### 5.3 Hive / LocalStore Caching
- **Box Name:** `'ward_cache'` (registered in `LocalStore.instance`).
- **Key Format:** `'ward_detail_<slug>'`
- **Cached Data Format:** Stringified JSON matching `WardDetailOut`.
- **LocalStore Methods:**
  - `String? getWardDetailCache(String slug)`
  - `Future<void> saveWardDetailCache(String slug, String jsonStr)`

---

## 6. UI Widget Keys Specification

All UI components MUST attach exact keys:

| Component | Key String | Type | Description / Usage |
|---|---|---|---|
| **Ward Chip** | `Key('wardChip_<id>')` | `ValueKey<String>` | Clickable chip on `IssueCard` or `IssueDetailScreen` that navigates to `/ward/:slug` |
| **Ward Detail Screen** | `Key('wardDetailScreen')` | `ValueKey<String>` | Root container of `WardDetailScreen` |
| **Ward Hero Banner** | `Key('wardHeroBanner')` | `ValueKey<String>` | Hero header card containing Ward Name and Ward Code |
| **Metric Total Card** | `Key('wardMetricTotal')` | `ValueKey<String>` | Stat card displaying total reported issues |
| **Metric Active Card** | `Key('wardMetricActive')` | `ValueKey<String>` | Stat card displaying open/active issues |
| **Metric Escalated Card** | `Key('wardMetricEscalated')` | `ValueKey<String>` | Stat card displaying escalated issues |
| **Metric Resolved Card** | `Key('wardMetricResolved')` | `ValueKey<String>` | Stat card displaying resolved issues |
| **Metric Resolution Rate Card** | `Key('wardMetricResolutionRate')` | `ValueKey<String>` | Stat card displaying resolution percentage |
| **Assigned Representative Card** | `Key('wardRepCard')` | `ValueKey<String>` | Card displaying assigned representative details |
| **Recent Issues List** | `Key('wardRecentIssuesList')` | `ValueKey<String>` | Scrollable ListView of recent issues in the ward |
| **Ward Screen Back Button** | `Key('wardDetailBackButton')` | `ValueKey<String>` | Navigation back button in app bar |

---

## 7. Test Contract Assertions

### 7.1 Pytest Backend Contract Assertions
```python
# backend/tests/features/issues/test_ward_place_page.py

@pytest.mark.asyncio
async def test_get_ward_detail_success(client):
    response = await client.get("/api/v1/wards/ward-45-urban-central")
    assert response.status_code == 200
    data = response.json()
    assert data["slug"] == "ward-45-urban-central"
    assert data["name"] == "Ward 45, Urban Central"
    assert "total_issues" in data
    assert "resolution_rate_pct" in data
    assert isinstance(data["recent_issues"], list)

@pytest.mark.asyncio
async def test_get_ward_detail_not_found(client):
    response = await client.get("/api/v1/wards/non-existent-ward-99")
    assert response.status_code == 404
    assert response.json()["code"] == "ward_not_found"

@pytest.mark.asyncio
async def test_get_wards_list(client):
    response = await client.get("/api/v1/wards")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] >= 1

@pytest.mark.asyncio
async def test_get_ward_by_location(client):
    response = await client.get("/api/v1/wards/by-location?latitude=19.1136&longitude=72.8697")
    assert response.status_code == 200
    data = response.json()
    assert data["slug"] == "ward-45-urban-central"
```

### 7.2 Flutter Widget Test Assertions
```dart
// app/test/features/ward/ward_detail_screen_test.dart

void main() {
  testWidgets('Tapping ward chip navigates to WardDetailScreen', (tester) async {
    await tester.pumpWidget(createTestApp(home: const FeedScreen()));
    await tester.pumpAndSettle();

    final wardChip = find.byKey(const Key('wardChip_101'));
    expect(wardChip, findsOneWidget);

    await tester.tap(wardChip);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
    expect(find.byKey(const Key('wardHeroBanner')), findsOneWidget);
    expect(find.byKey(const Key('wardMetricTotal')), findsOneWidget);
    expect(find.byKey(const Key('wardMetricActive')), findsOneWidget);
    expect(find.byKey(const Key('wardMetricResolved')), findsOneWidget);
  });
}
```
