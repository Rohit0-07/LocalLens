# F-08 Search & Explore — Interface Contracts

> Authoritative contracts that bind the (code-blind) test-writer, the coder, and the
> validator for the **Search subset** of feature F-08. Implementers and testers MUST
> match these names, shapes, routes, and strings exactly. This document is the only
> shared ground between the implementation and the tests.

Scope: search issues by keyword (title / description / category / ward), optional
proximity + status/category filters, pagination. Recent-searches UX persisted on-device.
The map itself is explicitly OUT of scope.

---

## 1. Backend contract

### 1.1 New feature module
```
backend/app/features/search/__init__.py
backend/app/features/search/router.py
backend/app/features/search/service.py
```

### 1.2 Router registration (edit existing file)
`backend/app/api/router.py` gains:
```python
from app.features.search.router import router as search_router
...
api_router.include_router(search_router, prefix="/search", tags=["search"])
```
Final path: `GET /api/v1/search`

### 1.3 Endpoint signature — `GET /api/v1/search`
Query parameters (name → type → constraints):
| param | type | required | constraints |
|-------|------|----------|-------------|
| `q` | str | yes | strip; 1..100 chars; whitespace-only -> 422 |
| `latitude` | float | no | -90..90; must accompany `longitude` |
| `longitude` | float | no | -180..180; must accompany `latitude` |
| `radius_km` | float | no | default 5.0; ge=0.1 le=50; used only when lat/lng given |
| `status` | str | no | one of `unacknowledged open under_review acknowledged escalating forwarded pending_quorum resolved disputed`; else 422 |
| `category` | str | no | max 32 chars |
| `limit` | int | no | default 20; ge=1 le=50 |
| `offset` | int | no | default 0; ge=0 |

- Supplying exactly one of `latitude`/`longitude` -> HTTP 400 with body
  `{"detail": ..., "code": "both_coordinates_required"}` (use AppError).
- Supplying invalid values (e.g. lat=999) -> 422.
- Auth: **optional** bearer (guests and signed-in both allowed). Signature mirrors the
  existing `OptionalUser` dependency used in `backend/app/features/issues/router.py`.
- Response `200` -> `list[IssueOut]` (EXACT same schema as `GET /issues` — see
  `backend/app/features/issues/schemas.py::IssueOut`). Results serialized with
  `issues.service.to_issue_out(issue, settings.jwt_secret, user_id=..., user_upvoted_ids=...)`
  exactly like the feed endpoint does.

### 1.4 `service.py` — public functions
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
    limit: int,
    offset: int,
) -> list[Issue]
```
Behaviour:
1. Trim `q`; empty after strip -> raise AppError(422).
2. Text match: case-insensitive substring across `Issue.title`, `Issue.description`,
   `Issue.category`, `Issue.ward`. Use parameterized SQL (SQLAlchemy `.ilike`), and
   **escape** `%`, `_`, `\` in `q` so user input cannot widen the LIKE pattern
   (SQL-injection defence). Helper `_escape_like(q: str) -> str`.
3. If `latitude` and `longitude` both provided: restrict to a bbox around the point
   with `radius_km`, then post-filter by haversine distance <= `radius_km` (mirror
   `issues.service.list_issues_near`; reuse its geohash/bbox/haversine logic).
4. Optional exact `status` filter; optional exact `category` filter.
5. Order `created_at desc`, then `limit`/`offset`.
6. Run `evaluate_escalation(issue, now)` on fetched issues (import from
   `app.features.issues.service`), commit if any changed.
7. **Privacy**: exclude `is_shielded == True` issues unless `status == "resolved"`
   (identical rule to the feed).
8. Return only the surviving, ordered `list[Issue]`.

### 1.5 Rate limiting (search-specific)
- New module `backend/app/core/ratelimit.py`:
  ```python
  class SlidingWindowRateLimiter:
      def __init__(self, max_requests: int, window_seconds: float): ...
      def allow(self, key: str) -> bool: ...
      def remaining(self, key: str) -> int: ...  # optional helper
  ```
- An instance is created in `create_app` and stored on `app.state.search_rate_limiter`
  (fresh per app -> no cross-test pollution).
- The `/search` endpoint depends on a dependency that, per request, computes the
  identity key: authenticated non-guest -> `str(user.id)`; otherwise `"anon"`. If
  `allow(key)` is False -> HTTP 429 with AppError code `rate_limited`.
- Config: `max_requests = 60`, `window_seconds = 60`.
- The rate-limiter is the ONLY place a 429 is emitted for search; it must be logically
  separate from issues upvote/comment limits.

---

## 2. Frontend contract

### 2.1 New feature directory
```
app/lib/features/search/domain/search_repository.dart
app/lib/features/search/data/search_api.dart
app/lib/features/search/data/recent_search_store.dart
app/lib/features/search/presentation/search_providers.dart
app/lib/features/search/presentation/search_screen.dart
```

### 2.2 `domain/search_repository.dart`
```dart
import '../../feed/domain/issue.dart';

