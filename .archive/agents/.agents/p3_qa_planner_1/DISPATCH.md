## 2026-08-10T11:51:51Z
You are the QA Planner subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p3_qa_planner_1`.

Your task is to execute P3 (QA Test Plan) of the F-14-FLAG Spec-Driven Development pipeline:
1. Read ONLY `/Users/rohit/Desktop/Python/LocalLens/docs/1_spec.md`. (You are isolated to `docs/1_spec.md` ONLY).
2. Generate `/Users/rohit/Desktop/Python/LocalLens/docs/3_test_plan.md` containing:
   - Test Plan Overview & Testing Strategy.
   - Backend Test Cases (`BE-FLAG-01` through `BE-FLAG-10`):
     * BE-FLAG-01: Valid flag submission returns 201 Created and FlagOut payload.
     * BE-FLAG-02: Duplicate flag submission returns 409 Conflict with code `duplicate_flag`.
     * BE-FLAG-03: Invalid category enum returns 400 Bad Request with code `validation_error`.
     * BE-FLAG-04: Details field exceeding 500 characters returns 400 Bad Request.
     * BE-FLAG-05: Rate limit exceeded (6th flag in 10 mins) returns 429 Too Many Requests with code `rate_limit_exceeded`.
     * BE-FLAG-06: Flagging non-existent issue ID returns 404 Not Found.
     * BE-FLAG-07: Admin retrieving flagged issues queue returns 200 OK with paginated list.
     * BE-FLAG-08: Admin queue status filtering (`pending`, `reviewed`, `dismissed`, `hidden`, `all`) works correctly.
     * BE-FLAG-09: Admin executing moderation action `hide_issue` updates issue status to hidden and logs audit.
     * BE-FLAG-10: Admin executing moderation action `ban_reporter` updates issue status and bans reporter account.
   - Frontend Widget & Integration Test Cases (`FE-FLAG-01` through `FE-FLAG-08`):
     * FE-FLAG-01: Tapping `issueCardOverflow_<id>` opens options menu containing `flagIssueOption_<id>`.
     * FE-FLAG-02: Tapping `flagIssueOption_<id>` as logged-in user opens `flagIssueDialog`.
     * FE-FLAG-03: `flagCategorySelect` dropdown enables selecting categories (`spam`, `abuse`, `pii`, `fake_report`, `other`).
     * FE-FLAG-04: Entering text into `flagDetailsInput` and tapping `submitFlagButton` calls `flagIssueNotifierProvider`.
     * FE-FLAG-05: Guest user tapping `flagIssueOption_<id>` triggers GuestGuard dialog modal.
     * FE-FLAG-06: LocalStore Hive cache `user_flagged_issue_ids` updates upon successful flag submission.
     * FE-FLAG-07: Admin queue screen renders items with `adminQueueFilterSelect` dropdown.
     * FE-FLAG-08: Tapping `moderateAction_<id>` executes moderation action and refreshes queue.
   - Security Test Cases (`SEC-FLAG-01` through `SEC-FLAG-05`):
     * SEC-FLAG-01: Guest user POST to `/api/v1/issues/{id}/flag` returns 403 Forbidden with `guest_restricted`.
     * SEC-FLAG-02: Regular non-admin user accessing `/api/v1/admin/*` returns 403 Forbidden with `admin_required`.
     * SEC-FLAG-03: Unauthenticated request (missing token) returns 401 Unauthorized.
     * SEC-FLAG-04: Rate limiting isolates counts per user ID and per anonymous session ID (`anon_id`).
     * SEC-FLAG-05: SQL injection attempt in `details` field or query params is safely handled via parameterization.
   - Coverage Matrix: Explicit table mapping AC-1 through AC-8 from `docs/1_spec.md` to specific test case IDs (100% AC coverage mandatory).
   - Explicit GAPs & Risks: Document out-of-scope items (AI/ML scanning, web admin portal, multi-tiered appeals) and untested edge cases.
3. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p3_qa_planner_1/handoff.md`.
4. Send a message to parent with completion status and path to handoff.md.
