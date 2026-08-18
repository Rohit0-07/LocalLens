# Plan — F-E: Make search work + differentiated, actionable errors

**Feature ID:** F-E (`search_fix`)
**Goal:** Search works for real users on every supported target; when the server genuinely cannot be reached (or fails), the UI shows a clear, differentiated, actionable error instead of the generic dead-end "Search unavailable".
**Inputs consumed:** verified source state from code exploration (search feature, core/config, core/network, backend search router/service, existing tests). Backend contract already verified live via curl (200).
**Scope boundary:** `app/lib/features/search/**`, `app/lib/core/config/**`, `app/lib/core/network/**` (error mapping only), `app/ios/Runner/Info.plist`, `backend/app/features/search/**` (tests only — no functional backend change). Everything else untouched (§1.3).

---

## 1. Scope & ownership

### 1.1 Files CREATED

| File | Purpose |
|---|---|
| `app/lib/features/search/domain/search_error_kind.dart` | `enum SearchErrorKind` + pure `SearchErrorKind classifySearchError(Object error)` mapper (unit-testable, code-blind). |
| `app/test/core/app_config_test.dart` | Base-URL resolution tests (dart-define override; Android emulator vs other platforms via `debugDefaultTargetPlatformOverride`). |
| `app/test/features/search/search_api_error_test.dart` | Defensive-parse tests: non-list body → `ApiParseException`; malformed item → `ApiParseException`. |

### 1.2 Files MODIFIED

| File | Change |
|---|---|
| `app/lib/core/config/app_config.dart` | Add `static const _envApiBaseUrl = String.fromEnvironment('API_BASE_URL')`; add `static String get _defaultHost` (Android non-web → `10.0.2.2`, else `127.0.0.1`); add `static String resolveApiBaseUrl()` (env override wins, else `http://<host>:8000/api/v1`); change `static const dev` → `static AppConfig get dev => AppConfig(apiBaseUrl: resolveApiBaseUrl())`. No change to callers (`media_url.dart`, `media_service.dart`, `app_config_provider.dart` keep compiling against `AppConfig.dev.apiBaseUrl`). |
| `app/lib/core/network/api_exceptions.dart` | Add `class ApiParseException extends ApiException` (server responded, but the body was not a `List` of parseable `Issue` objects). |
| `app/lib/features/search/data/search_api.dart` | Replace `final items = data as List<dynamic>; ... map(Issue.fromJson)` with a guarded parse: non-`List` body → `throw ApiParseException('Search response was not a list')`; per-item validation (`Map<String, Object?>` + `Issue.fromJson`) wrapped in try/catch → `ApiParseException` on `TypeError`/`FormatException`/cast failure. |
| `app/lib/features/search/presentation/search_providers.dart` | Import `search_error_kind.dart`. `runQuery` unchanged in shape; because it uses `AsyncValue.guard`, the thrown exception is preserved on `AsyncError.error`. Expose error kind at the UI boundary via `classifySearchError(error)` (see §3.2). |
| `app/lib/features/search/presentation/search_screen.dart` | `_buildResultsBody` `.when(error: (error, _) => ...)`: switch on `classifySearchError(error)` to 6 distinct `EmptyState`s (§3.1, §3.3). Empty-data and loading branches unchanged. |
| `app/ios/Runner/Info.plist` | Add `NSAppTransportSecurity` → `NSAllowsLocalNetworking: true` (minimal ATS relaxation for local/LAN cleartext; NO `NSAllowsArbitraryLoads`). |
| `app/macos/Runner/DebugProfile.entitlements`, `app/macos/Runner/Release.entitlements` | Add `com.apple.security.network.client` (outbound network). **Required for macOS-desktop search to work at all** — the sandbox currently blocks every request, so search shows a network error on macOS even when the backend is up. Outside the core `lib/**` scope; owner must approve this one-line-per-file change (§1.4). |

### 1.3 Files to NOT touch (parallel-agent conflict avoidance)

- `app/lib/features/compose/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`
- `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/representatives/**`, `backend/app/features/issues/**`
- Do NOT edit `backend/app/features/search/router.py` or `service.py` — the ward filter WIP there is verified correct (§2e) and the contract is live-verified; functional backend changes are out of scope.

### 1.4 Files NOT in `lib/**` (flagged, need owner sign-off)

`app/macos/Runner/*.entitlements` — see §1.2. If the owner declines, document macOS desktop as "search unsupported until entitlements land" and keep the plan's app logic unchanged.

