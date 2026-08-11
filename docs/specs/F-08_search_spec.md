# F-08 Search & Explore — Specification (Search subset)

## 1. Overview & motivation

Civic users need to find issues that matter to them without scrolling the full feed.
F-08 Search delivers keyword search over issues (title, description, category, ward)
with optional proximity and status/category filters, pagination, and an on-device
recent-searches UX. The map itself is explicitly out of scope.

## 2. User stories / personas

- **Civic user (signed-in):** searches issues by keyword, filters by category or
  status, finds issues near a location with lat/lng + radius, and re-runs past
  searches from "Recent searches".
- **Anonymous user (no token, i.e. guest):** must be able to search and get results
  (auth is optional). Guest searches are counted under a shared "anon" rate-limiter
  identity key.
- **Any user:** shielded (non-resolved) issues must never appear in results; search
  must be safe against SQL-injection probes.

## 3. Requirements (If/Then)

- If a client calls `GET /api/v1/search`, THEN the new `search` feature module
  (`backend/app/features/search/__init__.py`, `router.py`, `service.py`) handles it,
  registered in `backend/app/api/router.py` with `prefix="/search"`, `tags=["search"]`.
- If `q` is provided after stripping, THEN it must be 1..100 chars; an empty or
  whitespace-only `q` yields HTTP 422.
