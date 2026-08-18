import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/utils/profile_navigation.dart';
import 'package:local_lens/features/gamification/domain/gamification_models.dart';
import 'package:local_lens/features/profile/domain/public_user_profile.dart';

void main() {
  group('PublicUserProfile & BadgeItem resilient parsing', () {
    test('parses json with integer level correctly without throwing type errors', () {
      final json = {
        'id': 42,
        'username': 'civic_hero',
        'level': 3,
        'impact_score': 320,
        'issues_count': 12,
        'resolutions_count': 9,
        'upvotes_count': 45,
        'created_at': '2025-06-15T10:00:00Z',
        'badges': [
          {
            'id': 101,
            'name': 'First Alert',
            'description': 'Reported first issue',
            'icon_name': 'flag',
            'category': 'reporting',
            'threshold': 1,
            'is_unlocked': true,
          }
        ],
      };

      final profile = PublicUserProfile.fromJson(json);
      expect(profile.userId, equals(42));
      expect(profile.displayName, equals('civic_hero'));
      expect(profile.impactPoints, equals(320));
      expect(profile.level, equals('Community Sentinel')); // 320 points => Community Sentinel
      expect(profile.badges.length, equals(1));
      expect(profile.badges.first.key, equals('101'));
      expect(profile.badges.first.name, equals('First Alert'));
    });

    test('parses json with string level_name correctly', () {
      final json = {
        'user_id': 99,
        'display_name': 'District Champion User',
        'level_name': 'District Champion',
        'impact_points': 650,
      };

      final profile = PublicUserProfile.fromJson(json);
      expect(profile.userId, equals(99));
      expect(profile.displayName, equals('District Champion User'));
      expect(profile.level, equals('District Champion'));
    });

    test('BadgeItem parses integer ids as string keys safely', () {
      final badgeJson = {
        'badge_id': 505,
        'name': 'Master Resolver',
        'threshold': 10,
        'is_unlocked': false,
      };

      final badge = BadgeItem.fromJson(badgeJson);
      expect(badge.key, equals('505'));
      expect(badge.name, equals('Master Resolver'));
      expect(badge.threshold, equals(10));
      expect(badge.isUnlocked, isFalse);
    });
  });

  group('Profile Navigation & Anonymity Feedback Tests', () {
    testWidgets('openReporterProfile with null reporterId displays anonymous privacy toast', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  key: const Key('tapAnonymousUser'),
                  onPressed: () => openReporterProfile(context, ref, null),
                  child: const Text('Tap Anonymous'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('tapAnonymousUser')));
      await tester.pumpAndSettle();

      expect(
        find.text('This post is anonymous to safeguard citizen privacy & safety.'),
        findsOneWidget,
      );
    });
  });
}
