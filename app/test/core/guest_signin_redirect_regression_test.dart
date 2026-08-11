import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/router/app_router.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/gamification/domain/gamification_models.dart';
import 'package:local_lens/features/gamification/presentation/gamification_providers.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

class _GuestProfileController extends GamificationProfileNotifier {
  @override
  Future<GamificationProfile> build() async {
    return const GamificationProfile(
      isGuest: true,
      impactScore: 0,
      level: 1,
      levelName: 'Civic Rookie',
      streakDays: 0,
      canClaimStreak: false,
      badges: [],
      activityCounts: ActivityCounts(),
    );
  }
}

void main() {
  testWidgets(
    'guest signing in from the streak guard lands on sign-in, not a duplicate shell',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            () => _FixedSessionController(
              const Session(accessToken: 'g', userId: 'guest:1', isGuest: true),
            ),
          ),
          gamificationProfileProvider.overrideWith(
            () => _GuestProfileController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.push('/gamification');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('claimStreakButton')));
      await tester.pumpAndSettle();

      expect(find.text('Sign in required'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('LocalLens'), findsOneWidget);
      expect(find.text('Sign in required'), findsNothing);
    },
  );

  testWidgets('non-guest signed-in user is still bounced away from auth pages',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _FixedSessionController(
            const Session(accessToken: 't', userId: 42, isGuest: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/sign-in');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/feed');
  });
}
