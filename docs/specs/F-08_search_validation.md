# F-08 Search & Explore — Validation Report

Auditor role: **VALIDATOR / Security & QA**. Read-only audit; no production or test code modified.
Audit date: 2026-08-10. Scope: Search subset of F-08 (map out of scope).
**Re-audit (sign-off): 2026-08-10** — independent re-read of the fix pass; all prior blockers verified
closed against the actual code/tests (fix-agent claims not trusted).

## Overall verdict: **PASS**

Backend and frontend implement the F-08 contracts faithfully, all quality gates are green (ruff,
mypy, **115/115 backend tests**, flutter analyze clean in `lib/`, **94/94 flutter tests**), and the
fix pass closed every blocker and the full coverage/security/refactor backlog from the prior audit.
Both HIGH defects are resolved with regression tests, and every previously-missing contract/security
case is now covered and green. No blockers remain; the feature satisfies the F-08 acceptance criteria
(contracts §4) and quality gates.

---

## A. CONTRACT CONFORMANCE — **PASS** (2 minor deviations noted)

| Contract clause | Evidence | Result |
|---|---|---|
| `GET /api/v1/search` mounted at `/api/v1` + `prefix="/search"`, tags `search` | `api/router.py:14`; `router.py:34` | PASS |
| `q` required, strip, empty/whitespace → 422 | `router.py:49-51` (AppError `empty_query`) | PASS |
| `q` ≤ 100 → else 422 | `router.py:52-55` (`query_too_long`); `test_q_length_bounds` | PASS |
| coord pair rule → 400 `both_coordinates_required`; range → 422 | `router.py:41-42,56-61`; `test_single_coordinate_400`, `test_out_of_range_coordinates_422` | PASS |
| `radius_km` default 5.0, ge=0.1 le=50 | `router.py:43`; `test_radius_km_bounds` | PASS |
| `status` enum (9 values) else 422 | `router.py:14-24,62-63`; `test_invalid_and_valid_status` | PASS |
| `category` ≤ 32 chars else 422 | `router.py:64-67`; `test_category_limit_offset_bounds` | PASS |
| `limit` 1..50, `offset` ≥ 0 | `router.py:46-47`; `test_category_limit_offset_bounds` | PASS |
| Response = raw `list[IssueOut]`, exact feed schema, `to_issue_out` parity + `user_upvoted_ids` | `router.py:34,80-93`; `test_search_result_schema` | PASS |
| `OptionalUser` / guests allowed | `deps.py:70-101`; `test_guest_can_search` | PASS |
| Provider/store/provider names | `search_providers.dart:10-28` | PASS |
| `RoutePaths.search = '/search'`; GoRoute → `const SearchScreen()` | `route_paths.dart:14`; `app_router.dart:106-109` | PASS |
| Feed AppBar `IconButton(Icons.search)` tooltip `Search`, before bell, `context.push` | `feed_screen.dart:21-25` | PASS |
| `Key('searchField')`, hint, `autofocus` | `search_screen.dart:70-74` | PASS |
| 400 ms debounce cancel+re-arm; no search on empty/ws | `search_screen.dart:31-41` | PASS |
| Empty-state strings / Keys / actions | `search_screen.dart:88-154` | PASS |
| Hive key `recent_searches`, max 5, dedupe (case-insens), newest-first, trim | `recent_search_store.dart:16-17,34-49` | PASS |
| `SearchApi` map `q/lat/lng/limit:20`, `Issue.fromJson` | `search_api.dart:16-28`; `search_api_test.dart` | PASS |

Deviations (non-blocking):
- Extra `searchQueryProvider` (`search_providers.dart:18`) is an internal state provider not in
  the contracted 4-provider list — additive, acceptable (unchanged from prior audit).
- `message` strings were added under the required `EmptyState` titles (e.g.
  `'Search issues, categories, or wards to get started.'` `search_screen.dart:93`);
  titles match exactly, extras are consistent with `feed_screen.dart` convention.

**No public contract was changed by the fix pass** — provider/store names, `RoutePaths.search`,
GoRoute, Feed app-bar IconButton, Keys `'searchField'`/`'clearRecentSearches'`, Hive key
`'recent_searches'`, all exact strings, AppError codes (`empty_query`, `both_coordinates_required`,
`rate_limited`), HTTP codes, and `IssueOut` feed-parity are byte-identical to the contracts.

