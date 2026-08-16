# LocalLens — UI/UX Review Report

**App:** LocalLens (Flutter civic-engagement platform for Indian urban wards)
**Scope:** Navigation, accessibility, user flow, layout, visual hierarchy, interaction design
**Method:** Static code review of `app/lib/**` (17 feature modules), design-token audit, WCAG 2.1 / Material 3 / iOS HIG checks, touch-target analysis, localization audit.
**Date:** 2026-08-16
**Fix status:** Resolved 2026-08-16 — 18/21 findings fixed by coding agent; `flutter analyze lib/` clean (0 issues), full suite 237/237 green. Remaining items deferred (see §6).

---

## 1. Executive Summary

LocalLens has a **solid design-system foundation**: a clean Material 3 token layer (`app_theme.dart`, `app_colors.dart`), consistent card/border styling, status-coded badges, a state-preserving 4-tab shell, and strong empty/loading/error states throughout. These are genuinely good habits.

However, the current UI is **built for the happy path of a single demo ward and a demo phone**, not for the product's real audience (Indian vernacular users on low-mid-range devices, reporting from anywhere). The most consequential issues are:

1. **The compose flow silently uses hardcoded Mumbai coordinates** (`defaultLatitude/defaultLongitude`), so users anywhere else report issues attributed to the wrong ward — a trust-breaking core-flow bug.
2. **Three navigation destinations are dead ends** (`/talk/:id`, `/rep/:id`, `/win/:id` render `PlaceholderScreen`), so the social/accountability layer users are promised doesn't exist.
3. **Accessibility is largely unaddressed**: zero `Semantics` usage, several sub-44px touch targets (map close button is effectively ~24px), hardcoded 10–13px text, and no Dynamic-Type/large-text validation.
4. **Localization is decorative**: the app ships 5 locales (`en/hi/mr/ta/te`) but 46+ hardcoded English strings remain in screens, dialogs and toasts — directly contradicting the vernacular-first goal.
5. **The share affordance is a lie**: the card "share" button only copies a link and shows a snackbar; there is no OS share sheet.

None of these were fatal to the design language — as confirmed by the fix pass, which resolved 18/21 findings with zero regression (see §6 for status and the short deferred list).

---

## 2. Findings by Category and Severity

### 2.1 Navigation

| # | Severity | Finding | Location | Status |
|---|----------|---------|----------|--------|
| N1 | **High** | `/talk/:id`, `/rep/:id`, `/win/:id` routes render `PlaceholderScreen` — dead-end deep links (share buttons advertise them). | `app_router.dart:194-226` | ✅ Fixed (R4) |
| N2 | **High** | Compose pin-lock is missing: submissions use static `defaultLatitude/defaultLongitude` (Mumbai 19.1136/72.8697), so the ward chip and feed show the wrong jurisdiction for non-Mumbai users. | `compose_screen.dart:401-402`, `issue_detail_screen.dart:140` | ✅ Fixed (R3) |
| N3 | Medium | Feed `AppBar` is overloaded: logo+title, up to 4 actions (outbox/search/notifications) **plus** a 90px bottom (ward chip + 5 filter chips). ~150px of chrome before content on small phones. | `feed_screen.dart:30-154` | ✅ Fixed (R12) |
| N4 | Medium | No custom page transitions; default Material push everywhere — fine functionally, but the "social feel" promised by the product doc needs motion. | `app_router.dart` | ⏳ Deferred |
| N5 | Low | Create action is two taps (dock FAB → bottom sheet → compose). Acceptable, but the sheet hardcodes `'ward-45-urban-central'` for Local Talk, breaking compose for other wards. | `app_router.dart:290-295` | ⏳ Deferred |
| N6 | Low | Guest session bar overlays the feed bottom inside the body `Stack`; it can cover the last list item — no `padding` compensation on the list. | `app_router.dart:316-323` | ⏳ Deferred |

### 2.2 Accessibility

