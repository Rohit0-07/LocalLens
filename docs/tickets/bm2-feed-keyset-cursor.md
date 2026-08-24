# bm2-feed-keyset-cursor: Feed cursor must be keyset (created_at, id)

Status: Done

## Summary

`GET /feed` cursor `created_at < cursor` drops items sharing the same timestamp (second precision, seed data and bulk creates). Fix by keyset pagination on `(created_at, id)`: cursor `"<iso>|<last_id>"`, backend filters `created_at < cursor_dt OR (created_at = cursor_dt AND id < cursor_id)`, app sends that cursor. All feed-typed fetchers (issues/wins/notices/talk) must honor the tie-breaker so pages never skip or duplicate.

## Files to touch

- `backend/app/features/issues/service.py` — `list_issues_near` and `list_wins_near` accept `created_before_id: int | None` and add keyset filter `(created_at < created_before) OR (created_at = created_before AND id < created_before_id)`
- `backend/app/features/wards/service.py` — `list_all_talk_posts_near`, `list_notices_near` same keyset handling
- `backend/app/features/feed/service.py` — propagate `cursor_id` from `_parse_cursor` into per-type calls; keep `before_cursor` safety net in `get_multi_type_feed:166-176`
- `app/lib/features/feed/data/feed_api.dart` — build cursor as `"<iso>|<lastId>"` when paginating
- `app/lib/features/feed/presentation/feed_providers.dart` — store and pass `cursor_id` via feed state / nextCursor
- `backend/tests/features/feed/test_feed_cursor.py` — NEW: create 3 issues with identical `created_at` but different ids, paginate `limit=1`, assert no loss/dup across 3 pages
- `app/test/features/feed/feed_cursor_test.dart` — NEW: provider builds `"<iso>|<id>"` cursor correctly

## Out of scope

- Switching feed to offset pagination; `search` cursor changes; ranking/relevance; `GET /issues?lat&lng` offset path (separate ticket if needed)

## Verify command

```sh
cd backend && uv run ruff check . && uv run mypy app/features/feed app/features/issues app/features/wards && uv run pytest tests/features/feed -q
cd app && flutter analyze && flutter test test/features/feed/feed_cursor_test.dart
```

Full gate before landing: `make check`.

## Notes

- `backend/app/features/feed/service.py:10-33` `_parse_cursor` and `backend/app/features/feed/service.py:166-176` `before_cursor` already describe `"<iso>|<last_item_id>"` — this ticket completes the contract upstream where it is still `created_at <= created_before` only (`issues/service.py:399`, `wards/service.py:381,409`, `issues/service.py:699`).
- Keep backward compat: bare ISO cursor (no `|id`) must still work via `cursor_id = -1` strict `<` fallback.
- Follow `issues/service.py:404` over-fetch pattern `(offset+limit)*_GEO_OVERFETCH_FACTOR` then single slice — apply tie-breaker before `LIMIT`.
