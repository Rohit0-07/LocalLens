# F-08-filters Advanced Search Filters — Interface Contracts

> Authoritative contracts that bind the (code-blind) test-writer, the coder, and the
> validator for the **Advanced Search Filters** subset of feature F-08. Implementers and
> testers MUST match these names, shapes, routes, and strings exactly. This document is
> the only shared ground between the implementation and the tests.
>
> This subset EXTENDS the already-shipped Search feature (`F-08_search_contracts.md`).
> Every rule and name in that contract remains binding unless this document explicitly
> amends it. No existing parameter's meaning is changed; everything here is additive.

Scope: let users narrow search results by **status** (single-select), **category**
(multi-select), **distance** (within a radius), and **date range** (posted within a
window). New backend query parameters on the existing `GET /api/v1/search` endpoint plus
a new Material 3 filter bottom-sheet in the Search screen.

Non-goals (explicitly OUT of scope):
- No new post types (`type` filter deferred — requires wins/notices/local-talk).
- No map.
- No change to the `q`-required semantics, existing `status`, `category`, `radius_km`,
  `latitude`, `longitude`, `limit`, `offset` parameters, shielding, rate limiting, or
  response schema (`list[IssueOut]`).
- No persisted server-side filter preferences (filters are in-memory, per-session).

---

## 1. Backend contract

### 1.1 Files
No new module. Edit existing:
```
backend/app/features/search/router.py
backend/app/features/search/service.py
```
Route stays mounted at `GET /api/v1/search` (`api/router.py` unchanged).

### 1.2 New query parameters on `GET /api/v1/search`

| param | type | required | constraints |
|-------|------|----------|-------------|
| `categories` | list[str] (repeatable) | no | each item ≤ 32 chars; max 20 items; else 422; empty list = no filter |
| `created_after` | str (ISO-8601) | no | parseable else 422; see format rules |
| `created_before` | str (ISO-8601) | no | parseable else 422; see format rules |

Accepted `created_after` / `created_before` formats (all normalized to **naive UTC**):
- `YYYY-MM-DD` → interpreted as midnight UTC.
- `YYYY-MM-DDTHH:MM:SS` and `YYYY-MM-DDTHH:MM:SS.ffffff` → naive treated as UTC.
- Same forms with trailing `Z` or `+HH:MM` / `-HH:MM` offset → converted to UTC, tz stripped.
Any other string (e.g. `not-a-date`, `2026-13-99`) → HTTP 422.

Semantics:
- `categories`: `Issue.category IN (categories)` (OR within the list). Sent as repeated
  query params: `?categories=road&categories=water`.
- `created_after`: `Issue.created_at >= created_after` (naive UTC).
- `created_before`: `Issue.created_at <= created_before` (naive UTC).
- When BOTH `created_after` and `created_before` are supplied and
  `created_after > created_before` → HTTP 422.

### 1.3 Error codes (via `AppError`, existing `app/core/exceptions.py`)
| code | HTTP | when |
|------|------|------|
| `invalid_date_format` | 422 | unparseable `created_after` / `created_before` |
| `invalid_date_range` | 422 | `created_after > created_before` |
| `invalid_category` | 422 | any `categories` item > 32 chars, or more than 20 items |

Unchanged existing codes: `empty_query` (422), `query_too_long` (422),
`both_coordinates_required` (400), `invalid_status` (422), `rate_limited` (429).

### 1.4 `service.py` — signature change (additive)
```python
async def search_issues(
    session: AsyncSession,
    *,
    q: str,
    latitude: float | None,
    longitude: float | None,
    radius_km: float,
    status: str | None,
    category: str | None,
    categories: list[str] | None,
    created_after: datetime | None,
    created_before: datetime | None,
    limit: int,
    offset: int,
) -> list[Issue]
```
Behaviour additions (all existing steps 1–8 from `F-08_search_contracts.md` §1.4
unchanged):
1. If `categories` is non-empty: `statement = statement.where(Issue.category.in_(categories))`.
2. If `created_after` is not None: `statement = statement.where(Issue.created_at >= created_after)`.
3. If `created_before` is not None: `statement = statement.where(Issue.created_at <= created_before)`.
4. All of the above are **parameterized SQLAlchemy** expressions — no string
   interpolation of any user input (SQLi-safe by construction).