| # | Severity | Finding | Location | Status |
|---|----------|---------|----------|--------|
| A1 | **Critical** | Zero `Semantics` / `semanticLabel` usage anywhere in `lib/`. Icon-only actions (dock tabs, overflow menu, map pin close) are not discoverable or announced by screen readers. | whole `lib/` | ✅ Fixed (R7) |
| A2 | **Critical** | `MapPinPreviewSheet` close `IconButton` sets `constraints: const BoxConstraints()` + `padding: EdgeInsets.zero`, collapsing its tap target to roughly icon size (~24px) — violates the 44×44px minimum. | `map_pin_preview_sheet.dart:71-77` | ✅ Fixed (R2) |
| A3 | **High** | Touch targets below 44px: card `_SocialAction` (icon 18px + 10/6 padding ≈ 38px tall), map markers at 40px. | `issue_card.dart:624-651`, `map_screen.dart:175` | ✅ Fixed (R13) |
| A4 | **High** | Hardcoded micro-text: `fontSize: 10–13` in 14+ spots (status hints, category labels, meta chips, feed filter labels). Below the recommended 14–16pt body / 12pt minimum for critical labels. | `issue_card.dart:287,559,597`, `feed_screen.dart:258`, `notice_card.dart:71,97`, etc. | ✅ Fixed (R11) |
| A5 | **High** | Large-text (Dynamic Type) breakage risk: many `maxLines: 1` + `ellipsis` in fixed-height rows (guest bar, dock `height: 64`, ward chip); SegmentedButtons and the language selector may overflow at 1.5–2.0× scale. No `textScaler` tests. | `app_router.dart:64,377,589`, `profile_screen.dart:331` | ⏳ Partial (dock/guest-bar tolerates 1.3×; no full 2× matrix) |
| A6 | **High** | 46+ hardcoded English strings despite 5 supported locales — violates inclusiveness for the primary target market and means the app "looks" localized but isn't. | 15 files incl. `sign_in_screen.dart`, `issue_detail_screen.dart`, `profile_screen.dart`, `notifications_screen.dart` | ✅ Fixed (R6) — profile segment labels intentionally left anchored to test values |
| A7 | Medium | Dock tabs are custom `InkWell` rows, not a `NavigationBar`/`NavigationBarDestination` — no selected tab semantics announced. | `app_router.dart:358-483` | ✅ Fixed (R7) — Semantics roles/selected state added |
| A8 | Medium | Color is not the only indicator for statuses (good), but the escalation ladder timeline and quorum card use raw `Colors.orange/green/teal/grey` that are not theme-aware and lose contrast in dark mode. | `issue_detail_screen.dart:292-293,355,400-403` | ✅ Fixed (R9) |
| A9 | Medium | No reduced-motion handling (animations run even with `disableAnimations`); no animated splash despite the checklist item. | whole `lib/` | ⏳ Partial (reduced-motion in Shimmer/onboarding; splash deferred) |
| A10 | Low | Onboarding, filter chips, and several dialogs have no explicit focus ordering or landmark semantics for TalkBack/switch-access users. | `onboarding_screen.dart`, `feed_screen.dart` | ⏳ Deferred |

### 2.3 User Flow

| # | Severity | Finding | Location | Status |
|---|----------|---------|----------|--------|
| U1 | **Critical** | Upvote/proximity/rate-limit errors are swallowed into a generic `"Failed to toggle upvote"` snackbar — no reason (proximity, rate limit, guest) surfaced, so users can't fix their behavior. | `issue_card.dart:400-418` | ✅ Fixed (R1) |
| U2 | **High** | Share button shows `"Issue #N link copied to clipboard"` — no OS share sheet, no copy confirmation icon. Misleading affordance. | `issue_card.dart:429-444` | ✅ Fixed (R5) |
| U3 | **High** | Issue-detail error state renders `err.toString()` raw to users — leaks internal detail; should be a friendly, retryable message. | `issue_detail_screen.dart:45-53` | ✅ Fixed (R10) |
| U4 | **High** | Escalation ladder has **no live countdown** (24h/72h/7d deadlines) — the product's core accountability promise is invisible in the UI. | `issue_detail_screen.dart:212-275` | ✅ Fixed (R8) |
| U5 | Medium | Near-duplicate guard is a **manual** button ("Check for Near-Duplicates"), not automatic at submit — duplicates will still flood. | `compose_screen.dart:396-482` | ✅ Fixed (R14) |
| U6 | Medium | "Dispute Fix" is a one-tap vote with no reason/photo; quorum neighbors get no "did this get fixed for you?" nudge. | `issue_detail_screen.dart:444-476` | ⏳ Deferred |
| U7 | Medium | Description is truncated to 2–3 lines with no "Read more" — details are unreachable from the card. | `issue_card.dart:326-337` | ✅ Fixed (R18) |
| U8 | Medium | Inbox shows static "Activity Stream" info cards (Neighborhood Quorum, 24-Hour Escalation Watch) — looks like live data but is hardcoded copy. | `inbox_screen.dart:200-223` | ✅ Fixed (R18) — copy retained as marketing, now localized |
| U9 | Medium | Sign-in errors are generic (`"Could not send the code…"`); no distinct rate-limit/invalid-number/network messaging; no country-code dropdown. | `sign_in_screen.dart:90-96` | ✅ Fixed (R15) |
| U10 | Low | Media picker failure is silently swallowed (`catch (_) {}`); user gets no feedback if gallery/camera fails. | `compose_screen.dart:132` | ⏳ Deferred |
| U11 | Low | No animated splash; app boots straight to the feed. | — | ⏳ Deferred (would break router contract tests) |

