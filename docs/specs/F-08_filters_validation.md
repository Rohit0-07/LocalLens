# F-08-filters Advanced Search Filters — Validation Report

## 1. Overview

| Field | Value |
|---|---|
| Feature ID | `F-08` (subset: Advanced Search Filters) |
| Authoritative contract | `docs/specs/F-08_filters_contracts.md` |
| Product spec | `docs/1_spec.md` (AC-1..AC-8, SR-1..SR-6, non-goals) |
| Test plan | `docs/3_test_plan.md` (BE-01..BE-24, FE-01..FE-22, SEC-01..SEC-12, GAP-001..GAP-011) |
| Tech spec | `docs/2_tech_spec.md` |
| Interfaces extraction | `docs/4_interfaces.json` |
| Commit-era | Working tree on top of `7153df7` / `58a7376` (repo has 2 commits; all feature code is uncommitted work-in-tree). Extends the already-shipped F-08 Search feature. |
| Validator scope | Full read of contract, specs, plan, tech spec, interfaces, backend impl, frontend impl, and all tests. No production/test/doc-modifying actions taken — only the report file below was written. |

**Headline result: all quality gates are green** — backend 176 tests pass (22 new filter
tests + 154 pre-existing), ruff clean, mypy clean; frontend 133 tests pass (16 new filter
tests), analyze reports only the 12 documented pre-existing test/ warnings with **zero**
issues under `app/lib` or any `search_*` path.

---

## 2. Contract Traceability

### 2.1 Backend — new query parameters & error codes (§1.2, §1.3)

| Contract item | Impl location | Status |
|---|---|---|
| `categories` repeatable `list[str]`, each ≤32 chars, max 20, else 422 `invalid_category` | `router.py:71-78` | PASS |
| `created_after` / `created_before` ISO-8601, parseable else 422 `invalid_date_format` | `router.py:79-84` -> `service.py:20-36` | PASS |
| Both bounds & `created_after > created_before` -> 422 `invalid_date_range` | `router.py:85-94` | PASS |
| `parse_iso_datetime` returns **naive UTC** (no tzinfo) | `service.py:27` (Z→+00:00), `service.py:34-35` (`astimezone(UTC).replace(tzinfo=None)`), `service.py:36` (naive as-is) | PASS |
| `created_after <= created_before` enforced | `router.py:85-88` | PASS |
| `categories` semantics: `Issue.category.in_(categories)` (OR, parameterized) | `service.py:74-75` | PASS |
| Empty `categories` = no filter (list falsy) | `service.py:74` (`if categories:`) + test 16 | PASS |
| Signature `search_issues(..., categories, created_after, created_before, ...)` additive | `service.py:39-53` | PASS |
| Validation ORDER matches contract §1.6 (empty_query → query_too_long → both_coordinates (400) → invalid_status → invalid_category(single) → invalid_category(list) → parse after → parse before → invalid_date_range) | `router.py:52-94` | PASS (order identical; date *format* is validated, via both `parse_iso_datetime` calls, before range *semantics* — exactly as contracted) |
| Existing codes unchanged (`empty_query`, `query_too_long`, `both_coordinates_required`, `invalid_status`, `rate_limited`) | `router.py:53-66`, `router.py:27-31` | PASS |
| Route stays mounted at `GET /api/v1/search`, `api/router.py` unchanged | `router.py:34`; `api/router.py` untouched | PASS |

### 2.2 Frontend — classes / enums / constants / Keys / provider (§2.2–§2.8)

