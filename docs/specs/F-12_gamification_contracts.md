# Feature Contract: F-12 Gamification Engine (Impact Score, Civic Badges & Daily Streaks)

**ID:** `F-12`  
**Name:** Gamification Engine (Impact Score, Civic Badges & Daily Streaks)  
**Status:** BINDING_CONTRACT  
**Created:** 2026-08-10  

---

## 1. REST API Endpoints & Contracts

Base URL prefix: `/api/v1`

### 1.1 `GET /api/v1/gamification/me`
Retrieves the gamification profile for the current user (impact score, current level, daily streak state, badges, activity stats).

- **Auth Required:** Optional / Bearer Token.
  - If authenticated: calculates live score and fetches unlocked badges for `user_id`.
  - If unauthenticated / Guest user: returns default baseline gamification profile with 0 score, level 1 ("Civic Rookie"), can_claim_streak: false, empty badges list, and `is_guest: true`.
- **Response Status:**
  - `200 OK`: Success

#### Response Schema (`GamificationProfileOut`)
```json
{
  "user_id": 42,
  "is_guest": false,
  "impact_score": 145,
  "level": 2,
  "level_name": "Active Neighbor",
  "next_level_score": 300,
  "streak_days": 3,
  "last_streak_date": "2026-08-09",
  "can_claim_streak": true,
  "badges": [
    {
      "id": "first_report",
      "name": "First Report",
      "description": "Reported your first civic issue in LocalLens",
      "icon_name": "flag",
      "unlocked_at": "2026-08-08T10:00:00Z"
    },
    {
      "id": "civic_voter",
      "name": "Civic Voter",
      "description": "Upvoted 5 or more civic issues",
      "icon_name": "thumb_up",
      "unlocked_at": "2026-08-09T14:30:00Z"
    }
  ],
  "activity_counts": {
    "issues_created": 2,
    "upvotes_cast": 5,
    "quorum_votes_cast": 1,
    "comments_posted": 2
  }
}
```

---

### 1.2 `POST /api/v1/gamification/claim-daily-streak`
Claims the daily civic streak for the current authenticated user.

- **Auth Required:** `Bearer <token>` (Authenticated users only).
- **Request Body:** None / Empty `{}`
- **Response Status:**
  - `200 OK`: Daily streak claimed successfully.
  - `400 Bad Request`: Daily streak already claimed today (`"Daily streak already claimed today"`).
  - `401 Unauthorized`: Missing or invalid Bearer token.
  - `403 Forbidden`: Guest user trying to claim streak (`"Guest users cannot claim daily streaks. Please sign in."`).

#### Response Schema (`StreakClaimOut`)
```json
{
  "streak_days": 4,
  "points_earned": 15,
  "impact_score": 160,
  "message": "Daily streak claimed! +15 Impact Points"
}
```

---

### 1.3 `GET /api/v1/gamification/badges`
Publicly retrieves the metadata for all available system badges.

- **Auth Required:** Optional (Public).
- **Response Status:**
  - `200 OK`: Success (returns array of `BadgeMetadataOut`).

#### Response Schema (`List[BadgeMetadataOut]`)
```json
[
  {
    "id": "first_report",
    "name": "First Report",
    "description": "Reported your first civic issue in LocalLens",
    "icon_name": "flag",
    "category": "reporting",
    "threshold": 1
  },
  {
    "id": "civic_voter",
    "name": "Civic Voter",
    "description": "Upvoted 5 or more civic issues",
    "icon_name": "thumb_up",
    "category": "voting",
    "threshold": 5
  },
  {
    "id": "quorum_hero",
    "name": "Quorum Hero",
    "description": "Participated in 3 or more quorum verification votes",
    "icon_name": "verified",
    "category": "quorum",
    "threshold": 3
  },
  {
    "id": "neighborhood_voice",
    "name": "Neighborhood Voice",
    "description": "Posted 5 or more comments in community discussions",
    "icon_name": "forum",
    "category": "discussion",
    "threshold": 5
  },
  {
    "id": "streak_master",
    "name": "Streak Master",
    "description": "Maintained a 7-day daily streak",
    "icon_name": "bolt",
    "category": "streak",
    "threshold": 7
  }
]
```

---

## 2. Business Logic, Points & Badges Rules

### 2.1 Impact Score Formula
- **Issue Created:** +50 points
- **Upvote Cast:** +5 points
- **Quorum Vote Cast:** +20 points
- **Comment Posted:** +10 points
- **Daily Streak Claim:** +15 points per claim day

