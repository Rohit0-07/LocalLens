# F-F — Feed / Issues Page UI Redesign (Frontend-Only)

Implementation-ready plan for a cleaner, more attractive, less cluttered ISSUES/FEED list
page and its cards. Handed to a **coder agent** and independently to a **test agent**.

**Golden rule:** preserve every functional behavior and every existing widget **Key** listed
below. The redesign only changes visual hierarchy, spacing, density, and presentation.

---

## 1. Scope & ownership

### Files CREATED (frontend only)
| File | Purpose |
|------|---------|
| `app/lib/features/feed/presentation/widgets/feed_skeleton_list.dart` | New `FeedSkeletonList` widget (shimmer skeleton matching the NEW card geometry: header row, title bar, status bar, media block). Replaces `SkeletonList` usage in the feed ONLY. |
| `app/lib/features/feed/presentation/widgets/feed_empty_state.dart` | New `FeedEmptyState` widget (decorative icon-ring empty state; optional action). Used for both feed-empty and feed-error bodies. Renders the EXACT existing strings below. |

### Files MODIFIED (frontend only)
| File | Change |
|------|--------|
| `app/lib/features/feed/presentation/widgets/issue_card.dart` | Full visual redesign per §2.1. Preserve all keys + interactions. |
| `app/lib/features/feed/presentation/widgets/win_card.dart` | Declutter per §2.4 (unified surface/border, lower gallery, lighter hint). |
| `app/lib/features/feed/presentation/widgets/notice_card.dart` | Declutter per §2.5 (lighter valid-pill, unified surface). |
| `app/lib/features/feed/presentation/widgets/local_talk_card.dart` | Declutter per §2.6 (unified surface, tighter spacing, no new actions). |
| `app/lib/features/feed/presentation/feed_screen.dart` | AppBar bottom area spacing, list rhythm, loading/empty/error body wiring, end-of-feed restyle (§2.2). |

### Files that must NOT be touched
- `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`,
  `app/lib/features/profile/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`,
  `app/lib/features/issue_detail/**`, `app/lib/features/geo/**`, `backend/**`.
- `app/lib/core/l10n/app_strings.dart` — **do NOT add or change any string.** The redesign must
  reuse the existing feed strings: `feed_title`, `feed_filter_*`, `feed_unavailable`,
  `feed_unavailable_msg`, `action_retry`, `feed_empty_title`, `feed_empty_msg`,
  `feed_end_of_feed`, `feed_end_of_feed_msg`, `action_share`, `flag_issue`, `fuzzed`,
  `shielded`, `status_*`.
- `app/lib/shared/widgets/media_preview_widget.dart`, `status_badge.dart`, `empty_state.dart`,
  `skeleton_list.dart`, `app_theme.dart`, `app_colors.dart`, `app_router.dart`,
  `route_paths.dart`. The redesign must be achievable without modifying these.
  - NOTE: `status_badge.dart` and `app/lib/features/feed/data/feed_api.dart` /
    `app/lib/features/feed/domain/feed_repository.dart` carry **uncommitted WIP** (humanized
    status labels, `category` param on `checkNearDuplicates`). The coder must BUILD ON these
    WIP diffs, never revert them. (`media_preview_widget.dart` currently has NO diff — verified.)
- `app/lib/features/feed/domain/**` — no changes needed (all presentation-only).

### WIP baseline to preserve (already in working tree)
- `issue_card.dart`: `StringFormatters.humanize(category)` for category labels, reporter tap
  now always calls `openReporterProfile` (handles null internally).
- `status_badge.dart`: `StringFormatters.formatStatus` + localized label fallback.
- `feed_screen.dart`: added `feedNotificationButton` (unread badge) in the app bar.

---

## 2. Design spec

### 2.1 IssueCard — new layout (decluttered)

Replace the current structure (header / category+status+hint box-row / title / description /
media / meta chips / divider / footer) with the following vertical stack. All internal
spacing uses the 8-pt rhythm; card container uses radius **16**, elevation **0**, 1px border
`AppColors.lightBorder` / `AppColors.darkBorder`, background `AppColors.lightSurface` /
`AppColors.darkCard`, `clipBehavior: Clip.antiAlias`, inner `Padding(all: 16)`.

