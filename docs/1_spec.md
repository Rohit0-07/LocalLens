# Feature Specification: F-03 — Ward Awareness (Reverse Geocoding & Ward Boundary Lookup)

**Feature ID:** F-03 (subset: `reverse-geocode_2026-08-10`)
**Status:** DRAFT (pending approval)
**Binding artifact:** `docs/specs/F-03_contracts.md`

---

## 1. Feature Summary (for non-technical stakeholders)

LocalLens is a civic app where citizens report local issues. This feature tells every user which
municipal ward they are currently in, using their device location — with no sign-in and no need to
type an address.

When the app knows where a citizen is, it finds the nearest ward from the city's ward registry and
shows a short, human-readable place label (for example, "Ward 45, Urban Central"). This label
appears in two places:

1. **On the issue-reporting screen**, shown before the citizen publishes a report, so they can
   confirm which ward their report belongs to.
2. **In the top bar of the feed/home screen**, as a "nearby area" label, so citizens always know
   which ward the content around them covers.

The app handles every situation gracefully: while it is determining the location it shows a brief
"locating" state; if location cannot be determined it shows "Location unavailable"; and if the
citizen is outside any covered ward it clearly says "Outside coverage". None of these situations
ever blocks a citizen from reporting an issue or browsing the feed.

This phase is purely about the "which ward am I in?" label. No maps, no pins, and no street
addresses are involved.

---

## 2. User Stories

- **As a citizen reporting an issue**, I want to see which ward I am in before I publish my report,
  so that my report is correctly attributed to the right ward and reaches the right officials.
- **As a citizen browsing the feed**, I want to see a nearby-area label in the app bar, so that I
  can instantly tell which ward the content around me covers.
- **As a guest who has not signed in**, I want to look up my ward without creating an account, so
  that I can use the feature anonymously and without friction.
- **As a citizen outside covered service areas**, I want a clear "Outside coverage" message instead
  of an error, so that I understand my area is not covered yet.
- **As a privacy-conscious user**, I want the ward lookup to reveal only the ward name and never my
  identity or exact location details, so that I can use it without privacy concerns.
- **As a citizen exploring ward information**, I want to tap the ward label to open that ward's
  detail page, so that I can see ward-level civic information.

---

## 3. Business Rules

- **Nearest ward wins:** a location is matched to the single ward whose center is closest to that
  location, within the coverage ceiling (up to 50 km).
- **Coverage ceiling:** if no ward center is within the coverage ceiling of the location, the
  location is considered outside coverage.
- **Guest access:** ward lookup is available to everyone — signed-in citizens, guests, and
  anonymous visitors — with no sign-in prompt or permission barrier.
- **Privacy by default:** the lookup returns only ward place information. It never reveals the
  citizen's identity, contact details, or precise location to other users.
- **Read-only:** the lookup only reads the ward registry; it never records, stores, or changes
  anything about a citizen's location.
- **Non-blocking:** the ward label is informational. A missing, unavailable, or out-of-coverage
  location never prevents a citizen from publishing a report or using the feed.
- **Resolved once:** the app determines the citizen's ward once per screen visit and reuses it for
  both the compose and feed surfaces, keeping the feature fast and simple.

---

## 4. Acceptance Criteria (IF/THEN, numbered and traceable)

- **AC-1 — Reverse location lookup succeeds:** IF a citizen's location falls within the coverage
  ceiling of a known ward, THEN the app resolves the location to that ward and displays a
  human-readable ward place label (for example, "Ward 45, Urban Central"), including the ward's
  name and code, and the citizen can read it without any technical details.
- **AC-2 — Out-of-coverage result:** IF a citizen's location is not within the coverage ceiling of
  any known ward, THEN the app clearly displays an "Outside coverage" message, no ward is attached
  to the location, and no error is shown.
- **AC-3 — Invalid coordinates rejected clearly:** IF a lookup is attempted with impossible
  coordinates (for example, a latitude above 90 or a longitude beyond 180), THEN the request is
  rejected with a clear "invalid location" response, and the app does not crash, hang, or display a
  wrong ward.
- **AC-4 — Guest/unsigned-in visitor can still look up their ward:** IF a visitor who has not
  signed in looks up their ward, THEN the lookup succeeds exactly as it would for a signed-in user,
  with no sign-in prompt, no error, and no identity required.
