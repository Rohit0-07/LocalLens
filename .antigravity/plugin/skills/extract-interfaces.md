---
name: extract-interfaces
description: Run SDD Phase 4. Delegates to the interface-bridge subagent to regenerate docs/4_interfaces.json via the sdd MCP extractor.
---

Invoke the `interface-bridge` subagent with this task:

Call the `sdd_extract_interfaces` MCP tool to regenerate `docs/4_interfaces.json`, then read it
and verify the no-function-bodies contract, and report the totals (signatures, types, raises,
side_effects). Never read `src/**` directly and never edit anything. Relay the report and stop.
