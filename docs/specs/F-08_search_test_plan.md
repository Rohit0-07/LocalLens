# F-08 Search — Test Plan

Derived solely from `docs/specs/F-08_search_spec.md`. Enforces section 6 "Test coverage contract" plus implied edge cases.

## 1. Test strategy

- **Backend** (`backend/tests/features/search/test_search.py`): pytest + pytest-asyncio + httpx `client` fixture. Tests create issues via `POST /api/v1/issues` with `IssueCreate` JSON using `create_user_headers` (auth, non-guest); guest tests use `auth_headers` w/o a user. Tests call `GET /api/v1/search`. A fresh `SlidingWindowRateLimiter` (`max_requests=60, window_seconds=60`) is installed on `app.state.search_rate_limiter` per test. Ordinal delivered via default `created_at desc` ordering.
- **Frontend** (`app/test/features/search/search_screen_test.dart`): widget tests in `ProviderContainer` overridden with `FakeSearchRepository` (captures `queries`, `searchCount`, throws variant) + `FakeRecentSearchStore` (in-memory, tracks add/clear/dedupe), mounted in `MaterialApp(home: SearchScreen())` inside `UncontrolledProviderScope`; `buildIssue(...)` from `app/test/helpers.dart`. Pumps > 400 ms to pass the debounce. `FeedScreen` test uses a fake feed repository.
- Both tiers reuse existing fixture/helper patterns (feed parity per spec §4 Testability).

## 2. Backend test cases

- **BE-01** (item 1): Title match. Given 1 issue titled `Pothole on Main St`, When `GET /search?q=pothole` and `?q=poth` and `?q=POTHOLE`, Then 200 list[IssueOut] contains the issue in all three (exact, substring, case-insensitive); unrelated title excluded.
- **BE-02** (item 2): Category. Given issue `category="Roads"`, When `?q=pothole` returns it (category text matched) and `?q=pothole&category=Roads` keeps it while `?category=Parks` is empty; Then 200 with expected `code`/item presence.
- **BE-03** (item 3): Ward. Given issue `ward="Ward 4"`, When `?q=ward 4`, Then 200 contains it.
- **BE-04** (items 1+3 / implied): Description + unicode. Given keyword only in `description` (e.g. `"café lights"`), When `?q=café`, Then 200 contains it (unicode substring survives); also `?q=` description-bound keyword matches.
- **BE-05** (item 4): Proximity. Given two issues, A near `(40.7128,-74.0060)`, B far (> 50 km), When `?q=key&latitude=40.7128&longitude=-74.0060&radius_km=1` Then 200 has A, not B; When same query WITHOUT lat/lng Then 200 has both (global set).
- **BE-06** (item 6): Pagination. Given 5 matching issues, When `?limit=2&offset=2` Then 200 returns exactly 2, equal to chronological slice `created_at desc` start=2; `limit=50&offset=0` returns all.
- **BE-07** (item 7): Shielded privacy. Given shielded-non-resolved duplicate and non-shielded duplicate of same keyword, When `?q=key`, Then only the non-shielded one is returned; shielded `status="resolved"` sibling IS returned.
- **BE-08** (item 8): SQLi probes. Given seeds, When `?q=%25%27%20OR%201=1%20--` (`"%' OR 1=1 --"`) and `?q=pothole%25%27%20--` (`"pothole%' --"`), Then no `500`, no widened results — exact non-malicious hits only (match literals treated as plain text).
- **BE-09** (item 9): Empty/blank q. When `?q=` or `?q=%20%20` (whitespace-only), Then 422 (AppError), body `detail` non-empty.
- **BE-10** (item 10): One-coordinate. When `?q=k&latitude=40.0` only, Then 400 with body `code == "both_coordinates_required"`; same for longitude-only.
- **BE-11** (item 11): Out-of-range coords. When `latitude=91` or `-91` or `longitude=181`/`-181`, Then 422.
- **BE-12** (item 12): Invalid status. When `?status=invalid`, `?status=Resolved` (case), Then 422; each allowed value (`unacknowledged open under_review acknowledged escalating forwarded pending_quorum resolved disputed`) accepted.
- **BE-13** (item 13): Rate limit. Same fresh user: 60 sequential searches → all 200; 61st → 429 with `code == "rate_limited"`. A DIFFERENT user immediately 200 (unaffected). Duplicate same-query also consumed against the same key (assert 61st of identical `?q=pothole` still 429). Rate limit independent of upvote/comment limiters (issue endpoint still 200 after search 429).
- **BE-14** (item 14): Guest. When guest token `?q=key`, Then 200 with results (auth optional); guest requests share key `"anon"`.
- **BE-15** (route registry): `GET /api/v1/search` WITHOUT `q` → 422 by design (`q` is a required contract param, `F-08_search_contracts.md` §1.3); route mounted (not 404/405) is shown by every other case hitting `/api/v1/search`; Swagger schema exposes tag `search`.
- **BE-16** (edge, q bound): Given q of exactly 100 chars → 200; 101 chars → 422.
- **BE-17** (edge, radius bound): `radius_km` `0.05` → 422; `0.1` and `50` → 200; `60` → 422; default 5.0 applies when `lat/lng` given without `radius_km`.
- **BE-18** (edge, filter/paging bounds): `category` 33 chars → 422 (32 ok); `limit=0` and `limit=51` → 422 (`1`/`50` ok); `offset=-1` → 422 (`0` ok); default `limit=20`, `offset=0`.
- **BE-19** (edge, float precision): Given A at `(40.712800,-74.006000)`, When `latitude=40.7128&longitude=-74.006` (6-dp float) with `radius_km=0.1`, Then A returned (bbox/haversine float equality does not drop it; just-outside point at 0.06 km excluded).
- **BE-20** (req 9 / escalation): Seed an issue whose escalation threshold elapses; When searched and re-fetched via `GET /issues`, Then `evaluate_escalation` side-effects committed (field change persisted, not lost).
- **BE-21** (req 11 / schema): When 200, Then body is `list[IssueOut]` matching exact `GET /issues` feed schema fields (id, title, description, category, ward, status, coordinates, created_at, …) serialized via `to_issue_out`; no extra/omitted fields vs feed.

