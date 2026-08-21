# LocalLens — Agent Guide

Hyper-local civic issues platform. Monorepo: FastAPI backend (`backend/`, uv-managed,
async SQLAlchemy 2 + Alembic) and Flutter app (`app/`, Riverpod + go_router). Both sides
are feature-first: `backend/app/features/<name>/` mirrors `app/lib/features/<name>/`.

## 1. Start of every task

1. Read [`docs/CODEBASE_MAP.md`](docs/CODEBASE_MAP.md) — the one-page map of request
   flows, features (F-01…F-14), and tests. Then open **only** the files it or the
   ticket points to.
2. Setup/quickstart: [`README.md`](README.md). Per-area details: `backend/README.md`,
   `app/README.md`. Design docs: `LocalLens_App_Info.md`,
   `LocalLens_Feature_Checklist.md`; known issues: `bugs_remain.md`.
3. Verify with `make check` (ruff + mypy + pytest + flutter analyze + flutter test),
   or a targeted subset (`make lint`, `make test`). Full target list: `make help`.

## 2. Slash commands

Commands live in `.opencode/commands/`:

- `/start-task <id>` — work a ticket from `docs/tickets/` under bounded scope.
- `/new-ticket <desc>` — turn a description into a ticket file from the template.
- `/feature <desc>` — full loop: create ticket → implement → verify → report.
- `/bug <symptom>` — root-cause-first debugging flow.
- `/check` — run `make check` and triage failures.
- `/handoff` — compact the session for a teammate/next-session pickup.
- `/review [base]` — review the diff against a base branch before landing.

Skills shared by the whole team live in `.agents/skills/` (tdd, implement, code-review,
diagnosing-bugs, handoff, investigate, qa, review, health, …).

## 3. Tickets & DB snapshots

- Work is driven by **one ticket per task** in `docs/tickets/` (§4 below).
- Dev DB snapshots: `make sync-export` writes the team snapshot to
  `backend/data_migrations/sync.sql`; teammates apply it with `make sync-db`.

## 4. Ticket workflow

One ticket per task. The ticket is the contract.

1. **Ticket first.** Every non-trivial change gets a ticket at
   `docs/tickets/<short-id>.md` created from `docs/tickets/_TEMPLATE.md` (use
   `/new-ticket`). No ticket → no code changes.
2. **Read the contract.** The ticket's "Files to touch" bounds the diff; its
   "Verify command" defines done. If either looks wrong or incomplete, fix the
   ticket before coding.
3. **Plan then implement.** Non-trivial work: 2–4 line plan (exact files + how)
   approved before editing. Diff is the smallest that satisfies the ticket.
4. **Verify.** Run the ticket's Verify command (usually `make check` or the targeted
   test). Fix only what that run reveals.
5. **Report.** File → one line each, what you verified, deviations from the ticket.
6. Mark the ticket Status: Done when landed.

## 5. Golden rules

- Stay inside the ticket's file list; widen it only via an explicit ticket edit.
- Smallest possible diff; match existing conventions over personal preference.
- Working code ships as-is — no drive-by refactors, renames, or reformatting of
  untouched code.
- Add dependencies only after stating why an existing one cannot do the job.
- Unrelated bugs: note them in the report; fix only via their own ticket.

## 6. Conventions

### Backend (`backend/`)
- Feature layout: `app/features/<name>/{models.py,schemas.py,service.py,router.py}`;
  business logic in `service.py`, transport in `router.py`.
- Register new routers in `app/api/router.py` under `/api/v1`.
- Errors: raise `AppError` subclasses from `app/core/exceptions.py` → JSON envelope;
  dependencies come from `app/api/deps.py` (`SessionDep`, `SettingsDep`).
- Schema changes require an Alembic migration (`uv run alembic revision ...`);
  `make backend` runs migrations on start.
- ruff and mypy strict must pass clean.

### App (`app/`)
- Feature layout: `lib/features/<name>/{data,domain,presentation}` — repos/APIs in
  `data/`, models in `domain/`, screens/controllers/providers in `presentation/`.
- Routing: declare screens in `lib/core/router/app_router.dart` with `RoutePaths`
  constants; deep links use the `locallens://` scheme.
- State: Riverpod providers/controllers. Model changes → run `make gen` (freezed /
  json_serializable codegen) before building.
- New user-facing strings go through i18n (`core/l10n/`) for all 5 languages
  (en, hi, mr, ta, te). `flutter analyze` must pass clean.

### Tests
- Backend: mirror features — new code in `features/<name>` gets
  `tests/features/<name>/test_*.py`.
- App: `test/features/<name>/..._test.dart`, helpers in `test/helpers.dart`.
- Write tests only for code the task touches.
