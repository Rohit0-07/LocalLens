---
description: Run Phase 2 - Architect produces docs/2_tech_spec.md
---

Delegate to the `architect` subagent. Its task:
Read `docs/1_spec.md` (locked) and `docs/0_repo_index.json`, then write `docs/2_tech_spec.md`
(architecture, DB changes, file structure, API + error contracts, non-functional constraints).
If the spec is ambiguous or infeasible, it writes `docs/1_spec_questions.md` and stops.
It must never edit `docs/1_spec.md` or read `src/`. Relay what it wrote and stop.
