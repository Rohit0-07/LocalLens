---
description: Generate docs/1_spec.md from a raw idea
argument-hint: "<idea>"
---

Delegate to the `product-manager` subagent. Its task:
Generate the SDD Phase 1 product spec from this raw idea:

$ARGUMENTS

Per its system prompt: user stories, acceptance criteria, business rules, explicit
out-of-scope items. ZERO technical implementation detail. It may only write `docs/1_spec.md`.
After it returns, relay the doc's section list and stop. Do not advance past this phase; the
user must approve with /approve-spec before it locks.
