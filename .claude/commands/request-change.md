---
description: Request a change to spec or tech-spec - unlocks it and invalidates downstream phases
argument-hint: "spec|tech-spec \"reason\""
---

Delegate to the `change-manager` subagent. Its task:
The user requests a change to a locked document.

Target: $1  (must be `spec` or `tech-spec`)
Reason: $ARGUMENTS

Run: `python3 .sdd/bin/sdd.py request-change $1 --reason "$ARGUMENTS"`

Then run `python3 .sdd/bin/sdd.py status` and report the file is unlocked and marked
change-requested, plus the list of invalidated (stale) downstream phases that will re-run on
the next /run-loop. It must not touch any file directly and must not revise the document
itself — the owning agent (Product Manager for spec, Architect for tech-spec) revises next.
