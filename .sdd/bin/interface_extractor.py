"""Phase 5 - Interface Extractor.

Parses the implementation's AST and emits docs/4_interfaces.json containing ONLY:

  - type / schema definitions (dataclasses, TypedDict, Protocol, Enum, TypeAlias)
  - class and function signatures (name, parameters, annotations, returns)
  - declared exceptions / error codes (raises clauses + docstring tags + sentinels)
  - side effects explicitly documented in docstrings / tech spec (e.g. "writes to
    orders table", "calls payment gateway")

FUNCTION/METHOD BODIES ARE STRIPPED ENTIRELY. They never appear in the output:
we walk the AST for signatures only and serialize annotations, never bodies.

Python (`ast`) is implemented. TypeScript/JavaScript support (ts-morph) is a
drop-in follow-up - ask if the repo gains TS sources.
"""

from __future__ import annotations

import ast
import re
import typing
from dataclasses import dataclass, field, is_dataclass
from pathlib import Path

SOURCES = ("src", "app", "packages", "lib", ".")
SKIP_DIRS = {".git", ".sdd", ".opencode", ".claude", ".agents", ".antigravity", "__pycache__", "node_modules", "venv", ".venv", "docs", "logs", "tests", "dist", "build"}

_SIDE_EFFECT_KEYWORDS = re.compile(
    r"(?i)(writes?|inserts?|updates?|deletes?|appends?|persists?|calls?|invokes?|sends?|emails?|publishes?|enqueues?|posts?|commits?|flush(?:es)?|creates?)\s+(?:to\s+)?(?:the\s+)?([a-z0-9_.\s]{2,40}?)(?:\s|,|\.|$)"
)

_EXCEPTION_TAGS = re.compile(r"(?i)(?:raises?|raises\s+error|@raises|:raises|raises:\s*)\s*:?\s*([A-Za-z_][\w\.]*(?:\([^)]*\))?)")

_DOC_SIDE_EFFECT_SECTION = re.compile(
    r"(?is)(?:side effects?|side-effect|effects?)\s*:?[:\-]?\s*(.{0,200})",  # noqa: B028
)


@dataclass
class Param:
    name: str
    annotation: str | None
    has_default: bool = False


@dataclass
class Signature:
    name: str
    kind: str  # function | method | classmethod | staticmethod | property
    params: list[Param] = field(default_factory=list)
    returns: str | None = None
    raises: list[str] = field(default_factory=list)
    side_effects: list[str] = field(default_factory=list)
    docstring_first_line: str = ""


@dataclass
class TypeDef:
    name: str
    kind: str  # dataclass | TypedDict | Protocol | Enum | TypeAlias | class
    fields: list[tuple[str, str | None]] = field(default_factory=list)
    bases: list[str] = field(default_factory=list)


def _ann(node) -> str | None:
    if node is None:
        return None
    try:
        return ast.unparse(node).replace("\n", " ")
    except Exception:
        return None


def _side_effects(doc: str | None) -> list[str]:
    if not doc:
        return []
    found: list[str] = []
    for m in _SIDE_EFFECT_KEYWORDS.finditer(doc):
        action, target = m.group(1).lower(), m.group(2).strip()
        if len(target) >= 2 and "function" not in target.lower():
            found.append(f"{action} {target}")
    for m in _DOC_SIDE_EFFECT_SECTION.finditer(doc):
        chunk = m.group(1).strip()
        if chunk and not chunk.isspace():
            found.append(chunk[:120])
    # dedupe, keep order
    seen: set[str] = set()
    out: list[str] = []
    for s in found:
        if s not in seen:
            seen.add(s)
            out.append(s)
    return out


def _raises(doc: str | None, node_raises: list[str]) -> list[str]:
    out = list(node_raises)
    if doc:
        for m in _EXCEPTION_TAGS.finditer(doc):
            ex = m.group(1).strip()
            if ex and ex not in out:
                out.append(ex)
    return out


def _doc_first(doc: str | None) -> str:
    return doc.strip().split("\n")[0][:140] if doc and doc.strip() else ""


def _extract_signatures(tree: ast.Module) -> list[Signature]:
    sigs: list[Signature] = []
    for node in tree.body:
        if isinstance(node, ast.FunctionDef):
            doc = ast.get_docstring(node)
            raises = [ast.unparse(r) for r in node.raises] if hasattr(node, "raises") else []
            raises += [t.exception for t in _raises_clauses(node)]
            sigs.append(
                Signature(
                    name=node.name,
                    kind="function",
                    params=[Param(p.arg, _ann(p.annotation), p.default is not None) for p in node.args.args],
                    returns=_ann(node.returns),
                    raises=raises,
                    side_effects=_side_effects(doc),
                    docstring_first_line=_doc_first(doc),
                )
            )
    return sigs


def _raises_clauses(node) -> list:
    out = []
    for child in ast.walk(node):
        if isinstance(child, ast.Raise) and isinstance(child.exc, ast.Call) and isinstance(child.exc.func, ast.Name):
            out.append({"exception": child.exc.func.id})
    return out


