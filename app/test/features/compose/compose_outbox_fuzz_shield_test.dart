import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/compose/data/offline_outbox_queue.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/presentation/compose_screen.dart';

import '../../helpers.dart';

class MemoryLocalStore implements LocalStore {
  final Map<String, String> _storage = {};

  @override
  String? getString(String key) => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> clearDraft() async => _storage.remove('current_draft');

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> init() async {}

  @override
  String? loadDraft() => _storage['current_draft'];

  @override
  String? loadOutbox() => _storage['pending_outbox'];

  @override
  String? restoreAccessToken() => null;

  @override
  String? restoreUserId() => null;

  @override
  Future<void> saveDraft(String json) async => _storage['current_draft'] = json;

  @override
  Future<void> saveOutbox(String json) async => _storage['pending_outbox'] = json;

  @override
  Future<void> saveSession({required String accessToken, required Object userId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Compose Fuzz & Shield Mode and Offline Outbox Queue', () {
    test('OfflineOutboxQueue enqueues and flushes pending drafts', () async {
      final fakeRepo = FakeFeedRepository();
      final store = MemoryLocalStore();
      final outbox = OfflineOutboxQueue(store, fakeRepo);

      const draft = ComposeDraft(
        title: 'Broken streetlight at corner',
        description: 'Dark area at night',
        category: 'lighting',
        isAnonymous: true,
        isFuzzed: true,
        isShielded: true,
      );

      await outbox.enqueue(draft);
      final pending = outbox.getPendingQueue();
      expect(pending.length, 1);
      expect(pending.first.title, 'Broken streetlight at corner');
      expect(pending.first.isFuzzed, isTrue);
      expect(pending.first.isShielded, isTrue);

      final flushedCount = await outbox.flush();
      expect(flushedCount, 1);
      expect(outbox.getPendingQueue(), isEmpty);
    });

    testWidgets('ComposeScreen renders Fuzz, Shield, and Near-Duplicate buttons',
        (tester) async {
      final fakeAuth = FakeAuthRepository();
      final fakeFeed = FakeFeedRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: mockOverrides(
            authRepository: fakeAuth,
            feedRepository: fakeFeed,
          ),
          child: const MaterialApp(
            home: ComposeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compose_title')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('compose_fuzz_mode')),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('compose_fuzz_mode')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('compose_shield_mode')),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('compose_shield_mode')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('compose_anonymous')),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('compose_anonymous')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('check_near_duplicates_button')),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('check_near_duplicates_button')), findsOneWidget);
    });
  });
}