5. Ordering (`created_at desc, id desc`), `limit`/`offset`, escalation evaluation,
   shielded-privacy exclusion (`is_shielded and status != "resolved"`), and the
   haversine proximity post-filter are applied exactly as today, AFTER the new filters.

### 1.5 `service.py` — new public helper
```python
def parse_iso_datetime(value: str) -> datetime:
    """Parse an ISO-8601 datetime into a naive-UTC datetime.

    Accepts 'YYYY-MM-DD', 'YYYY-MM-DDTHH:MM:SS', 'YYYY-MM-DDTHH:MM:SS.ffffff',
    with optional trailing 'Z' or '+HH:MM' offset. On any parse failure raises
    AppError(message, status_code=422, code="invalid_date_format").
    """
```
Normalization details (must hold):
- Trailing `Z` is replaced by `+00:00` before parsing.
- Aware datetimes are converted with `astimezone(UTC)` then `.replace(tzinfo=None)`.
- Naive datetimes are used as-is (already UTC by contract).

### 1.6 `router.py` — validation order (endpoint body, after the rate-limit dependency)
1. `q` empty/whitespace → 422 `empty_query`; `q` > 100 → 422 `query_too_long`.
2. Exactly one of `latitude`/`longitude` → 400 `both_coordinates_required`.
3. `status` not in the allowed 9-value enum → 422 `invalid_status`.
4. `category` (single) > 32 chars → 422 `invalid_category`.
5. NEW: `categories` — any item > 32 chars OR more than 20 items → 422 `invalid_category`.
6. NEW: `parse_iso_datetime(created_after)` if provided → 422 `invalid_date_format` on failure.
7. NEW: `parse_iso_datetime(created_before)` if provided → 422 `invalid_date_format` on failure.
8. NEW: both provided and `created_after > created_before` → 422 `invalid_date_range`.
Then call `service.search_issues(...)` passing the parsed naive-UTC `datetime` objects.

---

## 2. Frontend contract

### 2.1 Files
New:
```
app/lib/features/search/domain/search_filters.dart
app/lib/features/search/presentation/search_filters_provider.dart
app/lib/features/search/presentation/advanced_filter_sheet.dart
```
Edited:
```
app/lib/features/search/domain/search_repository.dart
app/lib/features/search/data/search_api.dart
app/lib/features/search/presentation/search_providers.dart
app/lib/features/search/presentation/search_screen.dart
```
Router and `RoutePaths` are UNCHANGED.

### 2.2 `domain/search_filters.dart`
```dart
enum SearchDatePreset { anyTime, past24Hours, past7Days, past30Days }

enum SearchDistanceOption { any, within }

class SearchFilters {
  const SearchFilters({
    this.status,
    this.categories = const <String>[],
    this.distanceOption = SearchDistanceOption.any,
    this.radiusKm = 5.0,
    this.datePreset = SearchDatePreset.anyTime,
  });

  final String? status;
  final List<String> categories;
  final SearchDistanceOption distanceOption;
  final double radiusKm;
  final SearchDatePreset datePreset;

  bool get isActive => status != null ||
      categories.isNotEmpty ||
      distanceOption == SearchDistanceOption.within ||
      datePreset != SearchDatePreset.anyTime;

  SearchFilters copyWith({...});  // standard copyWith for all five fields
  SearchFilters reset();          // returns const SearchFilters()
}
```
Constants (live in this file):
```dart
const kSearchStatusOptions = <String>[
  'unacknowledged', 'under_review', 'escalating', 'forwarded',
  'pending_quorum', 'resolved', 'disputed',
];

const kSearchCategoryOptions = <String>[
  'road', 'water', 'power', 'lighting', 'waste', 'sewage', 'other',
];
```
Status strings MUST be byte-identical to the backend enum values.

