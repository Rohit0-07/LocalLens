# SDD Harness — Workspace Rules (OpenCode)

This repository runs a strict, auditable Spec-Driven Development pipeline. The pipeline is
enforced MECHANICALLY (permissions, hooks, chmod, CLI exit codes), not by these words. Treat
every rule below as the *intent*; the enforcement lives in `opencode.json`, the agents under
`.opencode/agents/`, the plugin `.opencode/plugins/sdd.ts`, and the CLI `.sdd/bin/sdd.py`.

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

## Gates

- `docs/1_spec.md` and `docs/2_tech_spec.md` are locked via `sdd.py approve`. Locking:
  chmod 444 + entry in `.sdd-locks.json`. Locking/unlocking happens ONLY through
  `/approve-spec`, `/approve-tech-spec`, `/request-change` (never by editing the manifest).
- Changing a locked doc via `/request-change` unlocks that one file and marks every dependent
  downstream phase `stale` so it is re-run, never silently reused.

## Mechanical isolation (do not attempt to bypass)

- The **test-engineer** is filesystem-denied from `src/`, the tech spec, bash, grep, glob of
  src, web, and subagents. This is permission-layer, not a suggestion.
- The **architect** and **product-manager** cannot read `src/`.
- The **coder** cannot read the test plan or interfaces, cannot edit docs, cannot commit.
- The **qa-planner** can only read `docs/1_spec.md`.

## Audit

Every tool call by any agent is appended to `logs/audit.jsonl` (agent, phase, tool, inputs,
output summary). Never hand-edit or fake `logs/**` or `.sdd/**`; they are bookkeeping.

## Commands

`/generate-spec`, `/approve-spec`, `/architect`, `/approve-tech-spec`, `/code`,
`/extract-interfaces`, `/generate-tests`, `/run-loop`, `/request-change`.

Run `/run-loop` to drive the pipeline; it stops at gates for your approval.
