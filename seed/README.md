# LocalLens Seed Data

Realistic demo data for populating the LocalLens development database. The seed
covers **every feature that is shipped** (auth, feed, compose, escalation &
quorum, threaded comments, notifications, search, gamification, representative
dashboard, flagging & moderation) with content that stays internally consistent
(matching counters, foreign keys, geohashes and derived anonymous identities).

## Layout

```
seed/
├── README.md               this file
├── data/                   one JSON file per record type
│   ├── users.json          citizens, admin, banned reporter
│   ├── representatives.json        verified ward councillor
│   ├── issues.json         19 issues: all 7 categories × all 7 statuses
│   ├── comments.json       threaded comments (7 nested replies)
│   ├── upvotes.json        per-issue upvote records
│   ├── notifications.json  all 5 notification types, read + unread
│   ├── flags.json          spam / fake_report / pii flags
│   ├── moderation_audits.json       dismiss + ban_reporter actions
│   ├── gamification.json   streak + impact profiles and unlocked badges
│   ├── official_responses.json      ward official responses
│   └── quorum_votes.json   confirm / dispute votes matching statuses
└── images/                 one SVG per issue, grouped by category
    ├── road/  ├── water/  ├── power/  ├── lighting/
    ├── waste/ ├── sewage/ └── other/
```

## How to seed

```sh
make seed                 # wipe seeded tables, then insert (from repo root)
cd backend && uv run python seed.py            # same, run directly
cd backend && uv run python seed.py --no-clear # idempotent re-run
cd backend && uv run python seed.py --db sqlite+aiosqlite:///./other.db
```

The script inserts in foreign-key order and then **reconciles derived counters**
(`upvotes_count`, `comments_count`, `flag_count`, `confirmations_count`,
`disputes_count`) from the child tables, and derives each `geohash` and
`anon_id` from the live `LOCALLENS_JWT_SECRET` — so the database matches exactly
what the API would return.

## What is seeded

| Area | Rows | Notes |
|------|------|-------|
| Users | 10 | admin, representative, 7 citizens, 1 banned reporter |
| Issues | 19 | categories `road water power lighting waste sewage other`; statuses `unacknowledged under_review escalating forwarded pending_quorum resolved disputed`; anonymous, fuzzed + shielded variants; one hidden |
| Comments | 19 | nested reply threads on 9 issues |
| Upvotes | 91 | spread across 18 issues |
| Notifications | 16 | `escalation`, `quorum_request`, `upvote_milestone`, `comment_reply`, `system_notice` |
| Flags / Moderation | 7 / 2 | spam + fake-report flags; `dismiss` + `ban_reporter` audits |
| Gamification | 8 profiles / 16 badges | streaks 0–12; `first_report`, `civic_voter`, `quorum_hero`, `streak_master` |
| Official responses | 5 | `acknowledged` / `in_progress` on ward issues |
| Quorum votes | 9 | confirms driving `resolved`, dispute driving `disputed` |

## Signing in as seeded users

All users authenticate via OTP. With the dev config, use `LOCALLENS_OTP_MASTER_CODE`
(or read the code from the backend log):

- **Admin**: phone `+919800000001` → open `/api/v1/admin/flagged-issues`.
- **Ward councillor**: phone `+919800000002` → open the representative dashboard.
- **Citizens**: phones `+919876500001` … `+919876500007`, plus email-only `priya.nair@example.com`.

## Images

The media pipeline is not wired into the database schema yet (see
`LocalLens_Feature_Checklist.md` — "Media: image carousel …" is pending), so
each `issues.json` entry carries an `image` field pointing at the matching SVG
under `seed/images/<category>/`. When media upload lands, these become the
attachments for the seeded reports.
