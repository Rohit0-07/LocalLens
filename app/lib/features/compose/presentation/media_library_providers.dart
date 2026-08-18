import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/captured_media_store.dart';
import '../data/media_service.dart';
import '../domain/captured_media.dart';

final capturedMediaStoreProvider = Provider<CapturedMediaStore>(
  (ref) => CapturedMediaStore(ref.watch(localStoreProvider)),
);

/// The captured-media library list. Loads from the local store on build and
/// exposes delete/mark-uploaded mutations that keep the store in sync.
final capturedMediaListProvider =
    NotifierProvider<CapturedMediaListController, List<CapturedMedia>>(
      CapturedMediaListController.new,
    );

class CapturedMediaListController
    extends Notifier<List<CapturedMedia>> {
  @override
  List<CapturedMedia> build() {
    return ref.watch(capturedMediaStoreProvider).loadAll();
  }

  void refresh() {
    state = ref.read(capturedMediaStoreProvider).loadAll();
  }

  /// Removes the given ids from the local library.
  Future<void> delete(List<String> ids) async {
    await ref.read(capturedMediaStoreProvider).deleteMany(ids);
    refresh();
  }

  /// Best-effort server delete for every selected item that has a
  /// `remoteMediaId`. On a 409 (attached to a published report) the local
  /// record is kept and the caller is informed via the returned message;
  /// on success the record is removed locally.
  Future<String?> deleteWithServer(List<CapturedMedia> items) async {
    final mediaService = ref.read(mediaServiceProvider);
    final store = ref.read(capturedMediaStoreProvider);
    final removed = <String>[];
    String? blockedMessage;

    for (final item in items) {
      final remoteId = item.remoteMediaId;
      if (remoteId == null || remoteId.isEmpty) {
        removed.add(item.id);
        continue;
      }
      try {
        await mediaService.deleteMedia(remoteId);
        removed.add(item.id);
      } on MediaDeleteException catch (e) {
        if (e.code == 'media_linked_to_issue') {
          blockedMessage ??= 'Attached to a published report';
        } else {
          removed.add(item.id);
        }
      } catch (_) {
        removed.add(item.id);
      }
    }

    if (removed.isNotEmpty) {
      await store.deleteMany(removed);
    }
    refresh();
    return blockedMessage;
  }

  Future<void> markUploaded(String id, String remoteMediaId) async {
    await ref.read(capturedMediaStoreProvider).markUploaded(id, remoteMediaId);
    refresh();
  }
}