## 3. Frontend test cases

- **FE-01** (item 1): Given empty fakes, When tap `Key('searchField')` and enterText `'Pothole'`, pump `600ms` (>400ms), Then fake captured exactly `['Pothole']`, `searchCount == 1`.
- **FE-02** (item 2): Given `FakeSearchRepository` returning 2 `buildIssue`, When type + pump, Then 2 `IssueCard`s with titles visible (`find.text(title)`); `ListView.separated` present.
- **FE-03** (item 3): When enterText `'   '` / `''`, pump 600ms, Then `searchCount == 0` (no fire).
- **FE-04** (item 4): Given 0 results, When type + pump, Then `EmptyState` title `'No issues found'` and message `'Try a different keyword.'`.
- **FE-05** (item 5): Given recents `['pothole','graffiti']`, empty query, Then `'Recent searches'` header + ListTiles render; When tap `'pothole'`, Then `TextField` text becomes `'pothole'` and a search fires (fake captured `'pothole'`).
- **FE-06** (item 6): Given recents set, When tap `TextButton` at `Key('clearRecentSearches')` (`'Clear'`), Then store cleared AND UI shows `'Discover issues near you'` (no `'Recent searches'`).
- **FE-07** (item 7): Given throwing fake, When type + pump, Then `'Search unavailable'` shown; When tap `'Retry'`, Then fake recalled with last query (error cleared / loading again).
- **FE-08** (item 8): Given empty recents + empty query, initial pump, Then exact tile `'Discover issues near you'`.
- **FE-09** (item 9): When enterText `'po'` then `'pot'` within the debounce window, pump 600ms, Then fake got exactly ONE call (`'pot'`).
- **FE-10** (item 10): Given `FeedScreen` w/ working fake feed repo, Then `find.byIcon(Icons.search)` in AppBar; tapping it pushes the search route (reaches `Key('searchField')`).
- **FE-11** (structure): On load, Then `Key('searchField')` TextField exists, hint `'Search issues, categories, wards'`, `autofocus == true` (focused).
- **FE-12** (store/recents): `FakeRecentSearchStore`/`HiveRecentSearchStore` — add 6 distinct queries → max 5, newest-first; add `'Pothole'` + `'pothole'` → stored once (case-insensitive dedupe, newest retained); `clear` empties.
- **FE-13** (serialization): Captured request map == `{q: trimmed, latitude?, longitude?, limit: 20}` via existing `Issue.fromJson` path (mirrors `FeedApi.fetchNearby`).
- **FE-14** (routing): `RoutePaths.search == '/search'`; feed app-bar `IconButton` (`Icon(Icons.search)`, `tooltip: 'Search'`) sits before the bell; tap pushes `/search` building `const SearchScreen()`.

## 4. Cross-tier edge cases & negative paths

