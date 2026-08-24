# home-hide-on-scroll: Hide Home header (logo + filters) on scroll-down, only feed cards visible

Status: Done

## Summary

Home `FeedScreen` AppBar (`app/lib/features/feed/presentation/feed_screen.dart:34`) stays pinned with logo, Ward chip and filter chips, wasting viewport. User requires entire header (including logo) to hide on scroll down so only feed cards remain visible, and reappear immediately on scroll up — mirroring Reels hide-on-scroll (YouTube/Instagram pattern).

## Files to touch

- `app/lib/features/feed/presentation/feed_screen.dart` — replace `Scaffold.appBar` + `body ListView` with `CustomScrollView` + `SliverAppBar(floating:true, snap:true, pinned:false)` containing title, actions, and bottom filters; body as `SliverList`/`SliverFillRemaining` for loading/error/empty/refresh. Ensures header fully collapses and feed cards expand to full screen when hidden.
- `app/test/features/feed/feed_header_scroll_test.dart` — NEW: widget test — pump FeedScreen with fake repo, drag list up (down scroll) → `SliverAppBar` not visible / scrolled out, drag down (up scroll) → header snaps back.

## Out of scope

- Reels (already done `reels-hide-on-scroll`), backend, offline caching (new_features.md §2 on hold).

## Verify command

```sh
cd app && dart analyze lib/features/feed/presentation/feed_screen.dart && flutter test test/features/feed/feed_header_scroll_test.dart
```

Full gate before landing: `flutter analyze`.

## Notes

- Must keep keys `feedTitleTap`, `feedScopeChip_all`, `feedFilterChip_all`, `feedAreaLabel`, `feedOutboxButton`, `feedNotificationButton` stable.
- `SliverAppBar` snap:true gives immediate reappear on slight upward drag as spec requires. Alternative manual `AnimatedSlide` would leave AppBar space occupied; sliver reclaims space so only cards are visible when hidden.
- `RefreshIndicator` wraps `CustomScrollView`; physics `AlwaysScrollableScrollPhysics`.
