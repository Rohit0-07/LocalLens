---
description: Turn a description into a ticket file in docs/tickets/ from the template
---

Create a ticket for: `$ARGUMENTS`

1. **Understand before writing.** Read `docs/CODEBASE_MAP.md` and skim only the files
   needed to scope the work. If the description is ambiguous, ask up to 3 clarifying
   questions first.
2. **Write the ticket** at `docs/tickets/<short-id>.md` from
   `docs/tickets/_TEMPLATE.md`. Pick a short kebab-case id (e.g. `feed-pagination`).
   Fill every section for real:
   - "Files to touch" must list exact paths (verify they exist) plus the test files.
   - "Verify command" must be runnable as written (`make check` or a targeted subset).
   - Keep it minimal — one task per ticket; split large work into multiple tickets.
3. **Show the result** — print the full ticket content and stop. Do not start
   implementing (use `/start-task <id>` for that).

Follow AGENTS.md §4 (ticket is the contract) and §6 (conventions inform file choices).
