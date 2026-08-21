## 2026-08-10T11:48:16Z
You are the P1 Contract Engineer subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p1_contract_engineer_1`.

Your task is to execute P1 (Contracts Document) of the F-14-FLAG Spec-Driven Development pipeline:
1. Inspect existing backend conventions in `/Users/rohit/Desktop/Python/LocalLens/backend/app/` (routers, schemas, dependencies, auth, database models).
2. Inspect existing app conventions in `/Users/rohit/Desktop/Python/LocalLens/app/lib/` (feed router, dio providers, Riverpod providers, go_router, LocalStore/Hive keys, widget keys structure).
3. Create the directory `/Users/rohit/Desktop/Python/LocalLens/docs/specs/` if needed, and write `/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md` with EXACT specifications for:
   - Endpoint paths:
     - POST /api/v1/issues/{id}/flag
     - GET /api/v1/admin/flagged-issues
     - POST /api/v1/admin/issues/{id}/moderate
   - HTTP methods, exact JSON request & response payload schemas, field types, validation rules, status codes (201, 200, 400, 401, 403, 404, 409, 429), and error response formats.
   - Flag categories: `spam`, `abuse`, `pii`, `fake_report`, `other`.
   - Moderation actions: `dismiss`, `hide_issue`, `ban_reporter`.
   - Admin/Mod authorization requirements (403 for non-admin).
   - GuestGuard integration rules (403 for guest users, login prompt trigger).
   - Rate limit specification (5 flags per 10 minutes per user/anon_id).
   - Duplicate flag guard rule per user/anon_id.
   - Riverpod provider contracts: `flagIssueNotifierProvider` and `adminFlaggedQueueProvider`.
   - Hive/LocalStore keys and local caching schemas.
   - UI Widget Keys:
     - `Key('issueCardOverflow_<id>')`
     - `Key('flagIssueOption_<id>')`
     - `Key('flagIssueDialog')`
     - `Key('flagCategorySelect')`
     - `Key('flagDetailsInput')`
     - `Key('submitFlagButton')`
   - Route paths for moderation/admin views if relevant.
   - Test contract assertions for pytest backend tests and Flutter widget tests.

4. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p1_contract_engineer_1/handoff.md`.
5. Send a message to parent with your completion status and path to handoff.md.