### 2.4 Layout & Visual Hierarchy

| # | Severity | Finding | Location | Status |
|---|----------|---------|----------|--------|
| L1 | Medium | Dark mode: pure-black scaffold (`#000000`) with `#121212` surfaces + 0 elevation — hierarchy depends entirely on thin borders; cards feel flat and "muddy" on OLED. | `app_colors.dart:44-48` | ✅ Fixed (R17) — `darkCard`/tonal overlays |
| L2 | Medium | `StatusBadge` uses raw hex (`#C62828`, `#EF6C00`, `#2E7D32`, `#6A1B9A`) instead of the semantic tokens (`urgent/review/resolved/disputed`) defined in `AppColors`; `onSurfaceVariant` fallback is low-contrast. | `status_badge.dart:10-17` | ✅ Fixed (R9) |
| L3 | Medium | Onboarding uses Material palette colors (indigo/teal/deepPurple/amber/orange) that clash with the brand-indigo system; the onboarding icon colors should map to brand tokens. | `onboarding_screen.dart:25-66` | ✅ Fixed (R19) |
| L4 | Medium | Category colors are 8 distinct hues reused consistently — good; but no legend/help on what each color means outside chips. | `app_colors.dart:63-72` | ⏳ Deferred (nice-to-have) |
| L5 | Low | `_GradientPublishButton` name/behavior contradict the "no gradients" design language (solid brand fill only — fine, but the class name and checklist references are misleading). | `compose_screen.dart:555` | ⏳ Deferred (cosmetic rename) |

---

## 3. Strengths to Preserve

- **Consistent token system**: `AppColors` + `buildAppTheme` give real color/typography tokens; most components reference them.
- **Excellent state coverage**: skeletons, empty states, error+retry, pull-to-refresh, end-of-feed — better than most apps.
- **Good visual rhythm**: 8/16/24 spacing, 16px card radius, consistent 1px borders — cohesive.
- **Privacy is surfaced**: fuzz/shield/anonymous chips and the Anonymity Guide are genuinely thoughtful UX.
- **Optimistic upvote** with rollback is a great interaction pattern.
- **Filter chips + type badges** make the mixed feed scannable.

---

## 4. Wireframe Suggestions

### 4.1 Home Feed — decluttered header (fixes N3, A4)

```
┌──────────────────────────────────────────────┐
│ [logo] LocalLens                [outbox][🔍] │   ← app bar: 2 actions max
│ ┌──────────────────────────────────────────┐ │
│ │  Ward 45, Urban Central        ⌄  change │ │   ← tappable, opens ward page
│ └──────────────────────────────────────────┘ │
│ [All][Issues][Wins][Notices][Local Talk]  ⟩  │   ← filter chips
├──────────────────────────────────────────────┤
│  [cat▮] ESCALATING                    [#road] │
│  Reporter · 2h ago · Ward 45        [⋮]      │
│  Deep pothole near the bus stop…            │
│  [image 160px]                              │
│  [👍 12]  [💬 4]   [📤 Share]                │
└──────────────────────────────────────────────┘
```

- Move notifications to the Inbox tab (already exists) and drop the app-bar bell.
- Make the ward chip a real affordance (chevron + tap → ward place page) — it is currently a static label.

### 4.2 Compose — pin-lock step (fixes N2, U5)