---

## 2. Root-cause & fix design

### 2a. Configurable base URL (`--dart-define`) with per-platform smart default

**Root cause:** `AppConfig.dev` hardcodes `http://127.0.0.1:8000/api/v1` and `app_config_provider.dart` always selects it. On the Android emulator `127.0.0.1` is the emulator itself → `ApiNetworkException` → "Search unavailable" for every query. Physical devices need a LAN IP that is currently impossible to inject. On macOS-desktop the sandbox blocks all outbound traffic entirely (§1.2).

**Fix (`app/lib/core/config/app_config.dart`):**

```dart
import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.useMockAuth = false});

  final String apiBaseUrl;
  final bool useMockAuth;

  static const _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get _defaultHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static String resolveApiBaseUrl() {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return 'http://$_defaultHost:8000/api/v1';
  }

  static AppConfig get dev => AppConfig(apiBaseUrl: resolveApiBaseUrl());
}
```

- `String.fromEnvironment('API_BASE_URL')` is compile-time; running with `--dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1` (physical device) or a staging URL bakes that value in.
- `AppConfig.dev` becomes a getter — existing callers (`network_providers.dart`, `media_url.dart`, `media_service.dart`, `auth_providers.dart`, `profile_providers.dart`, `app_config_provider.dart`) need no change.
- `app_config_provider.dart` is left as-is (still `(ref) => AppConfig.dev`).

**Run instructions (update `README.md` §Quickstart):**
- iOS simulator / macOS / web / desktop: no flag (defaults to `127.0.0.1`).
- Android emulator: no flag (defaults to `10.0.2.2`).
- Physical device: `flutter run --dart-define=API_BASE_URL=http://<LAN-IP>:8000/api/v1`.

### 2b. iOS ATS

**Root cause:** no `NSAppTransportSecurity`; ATS blocks cleartext HTTP to non-loopback hosts on real devices.

**Fix (`app/ios/Runner/Info.plist`)** — add inside the top-level `<dict>`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

`NSAllowsLocalNetworking` (iOS 10+) permits local/LAN cleartext without opening the whole app to arbitrary HTTP. Do NOT add `NSAllowsArbitraryLoads`. Android already has `android:usesCleartextTraffic="true"` (verified) — no Android change.

### 2c. Differentiated error UX

**Root cause:** `_buildResultsBody`'s `.when(error: (_, _))` ignores the exception entirely and shows one generic EmptyState for everything (network, 404, 422, 429, 500, JSON parse). `mapDioException` (`api_exceptions.dart:59-71`) already distinguishes `ApiNetworkException` vs `ApiServerException(statusCode, code, message)` and `ApiUnauthorizedException` — the UI just never reads it.

**Fix — classify the exception into a kind and render per-kind state (§3).** Classification logic (`classifySearchError`) maps:

| Exception | Kind |
|---|---|
| `ApiNetworkException` | `network` |
| `ApiUnauthorizedException` | `unauthorized` |
| `ApiServerException` with `statusCode == 429` | `rateLimited` |
| `ApiServerException` with `statusCode == 422` | `invalidQuery` |
| `ApiServerException` (5xx / other) | `server` |
| `ApiParseException` / anything else | `unexpected` |

### 2d. Defensive parse handling (non-list / malformed response)

**Root cause:** `data as List<dynamic>` and `item as Map<String, Object?>` + `Issue.fromJson` throw raw `TypeError`/`FormatException` (not an `ApiException`) when the body is a JSON object (e.g. an error envelope behind a 200 proxy) or a malformed item. Today that lands in the same generic "Search unavailable"; under the new scheme it must be distinguishable.

**Fix (`app/lib/core/network/api_exceptions.dart`):**

```dart
class ApiParseException extends ApiException {
  ApiParseException(super.message);
}
```

**Fix (`app/lib/features/search/data/search_api.dart`)** — after `getJson`:

```dart
final raw = data;
if (raw is! List) {
  throw ApiParseException('Search response was not a list: ${raw.runtimeType}');
}
try {
  return raw
      .map((item) => Issue.fromJson(item as Map<String, Object?>))
      .toList(growable: false);
} on Object catch (e) {
  throw ApiParseException('Search response item could not be parsed: $e');
}
```

