# BRIEFING — 2026-08-10T11:51:00Z

## Mission
Author the comprehensive F-14-FLAG OpenAPI & Flutter Contracts Specification (`docs/specs/F-14_flagging_contracts.md`) following LocalLens codebase conventions.

## 🔒 My Identity
- Archetype: Contract Engineer
- Roles: implementer, qa, specialist
- Working directory: /Users/rohit/Desktop/Python/LocalLens/.agents/p1_contract_engineer_1
- Original parent: 14041e08-17fe-4862-896b-1c1fc02ddc6a
- Milestone: F-14-FLAG Phase 1 Contracts

## 🔒 Key Constraints
- Complete contract specifications for backend & frontend flagging/moderation feature.
- Explicit schema definitions, error responses, rate limits, GuestGuard integration, Riverpod providers, Hive keys, widget keys, and test contract assertions.

## Current Parent
- Conversation ID: 14041e08-17fe-4862-896b-1c1fc02ddc6a
- Updated: 2026-08-10T11:51:00Z

## Task Summary
- **What to build**: `docs/specs/F-14_flagging_contracts.md`
- **Success criteria**: Exact specifications matching user requirements & existing codebase patterns.
- **Interface contracts**: `docs/specs/F-14_flagging_contracts.md`
- **Code layout**: `/Users/rohit/Desktop/Python/LocalLens/backend/app/` and `/Users/rohit/Desktop/Python/LocalLens/app/lib/`

## Key Decisions Made
- Auth/Guest check: Enforced 403 Forbidden with `code: "guest_restricted"` for guest users attempting `POST /api/v1/issues/{id}/flag`.
- Admin check: Enforced 403 Forbidden with `code: "admin_required"` for non-admin users attempting `/api/v1/admin/*` endpoints.
- Rate limit: 5 flags per 10 minutes per user/anon_id using `SlidingWindowRateLimiter(max_requests=5, window_seconds=600.0)`.
- Duplicate flag rule: Unique constraint on `(issue_id, reporter_id)` / `(issue_id, anon_id)` yielding 409 Conflict (`code: "duplicate_flag"`).
- Exact UI Widget Keys defined: `issueCardOverflow_<id>`, `flagIssueOption_<id>`, `flagIssueDialog`, `flagCategorySelect`, `flagDetailsInput`, `submitFlagButton`.

## Change Tracker
- **Files modified**:
  - `docs/specs/F-14_flagging_contracts.md` (Created contract specification document)
- **Build status**: Complete
- **Pending issues**: None

## Quality Status
- **Build/test result**: N/A (Documentation specification phase)
- **Lint status**: N/A
- **Tests added/modified**: N/A (Included pytest & Flutter widget test contract snippets in spec doc)

## Loaded Skills
- None
