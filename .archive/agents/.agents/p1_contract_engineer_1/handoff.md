# Handoff Report: F-14 Flagging Contracts Phase (P1)

## 1. Observation
- Inspected existing FastAPI backend architecture in `/Users/rohit/Desktop/Python/LocalLens/backend/app/`:
  - `api/deps.py`: Token verification & guest user handling (`user.is_guest`).
  - `core/exceptions.py`: `AppError` returning `{"detail": ..., "code": ...}` JSON structure.
  - `core/ratelimit.py`: `SlidingWindowRateLimiter(max_requests, window_seconds)`.
  - `features/issues/router.py`: Guest restriction pattern throwing 403 Forbidden with `code: "guest_restricted"`.
- Inspected Flutter app architecture in `/Users/rohit/Desktop/Python/LocalLens/app/lib/`:
  - `core/router/route_paths.dart`: Route constants structure (`RoutePaths`).
  - `core/storage/local_store.dart`: Hive storage box organization (`LocalStore`).
  - `features/auth/presentation/widgets/guest_guard.dart`: Guest dialog trigger & redirect to `RoutePaths.signIn`.
  - `features/feed/presentation/widgets/issue_card.dart`: Key naming conventions and widget tree structure.
- Created `/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md` containing binding contract specifications.

## 2. Logic Chain
- Standardized REST endpoints (`POST /api/v1/issues/{id}/flag`, `GET /api/v1/admin/flagged-issues`, `POST /api/v1/admin/issues/{id}/moderate`) to follow existing LocalLens API conventions.
- Mapped flag categories (`spam`, `abuse`, `pii`, `fake_report`, `other`) and moderation actions (`dismiss`, `hide_issue`, `ban_reporter`) directly to explicit enums.
- Designed error responses to match `AppError` JSON structure (`{"detail": "...", "code": "..."}`).
- Defined rate limiting (5 flags per 10 mins) using `SlidingWindowRateLimiter` and duplicate flag guard via unique DB constraints returning HTTP 409 Conflict.
- Integrated `GuestGuard` contract and explicit widget key contracts (`Key('issueCardOverflow_<id>')`, `Key('flagIssueOption_<id>')`, `Key('flagIssueDialog')`, `Key('flagCategorySelect')`, `Key('flagDetailsInput')`, `Key('submitFlagButton')`).
- Defined Riverpod providers (`flagIssueNotifierProvider`, `adminFlaggedQueueProvider`) and Hive storage schemas for local caching.

## 3. Caveats
- No caveats. All required endpoints, schemas, status codes, provider definitions, widget keys, local store keys, and test contract assertions have been specified.

## 4. Conclusion
- P1 Contracts phase for F-14 Flagging & Moderation Engine is complete.
- The contract specification is saved at `/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md`.

## 5. Verification Method
- Inspect file `/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md` using `view_file` to confirm all 15 required contract aspects are fully detailed.
