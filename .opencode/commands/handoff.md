---
description: Compact the session into a handoff doc for a teammate or next session
---

Produce a handoff for: `$ARGUMENTS` (defaults to "next session on this repo" if empty)

Follow the handoff skill (`.agents/skills/handoff/SKILL.md`). Capture:

1. **State** — branch (`git status`, dirty files), tickets touched in `docs/tickets/`
   and their Status fields, last verified state (`make check` result).
2. **Decisions** — what was chosen and why (ticket edits, convention calls, root
   causes found via `/bug`).
3. **Next steps** — ordered, concrete, each with its entry point (file path or ticket id).

Write it where the user asks; default to pasting it in chat so they can drop it into
the PR description or a message. Keep it compact — a teammate should resume in under
two minutes without re-reading the whole session.