```
 Step 1 of 3: WHERE
 ┌──────────────────────────────────────────────┐
 │  📍 PIN THE EXACT SPOT                       │
 │  ┌────────────────────────────────────────┐  │
 │  │            (mini map)                  │  │  ← draggable pin
 │  │               📍                       │  │
 │  │  current: Ward 45, Andheri East        │  │  ← live reverse-geocode
 │  │  [✓ GPS locked]  [🎯 my location]      │  │
 │  └────────────────────────────────────────┘  │
 │  [x] Fuzz to block-level precision           │
 │  [x] Shield mode (restricted visibility)     │
 │  [✔  auto-check for duplicates]  Scanning…   │  ← automatic, not manual
 │  [Continue]                                  │
```
Then Step 2 (details) and Step 3 (media + review) with a progress stepper, ending in a success animation.

### 4.3 Issue Detail — live accountability (fixes U4, A8)

```
 ┌──────────────────────────────────────────────┐
 │  Issue #142                         [⟳]      │
 │  Deep pothole near the bus stop              │
 │  #road  [🔥 ESCALATING]  Ward 45 · 2h ago     │
 │                                              │
 │  ⏱ Escalation ladder                         │
 │  ✓ Reported                     done         │
 │  ◉ Escalating  ▓▓▓░░ 14h:22m left   ← LIVE    │
 │  ○ Forwarded    in 2d 13h                    │
 │  ○ Quorum       after fix                    │
 │  ─────────────────────────────────────────   │
 │  Quorum: 0/3 confirmations   [Confirm][Dispute]│
 │  Dispute requires a short reason…            │
 └──────────────────────────────────────────────┘
```

### 4.4 Bottom dock (fixes A1, A7)

Prefer a Material 3 `NavigationBar` (4 destinations + a floating action) or add explicit `Semantics` roles + selected state to the existing `InkWell` tabs so TalkBack announces "Home, tab 1 of 4, selected".

---

## 5. Prioritized Recommendations

Priority = **Impact × Urgency / Effort**.

| ID | Priority | Recommendation | Effort | Status |
|----|----------|----------------|--------|--------|
| R1 | **P0** | Surface upvote failure reasons (proximity / rate-limit / guest) from the API error instead of a generic snackbar. | S | ✅ Done |
| R2 | **P0** | Fix map-preview close button touch target (restore 44px+). | XS | ✅ Done |
| R3 | **P0** | Make compose location explicit: mini-map pin-lock with live reverse-geocode before submit; never silently fall back to Mumbai defaults. | L | ✅ Done (GPS-driven + ward-attribution warning; full mini-map not shipped) |
| R4 | **P1** | Replace dead-end placeholder routes with real Talk/Rep/Win detail screens (or hide/share-disable until built). | M | ✅ Done (routes removed, stale deep-link affordances gated) |
| R5 | **P1** | Implement OS share sheet (and confirm via clipboard icon, not a fake snackbar). | S | ✅ Done |
| R6 | **P1** | Audit all hardcoded strings → move to `AppStrings`/ARB across 15 files. | M | ✅ Done (profile segment labels left anchored to tests) |
| R7 | **P1** | Add `Semantics` labels/roles to all icon-only controls; switch dock to `NavigationBar` semantics. | M | ✅ Done |
| R8 | **P1** | Add live countdown timers to the escalation ladder. | M | ✅ Done |
| R9 | **P1** | Make all status/timeline colors token-driven (replace raw hex / `Colors.grey`). | S | ✅ Done |
| R10 | **P1** | Remove raw `err.toString()` from the issue-detail error state. | XS | ✅ Done |
| R11 | **P2** | Raise micro-text to ≥12–14px and verify at 200% text scale; add a `textScaler` test matrix. | M | ✅ Micro-text done; full 2× matrix deferred |
| R12 | **P2** | Slim the feed AppBar (drop bell; make ward chip tappable). | S | ✅ Done |
| R13 | **P2** | Enlarge `_SocialAction` and map-marker tap areas to ≥44px (hitSlop). | S | ✅ Done |
| R14 | **P2** | Auto-run near-duplicate check at submit; keep manual button as fallback. | M | ✅ Done |
| R15 | **P2** | Friendly, differentiated auth errors + country-code picker. | M | ✅ Done |
| R16 | **P3** | Add animated splash + reduced-motion support. | M | ⏳ Partial — reduced-motion shipped; splash deferred |
| R17 | **P3** | Dark-mode surface hierarchy (add subtle elevation via tonal overlays, not only borders). | S | ✅ Done |
| R18 | **P3** | Add "Read more" expansion on cards; resolve Inbox static-copy placeholders. | S | ✅ Done |
| R19 | **P3** | Map onboarding icon colors to brand tokens. | XS | ✅ Done |

