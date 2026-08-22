# feed-scope-all-wards: Feed defaulted to local ward on refresh; needs an explicit "My ward" scope option

Status: Done

## Summary

bugs_remain.md Issue no 2: the feed behaved inconsistently — global at first
launch but scoped to the device's ward after a refresh, with no user control.
Expected: all wards by default, with a separate option to view only the own
ward's issues.

Fix (already present in the working tree, verified here): an explicit
`FeedScope` toggle in the feed app bar — "All wards" (default) and "My ward".
`GET /feed` now treats absent `latitude`/`longitude` as unscoped: the backend
queries with a planetary radius instead of filtering by distance, and the app
only sends coordinates when "My ward" is selected.

## Files touched

- `app/lib/features/feed/presentation/feed_providers.dart` — `FeedScope`
  enum + `feedScopeProvider`; controller fetches without coordinates for
  `allWards`.
- `app/lib/features/feed/data/feed_api.dart`,
  `app/lib/features/feed/domain/feed_repository.dart` — nullable coords.
- `app/lib/features/feed/presentation/feed_screen.dart` — scope chips.
- `backend/app/features/feed/router.py`, `service.py` — optional lat/lng,
  `_GLOBAL_RADIUS_KM` fallback.
- Tests: `app/test/features/feed/feed_scope_test.dart`,
  `backend/tests/features/feed/test_feed_scope.py`.

## Out of scope

- Ward picker beyond the device-assigned ward; map screen scoping.

## Verify command

```sh
cd app && flutter test test/features/feed/feed_scope_test.dart
cd backend && uv run pytest tests/features/feed/test_feed_scope.py
```

## Notes

Both suites pass (3/3 and 2/2). Default scope is `allWards`, so a refresh no
longer silently narrows the feed.