```
Card (key: issueCard_<id>)
└ InkWell (tap → RoutePaths.issueDetailFor(id))
  └ Padding(16) → Column(crossAxisAlignment: start)

    1) HEADER  (12px gap below)
       Row[
         InkWell(key: issueCardReporter_<id>) → Row[
           _CleanAvatar (size 36, keep existing anonymous/photo/initial logic),
           10px,
           Column[
             Row[ reporterLabel (titleSmall w700 onSurface), 4px,
                  verified icon (15) if !isAnonymous ],
             2px,
             Row(key: issueHeaderMeta_<id>)[
               category icon (13, categoryColor),
               3px,
               Text(category.toUpperCase(), 12px w700 categoryColor),
               6px, Text('•', onSurfaceVariant 12),
               6px, Icon(location_on_outlined, 12, onSurfaceVariant),
               2px, Flexible(Text(ward, ellipsis, onSurfaceVariant 12)),
               6px, Text('•', onSurfaceVariant 12),
               6px, Text(formatRelativeTime(createdAt), onSurfaceVariant 12),
             ],
           ],
         ],
         Spacer,
         PopupMenuButton(key: issueCardOverflow_<id>, icon more_horiz_rounded 20,
                         item: PopupMenuItem(key: flagIssueOption_<id>, value 'flag',
                                             icon flag_outlined urgent + Text(flag_issue))) —
                         KEEP the guest/session FlagIssueDialog behavior exactly.
       ]
       // NOTE: category/ward/time must be SEPARATE Text widgets (never one concatenated
       // string) so find.text('WATER') and find.text('Ward 45, Urban Central') still match.

    2) STATUS ROW  (key: issueStatusRow_<id>)  — 10px gap below
       Row[
         StatusBadge(status),            // shared widget, UNCHANGED
         if isEscalating  → inline Icon(local_fire_department, 14, urgent) + Text('ESCALATING',
                             12 w800 urgent)   // NO background box — plain, de-emphasized
         else if isPendingQuorum → Icon(how_to_vote, 14, verified) + Text('VERIFY',
                             12 w800 verified),
         Spacer,
       ]

    3) TITLE  — 6px gap below
       Text(title, titleMedium w800 16px height 1.3, maxLines 2, ellipsis)

    4) DESCRIPTION (only if non-empty)  — 6px gap below
       _ExpandableDescription: collapse to **2 lines** (down from 3), bodyMedium,
       onSurfaceVariant height 1.4, keep read-more/show-less (existing tr keys).

    5) MEDIA (only if mediaUrls/videoUrl/resolutionProof present)  — 10px gap below
       MediaPreviewWidget(key: issueMedia_<id>, maxHeight: **180**, heroTagPrefix 'issue_<id>')
       // Shared widget untouched; only maxHeight reduced for a lighter block.

    6) META CHIPS (only if isFuzzed || isShielded)  — 10px gap below
       Wrap(spacing 6, runSpacing 6) of _MetaChip (keep icons + tr keys fuzzed/shielded).

    7) FOOTER ACTIONS  (key: issueActions_<id>)  — NO Divider (whitespace instead), 12px above
       Row[
         _SocialAction(key: upvote_button_<id>, thumb_up_outlined/rounded, brand when active,
                       label Text(upvotesCount), onTap toggleUpvote)  — keep exact optimistic
                       toggle + SnackBar error handling,
         4px, _SocialAction(key: comment_button_<id>, chat_bubble_outline_rounded,
                       label _CommentCount, onTap _showCommentsModal),   // keep comments sheet
         Spacer,
         _SocialAction(key: share_button_<id>, share_outlined, tooltip action_share,
                       onTap SharePlus deep link),                      // keep deep-link text
       ]
       // _SocialAction: reduce minHeight 44 → 40, icon 18, label 13 w700. Unify idle color to
       // onSurfaceVariant; keep active upvote = brand + brand-tint background. This is the
       // ONLY visible action row on the card.
```

**Declutter outcomes enforced:** category is no longer a bordered box; the old 3-element
"category chip + status badge + escalation hint" row collapses into (a) a plain colored
category in the header meta and (b) one subtle status row. The Divider is removed. Media and
description are visually lighter. All existing keys (`issueCard_<id>`, `issueCardReporter_<id>`,
`issueCardOverflow_<id>`, `flagIssueOption_<id>`, `issueMedia_<id>`, `upvote_button_<id>`,
`comment_button_<id>`, `share_button_<id>`) are preserved verbatim.

### 2.2 FeedScreen — page-level changes

- **AppBar**: unchanged content and action keys (`feedOutboxButton`, search, `feedNotificationButton`).
  Keep `feed_title` + brand glyph. Do not add/remove actions.
