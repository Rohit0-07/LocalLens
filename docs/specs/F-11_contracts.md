# Feature Contract: F-11 Representative Dashboard & Governance Tools

**ID:** `F-11`  
**Name:** Representative Dashboard & Governance Tools (Official Rep Responses & Ward Issues Dashboard)  
**Status:** BINDING_CONTRACT  
**Created:** 2026-08-10  

---

## 1. REST API Endpoints & Contracts

Base URL prefix: `/api/v1`

### 1.1 `GET /api/v1/representatives/me`
Fetches representative profile and ward summary metrics for the authenticated user.

- **Auth Required:** `Bearer <token>` (User must have `is_representative == True`).
- **Response Status:**
  - `200 OK`: Success
  - `401 Unauthorized`: Missing or invalid Bearer token
  - `403 Forbidden`: User is authenticated but is not a verified representative (`is_representative == False` or no `RepresentativeProfile` record).

#### Response Schema (`RepresentativeProfileOut`)
```json
{
  "id": "repr_12345",
  "user_id": 42,
  "official_name": "Hon. Sarah Jenkins",
  "title": "Ward Councilor",
  "ward": "Ward 45, Urban Central",
  "verified_at": "2026-01-15T09:00:00Z",
  "total_ward_issues": 18,
  "escalated_ward_issues": 4,
  "responded_ward_issues": 12,
  "pending_response_ward_issues": 6
}
```

---

### 1.2 `GET /api/v1/representatives/ward-issues`
Fetches issues within the representative's assigned ward.

- **Auth Required:** `Bearer <token>` (Representative role enforced).
- **Query Parameters:**
  - `filter`: `string` (Optional, enum: `"all"`, `"escalated"`, `"needs_response"`; default: `"all"`).
  - `limit`: `integer` (Optional, 1–100, default: `20`).
  - `offset`: `integer` (Optional, ≥0, default: `0`).
- **Response Status:**
  - `200 OK`: Success
  - `401 Unauthorized`: Invalid/missing token
  - `403 Forbidden`: User is not a verified representative.

#### Response Schema (`WardIssuesResponse`)
```json
{
  "items": [
    {
      "id": 101,
      "title": "Severe Pothole on Main St",
      "description": "Deep pothole causing vehicle damage",
      "category": "road",
      "status": "escalated",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "geohash": "tdr1v",
      "ward": "Ward 45, Urban Central",
      "is_anonymous": false,
      "fuzz_location": false,
      "is_fuzzed": false,
      "is_shielded": false,
      "reporter_label": "Citizen #42",
      "anonymous_identity": "anon_abc123",
      "created_at": "2026-08-08T10:00:00Z",
      "acknowledged_at": null,
      "resolved_at": null,
      "upvotes_count": 15,
      "comments_count": 3,
      "confirmations_count": 0,
      "disputes_count": 0,
      "resolution_proof": null,
      "resolution_notes": null,
      "has_upvoted": false,
      "has_official_response": false
    }
  ],
  "total": 1
}
```

---

### 1.3 `POST /api/v1/issues/{id}/official-response`
Allows a verified representative to post an official response to an issue in their ward.

- **Auth Required:** `Bearer <token>` (Representative role enforced).
- **Path Parameters:**
  - `id`: `integer` (Issue ID).
- **Request Body (`OfficialResponseCreate`)**:
```json
{
  "message": "Public Works team dispatched. Work will begin on Wednesday.",
  "estimated_resolution_days": 3,
  "status_update": "acknowledged"
}
```
  - `message`: `string` (min: 5, max: 1000, required).
  - `estimated_resolution_days`: `integer | null` (optional, 1–365).
  - `status_update`: `string | null` (optional, enum: `"acknowledged"`, `"in_progress"`).

- **Response Status:**
  - `201 Created`: Official response posted successfully.
  - `400 Bad Request`: Validation failure (empty message, invalid status update enum).
  - `401 Unauthorized`: Missing/invalid token.
  - `403 Forbidden`: User is not a representative OR issue's ward does not match rep's ward.
  - `404 Not Found`: Issue ID does not exist.

#### Response Schema (`OfficialResponseOut`)
```json
{
  "id": "off_resp_9988",
  "issue_id": 101,
  "representative_id": "repr_12345",
  "official_name": "Hon. Sarah Jenkins",
  "title": "Ward Councilor",
  "ward": "Ward 45, Urban Central",
  "message": "Public Works team dispatched. Work will begin on Wednesday.",
  "estimated_resolution_days": 3,
  "status_update": "acknowledged",
  "created_at": "2026-08-10T02:00:00Z"
}
```

