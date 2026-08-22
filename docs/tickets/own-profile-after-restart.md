# own-profile-after-restart: Tapping your own name opened a generic public profile instead of your own profile tab

Status: Done

## Summary

bugs_remain.md Issue no 3: tapping your own reporter name from the home feed
showed a generalized public profile ("citizen_0001" / "Citizen #<id>") instead
of your own profile. Representatives who logged in likewise could not reach
their own profile (role badge + Representative Dashboard entry) this way.

Root cause: `Session.userId` is declared `Object`. Right after login the
backend returns an int, but `SessionController.build` restores the persisted
value as a **String** after an app restart. `openReporterProfile` compared
with `session.userId is int && session.userId == reporterId`, so after any
restart the self-check silently failed and every own-name tap pushed the
public profile route.

## Files to touch

- `app/lib/core/utils/profile_navigation.dart` — compare
  `session.userId.toString() == reporterId.toString()` (guest ids never
  collide because they are non-numeric).
- `app/test/features/feed/reporter_navigation_test.dart` — regression test:
  session with restored-style String userId `'42'` tapping own reporter must
  open the own-profile route, not the public profile.

## Out of scope

- Public profile content for representatives viewed by other users (by design,
  ward detail links to rep public profiles).
- Session model refactor (freezed codegen).

## Verify command

```sh
cd app && flutter analyze && flutter test test/features/feed/reporter_navigation_test.dart
```

## Notes

Test confirmed red before the fix (landed on `PUBLIC_PROFILE_42`) and green
after; all pre-existing navigation tests still pass.
