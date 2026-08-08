---
name: approve-spec
description: Approve and lock docs/1_spec.md (human gate). Runs the sdd CLI via change-manager.
---

Invoke the `change-manager` subagent with this task:

The user has approved `docs/1_spec.md`. Run:
`python3 .sdd/bin/sdd.py approve spec --approved-by user`
then `python3 .sdd/bin/sdd.py status` and report the file is locked and which phases are now
unblocked (2_tech_spec, 3_test_plan). It must not touch any file directly.
