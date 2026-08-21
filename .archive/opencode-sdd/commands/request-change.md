---
description: Request a change to spec or tech-spec - unlocks it and invalidates downstream phases
agent: change-manager
---

The user requests a change to a locked document.

Target: $1  (must be `spec` or `tech-spec`)
Reason: $ARGUMENTS

Run the change-request gate:
`python3 .sdd/bin/sdd.py request-change $1 --reason "$ARGUMENTS"`

Then run `python3 .sdd/bin/sdd.py status` and report:
- the file is unlocked (chmod 644) and marked change-requested
- the list of invalidated (stale) downstream phases that will be re-run on the next /run-loop
Do not touch any file directly, and do not revise the document yourself — the owning agent
(Product Manager for spec, Architect for tech-spec) will revise it next.
