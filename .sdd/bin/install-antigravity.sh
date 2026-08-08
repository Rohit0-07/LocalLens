#!/usr/bin/env bash
# Resolves <PROJECT_ROOT> placeholders to absolute paths in the Antigravity harness files.
# Antigravity requires absolute paths for hook commands and MCP server dirs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILES=(
  "$ROOT/.agents/hooks.json"
  "$ROOT/.antigravity/plugin/hooks.json"
  "$ROOT/.antigravity/plugin/mcp_config.json"
)

for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "skip: $f (missing)"
    continue
  fi
  if grep -q '<PROJECT_ROOT>' "$f"; then
    python3 - "$f" "$ROOT" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
root = sys.argv[2]
raw = path.read_text().replace("<PROJECT_ROOT>", root)
json.loads(raw)  # validate
path.write_text(raw)
print(f"wrote: {path}")
PY
  else
    echo "ok:   $f (no placeholder)"
  fi
done

echo
echo "Antigravity hooks ready. Next steps:"
echo "  1. (Optional) stage the plugin globally so agents/skills/commands work anywhere:"
echo "     agy plugin import $ROOT/.antigravity/plugin"
echo "  2. Verify the workspace hooks are loaded:"
echo "     agy inspect --settings | grep -A5 hooks"
echo "  3. Add the sdd MCP server from $ROOT/.antigravity/plugin/mcp_config.json"
echo "     (mcpServers.sdd) in the /mcp panel if it is not auto-discovered."
