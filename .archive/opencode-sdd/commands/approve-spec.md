---
description: Approve and lock docs/1_spec.md (human gate)
agent: change-manager
---

The user has approved `docs/1_spec.md`. Execute the approval gate:

Run: `python3 .sdd/bin/sdd.py approve spec --approved-by user`

Then run `python3 .sdd/bin/sdd.py status` and report:
- the file is locked (chmod 444 + manifest entry)
- which phases are now unblocked (2_tech_spec, 3_test_plan)
Do not touch any file directly.
