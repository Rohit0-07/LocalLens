---
description: Root-cause-first debugging flow for a reported bug or regression
---

Debug: `$ARGUMENTS`

Follow the diagnosing-bugs skill (`.agents/skills/diagnosing-bugs/SKILL.md`) and the
investigate skill (`.agents/skills/investigate/SKILL.md`) — whichever fits the symptom.

Iron rule: **no fix without a root cause.**

1. **Reproduce first.** Find the failing command/test/endpoint/screen before reading
   code. Start from `docs/CODEBASE_MAP.md` to locate the area; read only what the map
   points to.
2. **Investigate** — gather evidence (logs, tests, git history) and form hypotheses;
   verify each against evidence until exactly one survives.
3. **Root cause statement** — write one sentence: "X fails because Y." Get user
   agreement before editing anything.
4. **Fix minimally** at the root cause — no workaround patches, no drive-by fixes of
   unrelated symptoms (AGENTS.md §5). If a ticket exists, honor its file list; if not,
   propose the smallest file list and confirm.
5. **Verify** — the reproduction now passes, then `make check` (or targeted subset)
   stays clean. Add a regression test mirroring existing test layout (AGENTS.md §6).

Report: symptom → root cause → fix → verification.
