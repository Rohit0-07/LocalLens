## 2026-08-10T11:53:15Z

You are the Architect subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p4_architect_1`.

Your task is to execute P4 (Architect Tech Spec) of the F-14-FLAG Spec-Driven Development pipeline:
1. Read ONLY `/Users/rohit/Desktop/Python/LocalLens/docs/1_spec.md` and `/Users/rohit/Desktop/Python/LocalLens/docs/0_repo_index.json`. (You are isolated to these two files only; do NOT access backend/app or app/lib source files directly).
2. Generate `/Users/rohit/Desktop/Python/LocalLens/docs/2_tech_spec.md` detailing:
   - System Architecture & Component Interactions (Backend FastAPI + SQLAlchemy + Frontend Flutter + Riverpod + Hive).
   - Data Layer Specification:
     * DB Tables: `flags` (columns: `id`, `issue_id`, `reporter_id`, `anon_id`, `category`, `details`, `created_at`; unique indexes: `(issue_id, reporter_id)`, `(issue_id, anon_id)`), `moderation_audits` (columns: `id`, `issue_id`, `action`, `reason`, `moderated_by`, `created_at`).
     * Entity updates: `Issue` (add `is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)`, `flag_count: Mapped[int] = mapped_column(Integer, default=0)`), `User` (add `is_banned: Mapped[bool] = mapped_column(Boolean, default=False)`).
   - Backend Module & Endpoint Specifications:
     * API Endpoints: `POST /api/v1/issues/{id}/flag`, `GET /api/v1/admin/flagged-issues`, `POST /api/v1/admin/issues/{id}/moderate`.
     * Routers & Dependencies: `backend/app/features/issues/router.py` (or `backend/app/features/flagging/router.py`), auth checks via `deps.CurrentUser` (GuestGuard 403 `guest_restricted`, Admin 403 `admin_required`).
     * Services & Rate Limiting: `backend/app/features/issues/service.py` (or `flagging/service.py`) integrating `SlidingWindowRateLimiter(max_requests=5, window_seconds=600)`.
     * Schemas: `FlagCreate`, `FlagOut`, `FlaggedIssueItem`, `FlaggedQueueResponse`, `ModerationActionRequest`, `ModerationResultOut`.
   - Frontend UI & State Management Specifications:
     * Widgets & Key Bindings:
       - `IssueCard` overflow menu button `Key('issueCardOverflow_<id>')` & popup option `Key('flagIssueOption_<id>')`.
       - `FlagIssueDialog` widget (`Key('flagIssueDialog')`, `Key('flagCategorySelect')`, `Key('flagDetailsInput')`, `Key('submitFlagButton')`).
       - `AdminFlaggedQueueScreen` widget (`Key('adminQueueFilterSelect')`, `Key('moderateAction_<id>')`).
       - `GuestGuard` interceptor logic for guest users.
     * Riverpod Providers: `flagIssueNotifierProvider`, `adminFlaggedQueueProvider`.
     * Storage & Routes: `LocalStore` box `'flagged_issues'` (key `'user_flagged_issue_ids'`), `RoutePaths.adminFlaggedQueue`.
   - Exhaustive List of Files to Create and Modify:
     * Backend files to modify/create (models, schemas, service, router, api/router.py).
     * Frontend files to modify/create (dialog, providers, screen, card, router, local_store).
3. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p4_architect_1/handoff.md`.
4. Send a message to parent with completion status and path to handoff.md.