(NB: Dart `TypeError`/`FormatException` are thrown as `Object` — `on Object catch` catches `TypeError`, `FormatException`, and any cast failure. Keep `query` param-mapping identical; the `ward` null-aware element stays.)

### 2e. Ward-filter WIP — verified correct

Reviewed against source (not just diff):

- **Backend** — `router.py` adds `ward: Annotated[str | None, Query()]`, validates `len(ward) <= 64` (422 `invalid_ward`), passes `ward=` to `service.search_issues`. `service.py` implements ward matching: exact, `ILIKE`, alnum-normalized equality/`LIKE`, plus resolution of the `Ward` row by slug/name/code and OR-ing its `name`/`code`/`slug` into the match. `backend/tests/features/search/test_search.py::test_ward_filter` covers slug/name/code/partial + nonexistent ward + keyword×ward intersection. **Correct and complete.**
- **Frontend** — `SearchFilters.ward` (+ `copyWith`, `reset`, `isActive`), `SearchFiltersNotifier.setWard`, `SearchApi.search` sends `'ward': ?ward`, `SearchResultsNotifier.runQuery` passes `ward: filters.ward`, active-ward banner in `search_screen.dart` with an X to clear+re-search, ward chips in `advanced_filter_sheet.dart` from `wardListNotifierProvider`. **Correct and complete through runQuery.**
- **Gaps found (fix in this plan):**
  1. `search_api_filters_test.dart` never asserts the `ward` param is sent/omitted → add (§4.2).
  2. No widget test drives ward selection → repository → results → add (§4.2).
  3. `advanced_filter_sheet.dart` now `ref.watch(wardListNotifierProvider)` (real network). Widget tests that open the sheet (`search_filters_test.dart`) have no override → they attempt a real HTTP call. Add a `wardListNotifierProvider` override in both harnesses (`search_filters_test.dart`, `search_screen_test.dart`) returning `WardListResponse(items: [...])`; make `FakeWardRepository`/override available.
  4. With the ward section added, `applyFiltersButton`/`resetFiltersButton` may sit below the 2000px-tall test surface → tap with `tester.ensureVisible(...)` before `tester.tap(...)` in `search_filters_test.dart`.

### 2f. Empty-query must not hit the API

Already satisfied and to be re-verified by tests:
- `_onQueryChanged` returns early on trimmed-empty (`search_screen.dart:44`).
- `runQuery` returns early on empty (`search_providers.dart:58`).
- WIP added guards so `_openFilters` / `_clearFilters` only re-run when `query.isNotEmpty` (`search_screen.dart:79, 88`).
- Body routing: `query.isEmpty && !filtersActive` → preloaded feed; otherwise results body (filters-only with empty query renders "No issues found" without an API call).

---

## 3. Exact UI/UX contract

### 3.1 Search-screen state machine

| # | State | Trigger | Rendered widget |
|---|---|---|---|
| 1 | `idle/preload` | `query.isEmpty && !filtersActive` | `_buildPreloadedBody(recents)`: recents chips + preloaded feed (`multiTypeFeedProvider`) |
| 2 | `loading` | `AsyncLoading` | `SkeletonList` (unchanged) |
| 3 | `results` | `data` non-empty | `ListView.separated` of `IssueCard` (unchanged) |
| 4 | `empty` | `data` empty | `EmptyState(icon: Icons.search_off_outlined, title: 'No issues found', message: 'Try a different keyword or adjust your filters.')` (unchanged) |
| 5 | `network-error` | kind `network` | §3.3 table row 1 |
| 6 | `rate-limit` | kind `rateLimited` | §3.3 table row 2 |
| 7 | `invalid-query` | kind `invalidQuery` | §3.3 table row 3 |
| 8 | `server-error` | kind `server` | §3.3 table row 4 |
| 9 | `unauthorized` | kind `unauthorized` | §3.3 table row 5 |
| 10 | `unexpected` | kind `unexpected` | §3.3 table row 6 |

All error states (5–10) keep `actionLabel: 'Retry'` → `onAction: _retryLastQuery` (re-runs `_lastQuery`; no-op when empty, unchanged). This preserves the existing "Retry re-runs the last query" behavior.

### 3.2 How `SearchResultsNotifier` exposes the error kind

`searchResultsProvider` stays `AsyncNotifierProvider<SearchResultsNotifier, List<Issue>>`. `runQuery` continues to use `AsyncValue.guard`, so `AsyncError.error` already carries the exact thrown exception. The notifier exposes the kind through a pure classifier in `app/lib/features/search/domain/search_error_kind.dart`:

