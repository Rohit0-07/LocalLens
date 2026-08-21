# <short-id>: <One-line title>

Status: Open

## Summary

<2–4 lines: what is broken/missing, for whom, and why it matters. Link to any
design doc section (LocalLens_App_Info.md / LocalLens_Feature_Checklist.md).>

## Files to touch

<!-- The contract: the diff stays inside this list. Widen only by editing the ticket. -->

- `backend/...` — <what changes there>
- `app/lib/features/<name>/...` — <what changes there>
- `backend/tests/features/<name>/test_*.py` or `app/test/features/<name>/...` — <tests>

## Out of scope

- <explicitly excluded, so scope creep has something to point at>

## Verify command

```sh
make check        # or a targeted subset, e.g.: cd backend && uv run pytest tests/features/<name>
```

## Notes

- <constraints, conventions to follow (AGENTS.md §6), edge cases, prior art>