- **AppBar `bottom` PreferredSize**: keep `feedAreaLabel` (WardLocationChip, key preserved —
  asserted by `geo_screen_integration_test.dart`) and the 5 filter chips
  (`feedFilterChip_all|issues|wins|notices|local_talk`, key + selected-state behavior preserved).
  Tighten: `preferredSize` 90 → **84**, `SizedBox(height: 8)` → 4 between the ward row and the
  chip row, keep 16px horizontal padding on both rows.
- **List body (data state)**: `ListView.separated` with
  `padding: EdgeInsets.fromLTRB(16, 8, 16, 24)`, `separatorBuilder → SizedBox(height: 16)`
  (more air between cards). Item mapping / `switch (item.itemType)` logic unchanged.
- **Loading state**: replace `SkeletonList` with `FeedSkeletonList(itemCount: 4)` wrapped in
  `Padding(all: 16)`; skeleton widget root carries `key: Key('feedSkeleton')`. `SkeletonList`
  (shared) stays untouched for the search screen tests.
- **Error state**: keep `feed_unavailable` / `feed_unavailable_msg` / `action_retry`
  (taps `Retry` → `multiTypeFeedProvider.notifier.refresh()`). Render via the new
  `FeedEmptyState` with an action, or keep shared `EmptyState` — either is acceptable as long
  as the exact texts and the refresh wiring are preserved. Recommended: reuse the new
  `FeedEmptyState` for a consistent look.
- **Empty state**: replace shared `EmptyState` with `FeedEmptyState` (new) rendering exactly
  `feed_empty_title` ('All clear around here') and `feed_empty_msg`; root key
  `Key('feedEmptyState')`. It stays inside an `AlwaysScrollableScrollPhysics` ListView so
  pull-to-refresh still works.
- **End-of-feed**: keep `Key('endOfFeedState')` and the exact strings `feed_end_of_feed`
  ("You're all caught up!") / `feed_end_of_feed_msg`. Restyle lightly (vertical padding 32,
  icon ring 44px) — no text/key change.

### 2.3 Shared spacing & container tokens (applied to all four cards)

- Radius **16**, elevation **0**, 1px border, `clipBehavior: Clip.antiAlias`, inner padding **16**.
- Background: `AppColors.lightSurface` (light) / `AppColors.darkCard` (dark).
  (WinCard currently uses `darkSurface` in dark — unify to `darkCard` for tonal consistency.)
- Section gaps: 8/10/12 from the scale; never 4+ unrelated boxes on one row.

### 2.4 WinCard declutter (preserve every asserted behavior)
- Keep: `winCard_<id>` key, 'COMMUNITY WIN' banner + share `IconButton` (deep link), title,
  description, `PageView` before/after gallery, BEFORE/AFTER badges, `MediaFullScreenViewer`
  on tap, contributor credit text, swipe hint.
- Change: gallery `height: 220` → **200**; unify surface to `lightSurface`/`darkCard`;
  de-emphasize the "Swipe to compare before & after" row (fontSize 12 → 11, color stays
  onSurfaceVariant); keep contributor chips compact as-is.

### 2.5 NoticeCard declutter
- Keep: `noticeCard_<id>` key, official-header pill (verified, uppercase), title, description,
  ward row, `'Valid: ${_formatValidUntil(...)}'` pill with the exact current formatting.
- Change: valid-pill background `verified 0.12` → **0.08**, smaller icon (12→11); unify card
  surface; keep verified border tone.

### 2.6 LocalTalkCard declutter
- Keep: `localTalkCard_<id>`, `localTalkAuthor_<id>`, `localTalkMedia_<id>` keys, author row,
  `post.topic.toUpperCase()` text, title, 3-line body, replies pill `'${post.repliesCount} replies'`,
  date `day/month`. **Do NOT add any share/overflow icon** (FE-FEED-05 asserts none present).
- Change: unify surface to `lightSurface`/`darkCard`; media `maxHeight: 180`; tighten bottom
  row spacing (12 → 10).

---

## 3. Compatibility notes (existing tests)

Strategy: **zero test edits required if** the coder preserves every standalone widget below as a
separate `Text`/widget (never concatenated into one string). Targeted edits are listed as the
fallback. The test agent should NOT rewrite tests unless the coder changed a string shape.

