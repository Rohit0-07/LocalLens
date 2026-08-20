#!/usr/bin/env python3
"""SDD MCP server (stdio).

Exposes:
  sdd_index_repo          -> run Phase 0, write docs/0_repo_index.json, return summary
  sdd_extract_interfaces  -> run Phase 5, write docs/4_interfaces.json, return summary
  sdd_pipeline_status     -> return state + locks (short JSON)
  sdd_check_locked <path> -> return {"locked": bool, "change_request": ...}

Minimal Model Context Protocol stdio server (JSON-RPC 2.0), stdlib only.
Register in the harness as a local MCP server pointing at this file.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(os.environ.get("SDD_ROOT", Path(__file__).resolve().parents[2])).resolve()
sys.path.insert(0, str(Path(__file__).resolve().parent))
import hook_common as hc  # noqa: E402

TOOLS = {
    "sdd_index_repo": {
        "description": "Run the SDD Phase 0 repo indexer. Walks the repository and writes docs/0_repo_index.json (public exports, module boundaries, endpoints, DB schemas, dependency graph, per-module summaries). Regenerates automatically; never hand-edit the output.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    "sdd_extract_interfaces": {
        "description": "Run the SDD Phase 5 interface extractor. Parses source AST and writes docs/4_interfaces.json with ONLY signatures/types/exceptions/documented side-effects; function bodies are stripped entirely.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    "sdd_pipeline_status": {
        "description": "Return the current SDD pipeline state and lock manifest (phase statuses, loop counter, invalidations).",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    "sdd_check_locked": {
        "description": "Return whether a repository-relative path is currently locked by the SDD lock manifest.",
        "inputSchema": {
            "type": "object",
            "properties": {"path": {"type": "string", "description": "repo-relative path, e.g. docs/1_spec.md"}},
            "required": ["path"],
            "additionalProperties": False,
        },
    },
}


def _result(any_val) -> dict:
    if isinstance(any_val, dict):
        return any_val
    return {"value": any_val}


def handle(method: str, params: dict) -> dict | None:
    if method == "initialize":
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "sdd", "version": "1.0.0"},
        }
    if method == "notifications/initialized":
        return {}
    if method == "ping":
        return {}
    if method == "tools/list":
        return {"tools": [{"name": n, **spec} for n, spec in TOOLS.items()]}
    if method == "tools/call":
        name = params.get("name")
        args = params.get("arguments", {}) or {}
        if name == "sdd_index_repo":
            import repo_indexer
            report = repo_indexer.index_repo(ROOT)
            hc.write_doc("docs/0_repo_index.json", json.dumps(report, indent=2))
            st = hc.load_state()
            hc.set_phase(st, "0_repo_index", "done")
            hc.save_state(st)
            return _result({"ok": True, "modules": report["module_count"], "written": "docs/0_repo_index.json"})
        if name == "sdd_extract_interfaces":
            import interface_extractor
            report = interface_extractor.extract_interfaces(ROOT)
            hc.write_doc("docs/4_interfaces.json", json.dumps(report, indent=2))
            st = hc.load_state()
            hc.set_phase(st, "4_interfaces", "done")
            hc.save_state(st)
            return _result({"ok": True, "totals": report["totals"], "written": "docs/4_interfaces.json"})
        if name == "sdd_pipeline_status":
            st = hc.load_state()
            locks = hc.load_locks()
            return _result(
                {
                    "phases": {p: i["status"] for p, i in st["phases"].items()},
                    "loop_count": st.get("loop_count"),
                    "loop_cap": st.get("loop_cap"),
                    "locks": {k: ("locked" if v.get("change_request") is None else "change-requested") for k, v in locks.get("locks", {}).items()},
                }
            )
        if name == "sdd_check_locked":
            p = args.get("path", "")
            return _result({"path": p, "locked": hc.is_locked(p), "entry": hc.load_locks().get("locks", {}).get(p)})
        raise ValueError(f"unknown tool {name}")
    if method == "prompts/list":
        return {"prompts": []}
    if method == "resources/list":
        return {"resources": []}
    raise ValueError(f"unknown method {method}")


def main() -> None:
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg_id = msg.get("id")
        try:
            result = handle(msg.get("method", ""), msg.get("params", {}) or {})
        except Exception as exc:  # JSON-RPC error
            resp = {"jsonrpc": "2.0", "id": msg_id, "error": {"code": -32000, "message": str(exc)}}
        else:
            resp = {"jsonrpc": "2.0", "id": msg_id}
            if msg.get("method", "").startswith("notifications/"):
                continue  # no response for notifications
            resp["result"] = result
        sys.stdout.write(json.dumps(resp) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
