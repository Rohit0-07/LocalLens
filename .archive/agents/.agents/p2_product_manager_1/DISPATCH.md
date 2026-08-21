## 2026-08-10T11:50:50Z
You are the Product Manager subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p2_product_manager_1`.

Your task is to execute P2 (Product Manager Spec) of the F-14-FLAG Spec-Driven Development pipeline:
1. Read `/Users/rohit/Desktop/Python/LocalLens/LocalLens_Feature_Checklist.md` (specifically F-14-FLAG item) and `/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md`.
2. Generate `/Users/rohit/Desktop/Python/LocalLens/docs/1_spec.md` with:
   - Feature Title, Feature ID (`F-14-FLAG`), Overview, and Business Goals.
   - If/Then Acceptance Criteria (AC-1 to AC-N) structured strictly as Given/When/If/Then statements covering:
     * AC-1: Flagging an issue with valid category (`spam`, `abuse`, `pii`, `fake_report`, `other`) and optional details string.
     * AC-2: Duplicate flag guard (rejecting second flag attempt from same user or anon_id with HTTP 409 `duplicate_flag`).
     * AC-3: Rate limit guard (blocking >5 flags per 10 minutes per user/anon_id with HTTP 429 `rate_limit_exceeded`).
     * AC-4: Guest user protection (HTTP 403 `guest_restricted` on backend, app triggers GuestGuard modal with login prompt).
     * AC-5: Admin flagged issue queue retrieval (`GET /api/v1/admin/flagged-issues`) with pagination and status filtering (`pending`, `reviewed`, `dismissed`, `hidden`, `all`), non-admin rejected with HTTP 403 `admin_required`.
     * AC-6: Admin moderation actions (`POST /api/v1/admin/issues/{id}/moderate` with actions `dismiss`, `hide_issue`, `ban_reporter` and audit reason notes).
     * AC-7: UI Components & Widget Keys (`issueCardOverflow_<id>`, `flagIssueOption_<id>`, `flagIssueDialog`, `flagCategorySelect`, `flagDetailsInput`, `submitFlagButton`, `adminQueueFilterSelect`, `moderateAction_<id>`).
     * AC-8: Riverpod State Providers (`flagIssueNotifierProvider`, `adminFlaggedQueueProvider`) & LocalStore Hive cache (`user_flagged_issue_ids`).
   - Security Requirements (SQL parameterization, auth boundary enforcement, PII protection, rate limiting).
   - Non-Goals (No AI/ML automatic scanning, no separate web admin portal, no complex multi-tiered appeals tribunal).
3. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p2_product_manager_1/handoff.md`.
4. Send a message to parent with completion status and path to handoff.md.
