---
description: Run Phase 4 - Interface Bridge regenerates docs/4_interfaces.json
agent: interface-bridge
---

Run the SDD Phase 4 interface extraction phase. Per your system prompt:

1. Run `python3 .sdd/bin/sdd.py extract-interfaces` (bash).
2. Read `docs/4_interfaces.json` and verify the no-function-bodies contract.
3. Report the totals (signatures, types, raises, side_effects).

Never read source files yourself. Never edit anything. Stop after reporting.
