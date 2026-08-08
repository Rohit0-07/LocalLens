---
description: Run Phase 6 - Test Engineer writes tests in tests/ (isolated from src/)
---

Delegate to the `test-engineer` subagent. Its task:
Read `docs/3_test_plan.md` and `docs/4_interfaces.json` (its ONLY allowed inputs), plus
existing `tests/` for style, and write test files under `tests/` covering the plan against the
interface contract. It is mechanically denied `src/`, the tech spec, and the shell by hook and
tool allowlist — that is by design; it derives tests from the contract only. Relay the test
files it created and stop.
