---
description: Start a scoped task from a ticket in docs/tickets/ (bounded-scope workflow)
---

You are about to work on ticket: `$ARGUMENTS`

This repo uses a **one-ticket-per-task** workflow. Follow it exactly (AGENTS.md §4):

1. **Read the ticket** — `docs/tickets/$ARGUMENTS.md` is the contract. If it doesn't
   exist, STOP and tell the user to create it (use `docs/tickets/_TEMPLATE.md`).
2. **Read `docs/CODEBASE_MAP.md`** for the feature map, then **read ONLY the files listed
   in the ticket's "Files to touch"**. Do not explore or open anything else.
3. **Plan** — if the task is non-trivial, write a 2–4 line plan (exact files + how you'll
   change them) and stop for approval before editing.
4. **Implement** — smallest possible diff. Match existing conventions (AGENTS.md §6).
5. **Verify** — run the ticket's Verify command (e.g. `make check` or the targeted test).
   Fix only what that run reveals.
6. **Report** — summarize: file → one line each, what you verified, any deviations.

Golden rules (AGENTS.md §5): never touch files outside the ticket's list, never refactor
working code, never add dependencies, never add unrequested features. If the ticket looks
wrong or is missing files you need, STOP and ask the user to fix the ticket — do not widen
scope yourself. If you spot unrelated bugs, note them in your report but do not fix them.