---
description: Run make check (ruff + mypy + pytest + flutter analyze/test) and triage failures
---

Run `make check` and triage the result.

1. Run `make check`. Do not start fixing anything until the full run completes.
2. **Triage** every failure into one of:
   - **Pre-existing** — fails on a clean tree too (verify with `git stash` + rerun if
     unclear). Report only; fix via its own ticket.
   - **In scope** — caused by current work. Fix minimally, rerun, repeat.
3. Rerun `make check` (or the targeted failing subset) after fixes until green or
   until remaining failures are confirmed pre-existing.
4. **Report**: pass/fail per area (ruff, mypy, pytest, flutter analyze, flutter test),
   what you fixed, what remains and why.

If `make` itself is unavailable or a tool is missing from PATH, report the exact error
instead of improvising alternate toolchains.
