# 002-feed-ward-vs-global

**Status:** open

## Goal

Feed scope must be explicit: show all issues by default, ward-only only when the user
chooses it — never silently switch on refresh.

## Problem / expected behaviour

Bug report: "the feed only displays the local ward issues; at start it is global, on
refresh it gets local". The feed must not flip between global and ward-filtered
depending on refresh. Intended design: a separate, explicit control for "only my ward",
otherwise all wards are visible.

## Files to touch

- `app/lib/features/feed/presentation/feed_providers.dart`
- `app/lib/features/feed/presentation/feed_screen.dart`

## Files NOT to touch

- Backend feed/geo query code unless the fix is proven app-only (confirm first).

## Acceptance criteria

- [ ] Refreshing does not change the feed's scope
- [ ] There is an explicit ward-only toggle/option distinct from the default global view

## Verify

```sh
cd app && flutter analyze
flutter test test/features/feed
```