## Issue no 1: on clicking like button the name changes and it displays Verified citizen

this is not the intended behaviour why would it change to verified citizen

Status: Fixed — upvote/acknowledge/resolution/quorum/reassign endpoints returned issues
without an eagerly-loaded reporter, so `reporter_label_for` fell back to "Verified citizen".
Mutation endpoints in `backend/app/features/issues/service.py` now reload via
`_reloaded_issue` (selectinload reporter + assigned rep). Regression test:
`backend/tests/features/issues/test_upvote_reporter_label.py`.

## Issue no 2: The feed only displays the local ward, issues

at start it is global on refresh it get local, this is not intended behaviour
there should be a seperate option to view only the issues in the ward else all the
issues in all the ward should be visible

Status: Fixed — feed now has an explicit scope toggle: "All wards" (default)
and "My ward". `GET /feed` treats missing latitude/longitude as unscoped
(backend queries with a planetary radius); coordinates are sent only for
"My ward". Tests: `app/test/features/feed/feed_scope_test.dart`,
`backend/tests/features/feed/test_feed_scope.py`.
Ticket: `docs/tickets/feed-scope-all-wards.md`.

## Issue no 3:

On clicking the profile page, from home feed of self, it shows, a generalized old profile
with citizen#something, for representatives if they have logged in they should see there profile,
and no general plublic visble profile on their name

Status: Fixed — `Session.userId` is an int right after login but a String when
restored from storage after an app restart, so `openReporterProfile`'s
`session.userId is int` self-check silently failed and own-name taps pushed
the generic public profile ("citizen_…"). It now compares string forms, so
tapping your own name always opens your own profile tab (representatives get
their role badge + Representative Dashboard entry). Regression test:
`app/test/features/feed/reporter_navigation_test.dart`.
Ticket: `docs/tickets/own-profile-after-restart.md`.

## Issues no4:

The feed of issues, has issues which are community wins those issues are non opening one
means i cannot open those issues

Status: Fixed — `WinCard` had no tap handler on its card body (only share and
the before/after gallery responded), so community wins could not be opened.
The body is now wrapped in an InkWell that pushes
`RoutePaths.issueDetailFor(win.issueId)` (same pattern as `IssueCard`); this
also fixes win cards in search results. Regression test:
`app/test/features/feed/win_card_navigation_test.dart`.
Ticket: `docs/tickets/win-card-tap-to-open.md`.
