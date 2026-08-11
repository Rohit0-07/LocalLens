# Test Plan — F-03 Ward Awareness (Reverse Geocoding & Ward Boundary Lookup)

**Feature ID:** F-03 (subset: `reverse-geocode_2026-08-10`)
**Spec source:** `docs/1_spec.md` (DRAFT, pending approval)
**Phase:** 3 — QA Planning (black-box, business-verifiable)
**Scope:** Ward place label ("which ward am I in?") on the compose (reporting) screen and the feed/home app bar. No maps, no pins, no street addresses, no geofencing, no external geocoding providers.

**Traceability convention:** every test case links to the spec's acceptance criteria (AC-1 .. AC-10) and, where relevant, to the Non-Functional & Security Requirements section. Tests are phrased as observable business behavior only — never as implementation details (no function, class, or method names).

---

## 1. Backend Test Cases (BE)

The backend is the ward-lookup service that accepts a location and returns a ward place label result. All tests are executed by sending a lookup request with a device location and asserting on the returned response and on service stability.

### BE-01 — Successful reverse location lookup inside a ward
- **Steps:**
  1. Send a lookup request with a location that lies within the 50 km coverage ceiling of a known ward center (e.g., a point a few kilometers from the ward center).
- **Expected result:** The lookup succeeds and the response contains the matched ward's human-readable place name (e.g., "Ward 45, Urban Central") and its ward code. No technical details or internal errors appear. The citizen can read the label directly.
- **AC link:** AC-1, AC-9

### BE-02 — Nearest ward wins when the location is near several wards
- **Steps:**
  1. Send a lookup request with a location that is within range of two or more ward centers, but clearly closest to one of them.
- **Expected result:** The response resolves to the single ward whose center is closest to the location, never a random or multiple-ward result. The returned ward is the nearest one.
- **AC link:** AC-1 (Business Rule: "Nearest ward wins")

### BE-03 — Out-of-coverage location returns an "outside coverage" result
- **Steps:**
  1. Send a lookup request with a location that is farther than the 50 km coverage ceiling from every known ward center (e.g., a remote point with no wards nearby).
- **Expected result:** The lookup succeeds with an "outside coverage" result: no ward is attached to the location, no error is shown, and the response clearly indicates the location is outside coverage.
- **AC link:** AC-2

### BE-04 — Location at the coverage-ceiling boundary
- **Steps:**
  1. Send a lookup request with a location at approximately the 50 km ceiling distance from the nearest ward center (both just under and just over).
- **Expected result:** The service behaves consistently and without crashing: points within the ceiling resolve to a ward, points beyond it are "outside coverage". The exact boundary decision (whether the ceiling itself is included or excluded) is stable across repeated identical requests.
- **AC link:** AC-1, AC-2 (boundary of "Nearest ward wins" / "Coverage ceiling")

### BE-05 — Impossible coordinates rejected clearly (out-of-range)
- **Steps:**
  1. Send lookup requests with latitude above 90, below -90, longitude beyond 180, and beyond -180.
  2. Repeat for combinations of both values being out of range.
- **Expected result:** Each request is rejected with a clear "invalid location" response. The service does not crash, hang, return an internal error, or resolve a wrong ward.
- **AC link:** AC-3

### BE-06 — Missing coordinates rejected clearly
- **Steps:**
  1. Send a lookup request with no latitude and/or no longitude at all (fields absent or empty).
- **Expected result:** The request is cleanly rejected as invalid location data with a clear message. The service does not crash, hang, or return an internal error.
- **AC link:** AC-3 (per Non-Functional Requirement: "malformed, out-of-range, or missing location inputs must produce a clear rejection message")

### BE-07 — Guest / unsigned-in caller lookup succeeds
- **Steps:**
  1. Send a lookup request without any authentication, session, or identity information attached.
  2. Compare with the same request sent with a signed-in identity.
- **Expected result:** The anonymous request succeeds exactly as the signed-in one: same ward result, no sign-in prompt, no error, and no identity required or collected.
- **AC link:** AC-4