| Test file | Asserts (must keep passing) | Redesign hazard |
|-----------|-----------------------------|-----------------|
| `test/features/feed/issue_card_test.dart` | `find.text('Broken Water Pipe')`; `find.text('WATER')`; `find.byType(StatusBadge)` =1; `find.text('Citizen John')`; `MediaPreviewWidget` present/absent; `issueMedia_<id>`; fullscreen/video modal via tapping `issueMedia_<id>`; `upvote_button_<id>` optimistic `15→14`, `4→5`; repo.toggleCalls | Category must stay a standalone `Text('WATER')`. Keep `StatusBadge` + media key + upvote key/count `Text`. |
| `test/features/feed/upvote_interaction_test.dart` | `findCountText` via `upvote_button_<id>` then generic `upvote_button`, then `thumb_up_outlined`/`thumb_up`; optimistic toggles; SnackBar/error text on failure | Keep key + icons + count `Text`; keep error SnackBar wiring. |
| `test/features/feed/multi_feed_talk_extended_test.dart` | FE-FEED-01/02: all 5 `feedFilterChip_*` keys + `issueCard_101`/`winCard_202`/`noticeCard_303`/`localTalkCard_404` swap on filter. FE-FEED-03: WinCard 'COMMUNITY WIN', title, 'BEFORE'/'AFTER' after fling, credits 'Citizen John'/'Citizen Mary', `share_outlined` tap no-crash. FE-FEED-04: 'MUNICIPAL WATER BOARD', title, 'Valid: 20/8/2026'. FE-FEED-05: title, 'Neighbor Alice', 'SANITATION', '4 replies', **no** `share_outlined`. FE-FEED-07: `endOfFeedState` + "You're all caught up!" | Preserve banners/pills/credits/replies texts and absence of share on LocalTalk. |
| `test/features/feed/reporter_navigation_test.dart` | Tap `issueCardReporter_<id>` navigates own vs public profile per session | Keep `issueCardReporter_<id>` InkWell wrapping avatar+name (meta may live inside it). |
| `test/features/feed/feed_screen_test.dart` | issue titles; 'RESOLVED' (StatusBadge); error 'Feed unavailable' + tap 'Retry' → refetch; empty 'All clear around here' | Keep exact strings + Retry wiring + StatusBadge. |
| `test/features/feed/media_display_and_like_toggle_test.dart` | MediaPreviewWidget unit behaviors (shared, untouched); WinCard gallery; LocalTalk media key; IssueDetailScreen (untouched) | Only WinCard visual edits → keep PageView/gallery/fullscreen/share icon. |
| `test/features/feed/upvote_toggle_core_test.dart` | FeedApi + controller (no UI) | Untouched by UI redesign. |
| `test/features/feed/issue_test.dart` | Domain parsing | Untouched. |
| `test/features/geo/geo_screen_integration_test.dart` | `feedAreaLabel` key present in feed AppBar bottom | Keep `feedAreaLabel` wrapping the WardLocationChip. |
| `test/core/dock_and_notifications_header_test.dart` | `feedNotificationButton` + badge text '3' | Keep app bar notification button + Badge. |
| `test/shared/shimmer_loading_test.dart`, `test/core/offline_sync_onboarding_extended_test.dart` | `SkeletonList` behavior | `SkeletonList` untouched (feed uses new `FeedSkeletonList`). |

If any string shape must change anyway (e.g. category merged into one Text), the coder MUST flag
it in the PR description and the test agent updates **only** the exact `find.text` → 
`find.textContaining` lines listed above; no other assertions.

---

## 4. User-journey E2E test plan (new widget tests)

New file: `app/test/features/feed/feed_ui_redesign_e2e_test.dart` (test agent owns). Use the
existing fake-repository patterns from `multi_feed_talk_extended_test.dart` /
`issue_card_test.dart`. Keep assertions **structural** (keys, presence, counts) — never
pixel-perfect layout.

1. **T-FF-01 Home shows a clean mixed feed.** Seed one item of each type. Pump `FeedScreen`.
   Assert `issueCard_<id>`, `winCard_<id>`, `noticeCard_<id>`, `localTalkCard_<id>` all present;
   assert every issue card exposes exactly one footer actions row: `find.byKey(issueActions_<id>)`
   findsOneWidget AND within that card `find.byKey(issueStatusRow_<id>)` findsOneWidget AND
   `find.byKey(issueHeaderMeta_<id>)` findsOneWidget. Assert no `Divider` inside the issue card
   subtree (structure check for the declutter).
2. **T-FF-02 Filter chips switch card types.** Tap `feedFilterChip_issues` → only issue card
   present; `feedFilterChip_wins` → only win card; `feedFilterChip_notices` → only notice card;
   `feedFilterChip_local_talk` → only talk card; `feedFilterChip_all` → all four again.