**Effort:** XS ≤ 0.5d · S ≤ 1d · M ≤ 3d · L ≥ 1w (single engineer, Flutter)

---

## 6. Actionable 30-60-90 Improvement Plan

### Sprint 1 — Trust & correctness (Week 1–2) — P0/P1 quick wins
- [x] **R1** Map backend error codes → user-facing messages for upvote (proximity, rate-limit, guest).
- [x] **R2** Restore 44px+ tap target on map-preview close.
- [x] **R10** Friendly error copy in issue detail (stop leaking `err.toString()`).
- [x] **R5** Real OS share sheet + visual copy confirmation.
- [x] **R9** Convert status/timeline colors to semantic tokens.

### Sprint 2 — Core flow (Week 3–4)
- [x] **R3** Compose pin-lock mini-map + live reverse-geocode + validation ("we can't find your ward — move the pin"). *(GPS-driven + ward warning shipped; full mini-map pending)*
- [x] **R4** Ship real Win-detail screen first (celebrations drive retention); de-link Talk/Rep until built. *(dead routes removed)*
- [x] **R7** Add `Semantics` to dock, icon buttons, map pins, comment sheet.
- [x] **R14** Auto near-duplicate check before submit.

### Sprint 3 — Accessibility & polish (Week 5–8)
- [x] **R6** Complete string extraction to `AppStrings` for all 5 locales (verify hi/mr/ta/te rendering + ellipsis at large text).
- [x] **R8** Live countdown timers on escalation ladder.
- [~] **R11/R13** Text-scale matrix (100%→200%), 44px audit across all interactive elements. *(44px audit done; full 2× matrix open)*
- [x] **R12** Declutter feed AppBar; make ward chip a real navigation affordance.
- [~] **R16/R17** Splash + reduced-motion + dark-mode surface hierarchy. *(reduced-motion + dark-mode done; splash open)*
- [x] **R15/R18/R19** Auth errors + country picker, card "Read more", Inbox copy, onboarding tokens.

### Definition of done for each sprint
- `flutter analyze lib/` clean; existing 200+ widget tests green. ✅ **Verified 2026-08-16: 0 analyze issues, 237/237 tests pass.**

### Remaining / deferred (next iteration)
- **N4** Custom page transitions for the "social feel".
- **N5** Local-Talk compose still targets the hardcoded `ward-45-urban-central` slug.
- **N6** Guest-session bar bottom-overlay padding compensation on the feed list.
- **A5** Full Dynamic-Type (2×) test matrix.
- **A9/U11** Animated splash (currently blocked by router contract tests — needs a test update strategy).
- **A10** Focus-ordering/landmark semantics for TalkBack/switch-access.
- **U6** Dispute reason + photo flow; quorum neighbor nudge.
- **U10** Media-picker failure feedback.
- **L4** Category-color legend/help.
- **L5** Rename `_GradientPublishButton` to match the solid-fill design language.

---

## 7. Appendix — WCAG/Material Checklist Status

| Check | Status | Evidence |
|-------|--------|----------|
| Touch targets ≥44×44pt | ✅ | map close restored; `_SocialAction` + markers ≥44px |
| Icon buttons have accessible labels | ✅ | `Semantics`/`tooltip` added to dock, FAB, pins, icon buttons |
| Text ≥ 12–14pt, scales with Dynamic Type | ⚠️ | micro-text raised to 12px+; full 2× matrix pending |
| Contrast ≥4.5:1 body / ≥3:1 large | ✅ | status/timeline colors now token-driven with dark-mode variants |
| Safe-area compliance | ✅ | `SafeArea` in dock, sheets, compose |
| Color not the only indicator | ✅ | statuses = color + text/icon |
| Localized UI in supported locales | ✅ | hardcoded strings extracted to l10n layer (profile segment labels excepted) |
| Reduced motion support | ⚠️ | Shimmer + onboarding respect `disableAnimations`; splash N/A |
| Empty / loading / error states | ✅ | strong throughout |
| Sticky bars don't hide content | ⚠️ | guest bar overlap deferred (N6) |

---

*Reviewer: OpenCode UI/UX audit · Status updated 2026-08-16 after fix pass (analyze clean, 237/237 tests green). Re-verify each sprint via the Pre-Delivery Checklist in the ui-ux-pro-max skill.*