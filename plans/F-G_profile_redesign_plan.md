# F-G: Own Profile Page Redesign — Implementation Plan

Redesign the OWN `ProfileScreen` for cleaner hierarchy, role/ward surfacing, rep
account display, and better-organized Drafts / Outbox / My Issues sections.
Frontend-only: `UserOut` already returns `role` and `ward`; the frontend model
drops them. **No backend change required.**

---

## 1. Scope & ownership

### Files to modify (4 files, 1 new)

| File | Change |
|------|--------|
| `app/lib/features/profile/domain/user_profile.dart` | Add `role` (`String`, default `'citizen'`), `ward` (`String?`, default `null`), getter `isRepresentative`, parse both in `fromJson`. **This model is a plain hand-written immutable class, NOT freezed** (verified — unlike `Issue`/`Session`). Extend it in the same style. **No `build_runner` step.** |
| `app/lib/features/profile/presentation/profile_providers.dart` | Give the mock `'Demo Resident'` profile `role: 'citizen'`, `ward: 'Ward 45, Urban Central'`; give the guest fallback `role: 'guest'`, `ward: null`. No new providers. |
| `app/lib/features/profile/presentation/screens/profile_screen.dart` | Layout reorganization + role/ward chips + rep dashboard entry + improved empty states. All existing Keys preserved (see §2.5). |
| `app/lib/features/profile/presentation/widgets/profile_role_badge.dart` **(new)** | `ProfileRoleBadge` stateless pill (same visual language as `_RoleBadge` in `public_profile_screen.dart:537` but public, reusable). |

### Files NOT to touch (parallel-agent boundaries — hard)

- `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/ward/**`
- `app/lib/features/rep_dashboard/**` — including `rep_dashboard_screen.dart`, `rep_dashboard_providers.dart`. Do **not** import these; rep status is derived from `UserProfile.role` only. The `/rep-dashboard` route already exists (`app_router.dart:186`).
- `app/lib/features/profile/presentation/screens/public_profile_screen.dart` + `app/lib/features/profile/domain/public_user_profile.dart` — PUBLIC profile + rep metrics belong to the rep-accountability feature (already has WIP).
- `backend/app/features/representatives/**`, `media/**`, `geo/**`, `wards/**`, `search/**`

### Files in the *allowed* set that need NO change

- `settings_screen.dart`, `edit_profile_screen.dart`, `anonymity_guide_screen.dart`, `domain/user_settings.dart` — untouched.
- `app/lib/core/router/app_router.dart`, `route_paths.dart` — `RoutePaths.repDashboard` (`'/rep-dashboard'`) and its route are already registered. We only call `context.push(RoutePaths.repDashboard)` from the profile screen.

### Backend scope

**None.** `UserOut` already declares `role: str = "citizen"` and `ward: str | None = "Ward 45, Urban Central"` (`backend/app/features/auth/schemas.py:63-65`), and `GET /auth/me` populates both (`backend/app/features/auth/router.py:109-135`; guests get `role="guest"`, `ward=None`). Frontend drops them. Do not touch `backend/app/features/auth/**`.

---

## 2. Design spec

### 2.1 Domain model — `user_profile.dart`

```dart
// new fields
final String role;            // raw from /auth/me: 'citizen' | 'guest' | 'representative' | 'ward_official' | ...
final String? ward;           // e.g. 'Ward 45, Urban Central'

// constructor defaults
this.role = 'citizen',
this.ward,

// derived getter
bool get isRepresentative =>
    role.toLowerCase().contains('representative');
```

`fromJson` additions (fallback-safe, backward compatible with existing test fixtures which construct the model directly — those compile unchanged because the new params are optional):

```dart
role: (json['role'] as String?) ?? 'citizen',
ward: json['ward'] as String?,
```

No `copyWith`/`toJson` exists on this class and none is required.

### 2.2 Layout (top-to-bottom hierarchy)

Keep the existing `Scaffold`/`AppBar` (`openSettingsButton` unchanged), `RefreshIndicator`, `SingleChildScrollView` with 12px padding. Section ordering:

1. **Identity header** (existing `Row`, photo left / identity right — keep `editProfilePhotoButton`, `ProfileAvatar`, `editNameButton`, verified icon, `_buildBioSection`, anon-id chip, `profileIdentityToggle`). **Insert** a meta row directly below the name row (above the bio): `ProfileRoleBadge` + ward `Chip`. Both hidden for guests.
2. **Rep dashboard entry** (rep only, see §2.4).
3. **Guest banner** (guest only — existing text unchanged).
4. **Activity stats card** — add key `profileStatsCard`. Keep the three `_StatMetric`s with the EXACT labels `Issues` / `Upvotes` / `Verified` (existing tests match these via `textContaining`). Token styling unchanged (`outlineVariant` border, radius 16, `surface` fill).
5. **"Your Activity"** — one section header (`titleSmall`, weight 800) followed by ONE card containing two `ListTile`s separated by a `Divider(height: 1)`:
   - **Drafts** tile — key `profileDraftsButton`, leading `Icons.drafts_outlined`, title `Drafts`, subtitle `'$draftsCount saved'` when count > 0 else `'No drafts yet'`, trailing chevron. → `context.push(RoutePaths.drafts)`.
   - **Outbox** tile — key `viewOutboxButton`, leading `Icons.outbox_rounded`, title **`Offline Outbox`** (keeps `find.textContaining('Offline Outbox')` in `profile_settings_test.dart:389` green), subtitle `'Pending Outbox Items: $pendingOutboxCount'` + secondary line `profile_outbox_queued` / `profile_outbox_synced` (keep the existing `tr` keys), trailing chevron. → `context.push(RoutePaths.outbox)`.
6. **"My Reported Issues & Activity"** — keep the EXACT header string, `Report New` button (`RoutePaths.compose`, non-guest), filter chips `myIssuesFilter_all` / `myIssuesFilter_active` / `myIssuesFilter_resolved`, `GridView` of `_UserIssueGridTile` with `userIssueItem_<id>` / `deleteIssue_<id>` keys, guest sign-in prompt, error card, and the empty-filter state. **Preserve the `ACTIVE`/`RESOLVED` overlay badges** (`profile_posts_and_public_profile_test.dart` asserts them).

### 2.3 Empty states (less clutter)

- No drafts → subtitle `'No drafts yet'` (icon + muted text).
- Outbox empty → existing `'All local submissions synced'` (`profile_outbox_synced`).
- Zero activity → stats render `0`; My Issues shows the existing empty-filter card (`'No issues found in this filter.'`).
- Guest → existing `'Sign in to view and manage your reported issues history.'` card; stats still render zeros.

### 2.4 Rep account display (role badge + ward + navigation hook)

When `!profile.isGuest && profile.isRepresentative`:

- **Role pill** — `ProfileRoleBadge(role: profile.role)` (icon `Icons.how_to_reg_rounded`, `AppColors.brand` tint, 12% alpha fill, 30% border — same pattern as `public_profile_screen.dart:537`). Key `profileRoleBadge`.
- **Ward chip** — `Chip` with `Icons.location_on_outlined`, label `profile.ward`, `surfaceContainerHigh` background. Key `profileWardChip`. Hidden if `ward` is null/empty.
- **Rep dashboard entry card** — new prominent `Card` directly under the header row:
  - Key `repDashboardEntryButton` on the `InkWell`.
  - Leading tonal circle with `Icons.how_to_reg_rounded` in `colorScheme.primaryContainer`.
  - Title `Representative Dashboard` (`titleSmall`, weight 700); subtitle `profile.ward ?? 'Your ward'` (`bodySmall`, `onSurfaceVariant`).
  - Trailing `Icons.chevron_right`.
  - `onTap: () => context.push(RoutePaths.repDashboard)`.
  - **No metrics built here** — rep metrics are the rep feature's scope. This is surface-role + navigation only.

### 2.5 Keys — complete contract

**Preserved (must not rename/remove):** `openSettingsButton`, `editProfilePhotoButton`, `editNameButton`, `editBioButton`, `editBioField`, `saveBioButton`, `saveNameButton`, `changeLimitsOkButton`, `pickPhotoGalleryButton`, `profileIdentityToggle`, `viewOutboxButton`, `profileDraftsButton`, `myIssuesFilter_all`, `myIssuesFilter_active`, `myIssuesFilter_resolved`, `userIssueItem_<id>`, `deleteIssue_<id>`, `confirmDeleteIssueButton`.

**New:** `profileRoleBadge`, `profileWardChip`, `repDashboardEntryButton`, `profileStatsCard`.

### 2.6 Providers

None new. Rep status is a pure getter on `UserProfile` (`isRepresentative`). `userProfileProvider`, `myIssuesProvider`, `myIssuesFilterProvider`, `userSettingsProvider` stay as-is; only the mock data in `profile_providers.dart` gains `role`/`ward`.

### 2.7 Styling tokens

Reuse the existing clean token system — `colorScheme.surface`/`surfaceContainerHigh`/`outlineVariant`/`primary`/`onSurfaceVariant`, `AppColors.verified`, `AppColors.brand`, `AppColors.anonMask`; card radius `BorderRadius.circular(16)`, `elevation: 0` + `outlineVariant` border; page padding 12; section headers `titleSmall` weight 800. **No new design tokens.**

---

## 3. Backend design

No changes. State explicitly in the PR: `role`/`ward` already flow through `UserOut` (`schemas.py:63-65`) and are populated by `GET /auth/me` (`router.py:109-135`). Nothing to add, migrate, or test server-side.

---

## 4. User-journey E2E test plan (Flutter widget tests)

