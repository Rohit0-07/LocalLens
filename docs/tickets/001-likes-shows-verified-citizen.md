# 001-likes-shows-verified-citizen

**Status:** open

## Goal

Liking an issue must not change the displayed reporter identity.

## Problem / expected behaviour

Bug report: "on clicking like button the name changes and it displays Verified citizen".
Tapping the upvote/like control mutates the card's reporter label — this is not intended.
The reporter's name/anon badge must stay exactly as it was before the like; only the
like state/count should change.

## Files to touch

- `app/lib/features/feed/presentation/widgets/issue_card.dart`

## Files NOT to touch

- Backend upvote logic (`backend/app/features/issues/`), auth, any other feature.

## Acceptance criteria

- [ ] Like/unlike updates only the like state + count; reporter name/badge unchanged
- [ ] `flutter analyze` clean; no backend changes

## Verify

```sh
cd app && flutter analyze
flutter test test/features/feed
```