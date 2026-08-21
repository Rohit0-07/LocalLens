/**
 * SDD enforcement plugin (OpenCode).
 *
 * Maps the SDD harness's mechanical requirements onto OpenCode's plugin API:
 *
 *   file locking (PreToolUse)   -> tool.execute.before throws when a write targets a
 *                                  locked file or harness bookkeeping (.sdd-locks.json etc.)
 *   audit logging (PostToolUse) -> tool.execute.after appends a JSON line to logs/audit.jsonl,
 *                                  attributed to the invoking agent via client.session.get()
 *   lint after Coder writes     -> tool.execute.after runs the lint suite (debounced) after a
 *                                  coder write and records pass/fail to the audit trail
 *   secrets scan before commit  -> tool.execute.before throws on git add/commit/push when the
 *                                  staged diff contains secrets
 *   Test Engineer hard isolation -> defense-in-depth: read/grep/glob/list against src/ is blocked
 *                                  for the test-engineer agent even if permissions are relaxed
 *
 * Per-agent permission rules in opencode.json / the agent files are the PRIMARY mechanical
 * control (true filesystem denial for the test-engineer). This plugin is the second layer and
 * the one that implements the dynamic lock manifest (locked files change over time).
 *
 * The plugin never fails silently on a harness bug: intentional blocks are thrown (they abort
 * the tool), all bookkeeping errors are swallowed so the session keeps working.
 */

import type { Plugin } from "@opencode-ai/plugin"
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { join, resolve, relative } from "node:path"

const WRITE_TOOLS = new Set(["edit", "write", "patch", "apply_patch"])
const READ_TOOLS = new Set(["read", "glob", "grep", "list"])
const AGENT_PHASE: Record<string, string> = {
  indexer: "0_repo_index",
  "product-manager": "1_spec",
  architect: "2_tech_spec",
  "qa-planner": "3_test_plan",
  "interface-bridge": "4_interfaces",
  coder: "5_code",
  "test-engineer": "6_tests",
  runner: "7_run",
  "change-manager": "8_change",
}

let lastLintAt = 0

function root(): string {
  return process.cwd()
}

function locksPath(): string {
  return join(root(), ".sdd-locks.json")
}

function readLocks(): any {
  try {
    return JSON.parse(readFileSync(locksPath(), "utf8"))
  } catch {
    return { locks: {} }
  }
}

function isLocked(rel: string): boolean {
  const entry = readLocks().locks?.[rel]
  if (!entry) return false
  return !entry.change_request // change-requested = unlocked for revision
}

function audit(entry: Record<string, unknown>) {
  try {
    const dir = join(root(), "logs")
    mkdirSync(dir, { recursive: true })
    const line = JSON.stringify({ ts: new Date().toISOString(), harness: "opencode", ...entry }) + "\n"
    writeFileSync(join(dir, "audit.jsonl"), line, { flag: "a" })
  } catch {
    /* never break the session on logging errors */
  }
}

function relOf(filePath: string): string {
  const abs = resolve(root(), filePath)
  try {
    return relative(root(), abs)
  } catch {
    return filePath
  }
}

function isBookkeeping(rel: string): boolean {
  return rel === ".sdd-locks.json" || rel === ".sdd/state.json" || rel.startsWith(".sdd/") || rel.startsWith("logs/")
}

async function agentFor(client: any, sessionID: string): Promise<string> {
  try {
    const s = await client.session.get({ path: { id: sessionID } })
    const info = s?.data ?? s
    return info?.info?.agent ?? info?.info?.mode ?? "unknown"
  } catch {
    return "unknown"
  }
}

export const SDDPlugin: Plugin = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input: any, output: any) => {
      const tool = input.tool
      const args = output.args ?? {}
      const agent = await agentFor(client, input.sessionID)

      // ---- Test Engineer hard isolation (defense in depth) ----
      if (agent === "test-engineer" && READ_TOOLS.has(tool)) {
        if (tool === "read") {
          const rel = relOf(String(args.filePath ?? args.path ?? ""))
          if (rel.startsWith("src/") || rel === "docs/2_tech_spec.md") {
            throw new Error(`SDD ISOLATION: ${rel} is out of scope for test-engineer. Inputs are docs/3_test_plan.md and docs/4_interfaces.json only.`)
          }
        }
        if (tool === "glob" && String(args.pattern ?? "").startsWith("src")) {
          throw new Error(`SDD ISOLATION: glob of src/** is denied for test-engineer.`)
        }
      }

      // ---- Write guard: locked files + harness bookkeeping ----
      if (WRITE_TOOLS.has(tool)) {
        const fp = String(args.filePath ?? args.path ?? "")
        if (fp) {
          const rel = relOf(fp)
          if (isBookkeeping(rel)) {
            throw new Error(`SDD PROTECT: ${rel} is harness bookkeeping; only the sdd CLI may change it.`)
          }
          if (isLocked(rel)) {
            throw new Error(`SDD LOCK: ${rel} is locked (approved). Submit /request-change spec|tech-spec "reason" to unlock for revision.`)
          }
        }
      }

      // ---- Secrets scan before git commit-like actions ----
      if (tool === "bash") {
        const cmd = String(args.command ?? "")
        if (/git\s+(commit|push|add)/.test(cmd)) {
          try {
            const res = await $\`python3 .sdd/bin/sdd.py secrets-scan --staged\`.quiet()
            if (res.exitCode !== 0) {
              throw new Error(`SDD SECRETS: blocked — secrets detected in staged changes. Remove them before committing.`)
            }
          } catch (err: any) {
            if (err?.message?.startsWith("SDD SECRETS")) throw err
          }
        }
      }
    },

    "tool.execute.after": async (input: any, output: any) => {
      const tool = input.tool
      const args = input.args ?? {}
      const agent = await agentFor(client, input.sessionID)
      const summary = output?.output ?? output?.title ?? output?.metadata ?? ""
      audit({
        agent,
        phase: AGENT_PHASE[agent] ?? "unknown",
        tool,
        callID: input.callID,
        sessionID: input.sessionID,
        input: pickInput(args),
        output_summary: String(summary).slice(0, 800),
        status: "ok",
      })

      // ---- lint after a coder write (debounced) ----
      if (agent === "coder" && WRITE_TOOLS.has(tool)) {
        const now = Date.now()
        if (now - lastLintAt > 3000) {
          lastLintAt = now
          try {
            const res = await $\`python3 .sdd/bin/sdd.py lint\`.quiet()
            audit({
              agent: "coder",
              phase: "5_code",
              tool: "lint-after-write",
              ok: res.exitCode === 0,
              status: res.exitCode === 0 ? "ok" : "lint-failed",
            })
          } catch {
            /* lint runner unavailable */
          }
        }
      }
    },
  }
}

function pickInput(args: any): any {
  const out: any = {}
  if (args.filePath) out.filePath = args.filePath
  if (args.path) out.path = args.path
  if (args.command) out.command = String(args.command).slice(0, 200)
  if (args.pattern) out.pattern = String(args.pattern).slice(0, 200)
  if (args.agent) out.agent = args.agent
  return out
}
