# 003-rep-profile-shows-public-page

**Status:** open

## Goal

Representatives see their own representative profile from the app's profile tab, not a
generic citizen profile.

## Problem / expected behaviour

Bug report: "on clicking the profile page, from home feed of self, it shows a generalized
old profile with citizen#something; for representatives if they have logged in they should
see their profile, and no general public-visible profile on their name". Self-navigation
must open the signed-in user's own profile (representative dashboard for reps), never the
public citizen page.

## Files to touch

- `app/lib/core/utils/profile_navigation.dart`
- `app/lib/features/profile/presentation/profile_providers.dart`
- `app/lib/features/profile/presentation/screens/profile_screen.dart`

## Files NOT to touch

- Backend auth/representatives services unless proven necessary (confirm first).

## Acceptance criteria

- [ ] A logged-in representative tapping their own identity lands on their rep profile
- [ ] Public (non-self) profiles still show the generic citizen page for non-reps

## Verify

```sh
cd app && flutter analyze
flutter test test/features/profile
```