## 2026-08-10T11:58:40Z

You are the Coder subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p7_coder_1`.

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MECHANICAL ISOLATION RULE:
You must read ONLY `/Users/rohit/Desktop/Python/LocalLens/docs/2_tech_spec.md` (+ existing codebase under `backend/app/` and `app/lib/` for conventions + P6 tests to make green). You are strictly DENIED access to `docs/3_test_plan.md` and `docs/4_interfaces.json`.

Your task is to execute P7 (Coder Implementation) of the F-14-FLAG Spec-Driven Development pipeline:

1. Implement Backend Features in `backend/app/`:
   - `backend/app/features/issues/models.py`:
     * Add `Flag` model (`id`, `issue_id`, `reporter_id`, `anon_id`, `category`, `details`, `created_at`; unique constraints on `(issue_id, reporter_id)` and `(issue_id, anon_id)`).
     * Add `ModerationAudit` model (`id`, `issue_id`, `action`, `reason`, `moderated_by`, `created_at`).
     * Add `is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)` and `flag_count: Mapped[int] = mapped_column(Integer, default=0)` to `Issue`.
   - `backend/app/features/auth/models.py`:
     * Add `is_banned: Mapped[bool] = mapped_column(Boolean, default=False)` to `User`.
   - `backend/app/features/issues/schemas.py`:
     * Add `FlagCategory`, `ModerationAction`, `FlaggedQueueStatusFilter`, `FlagCreate`, `FlagOut`, `FlaggedIssueItem`, `FlaggedQueueResponse`, `ModerationActionRequest`, `ModerationResultOut`.
   - `backend/app/features/issues/service.py`:
     * Instantiate `flag_rate_limiter = SlidingWindowRateLimiter(max_requests=5, window_seconds=600)`.
     * Implement `create_flag()`, `get_flagged_queue()`, and `moderate_issue()`.
     * Ensure guest check raises `AppError(status_code=403, error_code="guest_restricted")`, duplicate flag check raises `AppError(status_code=409, error_code="duplicate_flag")`, rate limit check raises `AppError(status_code=429, error_code="rate_limit_exceeded")`, non-admin check raises `AppError(status_code=403, error_code="admin_required")`.
   - `backend/app/features/issues/router.py`:
     * Register endpoints: `POST /api/v1/issues/{id}/flag`, `GET /api/v1/admin/flagged-issues`, `POST /api/v1/admin/issues/{id}/moderate`.

2. Implement Frontend Features in `app/lib/`:
   - `app/lib/features/issues/presentation/widgets/flag_issue_dialog.dart`:
     * Dialog with exact keys `Key('flagIssueDialog')`, `Key('flagCategorySelect')`, `Key('flagDetailsInput')`, `Key('submitFlagButton')`.
   - `app/lib/features/issues/presentation/widgets/issue_card.dart`:
     * Overflow menu button `Key('issueCardOverflow_<id>')` and option `Key('flagIssueOption_<id>')` launching `FlagIssueDialog`.
   - `app/lib/features/issues/presentation/providers/flag_issue_provider.dart`:
     * Riverpod `flagIssueNotifierProvider`.
   - `app/lib/features/admin/presentation/screens/admin_flagged_queue_screen.dart`:
     * Admin queue screen with `Key('adminQueueFilterSelect')` and `Key('moderateAction_<id>')`.
   - `app/lib/features/admin/presentation/providers/admin_flagged_queue_provider.dart`:
     * Riverpod `adminFlaggedQueueProvider`.
   - `app/lib/core/router/route_paths.dart` and `app/lib/core/router/app_router.dart`:
     * Add `RoutePaths.adminFlaggedQueue = '/admin/flagged-queue'`.
   - `app/lib/core/storage/local_store.dart`:
     * Manage Hive box `'flagged_issues'`, key `'user_flagged_issue_ids'`.

3. Verification:
   - Run tests: `pytest` in `backend/` and `flutter test` in `app/` to ensure all tests pass green.

4. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p7_coder_1/handoff.md`.
5. Send a message to parent with completion status and path to handoff.md.
