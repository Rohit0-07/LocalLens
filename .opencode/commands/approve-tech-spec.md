---
description: Approve and lock docs/2_tech_spec.md (human gate)
agent: change-manager
---

The user has approved `docs/2_tech_spec.md`. Execute the approval gate:

Run: `python3 .sdd/bin/sdd.py approve tech-spec --approved-by user`

Then run `python3 .sdd/bin/sdd.py status` and report:
- the file is locked (chmod 444 + manifest entry)
- which phases are now unblocked (5_code, 4_interfaces)
Do not touch any file directly.