### 2.3 `presentation/search_filters_provider.dart`
```dart
final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new);

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setStatus(String? status);                 // replaces; null clears
  void toggleCategory(String category);           // add if absent, remove if present
  void setDistanceOption(SearchDistanceOption option);
  void setRadiusKm(double km);
  void setDatePreset(SearchDatePreset preset);
  void reset();                                   // state = const SearchFilters()
}
```

### 2.4 `presentation/advanced_filter_sheet.dart`
```dart
Future<SearchFilters?> showAdvancedFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
});
```
Calls `showModalBottomSheet<SearchFilters>` (`isScrollControlled: true`, rounded top
corners, M3 `surface`). Pops the applied `SearchFilters` on `'Show results'`; pops `null`
on barrier tap / swipe-down dismiss. The sheet is a `ConsumerStatefulWidget` seeded from
`initial`.

Sections (Material 3 only — `ChoiceChip`, `FilterChip`, `SegmentedButton`, `Slider`,
`TextButton`, `FilledButton`; theme tokens via `colorScheme`; **no gradients, no emoji,
no `Colors.*` literals**):

1. Header: `Text('Filters')` (titleLarge).
2. `Text('Status')` — single-select `Wrap` of `ChoiceChip`, labels = exact status strings
   from `kSearchStatusOptions`. Key per chip: `Key('statusChip_<status>')`.
3. `Text('Category')` — multi-select `Wrap` of `FilterChip`, labels = exact category
   strings from `kSearchCategoryOptions`. Key per chip: `Key('categoryChip_<category>')`.
4. `Text('Distance')` — two-segment `SegmentedButton<SearchDistanceOption>` with
   segments `'Any distance'` (Key `Key('distanceAny')`) and `'Within radius'`
   (Key `Key('distanceWithin')`). When `within` is selected, show a `Slider`
   (min 1, max 50, divisions 49, label `'<n> km'`) with `Key('distanceSlider')`.
5. `Text('Posted')` — single-select `Wrap` of `ChoiceChip` from `SearchDatePreset` with
   labels `'Any time'`, `'Past 24 hours'`, `'Past 7 days'`, `'Past 30 days'`. Keys:
   `Key('dateChip_anyTime')`, `Key('dateChip_past24Hours')`,
   `Key('dateChip_past7Days')`, `Key('dateChip_past30Days')`.
6. Action row: `TextButton` `'Reset'` (Key `Key('resetFiltersButton')`) — resets the
   sheet's LOCAL selection to `const SearchFilters()` (does NOT pop); `FilledButton`
   `'Show results'` (Key `Key('applyFiltersButton')`) — pops the current local selection.

### 2.5 `presentation/search_providers.dart` — `SearchResultsNotifier.runQuery`
```dart
Future<void> runQuery(String q, {double? latitude, double? longitude}) async
```
Behaviour (amends `F-08_search_contracts.md` §2.4):
- Reads the current filters via `ref.read(searchFiltersProvider)`.
- `status` → `filters.status` (only when non-null).
- `categories` → `filters.categories` (only when non-empty).
- Distance: when `filters.distanceOption == SearchDistanceOption.within`, sends
  `radiusKm = filters.radiusKm` AND, when the caller did not supply coordinates,
  defaults `latitude`/`longitude` to `defaultLatitude` / `defaultLongitude` from
  `app/lib/features/feed/presentation/feed_providers.dart` (19.1136, 72.8697).
- Date: derived at call time from `filters.datePreset` (all via
  `DateTime.now().toUtc()`):
  - `past24Hours` → `createdAfter = now - 24h`
  - `past7Days` → `createdAfter = now - 7d`
  - `past30Days` → `createdAfter = now - 30d`
  - `anyTime` → `createdAfter = null`, `createdBefore = null`
- No date range sends `createdBefore` (the UI has no independent "before" control).
- When `filters.isActive == false` the call is byte-identical to today (only `q`,
  optional coordinates, `limit: 20`).

