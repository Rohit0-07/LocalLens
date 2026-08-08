---
name: code
description: Run SDD Phase 5. Delegates to the coder subagent to implement docs/2_tech_spec.md into src/.
---

Invoke the `coder` subagent with this task:

Read `docs/2_tech_spec.md` (the ONLY requirements input) and implement it under `src/`.
If the tech spec is wrong or infeasible, HALT and write `docs/2_tech_spec_issues.md`.
Never edit the spec docs, never read the test plan or interfaces, never write tests, and never
commit. Relay what was implemented and stop.
