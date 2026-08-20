"""Phase 0 - Repo Indexer.

Walks the repository and produces a structured report (written to
docs/0_repo_index.json by sdd.py index):

  - top-level modules and a short natural-language summary per module
  - public exports (non-underscore top-level names) per module
  - module boundaries + import dependency graph
  - existing API endpoints (FastAPI/Flask/Django routing decorators)
  - DB schemas already in use (SQLAlchemy/Django models, raw SQL DDL)
  - dependency graph as adjacency list

Stdlib only. Heuristic-based; treats the repo as read-only.
"""

from __future__ import annotations

import ast
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

SOURCES = ("src", "app", "packages", "lib", ".")
SKIP_DIRS = {".git", ".sdd", ".opencode", ".claude", ".agents", ".antigravity", "__pycache__", "node_modules", "venv", ".venv", ".mypy_cache", ".ruff_cache", ".pytest_cache", "docs", "logs", "tests", "dist", "build"}
CODE_EXTS = {".py", ".ts", ".tsx", ".js", ".jsx"}

_ROUTE_PATTERNS = [
    (re.compile(r'@(?:app|router|api|bp|blueprint)\.(?:get|post|put|patch|delete|route)\(([^)]*)\)'), "fastapi/flask"),
    (re.compile(r'@(?:app|api|bp)\.[a-z_]+\s*\(["\']([^"\']+)["\']'), "fastapi/flask"),
    (re.compile(r'path\(["\']([^"\']+)["\']'), "django"),
]


@dataclass
class ModuleInfo:
    path: str
    language: str
    summary: str = ""
    public_exports: list[str] = field(default_factory=list)
    imports: list[str] = field(default_factory=list)
    endpoints: list[dict] = field(default_factory=list)
    db_models: list[str] = field(default_factory=list)
    db_schemas: list[str] = field(default_factory=list)


def _source_dirs(root: Path) -> list[Path]:
    dirs = []
    for s in SOURCES:
        if (root / s).is_dir() and s != ".":
            dirs.append(root / s)
    if not dirs:
        dirs = [root]
    return dirs


def _module_rel(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def _summary_for(module: ModuleInfo, text: str, code: str) -> str:
    """Short NL summary from module docstring + top-level names."""
    try:
        doc = ast.get_docstring(ast.parse(code)) if code and module.language == "python" else ""
    except Exception:
        doc = ""
    bits = []
    if doc:
        bits.append(doc.strip().split("\n")[0][:120])
    if module.public_exports:
        bits.append("provides: " + ", ".join(module.public_exports[:8]))
    if module.endpoints:
        bits.append(f"exposes {len(module.endpoints)} endpoint(s)")
    if module.db_models:
        bits.append(f"defines models: {', '.join(module.db_models[:5])}")
    return " | ".join(bits) if bits else "module with no obvious public surface"


def _analyze_python(path: Path) -> ModuleInfo:
    text = path.read_text(errors="replace")
    mod = ModuleInfo(path=path.as_posix(), language="python")
    try:
        tree = ast.parse(text)
    except SyntaxError:
        mod.summary = "unparseable python; skipped deep analysis"
        return mod

    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if not node.name.startswith("_"):
                mod.public_exports.append(node.name)
        elif isinstance(node, (ast.Assign, ast.AnnAssign)):
            targets = node.targets if isinstance(node, ast.Assign) else [node.target]
            for t in targets:
                if isinstance(t, ast.Name) and not t.id.startswith("_"):
                    mod.public_exports.append(t.id)

    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            for dec in node.decorator_list:
                src = ast.unparse(dec)
                if any(k in src for k in ("get", "post", "put", "patch", "delete", "route", "path", "url")):
                    m = re.search(r"[\"'](/[^\"']*)[\"']", src)
                    if m:
                        mod.endpoints.append({"method": src.split("(")[0], "path": m.group(1)})
        if isinstance(node, ast.ClassDef) and any(
            isinstance(b, ast.Name) and b.id in ("Model", "Base", "DeclarativeBase") for b in node.bases
        ):
            mod.db_models.append(node.name)
            if isinstance(node, ast.ClassDef):
                mod.db_models.append(node.name)

    mod.imports = []
    for node in tree.body:
        if isinstance(node, ast.Import):
            mod.imports.extend(a.name for a in node.names)
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                mod.imports.append(node.module)

    raw_ddl = re.findall(r"CREATE TABLE [^\n;]+", text, re.IGNORECASE)
    mod.db_schemas = [s.strip() for s in raw_ddl[:10]]

    mod.summary = _summary_for(mod, text, text)
    return mod


def _analyze_ts_js(path: Path) -> ModuleInfo:
    text = path.read_text(errors="replace")
    mod = ModuleInfo(path=path.as_posix(), language=path.suffix.lstrip("."))
    for name in re.findall(r"(?:export\s+(?:const|function|class|interface|type)\s+|export\s*\{[^}]*\b)([A-Za-z_$][\w$]*)", text):
        if name not in mod.public_exports:
            mod.public_exports.append(name)
    for pat, kind in _ROUTE_PATTERNS:
        for m in pat.finditer(text):
            for g in m.groups():
                if g and g.startswith("/"):
                    mod.endpoints.append({"framework": kind, "path": g.strip("\"'")})
    mod.imports = list(dict.fromkeys(re.findall(r"from\s+['\"]([^'\"]+)['\"]", text)))
    raw_ddl = re.findall(r"CREATE TABLE [^\n;]+", text, re.IGNORECASE)
    mod.db_schemas = [s.strip() for s in raw_ddl[:10]]
    mod.summary = _summary_for(mod, text, text)
    return mod


def index_repo(root: Path) -> dict:
    modules: list[ModuleInfo] = []
    sources = _source_dirs(root)
    for base in sources:
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix not in CODE_EXTS:
                continue
            if any(part in SKIP_DIRS for part in path.parts):
                continue
            if base == root and (".sdd" in path.parts or ".git" in path.parts):
                continue
            try:
                if path.suffix == ".py":
                    modules.append(_analyze_python(path))
                else:
                    modules.append(_analyze_ts_js(path))
            except OSError:
                continue

    adj: dict[str, list[str]] = {}
    for m in modules:
        adj.setdefault(m.path, [])
    for m in modules:
        deps = [d for d in m.imports if not d.startswith(".") and not d.startswith("__future__")]
        adj[m.path] = deps

    return {
        "schema_version": 1,
        "generated_at": None,  # filled by caller if needed
        "root": root.as_posix(),
        "languages": sorted({m.language for m in modules}),
        "modules": [
            {
                "path": m.path,
                "language": m.language,
                "summary": m.summary,
                "public_exports": m.public_exports,
                "endpoints": m.endpoints,
                "db_models": m.db_models,
                "db_schemas": m.db_schemas,
                "imports": m.imports,
            }
            for m in modules
        ],
        "module_count": len(modules),
        "dependency_graph": adj,
        "api_endpoints": [e for m in modules for e in m.endpoints],
        "db_schemas": list({s for m in modules for s in m.db_schemas}),
    }


if __name__ == "__main__":
    import sys
    from datetime import datetime, timezone

    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    rep = index_repo(root)
    rep["generated_at"] = datetime.now(timezone.utc).isoformat()
    print(json.dumps(rep, indent=2)[:4000])
