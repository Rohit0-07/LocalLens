# Tickets — how this repo is worked

Every change to LocalLens starts from **one ticket** in this folder: `NNN-slug.md`.
The ticket is the contract between you and the AI — it stops the AI from exploring,
"fixing" unrelated things, or adding features nobody asked for.

## How to use

1. **Create a ticket** (you, the builder): copy `_TEMPLATE.md` → `001-short-slug.md`,
   fill in Goal, Files to touch, Acceptance criteria, Verify. Keep it 15–30 lines.
   Number sequentially. If it's a bug, paste the report in "Problem / expected behaviour".
2. **Run it** (the AI): read the ticket, read ONLY the scoped files + `docs/CODEBASE_MAP.md`,
   implement the smallest diff, run the Verify command, report back. Nothing outside
   the ticket's file list gets touched.
3. **Close it**: when the acceptance criteria are met and verified, mark the ticket `done`
   (you do this, or the AI proposes it and you approve).

## Rules

- One ticket = one problem = one small diff. Big tasks get split into several tickets.
- A ticket is never started without a Verify command. Unverified work = not done.
- If a ticket turns out to need files outside its list, **stop and edit the ticket** —
  don't silently widen scope.
- See `AGENTS.md` §4 (workflow) and §5 (golden rules) for the enforced behaviour.

## Ticket statuses

`open` → `in-progress` → `done` (or `blocked` — say why, don't work around it).

## Index

| # | Slug | Status | Title |
|---|------|--------|-------|
| 001 | likes-shows-verified-citizen | open | Like button swaps reporter name to "Verified citizen" |
| 002 | feed-ward-vs-global | open | Feed filters to ward on refresh; no global/ward toggle |
| 003 | rep-profile-shows-public-page | open | Representative's own profile shows generic citizen page |