```dart
enum SearchErrorKind { network, rateLimited, invalidQuery, server, unauthorized, unexpected }

SearchErrorKind classifySearchError(Object error) {
  if (error is ApiNetworkException) return SearchErrorKind.network;
  if (error is ApiUnauthorizedException) return SearchErrorKind.unauthorized;
  if (error is ApiServerException) {
    return switch (error.statusCode) {
      429 => SearchErrorKind.rateLimited,
      422 => SearchErrorKind.invalidQuery,
      _ => SearchErrorKind.server,
    };
  }
  return SearchErrorKind.unexpected;
}
```

(imports: `package:local_lens/core/network/api_exceptions.dart`)

The screen calls `classifySearchError(error)` inside `.when(error: (error, _) => _buildSearchErrorState(classifySearchError(error)))`. This keeps `AsyncValue` semantics, needs no extra provider, and is directly driveable by widget tests (fake repo throws the typed exception). Do NOT use `results.error` string content as the discriminator.

### 3.3 Exact copy strings, icons, Keys

| Kind | `EmptyState` |
|---|---|
| `network` | `icon: Icons.cloud_off_outlined` · title `'Search unavailable'` · message `'We could not reach the server. Check your connection and make sure the app can reach the backend.'` · `'Retry'` |
| `rateLimited` | `icon: Icons.timer_outlined` · title `'Too many searches'` · message `'You have made too many searches. Please wait a moment and try again.'` · `'Retry'` |
| `invalidQuery` | `icon: Icons.search_off_outlined` · title `'Adjust your search'` · message `'Your search could not be processed. Try different keywords or filters.'` · `'Retry'` |
| `server` | `icon: Icons.error_outline` · title `'Search failed'` · message `'The server ran into a problem. Please try again.'` · `'Retry'` |
| `unauthorized` | `icon: Icons.lock_outline` · title `'Session expired'` · message `'Please sign in again to search.'` · `'Retry'` |
| `unexpected` | `icon: Icons.error_outline` · title `'Something went wrong'` · message `'The server returned an unexpected response. Please try again.'` · `'Retry'` |

**Keys:** no new widget `Key`s are required for error states (widget tests assert by `find.text(...)`); do not remove `Key('searchField')`, `Key('clearRecentSearches')`, `Key('filterButton')`, `Key('clearFiltersButton')`, or the sheet keys (`statusChip_*`, `categoryChip_*`, `wardChip_any`, `wardChip_<slug>`, `distanceAny`, `distanceWithin`, `distanceSlider`, `dateChip_*`, `applyFiltersButton`, `resetFiltersButton`).

Copy is hardcoded English literals, matching the existing convention in this screen (it already mixes `context.tr(...)` with literals for search copy). Do not add l10n keys for these strings in this plan.

### 3.4 Empty-query contract

- `searchField` text trimmed-empty → debounce returns before scheduling; `runQuery` returns before hitting the repository; UI stays in `idle/preload`. Filters-only (query empty, filters active) → `_buildResultsBody` shows `empty` state locally; no API call.

---

## 4. User-journey E2E test plan

### 4.1 Backend pytest (existing suite + 1 addition)

Run: `cd backend && uv run pytest tests/features/search/`

| Journey | Test (exists unless marked NEW) | Assertion |
|---|---|---|
| Type a query → results | `test_title_keyword_match`, `test_unicode_description_match` | 200, matching titles |
| 422 empty query | `test_whitespace_only_q_422`, `test_missing_q_422` | 422 + `detail` |
| 422 too-long query | `test_q_length_bounds` | 101 chars → 422; 100 → 200 |
| Filters applied | `test_category_match_and_category_filter`, `test_status_filter`, `test_proximity_radius_and_global_set`, `test_pagination_limit_offset` | correct filtering/paging |
| Rate limit 429 | `test_rate_limit_isolation`, `test_rate_limit_preserved_with_filters` | 60×200 then 429 `code == 'rate_limited'` |
| Ward filter flows through | `test_ward_filter`, `test_ward_match` | slug/name/code/partial match; nonexistent → [] ; keyword×ward intersection |
| **Ward length bound** | **NEW in `test_search.py`**: `ward` of 65 chars → 422 `code == 'invalid_ward'`; 64 chars → 200 | validates the §2e gap-1 mirror |
| Schema | `test_search_result_schema` | all fields present |
| Shielded privacy | `test_shielded_privacy`, `test_shielded_resolved_passes_through` | shielded non-resolved hidden |
| Security | `test_sqli_probes_safe`, `test_literal_wildcard_security_probes` | literal matching, no 500 |

