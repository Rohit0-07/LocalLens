import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/domain/captured_media.dart';
import 'package:local_lens/features/compose/data/captured_media_store.dart';
import 'package:local_lens/features/compose/presentation/media_library_screen.dart';
import 'package:local_lens/features/compose/presentation/media_library_providers.dart';

import '../../helpers.dart';

/// In-memory CapturedMediaStore fake mirroring the real store's contract so
/// the real CapturedMediaListController acts on it (loadAll / save / deleteMany /
/// markUploaded are what the screen and controller actually call).
class FakeCapturedMediaStore implements CapturedMediaStore {
  FakeCapturedMediaStore({List<CapturedMedia>? initial})
      : items = List.of(initial ?? const []);

  final List<CapturedMedia> items;
  final List<String> removedIds = [];

  @override
  List<CapturedMedia> loadAll() => List.of(items);

  @override
  Future<void> save(CapturedMedia media) async {
    items.removeWhere((m) => m.id == media.id || m.bytesBase64 == media.bytesBase64);
    items.insert(0, media);
  }

  Future<void> remove(String id) async {
    removedIds.add(id);
    items.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> delete(String id) async {
    removedIds.add(id);
    items.removeWhere((m) => m.id == id);
  }

  Future<void> deleteItem(String id) async {
    removedIds.add(id);
    items.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    removedIds.addAll(ids);
    items.removeWhere((m) => ids.contains(m.id));
  }

  @override
  Future<void> saveAll(List<CapturedMedia> items) async {
    for (final m in items) {
      await save(m);
    }
  }

  @override
  Future<void> markUploaded(String id, String remoteMediaId) async {}

  @override
  void clearAll() {
    items.clear();
  }
}

/// FakeMediaService recording deleteMedia calls (contract: add a FakeMediaService
/// recording uploadMedia/deleteMedia calls). Signature follows the F-A plan:
/// `deleteMedia(mediaId)` mirrors `DELETE /api/v1/media/{id}`.
class FakeMediaService extends MediaService {
  final List<String> deleteCalls = [];

  @override
  Future<void> deleteMedia(String mediaId) async {
    deleteCalls.add(mediaId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CapturedMedia _media(String id, {double? lat, double? lng}) {
  return CapturedMedia(
    id: id,
    bytesBase64: 'aGVsbG8=',
    capturedLat: lat,
    capturedLng: lng,
  );
}

Widget _buildLibrary({
  required FakeCapturedMediaStore store,
  bool pickMode = false,
}) {
  return ProviderScope(
    overrides: [
      capturedMediaStoreProvider.overrideWithValue(store),
      capturedMediaListProvider.overrideWith(CapturedMediaListController.new),
      mediaServiceProvider.overrideWithValue(FakeMediaService()),
      ...mockOverrides(
        authRepository: FakeAuthRepository(),
        feedRepository: FakeFeedRepository(),
      ),
    ],
    child: MaterialApp(
      home: MediaLibraryScreen(pickMode: pickMode),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CapturedMediaLibrary', () {
    testWidgets('lists captured images', (tester) async {
      final store = FakeCapturedMediaStore(
        initial: [_media('media_1'), _media('media_2')],
      );
      await tester.pumpWidget(
        _buildLibrary(store: store),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mediaItem_media_1')), findsOneWidget);
      expect(find.byKey(const Key('mediaItem_media_2')), findsOneWidget);
    });

    testWidgets('empty state shows mediaLibraryEmptyState', (tester) async {
      final store = FakeCapturedMediaStore();
      await tester.pumpWidget(
        _buildLibrary(store: store),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mediaLibraryEmptyState')), findsOneWidget);
    });

    testWidgets('single delete asks confirmation and removes item from store',
        (tester) async {
      final store = FakeCapturedMediaStore(
        initial: [_media('media_1'), _media('media_2')],
      );
      await tester.pumpWidget(
        _buildLibrary(store: store),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mediaDelete_media_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmDeleteMediaButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDeleteMediaButton')));
      await tester.pumpAndSettle();

      expect(store.removedIds, ['media_1']);
      expect(store.items.map((m) => m.id), isNot(contains('media_1')));
    });

    testWidgets('select mode selects all and batch deletes with confirm',
        (tester) async {
      final store = FakeCapturedMediaStore(
        initial: [_media('media_1'), _media('media_2')],
      );
      await tester.pumpWidget(
        _buildLibrary(store: store),
      );
      await tester.pumpAndSettle();

      // Enter select mode.
      await tester.tap(find.byKey(const Key('mediaSelectModeButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mediaSelectAllButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mediaDeleteSelectedButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteMediaButton')));
      await tester.pumpAndSettle();

      expect(store.removedIds, containsAll(['media_1', 'media_2']));
      expect(store.items, isEmpty);
    });

    testWidgets('pick mode pops with exactly the selected media',
        (tester) async {
      final store = FakeCapturedMediaStore(
        initial: [_media('media_1'), _media('media_2'), _media('media_3')],
      );
      List<CapturedMedia>? popped;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capturedMediaStoreProvider.overrideWithValue(store),
            capturedMediaListProvider.overrideWith(CapturedMediaListController.new),
            mediaServiceProvider.overrideWithValue(FakeMediaService()),
            ...mockOverrides(
              authRepository: FakeAuthRepository(),
              feedRepository: FakeFeedRepository(),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      popped = await Navigator.of(context).push<List<CapturedMedia>>(
                        MaterialPageRoute(
                          builder: (_) => MediaLibraryScreen(pickMode: true),
                        ),
                      );
                    },
                    child: const Text('open library'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open library'));
      await tester.pumpAndSettle();

      // Select exactly 2 of the 3 media items.
      await tester.tap(find.byKey(const Key('mediaItem_media_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mediaItem_media_2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addSelectedMediaButton')));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.map((m) => m.id).toList(), ['media_1', 'media_2']);
    });
  });
}
