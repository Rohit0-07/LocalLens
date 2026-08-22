# cw-card-actions: Give Community Win cards the same action buttons as issue posts

Status: Done

## Summary

Community Win cards (`WinCard`) only expose a header Share button, while issue
posts (`IssueCard`) show a full action set: like/upvote, comment, share, and
report (flag) via an overflow menu. Users expect parity so they can like,
discuss, share and flag a win without opening the underlying issue detail.
Every win points back to its source issue (`WinItem.issueId`), so all four
actions can delegate to the existing issue-scoped endpoints
(`/issues/{id}/upvote`, `/issues/{id}/comments`, `/issues/{id}/flag`) — no new
backend endpoints or migrations required.

## Files to touch

- `app/lib/features/feed/presentation/widgets/social_action.dart` — NEW: extract
  `SocialAction` + `CommentCount` from `issue_card.dart` (private there today)
  so both cards share one implementation.
- `app/lib/features/feed/presentation/widgets/issue_card.dart` — swap private
  `_SocialAction` / `_CommentCount` usages to the extracted shared widgets;
  behaviour unchanged.
- `app/lib/features/feed/presentation/widgets/win_card.dart` — convert to
  `ConsumerStatefulWidget`; replace header share button with the same overflow
  menu (report → `FlagIssueDialog`, guest-gated via `GuestGuard`) as IssueCard;
  add footer action row mirroring IssueCard: like (upvote via
  `multiTypeFeedProvider.toggleUpvote(win.issueId, ...)` with local optimistic
  state), comment (bottom-sheet hosting `CommentsSection(issueId:)`), share
  (existing deep-link share moved to footer row).
- `app/test/features/feed/win_card_actions_test.dart` — NEW: widget tests for
  the four actions on `WinCard`.
- Existing feed tests asserting the win-card share button may need key/locator
  updates (`app/test/features/feed/*`).

## Out of scope

- Backend changes: no new fields on `WinOut` (e.g. server-side
  `upvotes_count` / `has_upvoted` on wins). The win like button therefore shows
  local optimistic state only; syncing authoritative counts is future work.
- Any changes to comments, flagging or upvote business logic/endpoints.
- i18n additions: reuse existing keys (`flag_issue`, `action_share`); no new
  user-facing strings.

## Verify command

```sh
cd app && flutter analyze && flutter test test/features/feed
```

## Notes

- Mirror IssueCard patterns exactly: keys (`upvote_button_{id}`,
  `comment_button_{id}`, `share_button_{id}`, `flagIssueOption_{id}` — keyed by
  `win.issueId`), error snackbar via `upvoteErrorMessage`, guest gating via
  `sessionProvider` + `GuestGuard`.
- Upvote proximity/rate-limit errors apply (they are issue-scoped); surface them
  through the same snackbar path as IssueCard.
- Card tap still navigates to the underlying issue detail.
