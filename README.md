# LocalLens — Spec-Driven Development Harness

A strict, auditable, mechanically-enforced SDD pipeline that drives the same repository
through three AI coding harnesses: **OpenCode**, **Claude Code**, and **Antigravity (agy)**.

The pipeline is enforced by the harness's native mechanisms (permissions, hooks, subagent
tool allowlists, chmod + CLI exit codes) — NOT by prompt instructions. Each agent is an
isolated subagent with a read scope, a write scope, and no way around them.

## Pipeline

| Phase | Agent | Reads (only these) | Writes (only these) |
|------|-------|--------------------|---------------------|
| 0 | `indexer` | repo (via script) | `docs/0_repo_index.json` |
| 1 | `product-manager` | raw idea | `docs/1_spec.md` |
| 2 | `architect` | spec + repo index | `docs/2_tech_spec.md`, `docs/1_spec_questions.md` |
| 3 | `qa-planner` | spec ONLY | `docs/3_test_plan.md` |
| 4 | `interface-bridge` | extractor MCP only | `docs/4_interfaces.json` |
| 5 | `coder` | tech spec ONLY | `src/**`, `docs/2_tech_spec_issues.md` |
| 6 | `test-engineer` | plan + interfaces ONLY | `tests/**` |
| 7 | `runner` | tests | `.sdd/runs/latest/failures.json` |
| 8 | `change-manager` | CLI output | lock manifest via CLI only |

## Gates

- `docs/1_spec.md` and `docs/2_tech_spec.md` lock via `python3 .sdd/bin/sdd.py approve`
  (chmod 444 + `.sdd-locks.json`). Lock/unlock happens ONLY through the CLI — never by editing
  the manifest (the write hook blocks `.sdd/**` and `.sdd-locks.json` for every agent).
- `/request-change` (Claude/agy: `request-change` skill) unlocks the target file and marks every
  dependent downstream phase `stale` so it re-runs — never silently reused.
- The loop is capped at **5** (`sdd.py run-loop`, exit code 5); beyond that it escalates to the
  human. It is never unbounded.

## Mechanical enforcement matrix

| Rule | OpenCode | Claude Code | Antigravity |
|------|----------|-------------|-------------|
| Locked doc writes blocked | plugin `tool.execute.before` | `PreToolUse` hook | `PreToolUse` hook |
| Secrets blocked before commit/stage | plugin | hook + settings deny | hook + settings deny |
| `git commit/push` denied for agents | plugin | settings deny | hook deny |
| Audit log of every tool call | plugin `tool.execute.after` | `PostToolUse` hook | `PostToolUse` hook |
| Lint gate after coder write | plugin | hook | (reported; not enforced) |
| test-engineer read-denied `src/**` | native per-agent `permission` deny | hook + no-Bash subagent | hook (best-effort) + sandbox |
| architect/PM never read `src/**` | native deny | hook | hook |
| coder never reads test plan/interfaces | native deny | hook | hook |
| qa-planner reads spec only | native deny | hook | hook |
| loop cap / gate exit codes | `sdd.py run-loop` | same CLI | same CLI |

## Honest limitations

- **Claude Code**: no native per-agent *path* rules. Read isolation relies on the
  `PreToolUse` hook (which receives `agent_type`) — solid for `Read/Grep/Glob`, and the
  test-engineer has **no Bash tool**, so it cannot shell past it.
- **Antigravity**: the subagent tool toggles are coarse and the hook input does not reliably
  carry the invoking agent's identity. The read hook is best-effort. If you need hard
  test-engineer isolation under agy, run that phase in an OS sandbox (`sandbox-exec`) or a
  checkout with `src/` removed — see `.antigravity/` notes. The plugin is staged globally with
  `agy plugin import .antigravity/plugin`; `run-loop --harness antigravity` reports this gap.
- **OpenCode** is the reference implementation: native per-agent path rules + plugin API.

## Audit

Every tool call by any agent is appended to `logs/audit.jsonl` (harness, agent, phase, tool,
inputs, output summary, status). Phase start audits the exact input file list. Never
hand-edit `logs/**` or `.sdd/**`; they are bookkeeping.

## Commands

| Skill | OpenCode | Claude Code | Antigravity | Purpose |
|-------|----------|-------------|-------------|---------|
| generate-spec | `/generate-spec` | `/generate-spec` | `generate-spec` | Phase 1 |
| approve-spec | `/approve-spec` | `/approve-spec` | `approve-spec` | gate 1 |
| architect | `/architect` | `/architect` | `architect` | Phase 2 |
| approve-tech-spec | `/approve-tech-spec` | `/approve-tech-spec` | `approve-tech-spec` | gate 2 |
| code | `/code` | `/code` | `code` | Phase 5 → coder |
| extract-interfaces | `/extract-interfaces` | `/extract-interfaces` | `extract-interfaces` | Phase 4 → interface-bridge |
| generate-tests | `/generate-tests` | `/generate-tests` | `generate-tests` | Phase 6 → test-engineer |
| run-loop | `/run-loop` | `/run-loop` | `run-loop` | orchestrator |
| request-change | `/request-change` | `/request-change` | `request-change` | unlock + invalidate |
