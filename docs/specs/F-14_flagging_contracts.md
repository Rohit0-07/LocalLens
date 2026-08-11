# Feature Contract: F-14 Flagging & Moderation Engine

**ID:** `F-14`  
**Name:** Flagging & Moderation Engine (Content Flagging, Rate Limiting, Admin Moderation Queue & Action Auditing)  
**Status:** BINDING_CONTRACT  
**Created:** 2026-08-10  

---

## 1. Domain Enums & Core Specifications

### 1.1 Flag Categories (`FlagCategory`)
- `spam`: Repeated, low-quality, or promotional content.
- `abuse`: Harassment, hate speech, threats, or offensive language.
- `pii`: Personally Identifiable Information (phone numbers, full names, home addresses).
- `fake_report`: Fabricated issue report, false location, or misleading photo/details.
- `other`: Other policy violations requiring manual moderator review.

### 1.2 Moderation Actions (`ModerationAction`)
- `dismiss`: Dismisses raised flags for the issue; keeps issue public.
- `hide_issue`: Hides issue from public feeds, map views, and search results (`is_hidden = true`).
- `ban_reporter`: Hides issue and marks reporter account as restricted/banned from submitting new issues.

---

## 2. REST API Endpoints & Contracts

Base URL prefix: `/api/v1`

### 2.1 `POST /api/v1/issues/{id}/flag`
Submits a user or anonymous flag report against a specific civic issue.

- **Auth Required:** `Bearer <token>` required. Guest token rejected with 403 (`guest_restricted`).
- **Path Parameters:**
  - `id`: `integer` (ID of the target issue).
- **Request Body (`FlagCreate`)**:
```json
{
  "category": "spam",
  "details": "Repeated commercial promotional advertisement."
}
```
  - `category`: `string` (Required, enum: `"spam"`, `"abuse"`, `"pii"`, `"fake_report"`, `"other"`).
  - `details`: `string` (Optional, max 500 characters, nullable/omittable).

- **Responses & Status Codes:**
  - `201 Created`: Flag recorded successfully.
  - `400 Bad Request`: Invalid category or details exceeding 500 chars (`code: "validation_error"`).
  - `401 Unauthorized`: Missing or invalid Bearer token (`detail: "Not authenticated"` or `detail: "Invalid or expired token"`).
  - `403 Forbidden`: Guest user trying to flag (`detail: "Sign in required to flag issues"`, `code: "guest_restricted"`).
  - `404 Not Found`: Issue with specified `id` does not exist (`detail: "Issue not found"`, `code: "not_found"`).
  - `409 Conflict`: User or anon identity has already flagged this issue (`detail: "You have already flagged this issue"`, `code: "duplicate_flag"`).
  - `429 Too Many Requests`: Rate limit exceeded (max 5 flags per 10 minutes) (`detail: "Rate limit exceeded. Maximum 5 flags per 10 minutes."`, `code: "rate_limit_exceeded"`).

#### Response Schema (`FlagOut`)
```json
{
  "id": 1,
  "issue_id": 101,
  "reporter_id": 42,
  "anon_id": "anon_9a8b7c6d",
  "category": "spam",
  "details": "Repeated commercial promotional advertisement.",
  "created_at": "2026-08-10T12:00:00Z"
}
```

---

### 2.2 `GET /api/v1/admin/flagged-issues`
Retrieves a paginated list of flagged issues for moderator review.

- **Auth Required:** `Bearer <token>` (Admin/Moderator role enforced). Non-admin returns 403 (`admin_required`).
- **Query Parameters:**
  - `status_filter`: `string` (Optional, enum: `"pending"`, `"reviewed"`, `"dismissed"`, `"hidden"`, `"all"`; default: `"pending"`).
  - `category`: `string` (Optional, enum: `"spam"`, `"abuse"`, `"pii"`, `"fake_report"`, `"other"`).
  - `limit`: `integer` (Optional, 1–100, default: `20`).
  - `offset`: `integer` (Optional, ≥0, default: `0`).

- **Responses & Status Codes:**
  - `200 OK`: Success.
  - `401 Unauthorized`: Missing or invalid Bearer token.
  - `403 Forbidden`: Authenticated user is not an admin/moderator (`detail: "Admin authorization required"`, `code: "admin_required"`).

