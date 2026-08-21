---
description: Run Phase 6 - Test Engineer writes tests in tests/ (isolated from src/)
agent: test-engineer
---

Run the SDD Phase 6 test generation phase. Per your system prompt:

1. Read `docs/3_test_plan.md` and `docs/4_interfaces.json` (your ONLY allowed inputs).
2. Read existing `tests/` files for house style.
3. Write test files under `tests/` covering the plan against the interface contract.

You are mechanically denied access to `src/`, the tech spec, the shell, and the web. That is
by design. Derive tests from the contract only. Do not attempt workarounds. Report the test
files you created and stop.
