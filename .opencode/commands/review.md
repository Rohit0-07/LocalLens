---
description: Review the diff against a base branch before landing (default: main)
---

Review changes against base branch: `$ARGUMENTS` (default `main`)

Follow the code-review skill (`.agents/skills/code-review/SKILL.md`) and the review
skill (`.agents/skills/review/SKILL.md`) as applicable to the change.

1. **Establish the diff** — `git log --oneline <base>..HEAD` and
   `git diff <base>...HEAD`. If there are open tickets referenced by these commits,
   read them: they are the spec.
2. **Review along two axes**:
   - *Standards* — AGENTS.md §5/§6 conventions: feature layout, service vs router split,
     AppError usage, Riverpod patterns, i18n coverage, test mirroring.
   - *Spec* — does the diff deliver exactly what the ticket(s) asked, inside their
     "Files to touch" lists?
3. **Structural checks** — schema changes ship an Alembic migration; new routers are
   registered under `/api/v1`; new strings exist for all 5 languages; no secrets.
4. **Report** — findings ranked blocker / should-fix / nit, each with file:line and a
   suggested action. State explicitly what was checked and found clean. Do not edit
   code unless asked.