### 4.2 Flutter widget tests

Run: `cd app && flutter test test/features/search test/core/app_config_test.dart`

| Journey | File / case (N = NEW, U = update existing) | Drive & assert |
|---|---|---|
| Type → results | `search_screen_test.dart` 'results render as issue cards' | enterText → cards |
| Empty query → no API | 'whitespace-only and empty input never fire a search' (existing) **U** | `repo.searchCount == 0` |
| Filters-only, empty query → no API | **N** `search_screen_test.dart` | `setStatus('resolved')` with empty field → `repo.searchCount == 0`, shows 'No issues found' |
| Network down | 'error shows Search unavailable and Retry re-runs' (existing) **U** — change fake to `throw ApiNetworkException('offline')` (currently throws `StateError` which would now classify as `unexpected`) | title 'Search unavailable' + message; Retry re-runs → `searchCount == 2`, results shown |
| Server 500 | **N** | fake throws `ApiServerException(statusCode: 500, code: 'internal', message: 'x')` → 'Search failed' + Retry re-runs |
| Rate limit 429 | **N** | fake throws `ApiServerException(statusCode: 429, code: 'rate_limited', ...)` → 'Too many searches' |
| Invalid query 422 | **N** | fake throws `ApiServerException(statusCode: 422, code: 'query_too_long', ...)` → 'Adjust your search' |
| Unexpected / parse | **N** | fake throws `ApiParseException('x')` and separately `StateError` → 'Something went wrong' |
| Non-list body | **NEW** `search_api_error_test.dart` | `_FakeApiClient` canned as a JSON map → `expectLater(api.search(...), throwsA(isA<ApiParseException>()))`; canned list with a non-map item → `ApiParseException` |
| Ward param wiring | `search_api_filters_test.dart` **U** | `api.search(query: 'x', ward: 'ward-45-urban-central')` → `lastQuery['ward'] == 'ward-45-urban-central'`; no ward → `containsKey('ward') == false` |
| Ward flows to repo | **N** `search_screen_test.dart` | `notifier.setWard('ward-45-urban-central')`, type query → `repo.lastWard == 'ward-45-urban-central'` (add `lastWard` capture to `FakeSearchRepository`) |
| Ward chip in sheet | `search_filters_test.dart` **U** | override `wardListNotifierProvider` with a 2-ward list; tap `wardChip_ward-45-urban-central`, Apply → `searchFiltersProvider.ward == slug`; 'Any Ward' resets to null |
| Sheet robustness | `search_filters_test.dart` **U** | `tester.ensureVisible(find.byKey(const Key('applyFiltersButton')))` before tap (ward section pushed buttons below fold); add `wardListNotifierProvider` override to `buildHarness` |
| Config resolution | **NEW** `app_test/core/app_config_test.dart` | (a) without dart-define + `debugDefaultTargetPlatformOverride = TargetPlatform.iOS` → base URL contains `127.0.0.1`; (b) `= TargetPlatform.android` → contains `10.0.2.2`; (c) env override honored (compile the test file with `--dart-define` is impractical in `flutter test`, so instead assert `AppConfig.dev.apiBaseUrl` equality against an injected override constant — implement `resolveApiBaseUrl()` to read the env const, and test via a small seam: expose `resolveApiBaseUrl([String? override])` optional param; assert override path returns the override verbatim). Reset `debugDefaultTargetPlatformOverride` in tearDown. |

### 4.3 Live verification steps (tester on machine)

Prereq: `cd backend && uv run uvicorn app.main:app --reload` (port 8000), DB seeded (`uv run python seed.py`).