### 2.2 Levels Table
| Level | Name | Score Range | Next Level Target |
|---|---|---|---|
| 1 | Civic Rookie | 0 - 99 | 100 |
| 2 | Active Neighbor | 100 - 299 | 300 |
| 3 | Community Guardian | 300 - 699 | 700 |
| 4 | Civic Champion | 700 - 1499 | 1500 |
| 5 | City Hero | 1500+ | null |

### 2.3 Badges Automatic Unlocking Logic
Badges are dynamically evaluated when fetching `/gamification/me` or claiming streaks:
1. `first_report`: `issues_created >= 1`
2. `civic_voter`: `upvotes_cast >= 5`
3. `quorum_hero`: `quorum_votes_cast >= 3`
4. `neighborhood_voice`: `comments_posted >= 5`
5. `streak_master`: `streak_days >= 7`

---

## 3. Database Entities & Schemas

### 3.1 Table `user_gamifications`
- `id`: `Integer` (PK, autoincrement)
- `user_id`: `Integer` (FK -> `users.id`, unique, indexed)
- `impact_score`: `Integer` (default: 0)
- `streak_days`: `Integer` (default: 0)
- `last_streak_date`: `Date` (nullable)
- `created_at`: `DateTime` (default: utcnow)
- `updated_at`: `DateTime` (default: utcnow, onupdate: utcnow)

### 3.2 Table `user_badges`
- `id`: `Integer` (PK, autoincrement)
- `user_id`: `Integer` (FK -> `users.id`, indexed)
- `badge_id`: `String` (e.g., `'first_report'`, `'civic_voter'`, etc.)
- `unlocked_at`: `DateTime` (default: utcnow)

---

## 4. Frontend Architecture, Routing & Hive Keys

### 4.1 Route Paths (`app/lib/core/router/route_paths.dart`)
- `RoutePaths.gamification` = `'/gamification'`

### 4.2 Riverpod Providers (`app/lib/features/gamification/presentation/gamification_providers.dart`)
- `gamificationProfileProvider`: `FutureProvider<GamificationProfile>`
- `allBadgesProvider`: `FutureProvider<List<BadgeMetadata>>`
- `claimStreakNotifierProvider`: `StateNotifierProvider<ClaimStreakNotifier, AsyncValue<StreakClaimResult>>`

### 4.3 Hive Storage Keys (`app/lib/core/storage/local_store.dart`)
- Key: `'gamification_cache'` in `_draftsBox` (stores JSON string of cached profile for instant rendering)

---

## 5. UI Components, Strings & Widget Keys

### 5.1 `GamificationScreen` (`app/lib/features/gamification/presentation/gamification_screen.dart`)
- **Screen Key:** `Key('gamificationScreen')`
- **Header Title:** `'Civic Impact & Badges'`
- **Impact Score Card:** `Key('impactScoreCard')`
- **Impact Score Value:** `Key('impactScoreValue')`
- **Level Name Label:** `Key('levelNameLabel')`
- **Next Level Progress Bar:** `Key('levelProgressBar')`
- **Streak Banner:** `Key('streakBanner')`
- **Streak Days Counter:** `Key('streakDaysCounter')`
- **Claim Streak Button:** `Key('claimStreakButton')`
- **Badges Grid:** `Key('badgesGrid')`
- **Badge Item Card:** `Key('badgeCard_<id>')` (e.g. `Key('badgeCard_first_report')`)
- **Activity Breakdown Card:** `Key('activityBreakdownCard')`

### 5.2 `ProfileScreen` Integration (`app/lib/features/profile/presentation/screens/profile_screen.dart`)
- **Gamification Tile / Card Button:** `Key('viewGamificationButton')`

---

## 6. Test Binding Contract & Exact Invariants

1. **Endpoints:**
   - `GET /api/v1/gamification/me`
   - `POST /api/v1/gamification/claim-daily-streak`
   - `GET /api/v1/gamification/badges`

2. **Security & Rate Limits:**
   - Rate limit: 5 streak claims / minute per user/IP.
   - SQL Queries MUST use SQLAlchemy 2.0 ORM parameterization.
   - Guest user streak claim attempts MUST return HTTP `403 Forbidden`.

3. **UI Rules:**
   - Material 3 clean layout.
   - No `Colors.*` color literals.
   - No raw emoji characters or gradient overlays.