### BE-08 — Malformed numeric input does not crash the service
- **Steps:**
  1. Send lookup requests where latitude/longitude are non-numeric text (e.g., "abc", "12,5", "1e").
  2. Also send partially numeric values (e.g., "12abc", "+", "-", ".").
- **Expected result:** Every request is cleanly rejected as invalid location data. The service never crashes, never hangs, and never returns an internal error — a clear rejection message is returned for each.
- **AC link:** AC-10

### BE-09 — SQL injection attempts are rejected
- **Steps:**
  1. Send lookup requests whose coordinate fields contain SQL injection payloads (e.g., quoted fragments, statements appended to numeric values, comment syntax).
  2. Send the same payloads in any other free-text fields accepted by the lookup.
- **Expected result:** All injection payloads are treated as invalid location data and rejected. The service returns a clean rejection message, no stored data is altered or returned unexpectedly, and the service does not crash.
- **AC link:** AC-10 (Non-Functional: "attempts to inject extra text")

### BE-10 — Repeated and rapid calls do not crash or degrade
- **Steps:**
  1. Send a large burst of valid lookup requests back-to-back (same location and varied locations).
  2. Send a mixed burst of valid, invalid, out-of-range, and missing-coordinate requests.
- **Expected result:** Every request receives a correct response (ward result or clear rejection); no request hangs, no internal error surfaces, and the service remains responsive throughout and after the burst.
- **AC link:** AC-3, AC-10 (Non-Functional: "Stability on bad input"; "Speed")

### BE-11 — Response contains only ward place information (no personal data)
- **Steps:**
  1. Perform a successful lookup and inspect the full response contents.
- **Expected result:** The response contains only the ward place name, ward code, and distance to the ward center. It contains no identity, account details, contact information, device identifiers, precise street location, or any other personal data.
- **AC link:** AC-1 (Non-Functional: "No personal data (PII)")

### BE-12 — Distance to ward center is accurate to one decimal place
- **Steps:**
  1. Perform a lookup from a known location to a known ward center whose true distance is calculable.
- **Expected result:** The distance returned matches the true distance to the ward center, rounded to one decimal place (e.g., 12.3 km). The value is never reported with more precision than one decimal place and never contradicts the true proximity.
- **AC link:** AC-9

### BE-13 — Lookup is read-only and never alters stored data
- **Steps:**
  1. Record the state of the ward registry (e.g., the set of known wards and their centers) and of any citizen/report data.
  2. Perform a series of lookups: valid, out-of-coverage, invalid, and malformed.
  3. Compare the recorded state afterward.
- **Expected result:** Nothing in the ward registry or any citizen/report data has been created, modified, or deleted by any lookup. The lookup only reads the ward registry.
- **AC link:** AC-2 (Non-Functional: "Read-only operation"; "No abuse of location data")

---

## 2. Frontend Test Cases (FE)

The frontend is the app surfaces that display the ward label: the issue-reporting (compose) screen and the feed/home app bar. Widget tests run with a controllable (injectable/mockable) device location; where noted, device GPS is simulated.

### FE-01 — Compose widget shows the ward place label on success
- **Steps:**
  1. Open the issue-reporting screen with the simulated device location inside a covered ward.
  2. Wait for the lookup to complete.
- **Expected result:** The ward label widget above the report draft shows the human-readable ward place name (e.g., "Ward 45, Urban Central") with no technical details visible. The citizen can read it while composing.
- **AC link:** AC-1, AC-5

### FE-02 — Loading state shown while the location is being resolved
- **Steps:**
  1. Open the issue-reporting screen with a simulated device location whose resolution is delayed.
- **Expected result:** While the lookup is in progress the widget shows a brief "locating" state (e.g., "Locating…"). The citizen can keep drafting the report; the state does not block anything.
- **AC link:** AC-5, AC-7 (Target Flow A, step 2)

### FE-03 — Compose screen shows "Location unavailable" when location cannot be determined
- **Steps:**
  1. Open the issue-reporting screen with the simulated device location reported as unavailable (permission denied, GPS off, or network problem).
- **Expected result:** The widget shows a "Location unavailable" notice. The citizen can still continue composing and publishing the report without interruption.
- **AC link:** AC-7

