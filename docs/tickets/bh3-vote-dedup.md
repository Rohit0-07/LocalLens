# bh3-vote-dedup: Enforce vote uniqueness at DB level and close race

Status: Done

## Summary

Upvote and quorum votes can double-count under race: check-then-insert is not atomic. Enforce `UniqueConstraint(issue_id,user_id)` at DB level (already declared in `issues/models.py:170,185` and migration `f0a1b2c3d4e5`) and ensure counters use atomic `UPDATE ... SET count = count+1` with `IntegrityError -> 400` mapping, so concurrent POSTs cannot create duplicates. Preserves existing `already_upvoted` / `already_voted` codes and 5km proximity / rate-limit checks.

## Files to touch

- `backend/app/features/issues/models.py` — confirm `Upvote`/`QuorumVote` `UniqueConstraint` remains (no change if present)
- `backend/alembic/versions/f0a1b2c3d4e5_add_indexes_and_vote_unique_constraints.py` — verify upgrade idempotent; no new schema if already at head
- `backend/app/features/issues/service.py` — keep atomic `update(Issue).values(upvotes_count=Issue.upvotes_count+1)` (`upvote_issue:829`) and `confirmations_count/disputes_count` (`vote_quorum:562,574`) with `except IntegrityError -> AppError(400, already_upvoted/already_voted)`
- `backend/tests/features/issues/test_vote_dedup.py` — NEW: concurrent duplicate upvote/quorum returns 400 and counter increments exactly once

## Out of scope

- Rate-limit or proximity logic changes; frontend optimistic UI; new endpoints or migration beyond verifying `f0a1b2c3d4e5`

## Verify command

```sh
cd backend && uv run alembic upgrade head && uv run ruff check . && uv run mypy app/features/issues && uv run pytest tests/features/issues -k vote -q
```

Full gate before landing: `make check`.

## Notes

- Migration `f0a1b2c3d4e5` already creates `uq_upvotes_issue_user` and `uq_quorum_votes_issue_user`; ticket is verify-and-close if DB at head. If local DB stale, `alembic upgrade head` applies it (AGENTS.md §6).
- Service already does `select(Upvote/QuorumVote).where(...).scalar_one_or_none()` pre-check but commit relies on DB constraint via `IntegrityError` catch — correct pattern, do not remove pre-check (preserves fast 400).
- Atomic counters must stay as `UPDATE ... SET count = count+1` not read-modify-write.