| Contract item | Impl location | Status |
|---|---|---|
| `enum SearchDatePreset { anyTime, past24Hours, past7Days, past30Days }` | `search_filters.dart:1` | PASS |
| `enum SearchDistanceOption { any, within }` | `search_filters.dart:3` | PASS |
| `SearchFilters` defaults: status=null, categories=[] , distanceOption=any, radiusKm=5.0, datePreset=anyTime | `search_filters.dart:6-12` | PASS |
| `isActive` | `search_filters.dart:22-26` | PASS |
| `copyWith` (5 fields) + `reset()` -> `const SearchFilters()` | `search_filters.dart:28-44` | PASS |
| `kSearchStatusOptions` — 7 exact strings, byte-identical to backend enum subset | `search_filters.dart:47-55` | PASS |
| `kSearchCategoryOptions` — 7 exact strings | `search_filters.dart:57-65` | PASS |
| `searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new)` | `search_filters_provider.dart:5-8` | PASS |
| `SearchFiltersNotifier.build() -> const SearchFilters()` | `search_filters_provider.dart:12` | PASS |
| `setStatus` (null clears), `toggleCategory`, `setDistanceOption`, `setRadiusKm`, `setDatePreset`, `reset` | `search_filters_provider.dart:14-42` | PASS |
| `showAdvancedFilterSheet(context, {required SearchFilters initial})`; `showModalBottomSheet` `isScrollControlled: true`; pops applied filters on `'Show results'`, `null` on barrier/swipe dismiss | `advanced_filter_sheet.dart:6-16,35-37` | PASS |
| Header `Text('Filters')` | `advanced_filter_sheet.dart:50` | PASS |
| `Text('Status')` + 7 `ChoiceChip`, label = exact string, `Key('statusChip_<status>')` | `advanced_filter_sheet.dart:52-68` | PASS |
| `Text('Category')` + 7 `FilterChip`, `Key('categoryChip_<category>')` | `advanced_filter_sheet.dart:70-95` | PASS |
| `Text('Distance')` — segments `'Any distance'`/`'Within radius'` with Keys `distanceAny`/`distanceWithin`; `Slider` min 1 max 50 divisions 49 label `<n> km` Key `distanceSlider` (revealed only when `within`) | `advanced_filter_sheet.dart:97-139` | **DRIFT** — contract §2.4 specifies `SegmentedButton<SearchDistanceOption>`; implementation uses two `ChoiceChip`s at `:102,113`. Keys, labels and slider reveal/hide behavior are identical. See Defect 1 (NON-BLOCKER). |
| `Text('Posted')` + 4 `ChoiceChip` presets `'Any time'/'Past 24 hours'/'Past 7 days'/'Past 30 days'`, Keys `dateChip_anyTime|past24Hours|past7Days|past30Days` | `advanced_filter_sheet.dart:141-157`, `_datePresetLabel` `:182-193` | PASS |
| `TextButton 'Reset'` Key `resetFiltersButton` resets LOCAL selection (no pop) | `advanced_filter_sheet.dart:162-166,31-33` | PASS |
| `FilledButton 'Show results'` Key `applyFiltersButton` pops local selection | `advanced_filter_sheet.dart:168-172,35-37` | PASS |
| `runQuery` reads filters via `ref.read(searchFiltersProvider)`; status/categories/radius sent only when set; within-radius defaults lat/long to `defaultLatitude`/`defaultLongitude` (19.1136, 72.8697); date presets derived at call time via `DateTime.now().toUtc()`; never sends `createdBefore` | `search_providers.dart:56-93`; defaults verified at `feed_providers.dart:9-10` | PASS |
| Inactive filters → call byte-identical to today (only q, optional coords, `limit: 20`) | `search_providers.dart:61-89` (null status, empty categories, null radius, null dates) | PASS |
| `SearchRepository.search` additive signature | `search_repository.dart:3-14` | PASS |
| `SearchApi.search` mapping; `categories` as repeated list; ISO-8601 UTC ending in `Z` (`toUtc().toIso8601String()`); `limit: 20` always; filter keys omitted when inactive | `search_api.dart:11-41` | PASS |
| `IconButton` tooltip exactly `'Filters'`, `Icon(Icons.tune)`, `Key('filterButton')`; `Badge` when active; `TextButton 'Clear filters'` Key `clearFiltersButton` -> `reset()` + re-run last query | `search_screen.dart:100-114,75-78` | PASS |
| Sheet wiring (`showAdvancedFilterSheet`, apply result, re-run) | `search_screen.dart:64-73` | PASS |
| All Keys enumerated in scope (`filterButton`, `clearFiltersButton`, `statusChip_*`, `categoryChip_*`, `distanceAny`, `distanceWithin`, `distanceSlider`, `dateChip_*`, `applyFiltersButton`, `resetFiltersButton`) | Verified above; all present byte-exact | PASS |