### 2.6 `domain/search_repository.dart` — signature change (additive)
```dart
abstract interface class SearchRepository {
  Future<List<Issue>> search({
    required String query,
    double? latitude,
    double? longitude,
    String? status,
    List<String> categories = const <String>[],
    double? radiusKm,
    DateTime? createdAfter,
    DateTime? createdBefore,
  });
}
```

### 2.7 `data/search_api.dart` — `SearchApi.search`
Maps (only when non-null / non-empty / active):
- `q`; `latitude`/`longitude` when non-null; `limit: 20` always.
- `status` when non-null.
- `categories` when non-empty (Dio encodes a List as repeated params:
  `categories=road&categories=water`).
- `radius_km` when non-null.
- `created_after` when non-null → `createdAfter.toUtc().toIso8601String()` (e.g.
  `2026-08-03T12:00:00.000Z`).
- `created_before` when non-null → same encoding.
Response: existing `Issue.fromJson` per item (unchanged).

### 2.8 `presentation/search_screen.dart`
- AppBar `actions` gain an `IconButton` with `tooltip: 'Filters'`,
  `icon: const Icon(Icons.tune)`, `Key: Key('filterButton')`.
- When `ref.watch(searchFiltersProvider).isActive`:
  - the filter icon is wrapped in a `Badge` (small dot);
  - a `TextButton` labeled exactly `'Clear filters'` (`Key: Key('clearFiltersButton')`)
    appears to its right; tapping it calls `searchFiltersProvider.notifier.reset()`
    and re-runs the last query (`_runSearch(_lastQuery)` — no-op guard if empty).
- Tapping the filter icon:
  ```dart
  final result = await showAdvancedFilterSheet(
    context,
    initial: ref.read(searchFiltersProvider),
  );
  if (result != null) {
    ref.read(searchFiltersProvider.notifier).state = result;
    _runSearch(_lastQuery.isEmpty ? _controller.text.trim() : _lastQuery);
  }
  ```
- `_runSearch` / `_onQueryChanged` / `_runRecentSearch` / `_retryLastQuery` logic is
  otherwise UNCHANGED — `runQuery` reads the filters from the provider internally, so
  every search path automatically applies the current filters.
- Empty-query body, recents, skeleton, error, and no-results states are UNCHANGED.

---

## 3. Test contracts

### 3.1 Backend — new file `backend/tests/features/search/test_search_filters.py`
Reuse fixtures from `backend/tests/conftest.py`: `client`, `auth_headers`,
`create_user_headers`, `app`. Create issues via the PUBLIC `POST /api/v1/issues` API only
(no DB writes, no model imports). For date-window tests compute bounds in-test with
`datetime.now(UTC)` / `datetime.utcnow()` and relative `timedelta`s — do NOT attempt to
backdate issues. MUST cover:

1. `categories` single value → only issues in that category returned; others excluded.
2. `categories` multi (repeated `?categories=road&categories=water`) → issues in EITHER
   category returned (OR).
3. `categories` combined with `q` → only issues matching BOTH keyword AND category.
4. `created_after` in the recent past (e.g. now − 1 day) → freshly created issues returned.
5. `created_after` in the future (e.g. now + 1 day) → empty result set.
6. `created_before` in the near future (now + 1 day) → created issues returned.
7. `created_before` in the past (now − 1 day) → empty result set.
8. Both bounds spanning (past … future) → issues returned; window that excludes everything
   → empty.
9. `created_after > created_before` → 422 with `code == "invalid_date_range"`.
10. `created_after=not-a-date` → 422 with `code == "invalid_date_format"`.
11. `created_before=2026-13-99` → 422 with `code == "invalid_date_format"`.
12. Date-only format `created_after=2020-01-01` → 200 (accepted).
13. `created_after=2020-01-01T00:00:00Z` → 200; `created_after=2020-01-01T00:00:00+05:30`
    → 200 (offset normalized).
14. `categories` item > 32 chars → 422 with `code == "invalid_category"`.
15. `categories` with 21 items → 422 with `code == "invalid_category"`.
16. `categories` empty (no items at all) → 200, treated as no filter.
17. Combined: `status` + `categories` + `radius_km` + created-window all present → only
    the intersection returned.
