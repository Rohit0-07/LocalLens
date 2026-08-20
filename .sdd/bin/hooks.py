#!/usr/bin/env python3
"""Shared stdin-JSON parsing for external harness hooks (Claude Code / Antigravity).

Hook payloads differ slightly per harness; this normalizes:
  - tool name (Claude Code: 'Edit'/'Write'/'Bash'; Antigravity: 'write_to_file' etc.)
  - the target file path (edit/write tools)
  - the bash command string (bash tools)
  - the invoking agent type (Claude Code: agent_type; Antigravity: best-effort)

Exit codes follow the Claude Code hook convention:
  0 = allow, 2 = block (stderr is the feedback shown to the model).
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get("SDD_ROOT", "")).resolve() if os.environ.get("SDD_ROOT") else Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import hook_common as hc  # noqa: E402

WRITE_TOOLS_CC = {"Edit", "Write", "NotebookEdit"}
WRITE_TOOLS_AGY = {"write_to_file", "replace_file_content", "multi_replace_file_content"}
ALL_TOOLS_CC = {"Edit", "Write", "Bash", "Read", "Grep", "Glob", "NotebookEdit"}


def read_payload() -> dict:
    raw = sys.stdin.read() or "{}"
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def tool_input(payload: dict) -> dict:
    return payload.get("tool_input") or payload.get("input") or {}


def tool_name(payload: dict) -> str:
    return payload.get("tool_name") or payload.get("tool") or ""


def agent_type(payload: dict) -> str:
    return payload.get("agent_type") or payload.get("agent") or payload.get("subagent") or "main"


def find_target_path(payload: dict) -> str | None:
    ti = tool_input(payload)
    for key in ("file_path", "path", "file", "filename", "target_path"):
        v = ti.get(key)
        if isinstance(v, str) and v:
            return v
    # multi_replace_file_content style: dict of paths -> content
    for key in ("file_contents", "replaces", "edits", "files"):
        v = ti.get(key)
        if isinstance(v, dict):
            for p in v:
                if isinstance(p, str):
                    return p
    # fallback: scan string values for an existing repo path
    for v in ti.values():
        if isinstance(v, str) and v.startswith(("/", "./")):
            cand = (ROOT / v).resolve()
            try:
                rel = cand.relative_to(ROOT.resolve())
            except ValueError:
                continue
            if cand.exists() or any(part in rel.parts for part in ("docs", "src", "tests", ".sdd")):
                return rel.as_posix()
    return None


def bash_command(payload: dict) -> str:
    return str(tool_input(payload).get("command") or "")


def relative(p: str) -> str:
    cand = (ROOT / p).resolve()
    try:
        return cand.relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return p


def protect_state_files(rel: str) -> tuple[bool, str]:
    """Agents may never edit the harness's own bookkeeping files directly."""
    for guarded in (".sdd-locks.json", ".sdd/state.json"):
        if rel == guarded or rel.startswith(".sdd/") or rel.startswith("logs/"):
            return True, f"SDD PROTECT: {rel} is harness bookkeeping; only the sdd CLI may change it."
    return False, ""


def handle_claude_pre_edit(payload: dict) -> int:
    target = find_target_path(payload)
    if not target:
        return 0
    rel = relative(target)
    blocked, msg = protect_state_files(rel)
    if blocked:
        print(msg, file=sys.stderr)
        return 2
    if hc.is_locked(rel):
        print(f"SDD LOCK: {rel} is locked (see .sdd-locks.json). Submit /request-change to unlock for revision.", file=sys.stderr)
        return 2
    agent = agent_type(payload)
    scope = EDIT_SCOPE.get(agent)
    if scope is not None and "*" not in scope:
        if not any(POSIX_FNM.fnmatchcase(rel, pat) or POSIX_FNM.fnmatchcase(rel, pat.rstrip("/") + "/**") for pat in scope):
            print(
                f"SDD ISOLATION: write to {rel} is out of scope for agent '{agent}'. "
                f"Allowed edit targets: {', '.join(scope)}",
                file=sys.stderr,
            )
            return 2
    return 0


def handle_claude_pre_bash(payload: dict) -> int:
    cmd = bash_command(payload)
    if re.search(r"\bgit\s+(commit|push|add)", cmd):
        findings = hc.run_secrets_scan(staged=True)
        if findings:
            for f in findings[:5]:
                print(f"SECRETS: {f['path']}:{f['line']} {f['pattern']} {f['match']}", file=sys.stderr)
            print("Blocked: secrets detected in staged changes. Remove them before committing.", file=sys.stderr)
            return 2
    if re.search(r"\bgit\s+(reset|checkout)\s+--", cmd) and any(
        hc.is_locked(p) for p in ("docs/1_spec.md", "docs/2_tech_spec.md")
    ):
        print("SDD LOCK: refusing destructive git reset on potentially locked docs.", file=sys.stderr)
        return 2
    return 0


# Per-agent read scopes for harnesses WITHOUT native per-agent path rules (Claude Code,
# Antigravity). '*' = everything else. Paths are repo-relative.
READ_SCOPE: dict[str, list[str]] = {
    "test-engineer": ["docs/3_test_plan.md", "docs/4_interfaces.json", "tests/**", "AGENTS.md", "CLAUDE.md"],
    "qa-planner": ["docs/1_spec.md", "AGENTS.md", "CLAUDE.md"],
    "coder": ["docs/2_tech_spec.md", "docs/0_repo_index.json", "docs/1_spec.md", "src/**", "AGENTS.md", "CLAUDE.md"],
    "architect": ["docs/1_spec.md", "docs/0_repo_index.json", "docs/2_tech_spec.md", "AGENTS.md", "CLAUDE.md"],
    "product-manager": ["docs/1_spec.md", "docs/0_repo_index.json", "AGENTS.md", "CLAUDE.md"],
    "interface-bridge": ["docs/2_tech_spec.md", "docs/4_interfaces.json", "docs/0_repo_index.json", "AGENTS.md", "CLAUDE.md"],
    "runner": ["tests/**", ".sdd/**", "logs/**", "AGENTS.md", "CLAUDE.md"],
    "indexer": ["docs/**", "AGENTS.md", "CLAUDE.md"],
    "change-manager": ["*"],
}