**No string or Key drift** beyond the documented SegmentedButton widget-type drift (Defect 1).

---

## 3. Implementation Integrity

- **Backend query building is parameterized / SQLi-safe.** All user inputs enter SQL only via
  parameterized `Where` expressions: `Issue.category.in_(categories)` (`service.py:75`),
  `Issue.created_at >= / <= created_after/before` (`service.py:76-79`), `Issue.status ==
  status` (`:71`), `Issue.category == category` (`:73`), and the existing escaped `ilike`
  text match (`:58-64`, `_escape_like` `:16-17`). No f-string SQL interpolation anywhere.
- **Existing shielded / exclusion / escalation / haversine / ordering logic unchanged and
  still applied AFTER the new filters** in the same order: ordering `created_at desc, id
  desc` (`:80-82`), `limit/offset` (`:81`), escalation (`:92`), shielded exclusion
  (`is_shielded and status != "resolved"`, `:94`), haversine proximity post-filter
  (`:96-98`). This matches `2_tech_spec.md` §4.4 exactly.
- **Frontend mapping discipline:** `SearchApi.search` emits each filter key only when
  non-null / non-empty (`search_api.dart:25-33`); dates are `toUtc().toIso8601String()`
  and end in `Z` (asserted exactly in `search_api_filters_test.dart:63-66`).
- **Defaults for within-distance = 19.1136 / 72.8697** (`feed_providers.dart:9-10`,
  applied at `search_providers.dart:67-68`; asserted at `search_filters_test.dart:384-385`).
- **Reset in the sheet** clears only local `_selection` (`advanced_filter_sheet.dart:31-33`),
  never the provider, matching contract §2.4 / GAP-005 observed behaviour.
- **Clear filters on the screen** calls `notifier.reset()` then `_runSearch(_lastQuery)`
  with an empty-query no-op guard (`search_screen.dart:75-78`, guard at `:46`) — re-runs the
  last query, asserted at `search_filters_test.dart:352-361`.
- **Non-goals confirmed absent:**
  - No server-side saved-filter-preference feature: `rg "preference" backend/app` → **0
    hits**; search endpoint is stateless (filters are request-params only).
  - No type / post-kind filter: `router.py` / `service.py` have **no `type` parameter**;
    frontend `search_api.dart` maps only `status/categories/radius_km/created_after/
    created_before`.
- **Interfaces extraction (`docs/4_interfaces.json`) is stale**: `app/features/search/
  service.py` shows only `_utc_now` and `_escape_like` and `search_issues` is absent from
  the extraction; `parse_iso_datetime` and the extended signature are missing. The
  interface-bridge file predates this feature. It did **not** block testing (backend suite
  is green), but it is a process/documentation gap. See Defect 2 (NON-BLOCKER).

---

## 4. Test Coverage vs `docs/3_test_plan.md`

### 4.1 Counts measured

- Backend suite: **176 tests** (`backend/tests/features/search/test_search_filters.py` = **22**
  new; `test_search.py` = **25**; remainder = pre-existing across features). 176 − 22 = **154
  pre-feature tests → all still pass** (the claimed baseline).
- Frontend suite: **133 tests** (`search_filters_test.dart` = **14**; `search_api_filters_test.dart` = **2**; remainder = pre-existing).

### 4.2 Backend & Security mapping