---

## B. SECURITY AUDIT

### B.1 SQL injection — **PASS**
- `_escape_like` escapes `\` first (`service.py:16-17`), then `%`, `_`. Ordering is correct:
  backslashes inserted by the `%`/`_` replacements are not themselves re-escaped, and
  `\\`, `\%`, `\_` decode back to literals in the LIKE parser.
- Parameterized `.ilike(pattern, escape="\\")` on all four columns (`service.py:37-42`);
  `q` is never string-interpolated; the only string building is `f"%{_escape_like(query)}%"`
  (`service.py:36`) which feeds a bound parameter.
- Probes `"%' OR 1=1 --"` / `"pothole%' --"` return exact hits, no 500
  (`test_search.py:180-187`).
- **Re-audit:** literal-wildcard probes `100%`, `a_b`, `back\slash` now covered by
  `test_literal_wildcard_security_probes` (`test_search.py:378-397`) and assert **literal-only**
  matching: `100%` returns only the literal `100%` title (not `100XX`), `a_b` returns only `a_b`
  (not `aXb`), `back\slash` returns only the backslash title (not `backslash plain`), all HTTP 200.

### B.2 Shielded privacy — **PASS**
- Rule `if issue.is_shielded and issue.status != "resolved": continue` (`service.py:68`)
  is identical to the feed (`issues/service.py:138-139`). Non-shielded pass-through ✓;
- **Re-audit:** shielded+resolved pass-through is now covered by a genuine end-to-end flow
  (`test_shielded_resolved_passes_through`, `test_search.py:400-428`): create shielded issue →
  `POST /issues/{id}/resolve` (→ `pending_quorum`) → three `quorum-vote` confirms (→ `resolved`)
  → search returns it with `is_shielded is True`, HTTP 200.

### B.3 Rate limiter — **PASS**
- Sliding window correctness: `time.monotonic()` stamps per key, expired frames pruned,
  grants only while `len < max_requests` (`ratelimit.py:13-29`); `test_rate_limit_isolation`
  asserts 60 → 200, 61st → 429 (`test_search.py:240-251`).
- Identity key `str(user.id)` for non-guest else `"anon"` (`router.py:29`); guests carry
  `is_guest=True` so they pool on `"anon"`. Per-contract.
- 429 via `AppError(..., status_code=429, code="rate_limited")` (`router.py:31`).
- Limiter is per-app (`main.py:28` `app.state.search_rate_limiter = SlidingWindowRateLimiter(60, 60)`),
  fresh per test; DIFFERENT user unaffected (`test_search.py:249-251`).
- Thread-safe: `threading.Lock` guards the deque; no `await` inside the lock (`ratelimit.py:10,15-29`).
- **Re-audit (SEC-03):** two distinct guest tokens pooling on `anon` covered by
  `test_two_guest_tokens_pool_on_anon_key` (`test_search.py:450-465`): guest token 1 issues 60
  searches OK; guest token 2's 61st pooled search returns 429 `code == "rate_limited"`.

### B.4 PII / data exposure — **PASS**
- Response uses the exact feed `IssueOut` schema via the shared `to_issue_out`
  (`issues/service.py:29-77`); no `user`/`author`/`user_id`/`email`/`phone` fields.
- `anonymous_identity` is only derived when `issue.is_anonymous` (`issues/service.py:36-39`)
  — parity with feed; `test_search_result_schema` asserts the exact field set
  (`test_search.py:338-375`).

### B.5 DoS / inject further bounds — **PASS**
- `q` length capped server-side (router + test); `limit/offset/radius/category/status` all
  bounded; no ORM eager-load expansion; pagination bounds payload. Note: every request —
  even validation-failing ones — consumes a rate-limit token because the `_rate_limited`
  dependency runs before the endpoint body (`router.py:40`); this is a minor self-consumption
  nuance, not a bypass (defect #4 — ACCEPTED, documented; no functional fix).

### B.6 Limiter bypass review — **PASS**
- No off-by-one (token only appended on grant); key derivation unambiguous for
  authenticated/guest/anon; monotonic timestamps vs wall-clock prevent clock-skew bleed.
- **Re-audit:** idle-key eviction now implemented — `del self._timestamps[key]` in both `allow()`
  (`ratelimit.py:22-24`) and `remaining()` (`ratelimit.py:39-41`); no unbounded memory creep.

---

## C. TEST COVERAGE MATRIX

### Backend (`backend/tests/features/search/test_search.py`, **25 tests** — all green; was 20)

| Spec §3 req / plan case | Test | Covered |
|---|---|---|
| Title match exact/substring/case-insens (BE-01) | `test_title_keyword_match` | ✓ |
| Category match + `category` filter (BE-02; req 7) | `test_category_match_and_category_filter` | ✓ |
| Ward match (BE-03; req 3) | `test_ward_match` | ✓ |
| Description + unicode (BE-04; req 3) | `test_unicode_description_match` | ✓ |
| Proximity radius/global (+default radius) (BE-05; req 4) | `test_proximity_radius_and_global_set` | ✓ |
| Status filter applied/excluded (BE-06⇒req 6) | `test_status_filter` | ✓ |
| Pagination slice (BE-06; req 8) | `test_pagination_limit_offset` | ✓ |
| Shielded non-resolved excluded (BE-07; req 10) | `test_shielded_privacy` | ✓ |
| Shielded **resolved** passes (BE-07 tail) | `test_shielded_resolved_passes_through` | ✓ **NEW** |
| SQLi probes (BE-08; req 3) | `test_sqli_probes_safe` | ✓ |
| Literal wildcard probes `100%`, `a_b`, `back\slash` (SEC-01) | `test_literal_wildcard_security_probes` | ✓ **NEW** |
| Empty/ws q 422 (BE-09; req 2) | `test_whitespace_only_q_422` | ✓ |
| Missing `q` → 422 (BE-15 aligned to contract) | `test_missing_q_422` | ✓ **NEW** |
| Single coordinate 400 (BE-10; req 5) | `test_single_coordinate_400` | ✓ |
| Out-of-range coords 422 (BE-11; req 5) | `test_out_of_range_coordinates_422` | ✓ |
| Invalid/valid status (BE-12; req 6) | `test_invalid_and_valid_status` | ✓ |
| Rate limit 60/61st 429 + other user unaffected (BE-13; req 12) | `test_rate_limit_isolation` | ✓ |
| Two guest tokens pool on `anon` → 61st pooled 429 (SEC-03) | `test_two_guest_tokens_pool_on_anon_key` | ✓ **NEW** |
| Guest can search (BE-14; req 12 anon) | `test_guest_can_search` | ✓ |
| q 100/101 bound (BE-16; req 2) | `test_q_length_bounds` | ✓ |
| radius bounds + default (BE-17; req 4) | `test_radius_km_bounds` | ✓ |
| category/limit/offset bounds (BE-18; req 8) | `test_category_limit_offset_bounds` | ✓ (default `limit=20` not asserted explicitly) |
| Float-precision proximity (BE-19; req 4) | `test_float_precision_proximity` | ✓ |
| `evaluate_escalation` commit on search (BE-20; req 9) | `test_search_runs_escalation_for_both_statuses` | ✓ **NEW** |
| 200 `list[IssueOut]` feed schema / no extra fields (BE-21, SEC-04; req 11) | `test_search_result_schema` | ✓ |

> BE-15 note (carried from prior audit): the plan expects a **200** for `GET /search?status=open`
> (no `q`), but the contract (`F-08_search_contracts.md:36`) marks `q` as **required**, so missing
> `q` yields 422 by design. `test_missing_q_422` now pins the correct 422 behaviour; the
> route-mount intent is exercised by every other test hitting `/api/v1/search`. Contract preserved,
> not weakened.

### Frontend (`app/test/features/search/search_screen_test.dart` + `search_api_test.dart`, **18 tests** — all green; was 15)

| Plan case | Test | Covered |
|---|---|---|
| FE-01 non-empty → one debounced run, exact query | `'non-empty query fires one debounced search with exact query'` | ✓ |
| FE-02 results as cards | `'results render as issue cards'` | ✓ |
| FE-03 no fire on empty/ws | `'whitespace-only and empty input never fire a search'` | ✓ |
| FE-04 empty results title+msg | `'empty results show empty state'` | ✓ |
| FE-05 recents render + tap sets query & searches | `'recent searches render and tapping one runs it'` | ✓ |
| FE-05 acceptance regression (results **visible** after tapping a recent tile) | `'tapping a recent search renders its results'` | ✓ **NEW** — asserts result card text visible + `'Recent searches'` header gone |
| FE-06 Clear empties store+UI | `'Clear empties recents and shows initial state'` | ✓ |
| FE-07 error → unavailable + Retry re-runs | `'error shows Search unavailable and Retry re-runs'` | ✓ |
| FE-08 initial Discover | `'initial empty state shows Discover issues near you'` | ✓ |
| FE-09 debounce coalescing (exactly one) | `'rapid keystrokes within window fire exactly one search'` | ✓ |
| FE-10 app-bar icon+tooltip | `'FeedScreen app bar shows the search icon'` | ◐ PARTIAL — icon/tooltip asserted; route push to `searchField` not exercised (INFO, defect #7) |
| FE-11 key/hint/autofocus | `'search field has key, hint and autofocus'` | ✓ |
| FE-12 store cap/dedupe/newest/clear | `FakeRecentSearchStore` group (2 tests) | ◐ PARTIAL — fake only; `HiveRecentSearchStore` never exercised (INFO, defect #7) |
| FE-13 `SearchApi` query map + `Issue.fromJson` | `search_api_test.dart` `'SearchApi maps query params and parses via Issue.fromJson'` | ✓ **NEW** — subclasses `ApiClient`, asserts `'/search'`, `q`, `limit == 20`, latitude/longitude optionality, `Issue.fromJson` |
| FE-14 `RoutePaths.search` | `'RoutePaths.search is /search'` | ✓ |
| CT-01 offline → Retry succeeds | covered semantically by FE-07 (StateError, not `SocketException`) | ◐ |
| CT-02 429-then-retry single call | covered by FE-07 (`searchCount == 2`, no loop) | ✓ |
| CT-03 recents overflow → 5 remembered | store test uses 6 → 5; UI header length not asserted | ◐ |
| CT-04 case-insens dedupe + trim end-to-end | `'query is trimmed before search and recorded'` + store tests | ✓ |
| CT-05 backend/UI trim parity | BE-09 + FE-03/trim test (implicit) | ◐ |
| Loading branch → `SkeletonList` | `'shows skeleton list while search is in flight'` | ✓ **NEW** — holds an in-flight `Completer`, asserts `SkeletonList` present while loading and gone after completion |

**Uncovered acceptance criteria remaining:** FE-10 route-push landing and `HiveRecentSearchStore`
unit test (both INFO-level debt, defect #7 — ACCEPTED, non-blocking; contract requires only the
integration present and green). Everything flagged in the prior audit as ✗ MISSING is now covered.

---

## D. FRONTEND + BACKEND BALANCE — **PASS**

- Backend search-suite: **25 tests** (≥ 20 required). Frontend search-suite: **18 tests**
  (≥ 12 required). Both tiers' critical path (endpoint + screen state machine + serialization) is
  exercised; the only residuals are the two INFO-level gaps in C.

---

## E. TDD / NO-BIAS — **PASS**

- Backend tests drive only the HTTP API (`POST /api/v1/issues`, `GET /api/v1/search`) via the
  public `client` fixture; no SQL/ORM internals are inspected.
- Frontend tests drive widgets + Riverpod providers, faking through the **public contracts**
  `SearchRepository`, `RecentSearchStore` (`search_screen_test.dart:18-64`) and — in the new
  FE-13 suite — by subclassing the public `ApiClient` (`search_api_test.dart:5-19`).
  Assertions on `searchCount`/`queries`/`lastQuery` live on the fakes, not the implementation.
- `field.controller!.text` is a public widget property, not a private internal. No test reaches
  into `_debounce`, `SearchResultsNotifier` internals, or SQL. No bias toward implementation details.

---

## F. UI CLEANLINESS CHECK — **PASS**

`rg` across `app/lib/features/search/**` (re-run in this re-audit — **0 matches**):
- `LinearGradient|RadialGradient|SweepGradient|shaderMask|Gradient` → **0 matches**.
- Emoji/emoticon ranges (\u{1F300}-\u{1FAFF}, \u{2600}-\u{27BF}, \u{2B00}-\u{2BFF}) → **0 matches**.
- `Colors.` literals → **0 matches** (search UI uses `colorScheme`/theme tokens only).
- Material 3 components only (`AppBar`, `TextField`, `TextButton`, `ListTile`, `EmptyState`,
  shared `SkeletonList`, shared `IssueCard`); no custom animations/parallax/AI flair.
- Exception (not in feature): recycled `IssueCard`/`SkeletonList` widgets contain pre-existing
  `Colors.grey`/`Colors.purple`/`Colors.red` literals (`issue_card.dart`, `skeleton_list.dart`) —
  outside the new feature files (unchanged from prior audit).

---

## G. SOLID & CONSISTENCY — **PASS** (1 design note)

- Module split `router` / `service` / `ratelimit` is clean and single-responsibility.
- **Re-audit (defect #3):** the cross-module private coupling is gone. New public module
  `backend/app/features/issues/geo.py` exposes `haversine_km` (`geo.py:8`) and `bbox_statement`
  (`geo.py:19`); both `issues/service.py:9` and `search/service.py:7` import it **publicly**
  (`from app.features.issues.geo import bbox_statement, haversine_km`). `search/service.py:9`
  imports `evaluate_escalation` publicly from `app.features.issues.service`. No private
  cross-module imports remain.
- Interface-based DI: `SearchRepository` (domain) + `SearchApi` (data),
  `RecentSearchStore` + `HiveRecentSearchStore`, injected via `searchRepositoryProvider` /
  `recentSearchStoreProvider`; reuses existing `apiClientProvider`/`localStoreProvider`
  (`search_providers.dart:10-16`).
- State machine lives in `SearchResultsNotifier` / `RecentSearchesNotifier` (AsyncValue.guard
  pattern, `search_providers.dart:47-65`); widgets hold only view concerns (controller + debounce
  Timer).
- Conventions followed: `AppError` codes (`empty_query`, `both_coordinates_required`,
  `rate_limited`, …), shared `EmptyState`/`SkeletonList`/`IssueCard` reuse, feed parity in
  `to_issue_out`.
- Design note (unchanged): search results reuse `IssueCard`, which sources live state from
  `feedProvider` (`issue_card.dart`) — in search context upvoting targets the feed notifier, not
  the search list (accepted reuse; defect #6 — ACCEPTED, note only).

---

## H. QUALITY GATES (run by validator, real output)

### Backend (cwd `backend`)
```
$ .venv/bin/python -m ruff check app
All checks passed!

$ .venv/bin/python -m mypy app
Success: no issues found in 32 source files

$ .venv/bin/python -m pytest -q
........................................................................ [ 62%]
...........................................                             [100%]
115 passed in 49.08s
```
Search-only: `25 passed in 11.27s`.

### App (cwd `app`)
```
$ flutter analyze
...
9 issues found. (ran in 1.3s)
```
All 9 are pre-existing findings in `test/` files only (auth/email_guest_auth_test.dart,
feed/upvote_interaction_test.dart, issue_detail/comments_widget_test.dart). **`lib/` is clean,
including all search files.**

```
$ flutter test
...
All tests passed!
```
**94 tests** (`+94: All tests passed!`). Search-only: `18` tests (17 `search_screen_test.dart`
+ 1 new `search_api_test.dart`), `All tests passed!`.

---

## Prioritized defect list — closure status

| # | Sev | Location | Defect | Status | Evidence (re-audit) |
|---|-----|----------|--------|--------|---------------------|
| 1 | **HIGH** | `app/lib/features/search/presentation/search_screen.dart:48-55` | Tapping a recent search fetched results but never displayed them: `_runRecentSearch` did not set `searchQueryProvider`, so the `query.isEmpty ? recents : results` gate kept showing recents. | **CLOSED** | `_runRecentSearch` now cancels the debounce (`:49`), sets `_lastQuery` (`:52`), sets `searchQueryProvider` (`:53`), then runs the search (`:54`). Regression test `search_screen_test.dart:293-306` `'tapping a recent search renders its results'` seeds `repo.result` and asserts the result card text (`'Prior pothole'`) is **visible** and the `'Recent searches'` header is gone. |
| 2 | MED | coverage | Missing tests: resolved-shielded pass-through; escalation-commit; literal wildcards (`100%`, `a_b`, `back\slash`); two-guest `anon` pooling; missing-q 422; loading branch; `SearchApi` request map. | **CLOSED** | All added, all green: `test_shielded_resolved_passes_through` (resolved+quorum, E2E), `test_search_runs_escalation_for_both_statuses`, `test_literal_wildcard_security_probes`, `test_two_guest_tokens_pool_on_anon_key`, `test_missing_q_422`, `search_screen_test.dart` `.shows skeleton list while search is in flight`, `search_api_test.dart` FE-13. Coverage matrix in §C updated. |
| 3 | LOW | `backend/app/features/search/service.py:9-11` | Private cross-module import of `_bbox_statement`/`_haversine_km` from `issues.service`. | **CLOSED** | Public `issues/geo.py` `haversine_km`/`bbox_statement`; imported publicly by `issues/service.py:9` and `search/service.py:7`. |
| 4 | LOW | `backend/app/features/search/router.py:40` | `_rate_limited` dependency runs before param validation → 400/422 requests consume a rate-limit token (self-limited; no bypass). | **ACCEPTED** | Behaviour unchanged and documented in §B.5; prior audit stated no functional fix required. |
| 5 | LOW | `backend/app/core/ratelimit.py:11,16-22` | Idle-key deques never evicted → unbounded memory over long uptime. | **CLOSED** | `del self._timestamps[key]` on empty deque in `allow()` (`ratelimit.py:22-24`) and `remaining()` (`ratelimit.py:39-41`). |
| 6 | INFO | `app/lib/features/feed/presentation/widgets/issue_card.dart` | Search results reuse `IssueCard` which watches `feedProvider`; in search context upvote/status is decoupled from the search list. | **ACCEPTED** | Contract mandates `IssueCard` reuse; note only (unchanged). |
| 7 | INFO | `app/test/features/search/search_screen_test.dart` | `HiveRecentSearchStore` still untested (FE-12 fake-only); FE-10 route-push landing on `Key('searchField')` unasserted. | **ACCEPTED** | Non-blocking debt; contract requires the integration present and green, which it is. Optional future work. |

---

## Sign-off block

Overall: **PASS**.

**Re-audit (2026-08-10) result:** every blocker and recommended item from the prior
PASS-WITH-ISSUES audit is resolved against the actual code and tests — verified independently,
not from the fix agent's claims:

- **Defect #1 (HIGH), CLOSED** — `_runRecentSearch` sets `searchQueryProvider`, cancels the
  debounce, and sets `_lastQuery` (`search_screen.dart:48-55`); the regression widget test
  `'tapping a recent search renders its results'` asserts result cards are VISIBLE after tapping
  a recent tile (`search_screen_test.dart:293-306`).
- **Defect #2 (coverage), CLOSED** — SEC-01 literal wildcard probes (`100%`, `a_b`,
  `back\slash`) assert literal-only matching, no broadening, no 500; resolved-shielded E2E
  resolve+quorum pass-through; SEC-03 two-guest `anon` pooling (61st → 429 `rate_limited`);
  missing-`q` → 422; loading `SkeletonList` widget test; FE-13 `SearchApi` request-map test.
- **Defects #3 (refactor) and #5 (eviction), CLOSED; #4 and #6 ACCEPTED; #7 ACCEPTED** as
  non-blocking debt.

**Gates re-run by the validator (real output):** backend `ruff` clean; `mypy` clean (32 files);
`pytest` **115/115** (search suite **25/25**). App `flutter analyze` clean in `lib/` (9
pre-existing `test/` findings only); `flutter test` **94/94** (search suite **18/18**). Quality
dimension F re-verified: 0 gradients/emoji/`Colors.` in `app/lib/features/search/**`. Dimension E
re-verified: fakes via public contracts only.

**All blockers are closed and the feature satisfies the F-08 acceptance criteria (contracts §4)
and quality gates. The feature index/checklist may be marked complete.**