### FE-04 — Feed app bar shows "Location unavailable" and the feed still works
- **Steps:**
  1. Open the feed/home screen with the simulated device location reported as unavailable.
- **Expected result:** The app bar shows the "Location unavailable" notice, and the feed loads and scrolls normally with no interruption.
- **AC link:** AC-7

### FE-05 — Compose screen shows the location chip with the ward label
- **Steps:**
  1. Open the issue-reporting screen with a resolved ward.
- **Expected result:** A location chip is displayed on the compose screen showing the ward place label (e.g., "Ward 45, Urban Central") before the report is published, so the citizen can confirm the ward while composing.
- **AC link:** AC-5

### FE-06 — Feed app bar shows the nearby-area label
- **Steps:**
  1. Open the feed/home screen with a resolved ward.
- **Expected result:** The app bar shows the nearby-area label containing the ward place name, so the citizen can tell which ward the content around them covers.
- **AC link:** AC-6

### FE-07 — Compose shows "Outside coverage" when outside any ward
- **Steps:**
  1. Open the issue-reporting screen with a simulated device location outside the coverage ceiling of every ward.
- **Expected result:** The widget clearly displays "Outside coverage". No ward is attached, no error is shown, and publishing is not blocked.
- **AC link:** AC-2, AC-7

### FE-08 — Feed shows "Outside coverage" and the feed still works
- **Steps:**
  1. Open the feed/home screen with a simulated device location outside coverage.
- **Expected result:** The app bar shows "Outside coverage", and the feed continues to work normally.
- **AC link:** AC-2, AC-7

### FE-09 — Tapping the ward label opens the ward detail page
- **Steps:**
  1. With a resolved ward, tap the ward label on the compose screen (location chip).
  2. Return, then tap the ward label in the feed app bar.
- **Expected result:** Each tap opens that ward's detail page, where ward-level civic information can be explored. The ward shown on the detail page matches the tapped label.
- **AC link:** AC-8

### FE-10 — App correctly parses a successful lookup response
- **Steps:**
  1. Simulate the service returning a successful lookup result containing a ward name and ward code.
  2. Open the compose screen with that response.
- **Expected result:** The app renders the ward place label (name and code) from the response with no raw or technical content shown, and no crash or blank state.
- **AC link:** AC-1

### FE-11 — App correctly parses an "outside coverage" (not-found) response
- **Steps:**
  1. Simulate the service returning a not-found / "outside coverage" result.
  2. Open the compose and feed screens with that response.
- **Expected result:** Both surfaces show the "Outside coverage" message; no ward is displayed, no error dialog appears, and the screens remain fully usable.
- **AC link:** AC-2

### FE-12 — Ward label never blocks publishing the report
- **Steps:**
  1. Repeat the publish flow with each ward-label state: resolved, locating, unavailable, and outside coverage.
- **Expected result:** In every state the citizen can complete and publish the report. The label is purely informational and never blocks, delays, or cancels publishing.
- **AC link:** AC-5, AC-7 (Business Rule: "Non-blocking")

### FE-13 — Feed remains usable in every ward-label state
- **Steps:**
  1. Open the feed with each state: resolved, locating, unavailable, and outside coverage.
- **Expected result:** The feed loads, scrolls, and remains interactive in every state; the label is informational only.
- **AC link:** AC-6, AC-7 (Business Rule: "Non-blocking")

### FE-14 — Ward label is resolved once per screen visit and reused across surfaces
- **Steps:**
  1. Open the compose screen, let the ward resolve, then navigate to the feed screen without a new location request being observable.
- **Expected result:** The same ward label is shown on both surfaces for the same screen visit without the citizen seeing a second full "locating" cycle (Business Rule: "Resolved once"). If the citizen leaves and re-enters the flow, a fresh resolution may occur.
- **AC link:** AC-5, AC-6 (Business Rule: "Resolved once")

---

## 3. Security Test Cases (SEC)

### SEC-01 — Lookup responses contain no personal data (PII)
- **Steps:**
  1. Perform lookups as a signed-in user, as a guest, and as an anonymous visitor; capture each full response.
  2. Inspect every field of every response, including error and edge-case responses.
