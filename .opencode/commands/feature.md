---
description: Full feature loop — create ticket, implement under bounded scope, verify, report
---

Implement feature: `$ARGUMENTS`

Run the whole loop end to end:

1. **Ticket** — follow `/new-ticket`: produce `docs/tickets/<short-id>.md` from the
   template with real "Files to touch" and a runnable "Verify command". Show it and
   get user approval before writing any code.
2. **Implement** — follow `/start-task <id>` exactly: read only ticket-listed files,
   plan before editing (if non-trivial), smallest possible diff (AGENTS.md §5).
3. **Verify** — run the ticket's Verify command. Fix only what that run reveals.
4. **Report** — file → one line each, what you verified, deviations from the ticket.
5. Mark the ticket Status: Done.

Golden rules (AGENTS.md §5) apply throughout: stay inside the file list, no refactors,
no new dependencies without justification, note unrelated bugs without fixing them.
