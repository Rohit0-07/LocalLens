# NNN-short-slug

**Status:** open | in-progress | done | blocked

## Goal

One clear sentence: what the finished change looks like.

## Problem / expected behaviour

What happens today (or the bug report verbatim) and what SHOULD happen.

## Files to look for

- (exact files — no guessing, no browsing. From `docs/CODEBASE_MAP.md`.)

## Acceptance criteria

- [ ] verifiable outcome 1
- [ ] verifiable outcome 2

## Write Test

The tests should be written with a separate agent

- If the change are only in backend/frontend then only write backend/frontend test
- If the changes are in both then write tests for both
- The test Should be based on aceptance criteria
- The tests should be written in such a way that it can be run with `make check` command

## Verify

```sh
make check
# or targeted, e.g.:
# cd backend && uv run pytest tests/features/<name>
# flutter test test/features/<name>/..._test.dart
```