POSIX_FNM = __import__("fnmatch")

# Per-agent write scopes for harnesses without native per-agent path rules.
EDIT_SCOPE: dict[str, list[str]] = {
    "product-manager": ["docs/1_spec.md"],
    "architect": ["docs/2_tech_spec.md", "docs/1_spec_questions.md"],
    "qa-planner": ["docs/3_test_plan.md"],
    "interface-bridge": [],          # interfaces file is written by the extractor tool, not Edit
    "coder": ["src/**", "docs/2_tech_spec_issues.md"],
    "test-engineer": ["tests/**"],
    "runner": [],
    "indexer": [],
    "change-manager": [],            # manifest changes go through the CLI only
}


def read_allowed(agent: str, rel: str) -> bool:
    scope = READ_SCOPE.get(agent)
    if scope is None:
        return True
    if "*" in scope:
        return True
    return any(POSIX_FNM.fnmatchcase(rel, pat) or POSIX_FNM.fnmatchcase(rel, pat.rstrip("/") + "/**") for pat in scope)


def handle_claude_pre_read(payload: dict) -> int:
    agent = agent_type(payload)
    tname = tool_name(payload)
    if agent not in READ_SCOPE or tname not in ("Read", "Grep", "Glob", "List"):
        return 0
    target = find_target_path(payload)
    if not target:
        return 0
    rel = relative(target)
    if not read_allowed(agent, rel):
        print(
            f"SDD ISOLATION: {rel} is out of scope for agent '{agent}'. "
            f"Allowed: {', '.join(READ_SCOPE.get(agent, []))}",
            file=sys.stderr,
        )
        return 2
    return 0


def handle_claude_post(payload: dict) -> int:
    tname = tool_name(payload)
    agent = agent_type(payload)
    ti = tool_input(payload)
    resp = payload.get("tool_response") or {}
    entry = {
        "harness": "claude",
        "agent": agent,
        "phase": hc.phase_for_agent(agent),
        "tool": tname,
        "call_id": payload.get("call_id") or payload.get("session_id"),
        "session_id": payload.get("session_id"),
        "input": {k: v for k, v in ti.items() if k != "content" and k != "new_string"},
        "output_summary": (resp.get("output") or resp.get("title") or "")[:800] if isinstance(resp, dict) else str(resp)[:800],
        "status": "ok",
    }
    hc.audit(entry)

    # lint after a Coder write
    if agent == "coder" and tname in WRITE_TOOLS_CC:
        result = hc.run_lint()
        hc.audit(
            {
                "harness": "claude",
                "agent": "coder",
                "phase": "5_code",
                "tool": "lint-after-write",
                "ok": result["ok"],
                "status": "ok" if result["ok"] else "lint-failed",
            }
        )
        flag = "PASS" if result["ok"] else "FAIL"
        print(f"[SDD lint {flag}] after write to {find_target_path(payload)}", file=sys.stderr)
        for r in result["commands"]:
            if r["exit"] != 0:
                print(f"  {r['cmd']}: {r['output'][:1500]}", file=sys.stderr)
    return 0


def handle_agy_pre(payload: dict) -> int:
    tname = tool_name(payload)
    if tname in WRITE_TOOLS_AGY:
        target = find_target_path(payload)
        if target:
            rel = relative(target)
            blocked, msg = protect_state_files(rel)
            if blocked:
                print(msg, file=sys.stderr)
                return 2
            if hc.is_locked(rel):
                print(f"SDD LOCK: {rel} is locked. Use /request-change to unlock.", file=sys.stderr)
                return 2
    if tname == "run_command":
        cmd = bash_command(payload)
        if re.search(r"\bgit\s+(commit|push)\b", cmd):
            print("SDD ISOLATION: git commit/push is denied for all agents; the human commits.", file=sys.stderr)
            return 2
        if re.search(r"\bgit\s+add\b", cmd):
            findings = hc.run_secrets_scan(staged=True)
            if findings:
                for f in findings[:5]:
                    print(f"SECRETS: {f['path']}:{f['line']} {f['pattern']}", file=sys.stderr)
                print("Blocked: secrets detected in staged changes.", file=sys.stderr)
                return 2
    return 0


def handle_agy_post(payload: dict) -> int:
    entry = {
        "harness": "antigravity",
        "agent": agent_type(payload),
        "phase": hc.phase_for_agent(agent_type(payload)),
        "tool": tool_name(payload),
        "input": {k: v for k, v in tool_input(payload).items() if k not in ("content", "new_string")},
        "output_summary": str(payload.get("response") or payload.get("output") or "")[:800],
        "status": "ok",
    }
    hc.audit(entry)
    return 0


def main() -> int:
    payload = read_payload()
    handler = sys.argv[1] if len(sys.argv) > 1 else ""
    tname = tool_name(payload)
    if handler == "claude-pre-edit":
        return handle_claude_pre_edit(payload)
    if handler == "claude-pre-bash":
        return handle_claude_pre_bash(payload)
    if handler == "claude-pre-read":
        return handle_claude_pre_read(payload)
    if handler == "claude-post":
        return handle_claude_post(payload)
    if handler == "agy-pre":
        return handle_agy_pre(payload)
    if handler == "agy-post":
        return handle_agy_post(payload)
    return 0


if __name__ == "__main__":
    sys.exit(main())