18. Shielded privacy preserved: a shielded non-resolved issue matching every filter is
    still excluded; a non-shielded match is returned.
19. Rate limit preserved: 60 rapid searches from one user → 200; the 61st → 429
    `code == "rate_limited"` (smoke regression; full suite exists in `test_search.py`).
20. SQLi probes: `categories` value `"road' OR 1=1 --"` and junk date params never cause
    a 500 and never widen results (junk dates → 422, not 500).
21. Guest can search with filters active → 200.
22. Pagination composition: `limit`/`offset` slice correctly when filters are active.

### 3.2 Frontend — new files
`app/test/features/search/search_filters_test.dart` (sheet + screen integration) and
`app/test/features/search/search_api_filters_test.dart` (param mapping). Follow the
established widget-test pattern (see `search_screen_test.dart`): `ProviderContainer` +
`UncontrolledProviderScope`, `FakeSearchRepository implements SearchRepository` and a
`FakeRecentSearchStore` defined inside the test file, `buildIssue(...)` from
`app/test/helpers.dart`.

CRITICAL housekeeping: the existing `FakeSearchRepository` in
`app/test/features/search/search_screen_test.dart` MUST gain the new optional members
(`status`, `categories`, `radiusKm`, `createdAfter`, `createdBefore`) so it still
satisfies the extended interface; its behaviour and existing tests are unchanged.

MUST cover:
1. Filter icon present on `SearchScreen`; `tooltip == 'Filters'`; tapping opens the sheet
   (header `'Filters'` and `applyFiltersButton` become visible).
2. Sheet renders all 7 status chips; tapping one marks it selected (single-select).
3. Sheet renders all 7 category chips; tapping toggles (select → deselect).
4. `'Within radius'` segment reveals `distanceSlider`; `'Any distance'` hides it.
5. Tapping `'Past 7 days'` selects that date chip.
6. `'Reset'` clears all local selections (status/category/date deselected, distance
   `any`).
7. `'Show results'` with status=resolved + categories [road, water] + within/5 km +
   past7Days pops; `searchFiltersProvider` state reflects the selection and
   `isActive == true`.
8. Barrier-tap dismiss returns `null` → provider unchanged (`isActive == false`).
9. With active filters, app bar shows `'Clear filters'`; tapping it resets the provider
   and re-runs the last query (fake repository's `lastQuery` unchanged; captured filter
   args are null/empty afterwards).
10. With active filters, a search passes them exactly: `FakeSearchRepository` captures
    `status`, `categories`, `radiusKm`, `createdAfter` (non-null for past7Days),
    `createdBefore` (null).
11. No active filters → repository receives null status / empty categories / null radius
    / null dates (regression for existing behaviour).
12. Results still render as issue cards when filters are active.
13. `SearchApi` mapping (`search_api_filters_test.dart`): subclass `ApiClient`, assert the
    query map contains `status`, `categories` as a repeated list, `radius_km`,
    `created_after` ending in `Z`, `created_before`; and that when no filters are active
    none of those keys appear.
14. Unit test: `SearchFilters.reset()` returns an all-default `SearchFilters`; `isActive`
    is false for defaults and true when any field differs.

---

## 4. Acceptance (assert in validation)
- Backend: `GET /api/v1/search?q=...&categories=road&categories=water&status=resolved&created_after=...`
  returns 200 `list[IssueOut]` honouring every filter; date/category validation 422 codes
  exact; shielded + rate-limit + SQLi guarantees preserved; full pre-existing suite green.
- Frontend: `/search` filter icon opens the M3 sheet; chips/slider/presets behave;
  `'Show results'` / `'Clear filters'` / `'Reset'` wired; filters flow through
  `runQuery` → `SearchApi` → backend exactly as contracted; clean M3 UI (no gradients /
  emoji / `Colors.*`).
- Quality gates: backend `ruff check .` + `mypy app` clean; app `flutter analyze` clean;
  full backend `pytest` suite and full `flutter test` suite stay green (no regressions).
