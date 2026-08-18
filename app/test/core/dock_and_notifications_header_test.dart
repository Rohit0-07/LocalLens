import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/app.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/notifications/presentation/controllers/notifications_controller.dart';

import '../features/feed/multi_feed_talk_extended_test.dart';

class FakeLocalStoreForDock implements LocalStore {
  @override
  bool hasCompletedOnboarding() => true;

  @override
  String? restoreAccessToken() => 'token';

  @override
  String? restoreUserId() => '1';

  @override
  String? getString(String key) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepoForDock implements AuthRepository {
  @override
  Future<Session> verifyOtp({required String phone, required String code}) async =>
      const Session(accessToken: 'token', userId: 1);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Social Dock 5-Icon & Top Header Notifications Tests', () {
    testWidgets('Renders 5 bottom dock tabs with centered create button and top notification bell with badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(FakeLocalStoreForDock()),
            authRepositoryProvider.overrideWithValue(FakeAuthRepoForDock()),
            feedRepositoryProvider.overrideWithValue(
              FakeMultiTypeFeedRepository(items: []),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 3),
          ],
          child: const LocalLensApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify bottom dock tabs (Home, Map, Reels, Profile)
      expect(find.byKey(const Key('dockTab0')), findsOneWidget); // Home
      expect(find.byKey(const Key('dockTab1')), findsOneWidget); // Map
      expect(find.byKey(const Key('createDockButton')), findsOneWidget); // Centered Create Action
      expect(find.byKey(const Key('dockTab2')), findsOneWidget); // Reels
      expect(find.byKey(const Key('dockTab3')), findsOneWidget); // Profile

      // Verify Inbox dock tab is removed from the bottom bar
      expect(find.byKey(const Key('dockTab4')), findsNothing);

      // Verify top header notification icon button is present in FeedScreen with badge '3'
      expect(find.byKey(const Key('feedNotificationButton')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
