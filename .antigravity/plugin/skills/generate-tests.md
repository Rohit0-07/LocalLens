---
name: generate-tests
description: Run SDD Phase 6. Delegates to the test-engineer subagent (isolated from src/) to write tests in tests/.
---

Invoke the `test-engineer` subagent with this task:

Read `docs/3_test_plan.md` and `docs/4_interfaces.json` (its ONLY allowed inputs), plus existing
`tests/` for style, and write test files under `tests/` covering the plan against the interface
contract. It is mechanically denied `src/**`, the tech spec, and (typically) the shell by hook
and sandbox — that is by design; derive tests from the contract only. Relay the test files
created and stop.
