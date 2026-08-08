---
description: Run Phase 5 - Coder implements docs/2_tech_spec.md into src/
---

Delegate to the `coder` subagent. Its task:
Read `docs/2_tech_spec.md` (the ONLY requirements input) and implement it under `src/`.
If the tech spec is wrong or infeasible, it HALTS and writes `docs/2_tech_spec_issues.md`.
It must never edit the spec docs, never read the test plan or interfaces, never write tests,
and never commit. Relay what it implemented and stop.