abstract interface class SearchRepository {
  Future<List<Issue>> search({
    required String query,
    double? latitude,
    double? longitude,
  });
}
```

### 2.3 `data/recent_search_store.dart`
```dart
abstract interface class RecentSearchStore {
  List<String> load();            // sync read
  Future<void> add(String query); // trim, dedupe (case-insensitive), newest-first, cap 5
  Future<void> clear();
}
```
- `HiveRecentSearchStore implements RecentSearchStore` backed by the existing
  `LocalStore` (methods `getString` / `setString`, Hive key `'recent_searches'`,
  value = JSON-encoded `List<String>`, max 5 entries).

### 2.4 `presentation/search_providers.dart` — provider names (binding contract)
```dart
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchApi(ref.watch(apiClientProvider)),
);
final recentSearchStoreProvider = Provider<RecentSearchStore>(
  (ref) => HiveRecentSearchStore(ref.watch(localStoreProvider)),
);
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);
final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<Issue>>(SearchResultsNotifier.new);
```
- `SearchResultsNotifier`:
  - `build()` -> `const <Issue>[]`.
  - `Future<void> runQuery(String q, {double? latitude, double? longitude})` ->
    sets `AsyncLoading`, then `AsyncData` of results, then records the search:
    calls `recentSearchesProvider.notifier.add(q)` with the **trimmed** query.
  - On repository error -> `AsyncError` (UI surfaces retry).
- `RecentSearchesNotifier`:
  - `build()` -> `ref.watch(recentSearchStoreProvider).load()`.
  - `Future<void> add(String q)` and `Future<void> clear()` that update both store
    and state.
- `apiClientProvider` and `localStoreProvider` already exist and MUST be reused
  (`app/lib/core/network/network_providers.dart`,
  `app/lib/core/storage/storage_providers.dart`).

### 2.5 `presentation/search_screen.dart`
- `class SearchScreen extends ConsumerStatefulWidget` (owns a `TextEditingController`
  and a debounce `Timer`).
- AppBar with a `TextField` (`autofocus: true`) as the title; **Key: `Key('searchField')`**.
  Hint text: `'Search issues, categories, wards'`.
- Debounce: cancel + re-arm a 400 ms `Timer` on every text change; only when the
  trimmed text is non-empty do we call `searchResultsProvider.notifier.runQuery(query)`.
  Empty/whitespace-only input never triggers a search.
- Body state machine:
  1. query empty AND recentSearches non-empty -> "Recent searches" header
     (exact text `'Recent searches'`) + header action `TextButton` with exact text
     `'Clear'` (**Key: `Key('clearRecentSearches')`**) + a `ListTile` per recent
     search (leading history icon, trailing `Icon(Icons.arrow_outward)` optional);
     tapping a recent tile sets the query text and runs the search.
  2. query empty AND no recents -> `EmptyState` exact title `'Discover issues near you'`.
  3. search loading -> the existing shared `SkeletonList` widget.
  4. search error -> `EmptyState` exact title `'Search unavailable'`, action label
     `'Retry'` that re-runs the last query.
  5. results empty (query non-empty) -> `EmptyState` exact title `'No issues found'`,
     message `'Try a different keyword.'`.
  6. results non-empty -> `ListView.separated` of the existing feed `IssueCard`
     (reuse `import '../../feed/presentation/widgets/issue_card.dart'`), gap 12.
- Clean UI constraints: Material 3 components only; use theme `colorScheme` tokens;
  **no gradients, no emoji, no custom AI-looking flair**; consistent with
  `feed_screen.dart`. All strings above are hardcoded English literals (consistent
  with the rest of the app today).

### 2.6 Router + entry point
- `app/lib/core/router/route_paths.dart`: add `static const search = '/search';`
- `app/lib/core/router/app_router.dart`: register
  `GoRoute(path: RoutePaths.search, builder: (context, state) => const SearchScreen())`
  alongside the other top-level routes.
- `FeedScreen` (`app/lib/features/feed/presentation/feed_screen.dart`) AppBar `actions`:
  insert, before the existing bell icon, an `IconButton` with
  `icon: const Icon(Icons.search)` and `tooltip: 'Search'`, whose `onPressed` does
  `context.push(RoutePaths.search)`.

### 2.7 Serialization
- `SearchApi.search` returns issues parsed with the EXISTING `Issue.fromJson`
  (same as `FeedApi.fetchNearby`). Query map: `q`, optional `latitude`, optional
  `longitude`, `limit: 20`.

---

## 3. Test contracts

### 3.1 Backend — file `backend/tests/features/search/test_search.py`
Reuse existing fixtures from `backend/tests/conftest.py`: `client`, `auth_headers`,
`create_user_headers`. Create issues via `POST /api/v1/issues` with `IssueCreate` JSON
(auth required, non-guest). MUST cover:
1. Title keyword match (exact/substring, case-insensitive).
2. Category match + `category` filter param.
3. Ward match (issues created with ward text that appears).
4. Proximity: lat/lng + small radius returns only the near issue; another issue beyond
   radius excluded; without lat/lng the global result set includes both.
5. `status` filter applied; a matching issue with a different status excluded.
6. Pagination: `limit`/`offset` returns the expected slice.
7. **Shielded privacy**: a shielded, non-resolved issue is never returned; a non-shielded
   duplicate of the same keyword is returned.
8. **SQL-injection probe**: `q` values like `"%' OR 1=1 --"` and `"pothole%' --"` must
   not crash, must not widen the result set (assert the exact non-malicious hits, no
   `500`).
9. Whitespace-only / empty `q` -> 422.
10. Exactly one of lat/lng -> 400 with body `code == "both_coordinates_required"`.
11. Out-of-range lat/lng -> 422.
12. Invalid `status` value -> 422.
13. **Rate limit**: fresh test user issues 60 searches OK; the 61st sequential search
    from the SAME user returns 429 with `code == "rate_limited"`; a DIFFERENT user is
    not affected.
14. Guests can search (use a guest token; assert 200 + results).

### 3.2 Frontend — file `app/test/features/search/search_screen_test.dart`
Follow the established widget-test pattern: build `ProviderContainer` with all needed
overrides, pump `MaterialApp(home: SearchScreen())` inside
`UncontrolledProviderScope`. Provide `FakeSearchRepository implements SearchRepository`
and `FakeRecentSearchStore implements RecentSearchStore` defined **inside the test file**.
Use `buildIssue(...)` from `app/test/helpers.dart`. MUST cover:
1. Typing a non-empty query triggers `runQuery` after debounce (pump >= 400ms) and the
   fake repository captured the exact query.
2. Results render as issue cards (issue titles visible).
3. No search fires for empty / whitespace-only input (fake `searchCount` stays 0).
4. Empty results show empty state with title `'No issues found'`.
5. Recent searches render when query is empty and the store has entries; tapping a recent
   search sets the query text and triggers a search.
6. `'Clear'` action empties recent-searches list (store and UI).
7. Repository error -> title `'Search unavailable'` + `'Retry'` re-runs the last query.
8. Initial empty state title `'Discover issues near you'` when no recents.
9. Debounce: two rapid keystrokes within the window result in exactly ONE search call
   (after pumping past 400ms).
10. `FeedScreen` shows the app-bar search icon (pump `FeedScreen` with a working
    `FakeFeedRepository`; assert `find.byIcon(Icons.search)`).

---

## 4. Acceptance (assert in validation)
- Backend: `GET /api/v1/search?q=...` returns 200 `list[IssueOut]`; shielded excluded;
  SQLi probes safe; rate limit 429; coord pair validation.
- Frontend: `/search` route reachable from Feed app bar; debounced search; recents
  persisted (Hive key `recent_searches`); clean M3 UI; all above widget tests green.
- Quality gates: backend `ruff check .` + `mypy app` clean; app `flutter analyze` clean;
  full backend `pytest` suite and full `flutter test` suite stay green (no regressions).