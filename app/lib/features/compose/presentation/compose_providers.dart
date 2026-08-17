import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../data/hive_draft_store.dart';
import '../data/media_service.dart';
import '../data/offline_outbox_queue.dart';
import '../domain/compose_draft.dart';
import '../domain/draft_store.dart';
import '../domain/near_duplicate_candidate.dart';

/// Resolves the coordinates to create an issue at, using the exact same
/// coordinate source as the home feed (`feedCoordinatesProvider`). This
/// guarantees a newly created issue always falls inside the feed's query
/// radius; using real device GPS here while the feed anchors to the fixed
/// reference point could otherwise make new issues invisible.
Future<({double lat, double lng})> _createCoords(Ref ref) async {
  try {
    return await ref.read(feedCoordinatesProvider.future);
  } catch (_) {
    return (lat: defaultLatitude, lng: defaultLongitude);
  }
}

final draftStoreProvider = Provider<DraftStore>(
  (ref) => HiveDraftStore(ref.watch(localStoreProvider)),
);

/// The multi-draft list backing the Drafts page. Auto-disposes so a fresh
/// read happens each time the page is opened; explicit invalidation after
/// save/delete keeps an already-open page in sync.
final savedDraftsProvider = FutureProvider.autoDispose<List<ComposeDraft>>(
  (ref) async => ref.watch(draftStoreProvider).loadAll(),
);

final offlineOutboxProvider = Provider<OfflineOutboxQueue>((ref) {
  return OfflineOutboxQueue(
    ref.watch(localStoreProvider),
    ref.watch(feedRepositoryProvider),
  );
});

final nearDuplicateCheckProvider =
    FutureProvider.family<
      List<NearDuplicateCandidate>,
      ({double lat, double lng})
    >((ref, pos) async {
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
    // The single autosave draft never carries media bytes: attachments live
    // in widget state (and in saved drafts) and are re-attached on restore.
    await ref
        .read(draftStoreProvider)
        .save(draft.copyWith(mediaBytes: const []));
  }

  /// Pre-fills the controller with a draft opened from the Drafts page.
  void loadDraft(ComposeDraft draft) {
    state = draft;
  }

  /// Persists the current composition as a saved draft. When the composition
  /// already belongs to a saved draft (opened from the Drafts page) the same
  /// item is updated in place rather than duplicated.
  Future<ComposeDraft> saveAsDraft({List<String> mediaBytes = const []}) async {
    final current = state;
    final now = DateTime.now();
    final draft = current.copyWith(
      id: current.id.isNotEmpty ? current.id : _generateDraftId(),
      createdAt: current.createdAt ?? now,
      updatedAt: now,
      mediaBytes: mediaBytes,
    );
    await ref.read(draftStoreProvider).saveItem(draft);
    state = draft;
    return draft;
  }

  Future<void> deleteSavedDraft(String id) async {
    await ref.read(draftStoreProvider).deleteItem(id);
  }

  /// Discards the current draft without publishing it.
  Future<void> discard() async {
    final current = state;
    if (current.id.isNotEmpty) {
      await ref.read(draftStoreProvider).deleteItem(current.id);
    }
    await ref.read(draftStoreProvider).clear();
    state = const ComposeDraft();
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

    // Use the same coordinate resolution as the home feed so the created
    // issue is guaranteed to be visible in the feed's query radius. Prefer
    // the draft's explicit location (locked by the user) when present.
    var lat = current.latitude;
    var lng = current.longitude;
    if (lat == null || lng == null) {
      final coords = await _createCoords(ref);
      lat = coords.lat;
      lng = coords.lng;
    }

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
        latitude: lat,
        longitude: lng,
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

    if (current.id.isNotEmpty) {
      await ref.read(draftStoreProvider).deleteItem(current.id);
    }
    await ref.read(draftStoreProvider).clear();
    state = const ComposeDraft();
    return directSuccess;
  }
}

String _generateDraftId() => 'draft_${DateTime.now().microsecondsSinceEpoch}';
