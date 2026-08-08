# SDD Harness — Workspace Rules (Claude Code)

This repository runs a strict, auditable Spec-Driven Development pipeline. Enforcement is
MECHANICAL: `.claude/settings.json` hooks + permission rules, the subagent tool allowlists in
`.claude/agents/`, OS chmod, and the CLI `.sdd/bin/sdd.py`. Treat the rules below as intent;
the enforcement lives in the files named above.

## Pipeline (phases)

| Phase | Agent | Input (only these) | Output |
|------|-------|--------------------|--------|
| 0 | indexer | — (script walks repo) | `docs/0_repo_index.json` |
| 1 | product-manager | raw idea | `docs/1_spec.md` |
| 2 | architect | `docs/1_spec.md`, `docs/0_repo_index.json` | `docs/2_tech_spec.md` |
| 3 | qa-planner | `docs/1_spec.md` ONLY | `docs/3_test_plan.md` |
| 4 | interface-bridge | source via extractor only | `docs/4_interfaces.json` |
| 5 | coder | `docs/2_tech_spec.md` ONLY | `src/**` |
| 6 | test-engineer | `docs/3_test_plan.md`, `docs/4_interfaces.json` ONLY | `tests/**` |
| 7 | runner | — | full test run + `.sdd/runs/latest/failures.json` |
| 8 | change-manager | — | lock/unlock via CLI only |

## Gates & locks

- `docs/1_spec.md` and `docs/2_tech_spec.md` are locked via `sdd.py approve` (chmod 444 +
  `.sdd-locks.json` entry). A `PreToolUse` hook rejects writes to locked files for any agent.
- `/approve-spec`, `/approve-tech-spec`, `/request-change` are the ONLY paths to
  lock/unlock. `/request-change` unlocks one file and marks downstream phases stale.
- The harness bookkeeping files (`.sdd-locks.json`, `.sdd/state.json`, `.sdd/**`, `logs/**`)
  are edit-denied to every agent via settings.json permissions + the PreToolUse hook.

## Mechanical isolation (do not attempt to bypass)

Claude Code has no per-subagent *path* rules, so isolation is two-layer:
1. Each subagent's `tools` allowlist (e.g. test-engineer has NO Bash — it cannot `cat src/`).
2. A `PreToolUse` hook on `Read|Grep|Glob` keyed on `agent_type` that blocks out-of-scope
   paths per agent. A denied read is the harness refusing, not a suggestion.

- test-engineer: read-scoped to `docs/3_test_plan.md`, `docs/4_interfaces.json`, `tests/**`.
  No Bash, no web, no subagents.
- qa-planner: read-scoped to `docs/1_spec.md` only. No Bash.
- architect / product-manager: cannot read `src/**`.
- coder: cannot read the test plan or interfaces; cannot edit docs; cannot commit/push.

## Audit

Every tool call is appended to `logs/audit.jsonl` by the `PostToolUse` hook (agent, phase,
tool, inputs, output summary). Never hand-edit `logs/**` or `.sdd/**`.

## Commands

`/generate-spec`, `/approve-spec`, `/architect`, `/approve-tech-spec`, `/code`,
`/extract-interfaces`, `/generate-tests`, `/run-loop`, `/request-change`.
