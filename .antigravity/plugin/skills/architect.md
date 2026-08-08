---
name: architect
description: Run SDD Phase 2. Delegates to the architect subagent to produce docs/2_tech_spec.md.
---

Invoke the `architect` subagent with this task:

Read `docs/1_spec.md` (locked) and `docs/0_repo_index.json`, then write `docs/2_tech_spec.md`
(architecture, DB changes, file structure, API + error contracts, non-functional constraints).
If the spec is ambiguous or infeasible, write `docs/1_spec_questions.md` and stop. Never edit
`docs/1_spec.md` or read `src/**`. Relay what was written and stop.