- **CT-01** Offline: `SearchApi` throws network `SocketException` → widget shows `'Search unavailable'`; connectivity restored → `'Retry'` succeeds (one retry call, no spurious duplicate).
- **CT-02** Rapid retry after 429: fake returns failure once then success → UI surfaces error, `'Retry'` fires exactly one new call; no infinite auto-retry loop; UI stays interactive.
- **CT-03** Recents overflow: 7 searches → store keeps 5 newest; UI header list length == 5.
- **CT-04** Case-insensitive dedupe end-to-end: search `'Pothole'` then `'pothole'` → one recent entry, newest-first, trimmed storage (`add` stores trimmed query; `' pothole '` → `'pothole'`).
- **CT-05** Backend+UI trim parity: backend 422s on whitespace-only while UI never sends it; both trim before record/execute.

## 5. Security & privacy checklist

- **SEC-01** SQLi: BE-08 plus literal-wildcard breaking probes — q containing `%`, `_`, `\` (e.g. `100%`, `a_b`, `back\slash`) returns literal matches only (escaping effective; no crash, no `500`).
- **SEC-02** Shielded exclusion: shielded non-resolved issue never returned even when it is the ONLY match for any filter combination (q/category/status/proximity); identical to feed privacy rule.
- **SEC-03** Rate-limit identity isolation: `anon` is a shared key (two guest tokens pool to the same 60 budget → 61st pooled 429); each authenticated user's 60 is isolated from other users and from the `anon` pool; limiters logically distinct from upvote/comment.
- **SEC-04** PII: every issue returned by search exposes NO author/user identity — assert serialized `IssueOut` payload contains no `user`/`author`/`user_id`/`email`/`phone` fields (feed-parity schema, verified in BE-21).
- **SEC-05** Escaping regressions: `_`/`%`/`\` literal matching stable across unicode q (BE-04/BE-08/SEC-01 combined matrix).

## 6. Coverage traceability matrix (spec §3 req → tests)

| §3 req | Test IDs | Status |
|--------|----------|--------|
| 1 module/route/tags | BE-15 | covered |
| 2 q 1..100, empty/ws 422 | BE-09, BE-16 | covered |
| 3 ilike case-insens. substring + escape | BE-01, BE-02, BE-03, BE-04, BE-08, SEC-01 | covered |
| 4 proximity bbox+haversine / global | BE-05, BE-17, BE-19 | covered |
| 5 exclusive coords 400 / range 422 | BE-10, BE-11 | covered |
| 6 status enum 422 | BE-12 | covered |
| 7 category ≤32 exact | BE-02, BE-18 | covered |
| 8 limit/offset defaults+slicing, order | BE-06, BE-18 | covered |
| 9 evaluate_escalation commit | BE-20 | covered |
| 10 shielded exclusion | BE-07, SEC-02 | covered |
| 11 200 list[IssueOut] feed schema | BE-21, SEC-04 | covered |
| 12 search rate limiter / anon key / isolation | BE-13, BE-14, SEC-03 | covered |
| 13 SearchScreen structure/Key/hint/autofocus | FE-11, FE-01 | covered |
| 14 400ms debounce re-arm / trimmed q | FE-01, FE-09 | covered |
| 15 recents UI (header, Clear, tap-to-run) | FE-05, FE-06 | covered |
| 16 initial empty 'Discover issues near you' | FE-08 | covered |
| 17 loading Skeleton / error Retry / empty states | FE-04, FE-07, FE-03 | covered |
| 18 ListView.separated IssueCard gap 12 | FE-02 | covered |
| 19 record trimmed query via add | FE-05, CT-04, CT-05 | covered |
| 20 HiveRecentSearchStore ≤5/dedupe/newest/clear | FE-12, CT-03 | covered |
| 21 SearchApi Issue.fromJson map limit:20 | FE-13 | covered |
| 22 RoutePaths.search + app-bar icon push | FE-10, FE-14 | covered |
| 23 M3 colorScheme-only, no gradients/emoji | — | **GAP** (code-review only: asserts on theme inheritance + no `Icons.emoji_*`; add reviewer pass w/o unit test) |
| 24 provider wiring (4 providers) | FE-01..FE-14 (implicit) | **GAP** (no explicit existence assertion; every FE test bootstraps them — add one smoke test asserting providers resolve non-null) |
| 25 search_issues trims/422/returns list | BE-01..BE-21 | covered |

GAP remediation: add `FE-15` (resolve `searchRepositoryProvider`/`recentSearchStoreProvider`/`recentSearchesProvider`/`searchResultsProvider` non-null via container) and a review checklist item for §3 req 23.