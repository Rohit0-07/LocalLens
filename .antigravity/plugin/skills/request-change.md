---
name: request-change
description: Request a change to spec or tech-spec - unlocks it and invalidates downstream phases.
argument-hint: spec|tech-spec "reason"
---

Invoke the `change-manager` subagent with this task:

The user requests a change to a locked document.
Target: $1 (must be `spec` or `tech-spec`)
Reason: $ARGUMENTS

Run: `python3 .sdd/bin/sdd.py request-change $1 --reason "$ARGUMENTS"`
then `python3 .sdd/bin/sdd.py status` and report the file is unlocked and marked
change-requested, plus the invalidated (stale) downstream phases that will re-run on the next
run-loop. It must not touch any file directly and must not revise the document itself — the
owning agent (product-manager for spec, architect for tech-spec) revises next.