New file: `app/test/features/profile/profile_redesign_test.dart`. Reuse the established harness pattern from `profile_rework_test.dart` (ProviderScope + GoRouter stubs + `userProfileProvider.overrideWith((ref) async => UserProfile(...))`). Cases:

1. **Citizen header** — `UserProfile(role: 'citizen', ward: 'Ward 45, Urban Central', ...)` renders `profileRoleBadge` with text `Citizen`, `profileWardChip` with the ward text, `profileStatsCard`, both Activity tiles (`profileDraftsButton`, `viewOutboxButton`), and the `My Reported Issues & Activity` header. `repDashboardEntryButton` absent.
2. **Rep user journey** — `UserProfile(role: 'Ward Representative', ward: 'Ward 12, North', ...)` renders `profileRoleBadge` with `Ward Representative` + ward chip; `repDashboardEntryButton` present; tap → stub route asserting `/rep-dashboard` is reached (register a `RoutePaths.repDashboard` stub in the test router). Assert no rep metrics tiles exist on the profile itself.
3. **Guest journey** — guest `UserProfile(role: 'guest', ward: null, isGuest: true)` → no role badge, no ward chip, no rep entry; guest banner present; drafts/outbox tiles still render; My Issues shows the sign-in prompt.
4. **Empty states** — empty `DraftStore` → `'No drafts yet'`; empty outbox → `'All local submissions synced'`; zero-count stats render `0`.
5. **My-issues filters** — with `FakeFeedRepository` issues, tap `myIssuesFilter_active`/`myIssuesFilter_resolved`/`myIssuesFilter_all` and assert `userIssueItem_*` visibility (mirror `profile_posts_and_public_profile_test.dart`).
6. **Navigation reachability** — `openSettingsButton` → settings stub; `Report New` → compose stub; tap a draft/outbox tile → drafts/outbox stubs.
7. **Parsing unit tests** — `UserProfile.fromJson({'role': 'ward_official', 'ward': 'Ward 5'})` parses both; JSON with neither key defaults to `role: 'citizen'`, `ward: null`; `isRepresentative` true for `'Ward Representative'`/`'representative'`, false for `'citizen'`/`'guest'`.

### Existing tests to update

**None required.** Verified every key and label they assert is preserved: `editProfilePhotoButton`, `profileIdentityToggle`, `myIssuesFilter_*`, `userIssueItem_<id>`, `deleteIssue_<id>`, `viewOutboxButton`, `profileDraftsButton`, `openSettingsButton`, `editBioButton`/`editBioField`/`saveBioButton`, `changeLimitsOkButton`, `pickPhotoGalleryButton`, `saveNameButton`, `confirmDeleteIssueButton`, `'My Reported Issues & Activity'`, `'2 saved'`, `'Offline Outbox'`, `Issues`/`Upvotes`/`Verified` labels, guest banner text, photo-left-of-bio geometry (`profile_rework_test.dart:193`), and `ACTIVE`/`RESOLVED` overlays. New `UserProfile` params are optional, so all direct-constructor fixtures compile untouched.

Run before hand-off: `cd app && flutter analyze && flutter test test/features/profile/`.

---

## 5. Edge cases & ordering / dependencies

### Edge cases

- **Guest** → `role: 'guest'`, `ward: null`; hide role badge, ward chip, rep entry; show guest banner; keep Drafts/Outbox (device-local, works for guests); My Issues shows sign-in prompt.
- **`role` missing/null in API** → default `'citizen'` (no badge emphasis, no rep entry).
- **`ward` null/empty** → hide `profileWardChip`; rep entry subtitle falls back to `'Your ward'`.
- **Zero activity** → stats render `0`; My Issues shows the empty-filter card; no crash.
- **Rep role string mismatch** — `UserProfile.role` is the agreed signal. If the representatives feature ever has a rep whose `users.role` is still `'citizen'` (data inconsistency), the badge/entry won't show; fixing `users.role` assignment is the rep feature's responsibility and is explicitly out of scope. Do **not** probe `/representatives/me` from the profile feature to compensate.

### Ordering / dependencies

1. **Landing order**: `user_profile.dart` (model) → `profile_providers.dart` (mock) → `widgets/profile_role_badge.dart` → `profile_screen.dart` → tests.
2. No `build_runner` (plain class), no router changes, no backend changes.
3. **Only dependency consumed:** `RoutePaths.repDashboard` (already registered in `app_router.dart`). Wire navigation with `context.push(RoutePaths.repDashboard)`; do not add/import rep-dashboard code.
4. Do not touch the WIP-modified files (`public_profile_screen.dart`, `public_user_profile.dart`, `settings_screen.dart`, `profile_providers.dart` reset additions) — the `profile_providers.dart` edit here is additive (mock role/ward only) and must not disturb the existing uncommitted `resetToDefaults()` addition.