3. **T-FF-03 Tap card → detail navigation.** Build a minimal `GoRouter` harness
   (pattern from `reporter_navigation_test.dart`) with `/issue/:id` stub; tap `issueCard_<id>`
   InkWell; assert the stub route rendered with the right id.
4. **T-FF-04 Optimistic upvote.** Tap `upvote_button_<id>`; assert count text increments after
   one `pump` (optimistic) and repo toggle called once; tap again → decrements.
5. **T-FF-05 Overflow → flag.** Tap `issueCardOverflow_<id>`; assert `flagIssueOption_<id>`
   visible; for a signed-in session assert `FlagIssueDialog` opens; for a guest session assert
   `GuestGuard` dialog opens.
6. **T-FF-06 Card content hierarchy for an issue.** For an issue with media, fuzzed=true,
   status 'escalating': assert title, description preview (≤2 visible lines not asserted — only
   presence), `issueMedia_<id>`, `_MetaChip`-backed 'Fuzzed'/'Shielded' text, StatusBadge,
   'ESCALATING' inline hint present in `issueStatusRow_<id>`, and `upvote_button_<id>` /
   `comment_button_<id>` / `share_button_<id>` present in `issueActions_<id>`.
7. **T-FF-07 Status/empty/loading states.** Loading: `FeedSkeletonList` renders under
   `feedSkeleton` key. Empty: `feedEmptyState` + 'All clear around here'. Error: 'Feed
   unavailable' + 'Retry' triggers a second fetch. End-of-feed: scroll ListView, assert
   `endOfFeedState` + "You're all caught up!".
8. **T-FF-08 No share affordance on LocalTalk.** Assert `find.byIcon(Icons.share_outlined)`
   findsNothing when only a LocalTalkCard is rendered (protects the declutter from regressing).

Run: `cd app && flutter analyze && flutter test test/features/feed/`.

---

## 5. Edge cases & ordering/dependencies

### Edge cases the coder must handle
- **Anonymous issue**: `_CleanAvatar` shield mask, no verified icon, reporter label still shown;
  reporter tap still calls `openReporterProfile` (null-safe).
- **Null/empty media**: skip media block entirely; card layout stays balanced.
- **Long title / long description**: title 2-line ellipsis; description 2-line + read-more only
  when it overflows (`TextPainter.didExceedMaxLines` — keep `_ExpandableDescription`).
- **Status variants**: `open`, `resolved`, `escalating` (ESCALATING hint), `pending_quorum`
  (VERIFY hint), `pending_verification`, `disputed` — StatusBadge is shared and already handles
  all; hint row renders only for escalating/pending_quorum.
- **Both fuzzed AND shielded**: both `_MetaChip`s render (Wrap).
- **Dark mode**: every hardcoded color must switch on `theme.brightness` using
  `lightBorder`/`darkBorder`, `lightSurface`/`darkCard`, `categorySurfaceFor(isDark)` — the
  cards must not regress contrast in OLED-black dark theme.
- **Filtered-empty feed**: any filter returning [] must still render `feedEmptyState` +
  'All clear around here' (no new strings available).
- **Ward/meta line overflow**: `Text(ward)` is `Flexible` + ellipsis; category/time must never
  overflow on narrow screens.
- **Comment count**: keep `_CommentCount` watching `commentsProvider(issueId)` — do not swap for
  a static label.
- **Share deep link**: preserve the exact `locallens://issue/<id>` share text on issue and win.

### Ordering / dependencies
- **UI-only, self-contained.** No backend, domain, router, l10n, or theme changes.
- **Overlap with compose/media (F-A):** none by design — this plan does NOT modify
  `app/lib/shared/widgets/media_preview_widget.dart` or anything under `features/compose/**`.
  Coordinate ONLY if F-A concurrently edits `shared/widgets/media_preview_widget.dart`; then
  rebase review both diffs before merging.
- **Do not touch** `status_badge.dart` / `feed_api.dart` / `feed_repository.dart` beyond their
  existing uncommitted WIP (already in the tree — leave them as-is).
- **Suggested coder order**: (1) `feed_skeleton_list.dart` + `feed_empty_state.dart`,
  (2) `issue_card.dart`, (3) `win/notice/local_talk` cards, (4) `feed_screen.dart` wiring.
  Run `flutter analyze` after each step; run `flutter test test/features/feed/` at the end.