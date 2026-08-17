import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/domain/draft_store.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/drafts_screen.dart';

import '../../helpers.dart';

class FakeDraftStore implements DraftStore {
  FakeDraftStore({List<ComposeDraft>? drafts}) : drafts = drafts ?? [];

  final List<ComposeDraft> drafts;
  final List<String> deletedIds = [];

  @override
  Future<void> save(ComposeDraft draft) async {}

  @override
  Future<void> clear() async {}

  @override
  List<ComposeDraft> loadAll() => List.of(drafts);

  @override
  Future<void> saveItem(ComposeDraft draft) async {}

  @override
  Future<void> deleteItem(String id) async {
    deletedIds.add(id);
  }
}

ComposeDraft _draft(String id, String title, {bool withMedia = false}) {
  return ComposeDraft(
    id: id,
    title: title,
    description: 'Saved description for $title',
    category: 'road',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    mediaBytes: withMedia ? ['aGVsbG8='] : const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildDraftsApp(FakeDraftStore store) {
    final router = GoRouter(
      initialLocation: RoutePaths.drafts,
      routes: [
        GoRoute(
          path: RoutePaths.drafts,
          builder: (_, _) => const DraftsScreen(),
        ),
        GoRoute(
          path: RoutePaths.compose,
          builder: (ctx, state) {
            final draft = state.extra is ComposeDraft
                ? state.extra as ComposeDraft
                : null;
            return Scaffold(
              body: Text(
                'Compose:${draft?.id ?? 'none'}:${draft?.title ?? ''}',
              ),
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        draftStoreProvider.overrideWithValue(store),
        ...mockOverrides(
          authRepository: FakeAuthRepository(),
          feedRepository: FakeFeedRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('Drafts page', () {
    testWidgets('lists saved drafts with title, meta and thumbnail', (
      tester,
    ) async {
      final store = FakeDraftStore(
        drafts: [
          _draft('draft_1', 'Draft one', withMedia: true),
          _draft('draft_2', 'Draft two'),
        ],
      );

      await tester.pumpWidget(buildDraftsApp(store));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('draftsScreen')), findsOneWidget);
      expect(find.byKey(const Key('draftItem_draft_1')), findsOneWidget);
      expect(find.byKey(const Key('draftItem_draft_2')), findsOneWidget);
      expect(find.text('Draft one'), findsOneWidget);
      expect(find.text('Draft two'), findsOneWidget);
      // Only draft_1 carries media.
      expect(find.byKey(const Key('draftThumbnail')), findsOneWidget);
      expect(find.text('1 photo'), findsOneWidget);
    });

    testWidgets('shows empty state when no drafts saved', (tester) async {
      final store = FakeDraftStore();

      await tester.pumpWidget(buildDraftsApp(store));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('draftsEmptyState')), findsOneWidget);
      expect(find.text('No drafts yet'), findsOneWidget);
    });

    testWidgets('tapping a draft navigates to compose prefilled', (
      tester,
    ) async {
      final store = FakeDraftStore(drafts: [_draft('draft_1', 'Draft one')]);

      await tester.pumpWidget(buildDraftsApp(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('draftItem_draft_1')));
      await tester.pumpAndSettle();

      expect(find.text('Compose:draft_1:Draft one'), findsOneWidget);
    });

    testWidgets('single delete shows confirmation and removes draft', (
      tester,
    ) async {
      final store = FakeDraftStore(
        drafts: [
          _draft('draft_1', 'Draft one'),
          _draft('draft_2', 'Draft two'),
        ],
      );

      await tester.pumpWidget(buildDraftsApp(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('draftDelete_draft_1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete draft?'), findsOneWidget);
      final confirm = find.byKey(const Key('confirmDeleteDraftsButton'));
      expect(confirm, findsOneWidget);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(store.deletedIds, ['draft_1']);
    });

    testWidgets(
      'batch-select mode selects all and deletes selected with confirm',
      (tester) async {
        final store = FakeDraftStore(
          drafts: [
            _draft('draft_1', 'Draft one'),
            _draft('draft_2', 'Draft two'),
          ],
        );

        await tester.pumpWidget(buildDraftsApp(store));
        await tester.pumpAndSettle();

        // Enter select mode.
        await tester.tap(find.byKey(const Key('draftSelectModeButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('draftCheckbox_draft_1')), findsOneWidget);
        expect(find.byKey(const Key('draftCheckbox_draft_2')), findsOneWidget);

        // Select all.
        await tester.tap(find.byKey(const Key('selectAllButton')));
        await tester.pumpAndSettle();
        final box1 = tester.widget<Checkbox>(
          find.byKey(const Key('draftCheckbox_draft_1')),
        );
        final box2 = tester.widget<Checkbox>(
          find.byKey(const Key('draftCheckbox_draft_2')),
        );
        expect(box1.value, isTrue);
        expect(box2.value, isTrue);

        // Delete selected.
        await tester.tap(find.byKey(const Key('deleteSelectedButton')));
        await tester.pumpAndSettle();
        expect(find.text('Delete selected drafts?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirmDeleteDraftsButton')));
        await tester.pumpAndSettle();

        expect(store.deletedIds, containsAll(['draft_1', 'draft_2']));
        // Select mode exits back to the normal app bar.
        expect(find.byKey(const Key('draftSelectModeButton')), findsOneWidget);
        expect(find.byKey(const Key('draftCheckbox_draft_1')), findsNothing);
      },
    );

    testWidgets('Done button exits batch-select mode without deleting', (
      tester,
    ) async {
      final store = FakeDraftStore(drafts: [_draft('draft_1', 'Draft one')]);

      await tester.pumpWidget(buildDraftsApp(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('draftSelectModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draftCheckbox_draft_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('draftSelectModeDoneButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('draftSelectModeButton')), findsOneWidget);
      expect(find.byKey(const Key('draftCheckbox_draft_1')), findsNothing);
      expect(store.deletedIds, isEmpty);
    });
  });
}
