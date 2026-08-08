# SDD Harness Rules

This repository runs a strict, auditable Spec-Driven Development pipeline. Enforcement is
mechanical (hooks, permissions, CLI exit codes) — these rules describe the intent.

## Pipeline

| Phase | Agent | Input (only these) | Output |
|------|-------|--------------------|--------|
| 0 | indexer | script walks repo | `docs/0_repo_index.json` |
| 1 | product-manager | raw idea | `docs/1_spec.md` |
| 2 | architect | spec + repo index | `docs/2_tech_spec.md` |
| 3 | qa-planner | spec ONLY | `docs/3_test_plan.md` |
| 4 | interface-bridge | extractor only | `docs/4_interfaces.json` |
| 5 | coder | tech spec ONLY | `src/**` |
| 6 | test-engineer | plan + interfaces ONLY | `tests/**` |
| 7 | runner | — | full test run + failures |
| 8 | change-manager | — | lock/unlock via CLI only |

## Gates

- `docs/1_spec.md` and `docs/2_tech_spec.md` lock via `sdd.py approve` (chmod 444 + manifest).
  Lock/unlock only through the CLI (`/approve-spec`, `/approve-tech-spec`, `/request-change`).
- `/request-change` unlocks the target and marks downstream phases stale so they re-run.

## Isolation

- test-engineer is denied `src/**`, the tech spec, and (per subagent config) the shell.
- architect / product-manager never read `src/**`.
- coder never reads the test plan or interfaces, never writes docs, never commits.
- qa-planner reads `docs/1_spec.md` only.

Every tool call is appended to `logs/audit.jsonl`. Never hand-edit `logs/**` or `.sdd/**`.
