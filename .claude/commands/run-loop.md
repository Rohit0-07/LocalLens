---
description: Run the full SDD pipeline loop (respects approval gates + loop cap)
---

Run the SDD orchestrator and follow its output. Do NOT improvise the pipeline; the script is
the source of truth for phase ordering, gates, and the loop cap.

Run: `python3 .sdd/bin/sdd.py run-loop --harness claude`

Interpret the output:
- Stops with a GATE message (exit 3): do NOT advance. Tell the user which approval is needed
  (`/approve-spec` or `/approve-tech-spec`) and stop.
- Stops because dependencies are not done (exit 4): tell the user which phases must complete first.
- Escalates at the loop cap (exit 5): summarize the escalation from `logs/` and stop.
- Completes: report the final status and audit log location.

Relay the orchestrator's deterministic result; do not re-run phases by hand.