| Plan ID | Title | Test / evidence | Status |
|---|---|---|---|
| BE-01 | Status exact match | `test_search.py:141 test_status_filter` | Covered (pre-existing) |
| BE-02 | Single active status / replacement | Single `status` Query param by construction; pre-existing status tests; single-select falls to FE-03 | Covered-by-design |
| BE-03 | Single category filter | `test_search_filters.py:86` (contract #1) | Covered |
| BE-04 | Multi-category union | `:96` (#2, repeated params) | Covered |
| BE-05 | Categories → none | `:259` (#16 absent = no filter) | Covered |
| BE-06 | Within radius restricts | `test_search.py:94 test_proximity_radius_and_global_set`; combined in #17 `:269` | Covered |
| BE-07 | Any distance no restriction | `test_search.py:94` (global set branch) | Covered |
| BE-08 | No-location default area | Backend has no location; frontend defaults 19.1136/72.8697 (`search_filters_test.dart:384-385`) | Covered by FE (GAP-003 recorded) |
| BE-09/10/11 | 24h / 7d / 30d presets | `#4 :122`, `#8 :166`; preset maths is FE-side (evaluated at call time) | Covered via `created_after` semantics + FE runQuery |
| BE-12 | Any time no restriction | `#16 :259` (no date params) | Covered |
| BE-13 | Preset evaluated at run time | `search_providers.dart:70-78` computes from `DateTime.now().toUtc()` at call time | Covered-by-design (GAP-002) |
| BE-14 | All four combined — intersection | `#17 :269 test_combined_filters_intersection` | Covered |
| BE-15 | AND — partial match excluded | `#17 :269` (far-issue excluded by radius; water excluded by status/category) | Covered |
| BE-16 | Filtered search, no matches | `#5 :133`, `#7 :155`, `#8` second window | Covered |
| BE-17 | Filters never replace query | `test_search.py:184,459` (whitespace/missing q 422) | Covered |
| BE-18 | No filters = today | `#16 :259`; `search_filters_test.dart:388-401` | Covered |
| BE-19 | Consistent across runs | `#19 :311` (60 identical filtered runs) | Covered |
| BE-20 | Distance boundary determinism | `test_search.py:310 test_float_precision_proximity` | Covered (GAP-001) |
| BE-21 | Date boundary determinism | `>=`/`<=` (`service.py:76-79`) is deterministic; boundary inclusivity unspecified → GAP-002 | Covered-by-design; edge not separately tested |
| BE-22 | Filters not persisted server-side | Stateless endpoint; no preference code (0 hits); no carry-over state | Covered-by-design |
| BE-23 | Ordering/count unchanged | `service.py:80-82`; `test_search.py:152`; `#22 :358` | Covered |
| BE-24 | No filter cross-talk | Thread/isolation-per-request; not directly stress-tested | Covered-by-design (note) |
| SEC-01 | Malformed status rejected | `test_search.py:213 test_invalid_and_valid_status` | Covered |
| SEC-02 | Unknown category | ≤32-char free-form accepted; unknown-but-well-formed → empty (GAP-009); >32 → 422 `#14 :239`; SQLi probe → empty `#20 :322` | Partially covered (GAP-009 semantics documented) |
| SEC-03 | Out-of-range radius | `test_search.py:268 test_radius_km_bounds` | Covered |
| SEC-04 | Malformed date / impossible range | `#9 :190`, `#10 :204`, `#11 :212` | Covered |
| SEC-05 | Multiple statuses | Parameter is scalar; FastAPI shape prevents widening; no dedicated test | Covered-by-design (no test needed) |
| SEC-06 | Query-like values as data | `#20 :322` (`"road' OR 1=1 --"` → 200 empty; junk dates → 422) | Covered |
| SEC-07 | Shielded preserved under filters | `#18 :298` | Covered |
| SEC-08 | No PII in results | `test_search.py:332 test_search_result_schema`; schema untouched by filters; no new fields | Covered |
| SEC-09 | Rate limiting unchanged | `#19 :311` (60→200, 61st→429); `main.py:28` threshold 60/60 unchanged | Covered |
| SEC-10 | Guests use filters | `#21 :339`; `test_search.py:248` | Covered |
| SEC-11 | One malformed among valid rejects whole | Individual-violation tests `#9/#10/#14/#15`; no dedicated mixed valid+invalid case | Not explicitly tested — minor gap (closeable trivially) |
| SEC-12 | Distance doesn't expose location | No location fields in `IssueOut` or any filter output; `test_search_result_schema` | Covered-by-design |

### 4.3 Frontend mapping

| Plan ID | Title | Test | Status |
|---|---|---|---|
| FE-01 | Sheet opens from Search | `search_filters_test.dart:160` | Covered |
| FE-02 | Four sections visible | combined `:170,202,226,249` (section headers verified directly in sheet source `:52,70,97,141`) | Covered |
| FE-03 | Status single-select replaces | `:170` | Covered |
| FE-04 | Return to no status | via Reset `:269`; tap-again deselect of a status is **not** implemented (GAP-006) | Partially covered (GAP-006) |
| FE-05 | Categories multi | `:202` | Covered |
| FE-06 | Deselect category | `:202` | Covered |
| FE-07 | Within reveals slider | `:226` | Covered |
| FE-08 | Radius feeds search | `search_filters_test.dart:364` (radiusKm 5.0 captured) | Covered |
| FE-09 | Presets exact set, single-select | `:244` | Covered |
| FE-10 | Apply commits + re-run | `:297` | Covered |
| FE-11 | Reset clears sheet | `:269` | Covered |
| FE-12 | Reset vs applied filters | `:269` shows local-only reset; provider untouched until Apply (GAP-005 observed) | Covered (observed behaviour documented) |
| FE-13 | Clear filters re-runs | `:336` | Covered |
| FE-14 | Active indicator | `:336,349-350` (Clear filters + badge visible when active) | Covered |
| FE-15 | Indicator absent when inactive | `:320,332-333` (`isActive` false after dismiss); initial state | Covered |
| FE-16 | Filters on new typed query | `:364` | Covered |
| FE-17 | Filters on recent-search tap | `_runRecentSearch` → `_runSearch` → `runQuery` reads provider (`search_screen.dart:50-57`); not directly widget-tested | Covered-by-architecture (minor gap) |
| FE-18 | Filters on retry | `_retryLastQuery` → `runQuery` reads provider (`search_screen.dart:59-62`); not directly widget-tested | Covered-by-architecture (minor gap) |
| FE-19 | No-filter unchanged | `:388` | Covered |
| FE-20 | All four combined in UI | `:297` (status+2categories+within+past7Days → provider state) | Covered |
| FE-21 | Empty filtered results state | Pre-existing empty-state test (`search_screen_test.dart:170`); not directly under filters | Partially covered (GAP-007) |
| FE-22 | Filters session-only | Riverpod Notifier, no persistence code, never sent to a prefs endpoint | Covered-by-design |

### 4.4 GAP disposition (GAP-001..GAP-011)

| GAP | Disposition |
|---|---|
| GAP-001 distance boundary ≤ vs < | Unspecified; impl inclusive (`<=`, `service.py:97` via `haversine_km > radius_km` skip). Tested for determinism only. |
| GAP-002 date boundary / UTC clock | Presets use `DateTime.now().toUtc()` and `>=` (`service.py:76`): inclusive, UTC. Recorded, not mandated. |
| GAP-003 default area | Defined by contract §2.5 and implemented as 19.1136/72.8697 (`feed_providers.dart:9-10`); closed by contract + FE test. |
| GAP-004 radius range | Closed by contract: slider 1–50 km / divisions 49 (`advanced_filter_sheet.dart:130-132`); backend clamp `ge=0.1, le=50`. |
| GAP-005 Reset vs applied | Observably stable: Reset clears local selections only; applied filters persist until Apply. Recorded for FE-12. |
| GAP-006 status tap-again deselect | Not implemented; status chip `onSelected` always re-selects (`advanced_filter_sheet.dart:63-65`). Removal only via Reset/Clear. Recorded. |
| GAP-007 empty filtered presentation | Uses the shared empty state; not separately specified. Recorded. |
| GAP-008 rejection error shape | Contract §1.3 fixes codes (`invalid_*`, 422); message text not asserted by tests. Contract wins. |
| GAP-009 unknown-but-well-formed enum | Categories are free-form (any ≤32-char string); unknown categories match nothing (empty results) rather than reject. Consistent with impl; recorded. |
| GAP-010 filtered pagination | Mechanism-neutral; `#22 :358` verifies limit/offset slice under filters. |
| GAP-011 distance metric | Great-circle haversine (`service.py:97`, `issues/geo.py`). Metric defined by impl/order as contracted. |

---

## 5. Gate Results (exact outputs)

### Backend — cwd `/Users/rohit/Desktop/Python/LocalLens/backend`

```
$ .venv/bin/python -m pytest -q
  176 passed, 9 warnings in 70.57s (0:01:10)

$ .venv/bin/python -m ruff check app
  All checks passed!                      (exit 0)

$ .venv/bin/python -m mypy app
  Success: no issues found in 42 source files
```

- Backend test totals: **176 passed / 0 failed**; of these the new filter suite is **22**,
  and the pre-feature baseline of **154** all still passes (no regressions).

### Frontend — cwd `/Users/rohit/Desktop/Python/LocalLens/app`

```
$ flutter test
  00:05 +133: All tests passed!

$ flutter analyze
  12 issues found. (ran in 1.4s)
```

- Frontend test totals: **133 passed / 0 failed**; of these the new filter suites are
  **14 + 2 = 16**.
- `flutter analyze` — **12 issues**, every one PRE-EXISTING and confined to `test/`:
  1. `test/core/guest_signin_redirect_regression_test.dart:4:8` unused_import
  2. `test/features/auth/email_guest_auth_test.dart:10:8` unused_import
  3-5. `test/features/auth/email_guest_auth_test.dart:30/34/41` annotate_overrides
  6. `test/features/feed/upvote_interaction_test.dart:23:17` override_on_non_overriding_member
  7-8. `test/features/gamification/gamification_test.dart:358/359` unnecessary_underscores
  9-12. `test/features/issue_detail/comments_widget_test.dart:2/5/6/9` unused_import
- **Verified: `0` issues reference `app/lib` and `0` reference any `search_*` path**
  (`flutter analyze | rg "lib/|search"` → no matches). No NEW analyzer issues were
  introduced by this feature.

---

## 6. Security Review (SR-1..SR-6)

| SR | Requirement | Verifiable status | Evidence |
|---|---|---|---|
| SR-1 | Server-side validation, never widens | **MET** | Router validates status enum, category length, categories count/length, date format, date range — all server-side (`router.py:52-94`); violations raise 422 and never fall through to a wider result (`test_search_filters.py:190-257`). |
| SR-2 | Shielded/anonymous preserved | **MET** | `service.py:94` still excludes non-resolved shielded issues after new filters; `#18 :298` proves hidden + visible pair under active filters. |
| SR-3 | No PII exposure | **MET** | Filter output is unchanged `list[IssueOut]`; no filter adds reporter/contact/precise-location fields; schema asserted by `test_search.py:332`. Distance filtering is applied server-side; results never reveal the reference point (SEC-12). |
| SR-4 | Input safety (SQLi) | **MET** | All filters are parameterized (`service.py:71-79`); `#20 :322` probes `"road' OR 1=1 --"` (→ 200 empty) and junk dates (→ 422); never 500, never widened. |
| SR-5 | Rate limiting unchanged | **MET** | Threshold unchanged at 60 req/60 s (`main.py:28`); `#19 :311`: 60 filtered searches → 200, 61st → 429 `rate_limited`. |
| SR-6 | Guests unaffected | **MET** | `#21 :339` confirms guest (anon token) filtered search → 200 on same terms as registered users; no new protected-content path. |
| SR (select-lists) | Frontend select-lists constrained to fixed enums client-side | **MET** | Status/category chips render only from `kSearchStatusOptions` / `kSearchCategoryOptions` (7 each); distance/date segmented against the two fixed enums (`advanced_filter_sheet.dart:58-157`). |
| — | Rate-limit regression on invalid requests | N/A (pre-existing, accepted) | The `_rate_limit_search` dependency runs before param validation (as shipped in F-08); unchanged by this feature; a 422 request still consumes a token — self-limited, documented, not a regression. |

**SR-1..SR-6 are all verifiably MET.** No fabricated claims: rate-limit status is stated
from the measured 61st-request 429 and the `main.py:28` threshold.

---

## 7. UI Cleanliness (M3 standard)

Scanned the added/changed presentation + data + domain files
(`advanced_filter_sheet.dart`, `search_filters_provider.dart`, `search_screen.dart`,
`search_providers.dart`, `search_api.dart`, `search_repository.dart`,
`search_filters.dart`) for `Gradient`, `Colors.*`, `Color(0x..)`, and emoji ranges:

```
rg "Gradient|Colors\.|Color\(0x|emoji"... <7 files>   →   0 matches (exit 1)
```

**Result: no gradients, no emoji in UI strings, no hardcoded `Colors.*` / `Color(0x..)`
literals anywhere in the changed files.** M3 `surface`, `ChoiceChip`/`FilterChip`/
`Slider`/`TextButton`/`FilledButton`, and `colorScheme` theme tokens are used throughout
(`advanced_filter_sheet.dart:41-42,128,162,168`). Conforms to contract §2.4 and `2_tech_spec.md` §7.6.

---

## 8. Defects

1. **NON-BLOCKER — Distance section widget drift.** Contract §2.4 item 4 (and
   `2_tech_spec.md` §5.3) specifies a `SegmentedButton<SearchDistanceOption>` for the
   distance section; the implementation renders two `ChoiceChip`s
   (`advanced_filter_sheet.dart:102-123`). The outward contract surface (Keys
   `distanceAny`/`distanceWithin`, labels `'Any distance'`/`'Within radius'`, slider
   reveal/hide, value semantics) is byte-identical, all rendered M3 components are legal
   per the contract's widget allow-list, and all 14 frontend contract tests pass. Not a
   behavioral or gate violation — flag for consistency with the contract wording only.
2. **NON-BLOCKER — Stale interface-bridge extraction.** `docs/4_interfaces.json` was
   extracted **before** this feature: `app/features/search/service.py` lists only
   `_utc_now` and `_escape_like`; `parse_iso_datetime` and the extended `search_issues`
   signature are absent. It did not block the (green) backend suite, but the phase-4
   artifact should be regenerated so the test-engineer/validator inputs are current.

No BLOCKER defects found. No new lint/type/analyzer issue, no contract code/Key/string
drift, and no gate failure were observed.

---

## 9. VERDICT

**PASS**

---

## 10. Post-validation resolutions

Both NON-BLOCKER defects from §8 were resolved after this report was written (orchestrator-led loop iteration; no verdict change).

1. **Defect 1 — Distance widget drift: RESOLVED.** The coder replaced the two `ChoiceChip`s in the Distance section of `advanced_filter_sheet.dart` with a single `SegmentedButton<SearchDistanceOption>` (two `ButtonSegment`s). Keys `distanceAny`/`distanceWithin` are preserved on the segment label `Text` widgets, `selected`/`onSelectionChanged` follow the existing local-selection pattern, and the `distanceSlider` reveal/hide logic is unchanged. Verification: `flutter test test/features/search` → **34 passed**; full `flutter test` → **133 passed**; `flutter analyze` → 0 issues under `lib/`.
2. **Defect 2 — Stale interfaces extraction: RESOLVED.** `docs/4_interfaces.json` was regenerated with the project's `interface_extractor` against `backend/` → **45 modules**; `parse_iso_datetime` and the extended `search_issues` signature are now present.

Final gate state unchanged and green: backend 176 passed (ruff, mypy clean); frontend 133 passed.