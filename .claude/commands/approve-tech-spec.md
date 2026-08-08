---
description: Approve and lock docs/2_tech_spec.md (human gate)
---

Delegate to the `change-manager` subagent. Its task:
The user has approved `docs/2_tech_spec.md`. Run:

`python3 .sdd/bin/sdd.py approve tech-spec --approved-by user`

Then run `python3 .sdd/bin/sdd.py status` and report the file is locked and which phases are
now unblocked (5_code, 4_interfaces). It must not touch any file directly.
