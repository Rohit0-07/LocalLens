#!/usr/bin/env python3
"""SDD harness core CLI.

Subcommands
  init                          create .sdd-locks.json + .sdd/state.json
  status [--json]               print pipeline + lock status
  check-lock <relpath>          exit 0 if not locked, 1 if locked (for hooks)
  index                         Phase 0: regenerate docs/0_repo_index.json
  extract-interfaces            Phase 5: regenerate docs/4_interfaces.json
  approve <spec|tech-spec>      human gate: lock the artifact + mark phase done
  request-change <spec|tech-spec> --reason <r>
                                unlock + cascade invalidation to downstream phases
  force-unlock <relpath>        emergency human escape hatch
  lock <relpath> --approved-by <who>   raw lock (chmod 444 + manifest)
  unlock <relpath> --reason <r>        raw unlock (chmod 644 + manifest)
  audit                         read one JSON line from stdin -> logs/audit.jsonl
  secrets-scan [paths...] [--staged]   exit 1 on findings
  lint                          run lint suite, write logs/lint-<ts>.json
  run-loop [--harness opencode] drive the pipeline headlessly, respecting gates + loop cap
  phase-prompt <phase>          print the exact input file list + prompt for a phase
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import hook_common as hc  # noqa: E402

V = hc


def cmd_init(args):
    V.load_state()
    V.save_locks(V.load_locks())
    V.LOGS_DIR.mkdir(parents=True, exist_ok=True)
    print(f"initialized state at {V.STATE_FILE.relative_to(V.ROOT)}")
    print(f"initialized locks at {V.LOCKS_FILE.relative_to(V.ROOT)}")


def cmd_status(args):
    state = V.load_state()
    locks = V.load_locks()
    out = []
    out.append("== Pipeline ==")
    for phase, info in state["phases"].items():
        out.append(f"  {phase:<13} {info['status']:<8} artifact={V.PHASE_ARTIFACTS[phase]}")
    out.append(f"loop_count={state.get('loop_count')} / cap={state.get('loop_cap')}")
    out.append("== Locks ==")
    for rel, entry in locks.get("locks", {}).items():
        cr = " [CHANGE-REQUESTED]" if entry.get("change_request") else ""
        who = entry.get("approved_by") or "-"
        out.append(f"  {rel}  approved_by={who}{cr}")
    if state.get("invalidations"):
        out.append("== Recent invalidations ==")
        for inv in state["invalidations"][-5:]:
            out.append(f"  {inv['at']} change->{inv['target']}: {inv['reason']} -> {inv['invalidated']}")
    if args.json:
        print(json.dumps({"state": state, "locks": locks}, indent=2))
    else:
        print("\n".join(out))


def cmd_check_lock(args):
    sys.exit(1 if V.is_locked(args.path) else 0)


def cmd_index(args):
    state = V.load_state()
    if state["phases"]["1_spec"]["status"] == "done":
        print("error: docs/1_spec.md is locked/approved; re-indexing is safe but will not change it.", file=sys.stderr)
    import repo_indexer
    report = repo_indexer.index_repo(V.ROOT)
    V.write_doc("docs/0_repo_index.json", json.dumps(report, indent=2))
    V.set_phase(state, "0_repo_index", "done")
    V.save_state(state)
    V.audit({"harness": "cli", "phase": "0_repo_index", "agent": "indexer", "tool": "sdd index", "status": "ok"})
    n_exports = sum(len(m.get("public_exports", [])) for m in report["modules"])
    print(f"wrote docs/0_repo_index.json ({report['module_count']} modules, {n_exports} public defs)")


def cmd_extract_interfaces(args):
    import interface_extractor
    report = interface_extractor.extract_interfaces(V.ROOT)
    V.write_doc("docs/4_interfaces.json", json.dumps(report, indent=2))
    state = V.load_state()
    V.set_phase(state, "4_interfaces", "done")
    V.save_state(state)
    V.audit({"harness": "cli", "phase": "4_interfaces", "agent": "interface-bridge", "tool": "sdd extract-interfaces", "status": "ok"})
    print(f"wrote docs/4_interfaces.json ({report['modules']} modules)")


def cmd_approve(args):
    target = args.target
    state = V.load_state()
    if target == "spec":
        rel, phase = "docs/1_spec.md", "1_spec"
    else:
        rel, phase = "docs/2_tech_spec.md", "2_tech_spec"
    path = V.ROOT / rel
    if not path.exists() or path.stat().st_size == 0:
        print(f"error: {rel} is missing or empty; nothing to approve.", file=sys.stderr)
        sys.exit(2)
    V.lock_path(rel, approved_by=args.approved_by)
    V.set_phase(state, phase, "done")
    V.save_state(state)
    V.audit({"harness": "cli", "phase": phase, "agent": "user", "tool": "approve", "target": rel, "status": "ok"})
    print(f"approved + locked {rel}")


def cmd_request_change(args):
    target = args.target
    if target == "spec":
        rel, phase = "docs/1_spec.md", "1_spec"
    else:
        rel, phase = "docs/2_tech_spec.md", "2_tech_spec"
    state = V.load_state()
    V.unlock_path(rel, reason=args.reason)
    invalidated = V.invalidate(state, phase, reason=args.reason)
    state["phases"][phase]["status"] = "pending"
    V.save_state(state)
    V.audit({"harness": "cli", "phase": phase, "agent": "user", "tool": "request-change", "target": rel, "reason": args.reason, "invalidated": invalidated, "status": "ok"})
    print(f"unlocked {rel}")
    print(f"invalidated phases: {invalidated or 'none'}")
    if args.harness:
        print("downstream will be re-run on next run-loop")


def cmd_force_unlock(args):
    V.force_unlock_path(args.path)
    print(f"force-unlocked {args.path}")


def cmd_lock(args):
    V.lock_path(args.path, approved_by=args.approved_by)
    print(f"locked {args.path}")


def cmd_unlock(args):
    V.unlock_path(args.path, reason=args.reason)
    print(f"unlocked {args.path}")


def cmd_audit(args):
    entry = json.loads(sys.stdin.read() or "{}")
    V.audit(entry)
    print("logged")


def cmd_secrets_scan(args):
    findings = V.run_secrets_scan(paths=args.paths, staged=args.staged)
    if findings:
        for f in findings:
            print(f"{f['path']}:{f['line']}  {f['pattern']}  {f['match']}")
        print(f"secrets-scan: {len(findings)} finding(s)", file=sys.stderr)
        sys.exit(1)
    print("secrets-scan: clean")


def cmd_lint(args):
    result = V.run_lint()
    ts = V.now_iso().replace(":", "-")
    (V.LOGS_DIR / f"lint-{ts}.json").write_text(json.dumps(result, indent=2))
    for r in result["commands"]:
        flag = "OK " if r["exit"] == 0 else "FAIL"
        print(f"  [{flag}] {r['cmd']}")
        if r["exit"] != 0:
            print("    " + r["output"].strip()[:2000].replace("\n", "\n    "))
    sys.exit(0 if result["ok"] else 1)


# ---- Orchestration ----------------------------------------------------------

PHASE_PROMPTS = {
    "1_spec": (
        "You are the SDD Product Manager. Generate docs/1_spec.md from the idea in the audit "
        "prompt. Business language only: user stories, acceptance criteria, business rules, "
        "explicit out-of-scope items. ZERO implementation detail: no schemas, no endpoints, "
        "no library names, no file paths. Do NOT touch any other file."
    ),
    "2_tech_spec": (
        "You are the SDD Architect. Inputs (both given): locked docs/1_spec.md and "
        "docs/0_repo_index.json. Output docs/2_tech_spec.md: architecture, DB schema changes, "
        "file structure, API contracts, error/exception contracts, non-functional constraints. "
        "NEVER edit docs/1_spec.md. If you believe the spec needs clarification, write "
        "docs/1_spec_questions.md instead and stop."
    ),
    "3_test_plan": (
        "You are the SDD QA Planner. Input: locked docs/1_spec.md ONLY. Output docs/3_test_plan.md: "
        "scenarios, edge cases, expected behaviors in BUSINESS terms. No function names, no "
        "implementation awareness. You must not read source code or the tech spec."
    ),
    "4_interfaces": (
        "You are the SDD Interface Bridge. Run `sdd.py extract-interfaces` via bash; do NOT "
        "read source yourself. The result is written to docs/4_interfaces.json. Verify it "
        "contains only signatures, types, exceptions and documented side effects, with no "
        "function bodies."
    ),
    "5_code": (
        "You are the SDD Coder. Input: locked docs/2_tech_spec.md ONLY (given). Implement it. "
        "Never edit docs/1_spec.md or docs/2_tech_spec.md. If the tech spec is wrong or "
        "infeasible, HALT and write docs/2_tech_spec_issues.md; do not deviate silently. "
        "Do not write tests."
    ),
    "6_tests": (
        "You are the SDD Test Engineer. Inputs (both given): docs/3_test_plan.md and "
        "docs/4_interfaces.json ONLY. Write test files under tests/. You have NO access to "
        "src/ by design; write tests from the plan and the interface contract, never from "
        "implementation reading. Do not modify any docs/*.md files."
    ),
    "7_run": (
        "You are the SDD Runner. Run the FULL test suite (pytest) including pre-existing tests. "
        "On failure, write the structured failure details (assertion, expected/actual, stack "
        "trace, no editorializing) to .sdd/runs/latest/failures.json and stop. Do not fix code."
    ),
}

# which artifacts a phase may read as INPUT (mechanical input isolation)
PHASE_INPUTS = {
    "0_repo_index": [],
    "1_spec": [],
    "2_tech_spec": ["docs/1_spec.md", "docs/0_repo_index.json"],
    "3_test_plan": ["docs/1_spec.md"],
    "4_interfaces": ["docs/2_tech_spec.md", "docs/0_repo_index.json"],
    "5_code": ["docs/2_tech_spec.md"],
    "6_tests": ["docs/3_test_plan.md", "docs/4_interfaces.json"],
    "7_run": [],
}

GATES = {
    "1_spec": ("approved", "docs/1_spec.md is locked/approved"),
    "2_tech_spec": ("approved", "docs/2_tech_spec.md is locked/approved"),
}


def _opencode_invoke(agent: str, prompt: str) -> int:
    cmd = ["opencode", "run", "--agent", agent, "--auto", "-p", prompt]
    print(f"  $ {cmd[0]} run --agent {agent} --auto")
    return subprocess.run(cmd, cwd=V.ROOT).returncode


def cmd_run_loop(args):
    state = V.load_state()
    harness = args.harness or "opencode"
    state.setdefault("harness", harness)
    V.save_state(state)

    V.LOGS_DIR.mkdir(parents=True, exist_ok=True)
    (V.ROOT / ".sdd/runs").mkdir(parents=True, exist_ok=True)

    for phase in ["0_repo_index", "1_spec", "2_tech_spec", "3_test_plan", "4_interfaces", "5_code", "6_tests", "7_run"]:
        info = state["phases"][phase]
        if info["status"] == "done":
            continue

        # --- gates: never auto-advance past a required approval ---
        if phase in GATES:
            ok_status, msg = GATES[phase]
            if info["status"] != ok_status:
                print(f"\nGATE: {phase} requires approval ({msg}).")
                print(f"  run: /approve-{'spec' if phase == '1_spec' else 'tech-spec'}  then /run-loop")
                sys.exit(3)  # distinct exit code: blocked on a human gate

        # --- dependency check: refuse to run on stale/incomplete deps ---
        blocked = [d for d in info["depends_on"] if state["phases"][d]["status"] != "done"]
        if blocked:
            print(f"\nSKIP {phase}: dependencies not done -> {blocked}")
            sys.exit(4)

        # --- Phase 7 loop cap (mechanical, never unbounded) ---
        if phase == "7_run":
            failures = V.ROOT / ".sdd/runs/latest/failures.json"
            if failures.exists():
                if state.get("loop_count", 0) >= int(state.get("loop_cap", V.DEFAULT_LOOP_CAP)):
                    print("\nESCALATE: loop_count reached cap. Stopping. See logs/ for what was tried.")
                    state.setdefault("escalations", []).append(
                        {"at": V.now_iso(), "phase": "7_run", "loop_count": state["loop_count"], "loop_cap": state["loop_cap"]}
                    )
                    V.save_state(state)
                    sys.exit(5)
                state["loop_count"] = state["loop_count"] + 1
                V.save_state(state)

        # --- audit input contract (itemized) ---
        inputs = PHASE_INPUTS[phase]
        V.audit({"phase": phase, "agent": V.PHASE_AGENTS[phase], "tool": "run-loop", "harness": harness,
                 "inputs": inputs, "status": "in_progress", "loop_count": state.get("loop_count")})

        if phase in ("0_repo_index",):
            cmd_index(args)
            continue
        if phase == "4_interfaces":
            cmd_extract_interfaces(args)
            continue

        agent = V.PHASE_AGENTS[phase]
        prompt = PHASE_PROMPTS[phase]
        if phase == "1_spec":
            idea = args.idea or "(idea supplied by the user at the /generate-spec command)"
            prompt = prompt + f"\n\nRAW IDEA (do not repeat to the user): {idea}"
        print(f"\n== {phase} ({agent}) ==")
        code = _opencode_invoke(agent, prompt)
        if code != 0:
            print(f"phase {phase} exited {code}; stopping.")
            sys.exit(code)

        # verify the artifact appeared
        artifact = V.PHASE_ARTIFACTS[phase]
        if artifact:
            p = V.ROOT / artifact
            if not p.exists() or p.stat().st_size == 0:
                print(f"phase {phase} produced no artifact at {artifact}; stopping.")
                sys.exit(6)
        V.set_phase(state, phase, "done")
        V.save_state(state)
        V.audit({"phase": phase, "agent": agent, "tool": "run-loop", "harness": harness, "status": "done"})

    print("\nAll phases complete. No loop escalation required.")


def cmd_phase_prompt(args):
    phase = args.phase
    print("INPUT FILES (the ONLY context you may read):")
    for f in PHASE_INPUTS[phase]:
        print(f"  - {f}")
    print()
    print(PHASE_PROMPTS[phase])


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="sdd.py", description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init", help="create state + locks").set_defaults(func=cmd_init)

    ps = sub.add_parser("status", help="pipeline + lock status")
    ps.add_argument("--json", action="store_true")
    ps.set_defaults(func=cmd_status)

    pc = sub.add_parser("check-lock", help="exit 1 if path is locked")
    pc.add_argument("path")
    pc.set_defaults(func=cmd_check_lock)

    sub.add_parser("index", help="Phase 0").set_defaults(func=cmd_index)
    sub.add_parser("extract-interfaces", help="Phase 5").set_defaults(func=cmd_extract_interfaces)

    pa = sub.add_parser("approve", help="lock a phase artifact")
    pa.add_argument("target", choices=["spec", "tech-spec"])
    pa.add_argument("--approved-by", default="user")
    pa.set_defaults(func=cmd_approve)

    pr = sub.add_parser("request-change", help="unlock + cascade invalidation")
    pr.add_argument("target", choices=["spec", "tech-spec"])
    pr.add_argument("--reason", required=True)
    pr.add_argument("--harness", default=None)
    pr.set_defaults(func=cmd_request_change)

    pf = sub.add_parser("force-unlock", help="emergency escape hatch")
    pf.add_argument("path")
    pf.set_defaults(func=cmd_force_unlock)

    pl = sub.add_parser("lock", help="raw lock")
    pl.add_argument("path")
    pl.add_argument("--approved-by", default="user")
    pl.set_defaults(func=cmd_lock)

    pu = sub.add_parser("unlock", help="raw unlock")
    pu.add_argument("path")
    pu.add_argument("--reason", default="manual")
    pu.set_defaults(func=cmd_unlock)

    sub.add_parser("audit", help="log a JSON event from stdin").set_defaults(func=cmd_audit)

    pssec = sub.add_parser("secrets-scan", help="scan for secrets")
    pssec.add_argument("paths", nargs="*")
    pssec.add_argument("--staged", action="store_true")
    pssec.set_defaults(func=cmd_secrets_scan)

    sub.add_parser("lint", help="run lint suite").set_defaults(func=cmd_lint)

    prl = sub.add_parser("run-loop", help="drive the pipeline")
    prl.add_argument("--harness", choices=["opencode", "claude", "antigravity"], default="opencode")
    prl.add_argument("--idea", default=None)
    prl.set_defaults(func=cmd_run_loop)

    pp = sub.add_parser("phase-prompt", help="print phase input contract + prompt")
    pp.add_argument("phase", choices=list(PHASE_PROMPTS))
    pp.set_defaults(func=cmd_phase_prompt)

    return p


def main() -> int:
    args = build_parser().parse_args()
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
