# search-scale: Make `/api/v1/search` fast and index-backed

Status: Done (074522f)

## Summary

`GET /search` does its filtering in the wrong places: `limit`/`offset` are applied
in SQL *before* Python-side post-filtering (hidden/shielded issues, haversine
re-check) in `backend/app/features/search/service.py:149-170`, so pages come back
short and every fetched row may be discarded. Text match is a 6-way
leading-wildcard `ILIKE` chain plus per-row nested `REPLACE` expressions
(`_alnum_expr`), which no index can serve — cost grows linearly with table size.
All existing filter behaviour (q, status, category/categories, ward, account,
dates, geo radius) must be preserved exactly — the current behaviour contract
lives in `backend/tests/features/search/test_search.py` and
`test_search_filters.py`.

## Files to touch

- `backend/app/features/issues/models.py` — add an indexable lowercase
  `search_blob` column (title + description + category + ward, space-joined).
- `backend/app/features/issues/service.py` — populate `search_blob` wherever
  title/description/category/ward are written (compose/edit paths).
- `backend/app/features/search/service.py` — replace the ILIKE OR-chain and
  `_alnum_expr` REPLACE chains with a match against `search_blob`; push
  hidden/shielded filters into SQL; apply the radius check before `LIMIT`
  (distance computed in SQL inside the bbox subquery).
- `backend/app/features/account`-style account search stays as-is (users-table
  join kept for `account=` / `@handle` matching).
- `backend/alembic/versions/<new>_add_issue_search_blob.py` — add column +
  index, backfill `search_blob` for existing rows.
- `backend/tests/features/search/test_search.py` — extend: blob matching
  (case/punctuation-insensitive), pagination returns full pages when
  hidden/shielded rows are interleaved, radius filter before limit.
- `backend/tests/features/search/test_search_filters.py` — must stay green
  unchanged (behaviour contract).

## Out of scope

- App-side changes (stale-request cancellation, caching) — follow-up ticket.
- Keyset/cursor pagination and any API shape change (`IssueOut` list stays).
- Full-text/trigram engine-specific features (pg_trgm, FTS5) — must remain
  portable across sqlite (dev default) and Postgres.
- Rate limiting, relevance ranking/ranking signals.

## Verify command

```sh
cd backend && uv run ruff check . && uv run mypy app && uv run pytest tests/features/search tests/features/issues -q
```

Full gate before landing: `make check`.

## Notes

- Schema change ⇒ Alembic migration required (AGENTS.md §6);
  `make backend` runs migrations on start.
- Ward matching today accepts slug/name/code variants (`_alnum` comparison);
  preserve that behaviour by normalizing into `search_blob` the same way
  (`re.sub(r"[^a-z0-9]+", "", ...)` variant stored alongside, or normalize the
  query term instead of the column per-row).
- Leading-wildcard LIKE cannot use a plain index; the blob column turns the hot
  path into either prefix match (`blob LIKE 'term%'` on an indexed column) or an
  exact-token containment strategy — pick whichever keeps
  `test_search_filters.py` green without changing semantics for substring
  queries documented in the tests.
- Prior art for write-path denormalization: `geohash` is populated at compose
  time in `issues/service.py`.