def _extract_class(node: ast.ClassDef) -> tuple[TypeDef, list[Signature]]:
    bases = [ast.unparse(b) for b in node.bases]
    decorators = {ast.unparse(d) for d in node.decorator_list}
    kind = "class"
    if "dataclasses.dataclass" in decorators or "dataclass" in decorators:
        kind = "dataclass"
    elif any(b == "Enum" for b in bases):
        kind = "Enum"
    elif any("TypedDict" in b for b in bases):
        kind = "TypedDict"
    elif any("Protocol" in b for b in bases):
        kind = "Protocol"

    td = TypeDef(name=node.name, kind=kind, bases=bases)
    sigs: list[Signature] = []
    for child in node.body:
        if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
            doc = ast.get_docstring(child)
            kind_of = "method"
            if any("staticmethod" in ast.unparse(d) for d in child.decorator_list):
                kind_of = "staticmethod"
            elif any("classmethod" in ast.unparse(d) for d in child.decorator_list):
                kind_of = "classmethod"
            elif any("property" in ast.unparse(d) for d in child.decorator_list):
                kind_of = "property"
            raises = [t.exception for t in _raises_clauses(child)] + _raises(doc, [])
            sigs.append(
                Signature(
                    name=child.name,
                    kind=kind_of,
                    params=[Param(p.arg, _ann(p.annotation), p.default is not None) for p in child.args.args if p.arg != "self" and p.arg != "cls"],
                    returns=_ann(child.returns),
                    raises=raises,
                    side_effects=_side_effects(doc),
                    docstring_first_line=_doc_first(doc),
                )
            )
        elif isinstance(child, ast.Assign):
            for t in child.targets:
                if isinstance(t, ast.Name):
                    td.fields.append((t.id, _ann(child.annotation) if isinstance(child, ast.AnnAssign) else None))
        elif isinstance(child, ast.AnnAssign) and isinstance(child.target, ast.Name):
            td.fields.append((child.target.id, _ann(child.annotation)))
    return td, sigs


def extract_interfaces(root: Path) -> dict:
    """Root output JSON: signatures, types, exceptions, side effects - no bodies."""
    modules: list[dict] = []
    total_sigs = 0
    total_types = 0
    total_side_effects = 0
    total_raises = 0

    sources = [root / s for s in SOURCES if (root / s).is_dir()] or [root]
    for base in sources:
        for path in sorted(base.rglob("*.py")):
            if any(part in SKIP_DIRS for part in path.parts):
                continue
            try:
                text = path.read_text(errors="replace")
                tree = ast.parse(text)
            except (OSError, SyntaxError):
                continue
            sigs: list[Signature] = []
            types: list[TypeDef] = []
            for node in tree.body:
                if isinstance(node, ast.ClassDef):
                    td, class_sigs = _extract_class(node)
                    types.append(td)
                    sigs.extend(class_sigs)
                elif isinstance(node, ast.FunctionDef):
                    # handled by _extract_signatures below; skip duplicates
                    pass
            for node in tree.body:
                if isinstance(node, ast.FunctionDef):
                    doc = ast.get_docstring(node)
                    raises = [t.exception for t in _raises_clauses(node)] + _raises(doc, [])
                    sigs.append(
                        Signature(
                            name=node.name, kind="function",
                            params=[Param(p.arg, _ann(p.annotation), p.default is not None) for p in node.args.args],
                            returns=_ann(node.returns), raises=raises,
                            side_effects=_side_effects(doc), docstring_first_line=_doc_first(doc),
                        )
                    )
            total_sigs += len(sigs)
            total_types += len(types)
            for s in sigs:
                total_side_effects += len(s.side_effects)
                total_raises += len(s.raises)
            modules.append(
                {
                    "path": path.relative_to(root).as_posix(),
                    "signatures": [
                        {
                            "name": s.name,
                            "kind": s.kind,
                            "params": [{"name": p.name, "annotation": p.annotation, "has_default": p.has_default} for p in s.params],
                            "returns": s.returns,
                            "raises": s.raises,
                            "side_effects": s.side_effects,
                            "summary": s.docstring_first_line,
                        }
                        for s in sigs
                    ],
                    "types": [
                        {
                            "name": t.name,
                            "kind": t.kind,
                            "bases": t.bases,
                            "fields": [{"name": f[0], "annotation": f[1]} for f in t.fields],
                        }
                        for t in types
                    ],
                }
            )

    return {
        "schema_version": 1,
        "language": "python",
        "note": "function/method bodies are never included; signatures, types, exceptions and documented side effects only",
        "modules": modules,
        "totals": {
            "modules": len(modules),
            "signatures": total_sigs,
            "types": total_types,
            "raises": total_raises,
            "side_effects": total_side_effects,
        },
    }


if __name__ == "__main__":
    import json
    import sys

    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    print(json.dumps(extract_interfaces(root), indent=2)[:4000])