```sh
# 1) Happy path — 200 list (guest, anon rate bucket)
curl -s -i 'http://127.0.0.1:8000/api/v1/search?q=pothole' | head -1          # HTTP/1.1 200
curl -s 'http://127.0.0.1:8000/api/v1/search?q=pothole' | python3 -m json.tool # [] or list of IssueOut

# 2) 422 empty query
curl -s -i 'http://127.0.0.1:8000/api/v1/search?q=%20%20' | head -1           # HTTP/1.1 422
curl -s 'http://127.0.0.1:8000/api/v1/search?q=%20%20'                        # {"detail": "...", "code": "empty_query"}
curl -s -i 'http://127.0.0.1:8000/api/v1/search' | head -1                    # HTTP/1.1 422 (missing q)

# 3) 422 too-long query (101 chars)
curl -s 'http://127.0.0.1:8000/api/v1/search?q=kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk' | python3 -m json.tool

# 4) Ward filter — use a fresh guest token so you don't exhaust the shared anon bucket
TOKEN=$(curl -s -X POST 'http://127.0.0.1:8000/api/v1/auth/guest' | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
curl -s 'http://127.0.0.1:8000/api/v1/search?q=sewage&ward=ward-45-urban-central' -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# 5) Filters
curl -s 'http://127.0.0.1:8000/api/v1/search?q=road&status=open&radius_km=5&latitude=19.1136&longitude=72.8697' -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# 6) Rate limit — 60 OK then 61st is 429 (own bucket via guest token)
for i in $(seq 1 61); do curl -s -o /dev/null -w "%{http_code}\n" 'http://127.0.0.1:8000/api/v1/search?q=pothole' -H "Authorization: Bearer $TOKEN"; done   # 60×200, then 429
curl -s 'http://127.0.0.1:8000/api/v1/search?q=pothole' -H "Authorization: Bearer $TOKEN"   # {"detail": "...", "code": "rate_limited"}

# 7) Network-down path (app-side): stop uvicorn, type in app → 'Search unavailable' + Retry
```

### 4.4 Full-gate verification

`make check` (backend ruff+mypy+pytest; app `flutter analyze` + `flutter test`) must pass. `flutter analyze` must stay clean. Backend stays ruff + mypy strict clean.

---

## 5. Edge cases & ordering

### 5.1 Edge cases

| Case | Behavior |
|---|---|
| Blank / whitespace query | No API call (debounce + `runQuery` guards); `idle/preload` stays |
| Very long query (>100 chars) | Backend 422 `query_too_long` → `invalid-query` state ('Adjust your search'); no frontend truncation (out of scope, note: optional `maxLength: 100` on the field is a later UX nicety, not required) |
| Rapid typing | 400 ms debounce coalesces to one request (existing test). Known pre-existing race: an in-flight older response can resolve after a newer query's response (Riverpod last-write-wins). Out of scope; optional future guard is a per-`runQuery` sequence token that discards stale results |
| Offline / server unreachable | `ApiNetworkException` → `network` state ('Search unavailable' + actionable copy + Retry) |
| Rate limit 429 | `rateLimited` state ('Too many searches' + wait-and-retry copy) |
| 422 from backend | `invalidQuery` state |
| 401 | `unauthorized` state; `ApiClient` interceptor already signs out + shows the session-expired toast (unchanged) |
| 500 / other 4xx | `server` state ('Search failed') |
| Non-list body / malformed item / JSON that passes but fails `Issue.fromJson` | `ApiParseException` → `unexpected` state ('Something went wrong') |
| Filters-only, empty query | No API call; local 'No issues found' |
| Ward selected then cleared via banner X | Re-runs last query without ward |
| Widget tests that open the filter sheet | Must override `wardListNotifierProvider` (new network dep introduced by the ward WIP) |

### 5.2 Ordering / dependencies

1. **Config + platform**: `app_config.dart` (2a) → `Info.plist` (2b) → macOS entitlements (owner sign-off, 1.4). Enables real connectivity on all targets; independent of UI.
2. **Error taxonomy**: `api_exceptions.dart` `ApiParseException` (2d) → `search_error_kind.dart` classifier (3.2). Pure Dart, unit-testable, no UI dependency.
3. **Data layer**: `search_api.dart` guarded parse (2d) — depends on (2); unit-testable via `_FakeApiClient`.
4. **UI**: `search_screen.dart` differentiated EmptyStates (3.3) — depends on (2) classifier.
5. **Ward WIP hardening**: `search_filters_test.dart`/`search_screen_test.dart` harness overrides + `ensureVisible`; `search_api_filters_test.dart` ward param (2e gaps).
6. **Tests**: frontend widget/unit additions (§4.2), backend `test_search.py` ward-length 422 (§4.1).
7. **Verify**: live curl (§4.3) + `make check` (§4.4).

Steps 1–4 are strictly sequential; 5 can start once 2 lands (classifier/taxonomy independent of base URL); 6 depends on 3–5; 7 is last.