- If text matching runs, THEN it must be a case-insensitive substring match across
  `Issue.title`, `Issue.description`, `Issue.category`, and `Issue.ward`, using
  parameterized SQL `.ilike`) with `_escape_like` escaping `%`, `_`, `\`.
- If both `latitude` (-90..90) and `longitude` (-180..180) are supplied, THEN results
  are restricted to radius `radius_km` (default 5.0, ge=0.1 le=50) via bbox +
  haversine post-filter (reuse `list_issues_near` logic); if neither is supplied,
  THEN the global result set is used.
- If exactly one of `latitude`/`longitude` is supplied, THEN HTTP 400 with body
  `{"detail": ..., "code": "both_coordinates_required"}` via AppError; out-of-range
  values yield 422.
- If `status` is supplied, THEN it must be one of `unacknowledged open under_review
  acknowledged escalating forwarded pending_quorum resolved disputed`, else 422; it
  is applied as an exact status filter.
- If `category` is supplied, THEN it must be ≤32 chars and applied as an exact
  category filter.
- If `limit`/`offset` are supplied, THEN defaults are 20/0, `limit` ge=1 le=50,
  `offset` ge=0; results are ordered `created_at desc` then sliced by `limit`/`offset`.
- If any issues are fetched, THEN `evaluate_escalation(issue, now)` runs and any
  changes are committed.
- If an issue has `is_shielded == True` and `status != "resolved"`, THEN it is
  excluded from results (identical privacy rule to the feed).
- If a request succeeds, THEN the response is HTTP 200 as a `list[IssueOut]` using the
  exact `GET /issues` schema, serialized via `issues.service.to_issue_out(...)` exactly
  like the feed endpoint.
- If auth is optional (guests allowed via the existing `OptionalUser` dependency),
  THEN a `SlidingWindowRateLimiter` (`backend/app/core/ratelimit.py`, configured
  `max_requests=60`, `window_seconds=60`) on `app.state.search_rate_limiter` checks an
  identity key per request (`str(user.id)` for non-guest, else `"anon"`); if
  `allow(key)` is False THEN HTTP 429 with AppError code `rate_limited`. The
  rate-limiter must be logically separate from issues upvote/comment limits.
- If the frontend search screen builds, THEN `SearchScreen` (ConsumerStatefulWidget,
  owning a `TextEditingController` and debounce `Timer`) renders an AppBar
  `TextField` with `autofocus: true`, **Key `Key('searchField')`**, hint
  `'Search issues, categories, wards'`.
- If the user types, THEN a 400 ms debounce `Timer` is cancelled and re-armed on every
  text change; only trimmed non-empty text calls `searchResultsProvider.notifier.runQuery(...)`.
- If the query is empty and recents exist, THEN show header `'Recent searches'` with a
  `TextButton` labeled `'Clear'` (**Key `Key('clearRecentSearches')`**) and a
  `ListTile` per recent search (leading history icon, optional trailing
  `Icon(Icons.arrow_outward)`); tapping a tile sets the query and runs the search.
- If the query is empty and there are no recents, THEN `EmptyState` shows exact title
  `'Discover issues near you'`.
- If a search loads, THEN the shared `SkeletonList` is shown; on error THEN
  `EmptyState` title `'Search unavailable'` with action `'Retry'` re-running the last
  query; on empty results (non-empty query) THEN `EmptyState` title `'No issues found'`,
  message `'Try a different keyword.'`.
- If results are non-empty, THEN a `ListView.separated` of the existing feed
  `IssueCard` (gap 12) renders them.
- If a search completes, THEN `SearchResultsNotifier.runQuery` records the **trimmed**
  query via `RecentSearchesNotifier.add`; `RecentSearchesNotifier` updates both state
  and store.
- If recents are persisted, THEN `HiveRecentSearchStore` (implementing
  `RecentSearchStore`, backed by existing `LocalStore` getString/setString, Hive key
  `'recent_searches'`, JSON-encoded `List<String>`) keeps at most 5 entries, trimmed,
  deduped case-insensitively, newest-first; `add`, `load` (sync), and `clear` behave as
  specified in `RecentSearchStore`.
- If serializing results, THEN `SearchApi.search` uses the EXISTING `Issue.fromJson`
  (same as `FeedApi.fetchNearby`) with query map `q`, optional `latitude`/`longitude`,
  `limit: 20`.
- If routing, THEN `RoutePaths.search = '/search'` exists, a
  `GoRoute(path: RoutePaths.search, builder: ...)` builds `const SearchScreen()`, and
  `FeedScreen` AppBar `actions` insert, before the bell icon, an `IconButton`
  (`Icon(Icons.search)`, `tooltip: 'Search'`) that does `context.push(RoutePaths.search)`.
- If building the UI, THEN Material 3 components, theme `colorScheme` tokens only; **no
  gradients, no emoji**, consistent with `feed_screen.dart`; all listed strings are
  hardcoded English literals.
- If providers are wired, THEN `searchRepositoryProvider`, `recentSearchStoreProvider`,
  `recentSearchesProvider`, and `searchResultsProvider` exist exactly as contracted,
  reusing the existing `apiClientProvider` and `localStoreProvider`.
- If `search_issues(session, ...)` is called, THEN `service.py` trims `q`,
  raises `AppError(422)` for empty-after-strip, applies all above behaviour, and
  returns only surviving, ordered `list[Issue]`.

## 4. Non-functional requirements

- **SOLID:** feature split into module (`router`/`service`), abstract repository +
  store interfaces on the frontend.
- **TDD:** every backed-units are covered by tests written against the contracts.
- **Security:** parameterized `.ilike` with `%`/`_`/`\` escaping (SQLi-safe); shielded
  privacy rule identical to feed; search-specific rate limiter (60/min) keyed per user
  id or `"anon"`.
- **Performance:** 400 ms debounce prevents per-keystroke requests; `limit`/`offset`
  pagination bounds payload size.
- **Testability:** `SearchRepository`/`RecentSearchStore` are injectable interfaces;
  rate limiter instantiated per app (fresh per test); fixtures reused.
- **Consistency:** mirrors existing feed patterns (OptionalUser, to_issue_out,
  IssueCard, LocalStore, providers, test helpers).

## 5. Non-goals

- Map view / map rendering.
- Geospatial clustering.
- Multi-post-type search (issues only).
- Backend search index or vector/text-search engine.

## 6. Test coverage contract

### Backend — `backend/tests/features/search/test_search.py`
Reuse `client`, `auth_headers`, `create_user_headers` fixtures; create issues via
`POST /api/v1/issues` with `IssueCreate` JSON (auth required, non-guest). MUST cover:
1. Title keyword match (exact/substring, case-insensitive).
2. Category match + `category` filter param.
3. Ward match (issues created with ward text that appears).
4. Proximity: lat/lng + small radius returns only the near issue; issue beyond radius
   excluded; without lat/lng the global result set includes both.
5. `status` filter applied; a matching issue with a different status excluded.
6. Pagination: `limit`/`offset` returns the expected slice.
7. Shielded privacy: shielded non-resolved issue never returned; non-shielded duplicate
   of the same keyword returned.
8. SQL-injection probe: `q` values like `"%' OR 1=1 --"` and `"pothole%' --"` must not
   crash, must not widen results (assert exact non-malicious hits, no `500`).
9. Whitespace-only / empty `q` -> 422.
10. Exactly one of lat/lng -> 400 with body `code == "both_coordinates_required"`.
11. Out-of-range lat/lng -> 422.
12. Invalid `status` value -> 422.
13. Rate limit: fresh test user issues 60 searches OK; the 61st sequential search from
    the SAME user returns 429 with `code == "rate_limited"`; a DIFFERENT user is not
    affected.
14. Guests can search (guest token; assert 200 + results).

### Frontend — `app/test/features/search/search_screen_test.dart`
Follow the established widget-test pattern: `ProviderContainer` with all needed
overrides, `MaterialApp(home: SearchScreen())` in `UncontrolledProviderScope`,
`FakeSearchRepository implements SearchRepository` and
`FakeRecentSearchStore implements RecentSearchStore` defined inside the test file,
`buildIssue(...)` from `app/test/helpers.dart`. MUST cover:
1. Typing a non-empty query triggers `runQuery` after debounce (pump >=400ms) and the
   fake captured the exact query.
2. Results render as issue cards (titles visible).
3. No search fires for empty/whitespace-only input (fake `searchCount` stays 0).
4. Empty results show `'No issues found'`.
5. Recent searches render when query empty; tapping a recent sets query text and
   triggers a search.
6. `'Clear'` empties recent-searches list (store and UI).
7. Repository error -> `'Search unavailable'` + `'Retry'` re-runs last query.
8. Initial empty state `'Discover issues near you'` when no recents.
9. Debounce: two rapid keystrokes within the window produce exactly ONE search call
   (after pumping past 400ms).
10. `FeedScreen` shows the app-bar search icon (`find.byIcon(Icons.search)` with a
    working fake feed repository).

### Acceptance
- Backend: `GET /api/v1/search?q=...` returns 200 `list[IssueOut]`; shielded excluded;
  SQLi probes safe; rate limit 429; coord-pair validation. Frontend: `/search` reachable
  from Feed app bar; debounced search; recents persisted (Hive key `recent_searches`);
  clean M3 UI; widget tests green. Quality gates: `ruff check .` + `mypy app` clean;
  `flutter analyze` clean; full `pytest` and `flutter test` suites stay green.