#### Response Schema (`FlaggedQueueResponse`)
```json
{
  "items": [
    {
      "issue_id": 101,
      "issue_title": "Illegal Dumping on Elm Street",
      "issue_description": "Garbage pile blocking sidewalk",
      "issue_status": "open",
      "is_hidden": false,
      "reporter_id": 42,
      "flag_count": 3,
      "categories": ["spam", "abuse"],
      "latest_flag_at": "2026-08-10T12:00:00Z",
      "flags": [
        {
          "id": 1,
          "reporter_id": 42,
          "anon_id": "anon_9a8b7c6d",
          "category": "spam",
          "details": "Repeated commercial promotional advertisement.",
          "created_at": "2026-08-10T12:00:00Z"
        }
      ],
      "moderated_at": null,
      "moderated_by": null,
      "moderation_action": null
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

---

### 2.3 `POST /api/v1/admin/issues/{id}/moderate`
Applies a moderation decision (`dismiss`, `hide_issue`, `ban_reporter`) to an issue and updates audit logs.

- **Auth Required:** `Bearer <token>` (Admin/Moderator role enforced).
- **Path Parameters:**
  - `id`: `integer` (Target issue ID).
- **Request Body (`ModerationActionRequest`)**:
```json
{
  "action": "hide_issue",
  "reason": "Verified spam and promotional content."
}
```
  - `action`: `string` (Required, enum: `"dismiss"`, `"hide_issue"`, `"ban_reporter"`).
  - `reason`: `string` (Optional, max 500 characters).

- **Responses & Status Codes:**
  - `200 OK`: Moderation action applied successfully.
  - `400 Bad Request`: Invalid action enum or invalid payload.
  - `401 Unauthorized`: Missing or invalid Bearer token.
  - `403 Forbidden`: Authenticated user is not an admin/moderator (`code: "admin_required"`).
  - `404 Not Found`: Target issue not found (`code: "not_found"`).

#### Response Schema (`ModerationResultOut`)
```json
{
  "issue_id": 101,
  "action": "hide_issue",
  "reason": "Verified spam and promotional content.",
  "moderated_by": 1,
  "moderated_at": "2026-08-10T12:05:00Z",
  "issue_status": "hidden",
  "reporter_banned": false
}
```

---

## 3. Error Responses & Standard Status Codes

All API errors return a standard JSON payload:
```json
{
  "detail": "Error description message",
  "code": "error_code_identifier"
}
```

| HTTP Code | Error Code (`code`) | Cause / Condition | Response Body Example |
|---|---|---|---|
| **201 Created** | N/A | Flag successfully registered | `FlagOut` object |
| **200 OK** | N/A | Moderation action or queue retrieval success | `FlaggedQueueResponse` / `ModerationResultOut` |
| **400 Bad Request** | `validation_error` | Invalid enum value or field constraint violation | `{"detail": "Invalid flag category 'invalid'", "code": "validation_error"}` |
| **401 Unauthorized** | `unauthorized` | Token missing, invalid, or expired | `{"detail": "Not authenticated"}` |
| **403 Forbidden** | `guest_restricted` | Guest user attempting `POST /api/v1/issues/{id}/flag` | `{"detail": "Sign in required to flag issues", "code": "guest_restricted"}` |
| **403 Forbidden** | `admin_required` | Non-admin attempting `/api/v1/admin/*` endpoints | `{"detail": "Admin authorization required", "code": "admin_required"}` |
| **404 Not Found** | `not_found` | Target issue ID does not exist | `{"detail": "Issue not found", "code": "not_found"}` |
| **409 Conflict** | `duplicate_flag` | User or anon_id already flagged this issue | `{"detail": "You have already flagged this issue", "code": "duplicate_flag"}` |
| **429 Too Many Requests** | `rate_limit_exceeded` | Exceeded 5 flags per 10 minutes limit | `{"detail": "Rate limit exceeded. Maximum 5 flags per 10 minutes.", "code": "rate_limit_exceeded"}` |

---

## 4. Security, Authorization & Business Rules

### 4.1 Admin/Mod Authorization Requirements
- Authenticated user object must satisfy `user.is_admin == True` or `user.role in ("admin", "moderator")`.
- If an unprivileged user accesses `/api/v1/admin/*`, the server immediately responds with `403 Forbidden` and `code: "admin_required"`.

### 4.2 GuestGuard Integration Rules
- Anonymous / guest users (where `user.is_guest == True` or JWT `sub` starts with `"guest:"`) are blocked from flagging.
- On backend: returns `403 Forbidden` with `code: "guest_restricted"`.
- On Flutter app:
  1. Tapping `Key('flagIssueOption_<id>')` checks guest status via auth provider.
  2. If guest or if API returns `403 guest_restricted`, triggers `GuestGuard` dialog modal (`GuestGuard` widget).
  3. Clicking "Sign In" on `GuestGuard` redirects user via `context.push(RoutePaths.signIn)`.

### 4.3 Rate Limit Specification
- Enforced using `SlidingWindowRateLimiter(max_requests=5, window_seconds=600.0)`.
- Key identifier: `f"flag_rate:{user.id}"` for registered users or `f"flag_rate:{anon_id}"` for anonymous sessions.
- Rejection threshold: 6th flag within any 10-minute window yields `429 Too Many Requests` (`code: "rate_limit_exceeded"`).

### 4.4 Duplicate Flag Guard Rule
- Database unique constraint on `(issue_id, reporter_id)` for logged-in users, and `(issue_id, anon_id)` for guest/anonymous identities.
- Attempting to submit a second flag for the same issue yields `409 Conflict` (`code: "duplicate_flag"`).

---

## 5. Frontend State & Local Storage Contracts

### 5.1 Riverpod Provider Contracts

#### 1. `flagIssueNotifierProvider`
- **Type:** `AutoDisposeAsyncNotifierProviderFamily<FlagIssueNotifier, FlagOut?, int>` (keyed by `issueId`).
- **State:** `AsyncValue<FlagOut?>` (Null initially; holds `FlagOut` on success).
- **Methods:**
  - `Future<bool> submitFlag({required String category, String? details})`:
    - Checks auth state: if guest, displays `GuestGuard` dialog and returns `false`.
    - Invokes `POST /api/v1/issues/{id}/flag`.
    - Handles `409 Conflict` by setting user-friendly error ("Already flagged this issue").
    - Handles `429 Rate Limit` by setting rate-limit message.
    - On success: updates local `LocalStore` cached flagged set and returns `true`.

#### 2. `adminFlaggedQueueProvider`
- **Type:** `AutoDisposeAsyncNotifierProviderFamily<AdminFlaggedQueueNotifier, FlaggedQueueResponse, FlaggedQueueFilter>`
- **State:** `AsyncValue<FlaggedQueueResponse>`
- **Filter Param (`FlaggedQueueFilter`)**:
  - `status`: `String` (default: `"pending"`)
  - `category`: `String?`
  - `limit`: `int` (default: `20`)
  - `offset`: `int` (default: `0`)
- **Methods:**
  - `Future<void> moderateIssue({required int issueId, required String action, String? reason})`:
    - Calls `POST /api/v1/admin/issues/{id}/moderate`.
    - On success, updates local state array by removing or updating the moderated issue.

---

### 5.2 Hive / LocalStore Keys & Local Caching Schemas

- **Box Name:** `'flagged_issues'` (managed in `LocalStore.instance`).
- **Key Name:** `'user_flagged_issue_ids'`
- **Cached Data Format:** JSON string storing array of issue IDs flagged by current user.
```json
{
  "flagged_issue_ids": [101, 105, 204],
  "last_updated": "2026-08-10T12:00:00Z"
}
```
- **LocalStore Methods:**
  - `Set<int> getFlaggedIssueIds()`
  - `Future<void> addFlaggedIssueId(int issueId)`
  - `bool isIssueFlaggedLocally(int issueId)`

---

### 5.3 Route Paths for Moderation/Admin Views

Add to `RoutePaths` in `app/lib/core/router/route_paths.dart`:
- `static const adminFlaggedQueue = '/admin/flagged-queue';`
- `static const moderationDetail = '/admin/issues/:id/moderate';`
- `static String moderationDetailFor(int id) => '/admin/issues/$id/moderate';`

---

## 6. UI Widget Keys Specification

All UI components related to flagging and moderation MUST attach exact keys:

| Component | Key String | Type | Usage |
|---|---|---|---|
| **Issue Card Overflow Menu** | `Key('issueCardOverflow_<id>')` | `ValueKey<String>` | IconButton on `IssueCard` to open actions menu |
| **Flag Issue Option** | `Key('flagIssueOption_<id>')` | `ValueKey<String>` | PopupMenuItem / ListTile option inside overflow menu |
| **Flag Issue Dialog** | `Key('flagIssueDialog')` | `ValueKey<String>` | Root `AlertDialog` or `BottomSheet` for flagging |
| **Flag Category Dropdown/Radio** | `Key('flagCategorySelect')` | `ValueKey<String>` | DropdownButton or RadioGroup for category selection |
| **Flag Details TextField** | `Key('flagDetailsInput')` | `ValueKey<String>` | TextField for optional user explanation |
| **Submit Flag Button** | `Key('submitFlagButton')` | `ValueKey<String>` | ElevatedButton / FilledButton to submit flag |
| **Admin Queue Filter Dropdown** | `Key('adminQueueFilterSelect')` | `ValueKey<String>` | Filter selection on Admin Queue screen |
| **Moderate Action Button** | `Key('moderateAction_<id>')` | `ValueKey<String>` | Button on Admin Queue item to moderate issue |

---

## 7. Automated Test Contract Assertions

### 7.1 Backend Pytest Contract Assertions

```python
# tests/test_flagging_contracts.py

@pytest.mark.asyncio
async def test_flag_issue_success(client, auth_headers):
    response = await client.post(
        "/api/v1/issues/101/flag",
        headers=auth_headers,
        json={"category": "spam", "details": "Commercial spam"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["issue_id"] == 101
    assert data["category"] == "spam"
    assert "id" in data
    assert "created_at" in data

@pytest.mark.asyncio
async def test_flag_issue_guest_returns_403(client, guest_headers):
    response = await client.post(
        "/api/v1/issues/101/flag",
        headers=guest_headers,
        json={"category": "spam"}
    )
    assert response.status_code == 403
    assert response.json()["code"] == "guest_restricted"

@pytest.mark.asyncio
async def test_flag_issue_duplicate_returns_409(client, auth_headers):
    # First flag
    await client.post("/api/v1/issues/101/flag", headers=auth_headers, json={"category": "spam"})
    # Second flag
    response = await client.post("/api/v1/issues/101/flag", headers=auth_headers, json={"category": "spam"})
    assert response.status_code == 409
    assert response.json()["code"] == "duplicate_flag"

@pytest.mark.asyncio
async def test_flag_issue_rate_limit_returns_429(client, auth_headers_factory):
    headers = auth_headers_factory(user_id=99)
    for i in range(1, 6):
        resp = await client.post(f"/api/v1/issues/{i}/flag", headers=headers, json={"category": "spam"})
        assert resp.status_code == 201
    
    # 6th attempt within window
    resp = await client.post("/api/v1/issues/6/flag", headers=headers, json={"category": "spam"})
    assert resp.status_code == 429
    assert resp.json()["code"] == "rate_limit_exceeded"

@pytest.mark.asyncio
async def test_admin_flagged_issues_non_admin_returns_403(client, regular_user_headers):
    response = await client.get("/api/v1/admin/flagged-issues", headers=regular_user_headers)
    assert response.status_code == 403
    assert response.json()["code"] == "admin_required"

@pytest.mark.asyncio
async def test_admin_moderate_issue_hide_success(client, admin_headers):
    response = await client.post(
        "/api/v1/admin/issues/101/moderate",
        headers=admin_headers,
        json={"action": "hide_issue", "reason": "Confirmed spam"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["action"] == "hide_issue"
    assert data["issue_status"] == "hidden"
```

---

### 7.2 Flutter Widget Test Contract Assertions

```dart
// test/features/flagging/flag_dialog_test.dart

void main() {
  testWidgets('Tapping flag option opens flag dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap overflow menu
    final overflowBtn = find.byKey(const Key('issueCardOverflow_101'));
    expect(overflowBtn, findsOneWidget);
    await tester.tap(overflowBtn);
    await tester.pumpAndSettle();

    // Tap flag option
    final flagOption = find.byKey(const Key('flagIssueOption_101'));
    expect(flagOption, findsOneWidget);
    await tester.tap(flagOption);
    await tester.pumpAndSettle();

    // Expect dialog
    expect(find.byKey(const Key('flagIssueDialog')), findsOneWidget);
    expect(find.byKey(const Key('flagCategorySelect')), findsOneWidget);
    expect(find.byKey(const Key('submitFlagButton')), findsOneWidget);
  });

  testWidgets('Guest user tapping flag option triggers GuestGuard dialog', (tester) async {
    await tester.pumpWidget(createWidgetWithGuestSession());

    final flagOption = find.byKey(const Key('flagIssueOption_101'));
    await tester.tap(flagOption);
    await tester.pumpAndSettle();

    // Should show GuestGuard dialog with Sign in required
    expect(find.text('Sign in required'), findsOneWidget);
  });

  testWidgets('Submitting valid flag updates provider state', (tester) async {
    await tester.pumpWidget(createWidgetWithAuthSession());

    // Fill form and submit
    await tester.enterText(find.byKey(const Key('flagDetailsInput')), 'Spam report');
    await tester.tap(find.byKey(const Key('submitFlagButton')));
    await tester.pumpAndSettle();

    expect(find.text('Flag submitted successfully'), findsOneWidget);
  });
}
```
