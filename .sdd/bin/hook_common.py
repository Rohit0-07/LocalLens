"""Shared helpers for the SDD harness: lock manifest, state, audit log, secrets scan, lint.

Used by:
  - sdd.py            (the core CLI / orchestrator)
  - shell hook wrappers (Claude Code / Antigravity) via `sdd.py check-lock` etc.
  - the OpenCode plugin reads .sdd-locks.json directly (same schema, no import needed)

Everything here is stdlib-only and safe to import from any of the above.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(os.environ.get("SDD_ROOT", "")).resolve() if os.environ.get("SDD_ROOT") else Path(__file__).resolve().parents[2]

LOCKS_FILE = ROOT / ".sdd-locks.json"
STATE_FILE = ROOT / ".sdd/state.json"
LOGS_DIR = ROOT / "logs"
AUDIT_FILE = LOGS_DIR / "audit.jsonl"
DOCS_DIR = ROOT / "docs"

DEFAULT_LOOP_CAP = 5

# ---- Lock manifest -----------------------------------------------------------


def load_locks() -> dict:
    if not LOCKS_FILE.exists():
        return {"version": 1, "locks": {}}
    try:
        return json.loads(LOCKS_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return {"version": 1, "locks": {}}


def save_locks(locks: dict) -> None:
    LOCKS_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = LOCKS_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(locks, indent=2) + "\n")
    tmp.replace(LOCKS_FILE)  # atomic rename


def is_locked(rel_path: str) -> bool:
    locks = load_locks()
    entry = locks.get("locks", {}).get(rel_path)
    if not entry:
        return False
    # A lock with an active change_request is "unlocked for revision".
    if entry.get("change_request"):
        return False
    return True


def lock_path(rel_path: str, approved_by: str, chmod: bool = True) -> None:
    locks = load_locks()
    locks.setdefault("locks", {})[rel_path] = {
        "locked_at": now_iso(),
        "approved_by": approved_by,
        "change_request": None,
    }
    save_locks(locks)
    if chmod:
        target = ROOT / rel_path
        if target.exists():
            try:
                target.chmod(0o444)
            except OSError:
                pass


def unlock_path(rel_path: str, reason: str, chmod: bool = True) -> None:
    locks = load_locks()
    entry = locks.get("locks", {}).get(rel_path)
    if entry:
        entry["change_request"] = {"reason": reason, "requested_at": now_iso()}
    else:
        locks.setdefault("locks", {})[rel_path] = {
            "locked_at": None,
            "approved_by": None,
            "change_request": {"reason": reason, "requested_at": now_iso()},
        }
    save_locks(locks)
    if chmod:
        target = ROOT / rel_path
        if target.exists():
            try:
                target.chmod(0o644)
            except OSError:
                pass


def force_unlock_path(rel_path: str) -> None:
    """Human emergency escape hatch. Removes the lock entry entirely and restores write perms."""
    locks = load_locks()
    locks.setdefault("locks", {}).pop(rel_path, None)
    save_locks(locks)
    target = ROOT / rel_path
    if target.exists():
        try:
            target.chmod(0o644)
        except OSError:
            pass


# ---- State / pipeline -------------------------------------------------------

PHASE_ARTIFACTS = {
    "0_repo_index": "docs/0_repo_index.json",
    "1_spec": "docs/1_spec.md",
    "2_tech_spec": "docs/2_tech_spec.md",
    "3_test_plan": "docs/3_test_plan.md",
    "4_interfaces": "docs/4_interfaces.json",
    "5_code": "src/",
    "6_tests": "tests/",
    "7_run": None,
}

PHASE_AGENTS = {
    "0_repo_index": "indexer",
    "1_spec": "product-manager",
    "2_tech_spec": "architect",
    "3_test_plan": "qa-planner",
    "4_interfaces": "interface-bridge",
    "5_code": "coder",
    "6_tests": "test-engineer",
    "7_run": "runner",
}

# depends_on = the phases whose artifacts must be current before this phase runs.
PHASE_DEPENDS = {
    "0_repo_index": [],
    "1_spec": ["0_repo_index"],
    "2_tech_spec": ["1_spec", "0_repo_index"],
    "3_test_plan": ["1_spec"],
    "4_interfaces": ["2_tech_spec", "0_repo_index"],
    "5_code": ["2_tech_spec"],
    "6_tests": ["3_test_plan", "4_interfaces"],
    "7_run": ["5_code", "6_tests"],
}

# For a change to <target phase>, which phases must be re-run?
DOWNSTREAM = {}
for _p, _deps in PHASE_DEPENDS.items():
    for _d in _deps:
        DOWNSTREAM.setdefault(_d, []).append(_p)


def default_state() -> dict:
    return {
        "version": 1,
        "loop_cap": DEFAULT_LOOP_CAP,
        "loop_count": 0,
        "loop_open": False,
        "harness": None,
        "phases": {
            p: {"status": "pending", "updated_at": None, "depends_on": list(PHASE_DEPENDS[p])}
            for p in PHASE_DEPENDS
        },
        "invalidations": [],
        "escalations": [],
        "runs": {},
    }


def load_state() -> dict:
    if not STATE_FILE.exists():
        st = default_state()
        save_state(st)
        return st
    try:
        return json.loads(STATE_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return default_state()


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2) + "\n")
    tmp.replace(STATE_FILE)


def set_phase(state: dict, phase: str, status: str) -> None:
    state["phases"].setdefault(phase, {"status": "pending", "updated_at": None, "depends_on": []})
    state["phases"][phase]["status"] = status
    state["phases"][phase]["updated_at"] = now_iso()


def invalidate(state: dict, target: str, reason: str) -> list[str]:
    """Mark target and every transitive downstream phase 'stale'.

    Returns the list of invalidated phases, ordered most-downstream-first.
    """
    invalidated: list[str] = []
    seen: set[str] = set()
    stack = [target]
    while stack:
        p = stack.pop()
        for child in DOWNSTREAM.get(p, []):
            if child not in seen:
                seen.add(child)
                invalidated.append(child)
                stack.append(child)
    invalidated.sort(key=lambda p: int(p.split("_")[0]), reverse=True)
    for p in invalidated:
        if state["phases"][p].get("status") == "done":
            state["phases"][p]["status"] = "stale"
    state["invalidations"].append(
        {"target": target, "reason": reason, "at": now_iso(), "invalidated": list(invalidated)}
    )
    return invalidated


# ---- Audit log --------------------------------------------------------------

def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def audit(entry: dict) -> None:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    entry.setdefault("ts", now_iso())
    with AUDIT_FILE.open("a") as fh:
        fh.write(json.dumps(entry) + "\n")


def phase_for_agent(agent: str) -> str:
    for phase, ag in PHASE_AGENTS.items():
        if ag == agent:
            return phase
    return "unknown"


# ---- Secrets scan -----------------------------------------------------------

SECRET_PATTERNS = [
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),                     # AWS access key id
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b"),  # GitHub tokens
    re.compile(r"\b(sk|pk|rk)_[A-Za-z0-9]{20,}\b"),           # OpenAI-style keys
    re.compile(r"(?i)(api[_-]?key|secret|password|token)\s*[=:]\s*[\"']?[A-Za-z0-9_\-\.]{16,}"),
    re.compile(r"(?i)bearer\s+[A-Za-z0-9\-_\.]{20,}"),
]

ENTROPY_MIN = 4.0
ENTROPY_MIN_LEN = 20


def _shannon(text: str) -> float:
    if not text:
        return 0.0
    counts: dict[str, int] = {}
    for ch in text:
        counts[ch] = counts.get(ch, 0) + 1
    n = len(text)
    return -sum((c / n) * (c / n and __import__("math").log2(c / n)) for c in counts.values())


def scan_path(path: Path, findings: list[dict]) -> None:
    try:
        if path.stat().st_size > 1_000_000:
            return
        text = path.read_text(errors="replace")
    except OSError:
        return
    for lineno, line in enumerate(text.splitlines(), 1):
        for pat in SECRET_PATTERNS:
            m = pat.search(line)
            if m:
                findings.append(
                    {
                        "path": str(path.relative_to(ROOT)) if path != ROOT else str(path),
                        "line": lineno,
                        "pattern": pat.pattern,
                        "match": _redact(m.group(0)),
                    }
                )
                break
        # high-entropy token heuristic on quoted values
        m = re.search(r"[\"']([A-Za-z0-9_\-\.]{20,})[\"']", line)
        if m and _shannon(m.group(1)) >= ENTROPY_MIN:
            findings.append(
                {
                    "path": str(path.relative_to(ROOT)) if path != ROOT else str(path),
                    "line": lineno,
                    "pattern": "high-entropy",
                    "match": _redact(m.group(1)),
                }
            )


def _redact(s: str, keep: int = 4) -> str:
    if len(s) <= keep * 2:
        return "***"
    return s[:keep] + "…" * 3 + s[-keep:]


def staged_files() -> list[str]:
    """Files staged for commit if in a git repo, else []."""
    try:
        out = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "-z"],
            capture_output=True, text=True, check=True,
        ).stdout
        return [p for p in out.split("\0") if p]
    except (OSError, subprocess.CalledProcessError):
        return []


def run_secrets_scan(paths: list[str] | None = None, staged: bool = False) -> list[dict]:
    targets: list[Path] = []
    if staged:
        for rel in staged_files():
            targets.append(ROOT / rel)
    for p in paths or []:
        cand = ROOT / p
        if cand.is_dir():
            targets.extend(cand.rglob("*"))
        elif cand.exists():
            targets.append(cand)
    findings: list[dict] = []
    for t in targets:
        if t.is_file() and not _is_binary(t):
            scan_path(t, findings)
    return findings


def _is_binary(path: Path) -> bool:
    try:
        with path.open("rb") as fh:
            return b"\x00" in fh.read(1024)
    except OSError:
        return True


# ---- Lint -------------------------------------------------------------------

def run_lint(state: dict | None = None) -> dict:
    """Run repo linters. Returns {'ok': bool, 'commands': [{cmd, exit, output}]}.

    Defaults for a Python repo; extend via .sdd/config.json {"lint": [commands...]}.
    """
    cfg = _load_sdd_config()
    commands = cfg.get("lint") or [
        ["python3", "-m", "compileall", "-q", "-f", "src", "tests"],
        ["python3", "-m", "ruff", "check", "src", "tests"],
        ["python3", "-m", "pytest", "--collect-only", "-q", "tests"],
    ]
    results = []
    for cmd in commands:
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT, timeout=180)
        except (OSError, subprocess.TimeoutExpired) as exc:
            results.append({"cmd": " ".join(cmd), "exit": -1, "output": str(exc)})
            continue
        results.append({"cmd": " ".join(cmd), "exit": proc.returncode, "output": (proc.stdout + proc.stderr)[-4000:]})
    ok = all(r["exit"] == 0 for r in results)
    return {"ok": ok, "commands": results}


def _load_sdd_config() -> dict:
    cfg_file = ROOT / ".sdd/config.json"
    if cfg_file.exists():
        try:
            return json.loads(cfg_file.read_text())
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


# ---- Misc -------------------------------------------------------------------

def file_hash(path: Path) -> str:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()[:12]
    except OSError:
        return "missing"


def write_doc(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    p.chmod(0o644)