- **Expected result:** No response reveals identity, account details, contact information, device identifiers, or precise location. Only ward place information (name, code, distance to ward center) is ever returned.
- **AC link:** AC-1, AC-4 (Non-Functional: "No personal data (PII)")

### SEC-02 — No authentication bypass is possible (and none is needed)
- **Steps:**
  1. Attempt the lookup with no credentials, with a bogus/expired credential, and with a valid credential.
- **Expected result:** All three attempts return identical ward results. No sign-in prompt, no error for the anonymous/bogus attempts, and no identity is required — guest access is a designed capability, not a vulnerability. The lookup never grants access to anything beyond ward place information.
- **AC link:** AC-4 (Non-Functional: "No personal identity required")

### SEC-03 — Input validation boundaries enforced
- **Steps:**
  1. Send coordinates at and just beyond every documented boundary: latitude +90 / -90, longitude +180 / -180, and the 50 km coverage ceiling.
  2. Send extreme but valid numeric values (very large, very small, high precision) and empty values.
- **Expected result:** Values outside the valid ranges are rejected with the clear "invalid location" response; values inside the ranges are processed normally. No input causes a crash, hang, internal error, or wrong ward.
- **AC link:** AC-3, AC-10 (Non-Functional: "Stability on bad input")

### SEC-04 — SQL injection attempts are blocked
- **Steps:**
  1. Send lookup requests with SQL injection payloads embedded in coordinate fields and any other accepted input fields (quotes, stacked statements, comment syntax, union clauses).
- **Expected result:** All payloads are rejected as invalid location data with a clean rejection message. No unauthorized data is returned or altered, and the service does not crash or reveal internal details.
- **AC link:** AC-10 (Non-Functional: "Stability on bad input")

### SEC-05 — Lookup is strictly read-only
- **Steps:**
  1. Snapshot the ward registry and any citizen/report data before and after a battery of lookups (valid, invalid, injection, out-of-range).
- **Expected result:** No data is written, fuzzed, or altered by any lookup. The feature only reads the ward registry.
- **AC link:** AC-2 (Non-Functional: "Read-only operation")

### SEC-06 — Citizen location is never stored, shared, or reused
- **Steps:**
  1. Perform lookups and then verify that no location data, history, or analytics attributable to the citizen exists after the lookup completes.
- **Expected result:** The location used for the lookup is not stored, logged for identity, shared with third parties, or used for any purpose other than determining the ward label. No per-user location history exists.
- **AC link:** AC-1, AC-4 (Non-Functional: "No abuse of location data"; Non-Goal: "No per-user location history, tracking, or analytics")

### SEC-07 — Oversized and hostile input handled without internal-error leakage
- **Steps:**
  1. Send lookup requests with extremely long coordinate strings, repeated characters, embedded control characters, and non-UTF-8 byte sequences.
- **Expected result:** Each request is cleanly rejected as invalid location data. No internal error, stack trace, or server detail is ever returned to the caller, and the service does not crash or hang.
- **AC link:** AC-10 (Non-Functional: "Stability on bad input")

### SEC-08 — Wrongly structured requests are rejected cleanly
- **Steps:**
  1. Send requests with structurally invalid payloads (e.g., missing fields, extra unknown fields, duplicated fields, malformed value lists) in addition to the malformed-numeric cases.
- **Expected result:** Every structurally invalid request is cleanly rejected as invalid location data; none triggers an internal error, crash, hang, or a wrong ward result.
- **AC link:** AC-10 (Non-Functional: "Stability on bad input")

---

## 4. Coverage Matrix (AC-1 .. AC-10)