- **AC-5 — Compose flow shows the ward before publishing:** IF a citizen is drafting an issue
  report and their ward has been resolved, THEN the issue-reporting screen shows the ward place
  label before the report is published, so the citizen can confirm the ward while composing.
- **AC-6 — Feed flow shows the nearby-area label:** IF a citizen opens the feed/home screen and
  their ward has been resolved, THEN the app bar shows the nearby-area label with the ward place
  name.
- **AC-7 — Unavailable location is handled gracefully:** IF the device location cannot be
  determined (for example, permission denied, GPS unavailable, or a network problem), THEN the app
  shows a "Location unavailable" notice in both the reporting screen and the feed app bar, and the
  citizen can continue reporting and browsing without interruption.
- **AC-8 — Ward label opens ward details:** IF a citizen taps the ward label on the reporting
  screen or feed, THEN the app opens that ward's detail page, so the citizen can explore
  ward-level civic information.
- **AC-9 — Distance shown is accurate:** IF a location is successfully matched to a ward, THEN the
  distance to the ward center shown to the citizen is accurate to one decimal place, so the label
  reflects genuine proximity.
- **AC-10 — Defensive handling of malformed input:** IF a lookup is attempted with malformed or
  non-numeric location data (including attempts to inject extra text), THEN the request is cleanly
  rejected as invalid location data, and the service never crashes or returns an internal error.

---

## 5. Non-Functional & Security Requirements

- **Stability on bad input:** malformed, out-of-range, or missing location inputs must produce a
  clear rejection message. The feature must never crash, hang, or surface an internal error to the
  citizen.
- **No personal data (PII):** the lookup returns only ward place information — the ward name,
  ward code, and distance to the ward center. It must never return a citizen's identity, account
  details, contact information, device identifiers, or any other personal data.
- **No personal identity required:** ward lookup works for everyone — signed-in, guest, or
  anonymous — without collecting, requiring, or storing any personal identity.
- **Read-only operation:** the lookup never writes, fuzzes, or alters any citizen data or report
  data. It only reads the ward registry.
- **Speed:** the lookup must feel instant to citizens and must never block drafting a report or
  browsing the feed.
- **No abuse of location data:** the citizen's location is used solely to determine the ward label
  and is not stored, shared, or used for any other purpose in this feature.

---

## 6. Explicit Non-Goals (Out of Scope)

- **No map rendering:** no map SDK, tiles, pins, clustering, or any visual map in this subset.
- **No geofencing:** no background location monitoring and no alerts when entering or leaving a
  ward.
- **No external geocoding providers:** no third-party address services (for example, Google or
  Mapbox street addresses); the lookup is purely against the internal ward registry.
- **No street addresses or named places:** the label is the ward place name only, never a street
  address.
- **No precise ward boundaries:** coverage is determined by distance from a ward's center point
  (up to the 50 km ceiling), not by drawn boundary polygons.
- **No changes to how reported issues are location-fuzzed or stored** when a report is published.
- **No new sign-in or registration flows.**
- **No per-user location history, tracking, or analytics.**
- **No changes to ward detail pages** other than being reachable by tapping the new ward label.

---

## 7. Target User Flows

### Flow A — Reporting (Compose) Flow

1. A citizen opens the issue-reporting screen to file a report.
2. The app quietly determines the citizen's current location and resolves it to a ward, showing a
   brief "locating" state while it works.
3. The reporting screen shows the ward place label above the report draft.
4. Outcomes:
   - Location resolved → the label shows the ward place name (for example, "Ward 45, Urban
     Central").
   - Location not available → the label shows "Location unavailable".
   - Location outside coverage → the label shows "Outside coverage".
5. The citizen reviews the ward label (and may tap it to open the ward's detail page), completes
   the report, and publishes. The label never blocks publishing.

### Flow B — Feed (Home) Flow

1. A citizen opens the feed/home screen.
2. The app resolves the current location to a ward and shows the nearby-area label in the app bar.
3. Outcomes:
   - Location resolved → the app bar shows the ward place name.
   - Location not available → the app bar shows "Location unavailable" and the feed still works
     normally.
4. The citizen may tap the label to open the ward's detail page.
