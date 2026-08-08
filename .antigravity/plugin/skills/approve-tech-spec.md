---
name: approve-tech-spec
description: Approve and lock docs/2_tech_spec.md (human gate). Runs the sdd CLI via change-manager.
---

Invoke the `change-manager` subagent with this task:

The user has approved `docs/2_tech_spec.md`. Run:
`python3 .sdd/bin/sdd.py approve tech-spec --approved-by user`
then `python3 .sdd/bin/sdd.py status` and report the file is locked and which phases are now
unblocked (5_code, 4_interfaces). It must not touch any file directly.
