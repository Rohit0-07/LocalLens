---
description: Run the full SDD pipeline loop (respects approval gates + loop cap)
agent: build
---

Drive the SDD pipeline end to end by running the orchestrator script and following its output.
Do NOT improvise the pipeline yourself; the script is the source of truth for phase ordering,
approval gates, and the loop cap.

1. Run: `python3 .sdd/bin/sdd.py run-loop --harness opencode`
2. Interpret the output:
   - If it stops with a GATE message (exit 3), do NOT advance. Tell the user exactly which
     approval is needed (`/approve-spec` or `/approve-tech-spec`) and stop.
   - If it stops because dependencies are not done (exit 4), tell the user which phases must
     complete first.
   - If it escalates at the loop cap (exit 5), summarize the escalation from
     `logs/` and stop — the user must intervene.
   - If it completes, report the final `/run-loop` status and the audit log location.

Your job is to relay the orchestrator's deterministic result, not to re-run phases by hand.