---

### 1.4 `GET /api/v1/issues/{id}/official-responses`
Publicly retrieves all official representative responses for a given issue.

- **Auth Required:** Optional (Guests and registered users can read).
- **Path Parameters:** `id`: `integer`
- **Response Status:**
  - `200 OK`: Success (returns array of `OfficialResponseOut`).
  - `404 Not Found`: Issue does not exist.

---

## 2. Frontend Architecture, Providers & Hive Keys

### 2.1 Route Paths (`app/lib/core/router/route_paths.dart`)
- `RoutePaths.repDashboard` = `'/rep-dashboard'`

### 2.2 Riverpod Providers (`app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart`)
- `repProfileProvider`: `FutureProvider<RepresentativeProfile>`
- `wardIssuesFilterProvider`: `StateProvider<String>` (values: `'all'`, `'escalated'`, `'needs_response'`)
- `wardIssuesProvider`: `FutureProvider.family<WardIssuesResponse, String>` (param: filter)
- `officialResponsesProvider`: `FutureProvider.family<List<OfficialResponse>, int>` (param: issueId)
- `repDashboardNotifierProvider`: `StateNotifierProvider` or AsyncNotifier managing official response submissions.

### 2.3 Local Storage / Hive Keys (`app/lib/core/storage/local_store.dart`)
- Box Name: `'rep_cache'`
- Cache Key: `'rep_profile'` (stores JSON string of cached profile for offline/fast load)

---

## 3. UI Components, Strings & Widget Keys

### 3.1 `RepDashboardScreen` (`app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart`)
- **Key:** `Key('repDashboardScreen')`
- **Header:**
  - Title: `'Representative Dashboard'`
  - Rep Name: `Key('repProfileName')`
  - Ward Badge: `Key('repProfileWard')`
- **Metrics Cards:**
  - Total Issues: `Key('metricTotalWardIssues')`
  - Escalated Issues: `Key('metricEscalatedWardIssues')`
  - Pending Response: `Key('metricPendingResponseWardIssues')`
- **Filter Chips:**
  - All: `Key('wardFilterChip_all')`
  - Escalated: `Key('wardFilterChip_escalated')`
  - Needs Response: `Key('wardFilterChip_needs_response')`
- **Issue Item List:** `Key('wardIssueList')`
- **Action Button on Item:** `Key('respondToIssueButton_<id>')`

### 3.2 Post Official Response Sheet / Dialog
- **Dialog Key:** `Key('postOfficialResponseDialog')`
- **Message Input:** `Key('officialResponseInput')`
- **ETA Input:** `Key('officialEtaInput')`
- **Submit Button:** `Key('submitOfficialResponseButton')`
- **Cancel Button:** `Key('cancelOfficialResponseButton')`

### 3.3 `OfficialResponseCard` (`app/lib/features/issue_detail/presentation/widgets/official_response_card.dart`)
- **Card Key:** `Key('officialResponseCard_<id>')`
- **Badge Text:** `'Official Representative Response'`
- **Verified Icon:** `Icons.verified_user` / `Icons.shield_outlined`
- **Title Key:** `Key('officialResponseTitle')`
- **Message Key:** `Key('officialResponseMessage')`

---

## 4. Test Binding Contract & Exact Invariants

1. **Endpoint Names:**
   - `/api/v1/representatives/me`
   - `/api/v1/representatives/ward-issues`
   - `/api/v1/issues/{id}/official-response`
   - `/api/v1/issues/{id}/official-responses`

2. **Security Limits:**
   - Rate limit: 30 requests/minute per user for representative endpoints.
   - Non-rep requests MUST return HTTP `403 Forbidden`.
   - Rep attempting to respond to issue outside their ward MUST return HTTP `403 Forbidden`.

3. **Database Entities:**
   - Table `representative_profiles`: `id` (String PK), `user_id` (ForeignKey `users.id`), `official_name` (String), `title` (String), `ward` (String), `verified_at` (DateTime).
   - Table `official_responses`: `id` (String PK), `issue_id` (ForeignKey `issues.id`), `representative_id` (ForeignKey `representative_profiles.id`), `message` (Text), `estimated_resolution_days` (Integer nullable), `status_update` (String nullable), `created_at` (DateTime).

4. **UI Styling Rules:**
   - Clean Material 3 only.
   - No `Colors.*` color literals (use `Theme.of(context).colorScheme`).
   - No raw gradients or emojis in status labels.
