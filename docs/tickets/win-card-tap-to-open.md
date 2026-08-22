# win-card-tap-to-open: Community Win cards in feed/search are not tappable to open the underlying issue

Status: Done

## Summary

Community Win cards rendered in the feed (and search results) cannot be opened:
`WinCard` has no tap handler on its body — only the share button and the
before/after gallery respond. Users see a resolved issue ("COMMUNITY WIN") but
cannot navigate to its detail page, unlike regular `IssueCard`s which push
`/issue/:id` on tap (bugs_remain.md, Issue no 4).

## Files to touch

- `app/lib/features/feed/presentation/widgets/win_card.dart` — wrap the card
  body in an `InkWell` → `context.push(RoutePaths.issueDetailFor(win.issueId))`,
  mirroring `IssueCard` (issue_card.dart:185); nested share/gallery taps stay.
- `app/test/features/feed/win_card_navigation_test.dart` — new regression test:
  tapping the win card pushes `/issue/<id>`; share button still does not
  navigate.

## Out of scope

- Backend `/wins` payload changes (no schema change needed).
- Notice / LocalTalk card navigation behaviour.
- Search screen changes beyond what `WinCard` inherits automatically.

## Verify command

```sh
cd app && flutter analyze && flutter test test/features/feed/win_card_navigation_test.dart
```

## Notes

- `WinItem.issueId` already exists (win.dart) and `_shareWin` already builds
  `locallens://issue/<id>`; reuse `RoutePaths.issueDetailFor`.
- Gallery `GestureDetector` and share `IconButton` are nested inside the card;
  Flutter's gesture arena lets them win over the outer `InkWell`, same as the
  nested reporter `InkWell` inside `IssueCard`.
