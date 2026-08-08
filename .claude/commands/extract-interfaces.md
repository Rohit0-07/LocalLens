---
description: Run Phase 4 - Interface Bridge regenerates docs/4_interfaces.json
---

Delegate to the `interface-bridge` subagent. Its task:
Call the `mcp__sdd__sdd_extract_interfaces` MCP tool to regenerate `docs/4_interfaces.json`,
then read it and verify the no-function-bodies contract, and report the totals
(signatures, types, raises, side_effects). It must never read `src/` itself and never edit
anything. Relay the report and stop.