| Acceptance Criterion | BE tests | FE tests | SEC tests |
|---|---|---|---|
| **AC-1** — Reverse location lookup succeeds (ward label with name and code, no technical details) | BE-01, BE-02, BE-04, BE-11 | FE-01, FE-10 | SEC-01, SEC-06 |
| **AC-2** — Out-of-coverage result ("Outside coverage", no ward, no error) | BE-03, BE-04, BE-13 | FE-07, FE-08, FE-11 | SEC-05 |
| **AC-3** — Invalid coordinates rejected clearly (no crash/hang/wrong ward) | BE-05, BE-06, BE-10 | — | SEC-03 |
| **AC-4** — Guest/unsigned-in visitor can look up their ward | BE-07 | — | SEC-01, SEC-02, SEC-06 |
| **AC-5** — Compose flow shows the ward before publishing | BE-01 | FE-01, FE-02, FE-05, FE-12, FE-14 | — |
| **AC-6** — Feed flow shows the nearby-area label | BE-01 | FE-06, FE-13, FE-14 | — |
| **AC-7** — Unavailable location handled gracefully (both screens, non-blocking) | — | FE-02, FE-03, FE-04, FE-07, FE-08, FE-12, FE-13 | — |
| **AC-8** — Ward label opens ward details page | — | FE-09 | — |
| **AC-9** — Distance shown is accurate to one decimal place | BE-01, BE-12 | — | — |
| **AC-10** — Defensive handling of malformed/non-numeric/injected input | BE-08, BE-09, BE-10 | — | SEC-03, SEC-04, SEC-07, SEC-08 |

Every acceptance criterion (AC-1 .. AC-10) maps to at least one BE, FE, or SEC test case.

---

## 5. GAPs — Uncovered Requirements & Test-Environment Limitations

### 5.1 Requirements with no or partial test coverage

- **AC-7 — Backend-facing gap:** AC-7 (unavailable location) is only exercised at the frontend level (FE-02..FE-04, FE-12, FE-13). There is no backend test for a location that cannot be determined, because the spec does not define any backend input that represents "GPS unavailable / permission denied" — those conditions exist only on the device. If the backend exposes an explicit "unavailable" or "cannot determine" result contract (see `docs/specs/F-03_contracts.md`, not readable in this phase), a BE case should be added to assert that such a result maps to "Location unavailable" and never to an error.

- **AC-9 — Display of distance on the frontend:** AC-9 is only covered at the backend level (BE-12). The spec's example label ("Ward 45, Urban Central") does not state where or whether the distance appears in the UI, so no FE assertion can be written for how the one-decimal-place distance is *displayed*. Once the label format is fixed, an FE test must verify the citizen-visible distance formatting (e.g., "12.3 km").

- **Business Rule "Resolved once":** covered by a proxy test (FE-14) that observes the absence of a second "locating" cycle when moving between compose and feed. True verification that the resolution is reused rather than repeated would require internal observation; FE-14 is the strongest black-box proxy available.

- **Non-Functional "Speed" (feels instant):** no quantitative threshold is defined in the spec, so no latency assertion can be written. BE-10 (burst of calls stays responsive) and FE-12/FE-13 (never blocks drafting/browsing) are the closest proxies. A measurable target (e.g., "lookup completes in under X seconds") is needed to close this gap.

- **Non-Goal "No external geocoding providers":** the spec forbids third-party address services. Verifying that no external provider is contacted requires network-traffic observation, which is a test-environment capability not available in the Phase 3 plan. A network-level test should be added in the test environment if feasible.

### 5.2 Test-environment limitations

- **Real GPS in widget tests:** widget/FE tests run in a simulated environment with no real device GPS. The device location **must be injectable/mockable** for every FE test (FE-01..FE-14); if the location source cannot be controlled by the test harness, all FE ward-resolution states (resolved, locating, unavailable, outside coverage) are untestable. This is a hard prerequisite for the FE suite.
- **Boundary semantics of the 50 km ceiling:** the spec does not state whether a location at exactly the ceiling distance is inside or outside coverage. BE-04 therefore asserts *consistency* across identical requests rather than a specific in/out verdict. The verdict must be pinned down (and BE-04 updated) once the exact comparison rule is defined.
- **No access to the binding contracts artifact:** `docs/specs/F-03_contracts.md` (referenced by the spec) is not readable in Phase 3, so response/request field names, error codes, and the exact "invalid location" / "outside coverage" response shapes cannot be asserted verbatim. All expectations in this plan are therefore phrased in business terms ("a clear invalid-location response") rather than exact message strings.
