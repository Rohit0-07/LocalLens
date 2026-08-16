import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../data/hive_draft_store.dart';
import '../data/media_service.dart';
import '../data/offline_outbox_queue.dart';
import '../domain/compose_draft.dart';
import '../domain/draft_store.dart';
import '../domain/near_duplicate_candidate.dart';

final draftStoreProvider = Provider<DraftStore>(
  (ref) => HiveDraftStore(ref.watch(localStoreProvider)),
);

final offlineOutboxProvider = Provider<OfflineOutboxQueue>((ref) {
  return OfflineOutboxQueue(
    ref.watch(localStoreProvider),
    ref.watch(feedRepositoryProvider),
  );
});

final nearDuplicateCheckProvider = FutureProvider.family<
    List<NearDuplicateCandidate>,
    ({double lat, double lng})>((ref, pos) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.checkNearDuplicates(latitude: pos.lat, longitude: pos.lng);
});

final composeControllerProvider =
    NotifierProvider<ComposeController, ComposeDraft>(ComposeController.new);

class ComposeController extends Notifier<ComposeDraft> {
  @override
  ComposeDraft build() {
    final store = ref.watch(localStoreProvider);
    final raw = store.loadDraft();
    if (raw == null) return const ComposeDraft();
    try {
      return ComposeDraft.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const ComposeDraft();
    }
  }

  Future<void> update(ComposeDraft draft) async {
    state = draft;
    await ref.read(draftStoreProvider).save(draft);
  }

  /// Uploads the attached media bytes (if any) and publishes the issue with
  /// the resulting media URLs. Falls back to the offline outbox on failure.
  Future<bool> submit({
    List<Uint8List> mediaBytes = const [],
    bool isInAppCamera = false,
  }) async {
    final current = state;
    final repo = ref.read(feedRepositoryProvider);
    final outbox = ref.read(offlineOutboxProvider);

    List<String> mediaUrls = const [];
    bool directSuccess = false;
    try {
      if (mediaBytes.isNotEmpty) {
        final mediaService = ref.read(mediaServiceProvider);
        final results = <String>[];
        for (final bytes in mediaBytes) {
          final result = await mediaService.uploadMedia(
            bytes: bytes,
            isInAppCamera: isInAppCamera,
            isFuzzed: current.isFuzzed,
          );
          results.add(result.url);
        }
        mediaUrls = results;
      }
      await repo.createIssue(
        title: current.title,
        description: current.description,
        category: current.category,
        latitude: current.latitude ?? defaultLatitude,
        longitude: current.longitude ?? defaultLongitude,
        isAnonymous: current.isAnonymous,
        isFuzzed: current.isFuzzed,
        isShielded: current.isShielded,
        mediaUrls: mediaUrls,
      );
      directSuccess = true;
    } catch (_) {
      await outbox.enqueue(current);
      directSuccess = false;
    }

    await ref.read(draftStoreProvider).clear();
    state = const ComposeDraft();
    return directSuccess;
  }
}

