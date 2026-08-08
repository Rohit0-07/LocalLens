---
description: Approve and lock docs/1_spec.md (human gate)
---

Delegate to the `change-manager` subagent. Its task:
The user has approved `docs/1_spec.md`. Run:

`python3 .sdd/bin/sdd.py approve spec --approved-by user`

Then run `python3 .sdd/bin/sdd.py status` and report the file is locked and which phases are
now unblocked (2_tech_spec, 3_test_plan). It must not touch any file directly.
