# reels-hide-on-scroll: Hide Reels banner on scroll-down, show on scroll-up

Status: Done

## Summary

Reels header (`Reels` brand + refresh) at `app/lib/features/reels/presentation/reels_screen.dart:105` is static and wastes viewport on a full-screen reel feed. Make it hide when the user scrolls down through reels and reappear immediately on any upward drag, matching YouTube/Instagram Reels app-bar behavior. Users see more photo content while swiping down, and retain one-handed access to refresh on upward intent.

## Files to touch

- `app/lib/features/reels/presentation/reels_screen.dart` — wrap header `Positioned` in `AnimatedSlide` driven by `NotificationListener<UserScrollNotification>` + `ValueNotifier<bool> _showHeader`; hide = `Offset(0,-1.5)`, show = `Offset.zero`, `Duration(milliseconds: 220)`, `Curves.easeOut`. Must respect `MediaQuery.padding.top`.
- `app/test/features/reels/reels_banner_scroll_test.dart` — NEW: widget test — pump Reels with 2+ items, dispatch scroll down → header off-screen, dispatch small scroll up → header reappears.

## Out of scope

- Backend changes; Offline Support – Local Caching (new_features.md §2) — explicitly on hold until user says so.
- Changing `reels_providers.dart` pagination/cursor logic; new dependencies; design token changes.

## Verify command

```sh
cd app && dart analyze lib/features/reels/presentation/reels_screen.dart && flutter test test/features/reels/reels_banner_scroll_test.dart
```

Full gate before landing: `make check` (via `flutter analyze`).

## Notes

- Reels uses vertical `PageView` not `ListView` — listen via `NotificationListener<UserScrollNotification>` on the `PageView` periphery, checking `notification.direction == ScrollDirection.reverse` (down) → hide, `forward` (up) → show. Reappear is immediate on up, no debounce. Prior art: feed `loadMore` pattern; keep `Key('reelsRefreshButton')` stable.
- Animation must not intercept PageView gestures; header stays `Positioned` but animated via `SlideTransition`.
