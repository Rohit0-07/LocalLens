import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../data/hive_draft_store.dart';
import '../data/media_service.dart';
import '../data/offline_outbox_queue.dart';
import '../domain/captured_media.dart';
import '../domain/compose_draft.dart';
import '../domain/draft_store.dart';
import '../domain/near_duplicate_candidate.dart';
import 'media_library_providers.dart';

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

/// Resolves the issue coordinates for a publish: the first attached photo
/// with GPS wins, then the draft's explicit location lock, then the feed
/// reference point.
Future<({double lat, double lng})> resolveComposeCoords(
  Ref ref,
  ComposeDraft draft,
  List<CapturedMedia> media,
) async {
  final gpsMedia = media.where((m) => m.hasGps).firstOrNull;
  if (gpsMedia != null) {
    return (lat: gpsMedia.capturedLat!, lng: gpsMedia.capturedLng!);
  }
  if (draft.latitude != null && draft.longitude != null) {
    return (lat: draft.latitude!, lng: draft.longitude!);
  }
  return _createCoords(ref);
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
    ref.watch(mediaServiceProvider),
  );
});

final nearDuplicateCheckProvider =
    FutureProvider.family<
      List<NearDuplicateCandidate>,
      ({double lat, double lng, String? category})
    >((ref, params) async {
      final repo = ref.watch(feedRepositoryProvider);
      return repo.checkNearDuplicates(
        latitude: params.lat,
        longitude: params.lng,
        category: params.category,
        radiusKm: 0.030,
      );
    });

final composeControllerProvider =
    NotifierProvider<ComposeController, ComposeDraft>(ComposeController.new);

class ComposeController extends Notifier<ComposeDraft> {
  Timer? _autosaveTimer;

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
    // Debounce the autosave write so fast typing doesn't clobber the draft
    // store on every keystroke. Media is persisted too, so a restart restores
    // attachments instead of dropping them.
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(draftStoreProvider).save(state);
    });
  }

  /// Pre-fills the controller with a draft opened from the Drafts page.
  void loadDraft(ComposeDraft draft) {
    _autosaveTimer?.cancel();
    state = draft;
  }

  /// Persists the current composition as a saved draft. When the composition
  /// already belongs to a saved draft (opened from the Drafts page) the same
  /// item is updated in place rather than duplicated.
  Future<ComposeDraft> saveAsDraft({
    List<CapturedMedia> media = const [],
  }) async {
    _autosaveTimer?.cancel();
    final current = state;
    final now = DateTime.now();
    final draft = current.copyWith(
      id: current.id.isNotEmpty ? current.id : _generateDraftId(),
      createdAt: current.createdAt ?? now,
      updatedAt: now,
      media: media,
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
    _autosaveTimer?.cancel();
    final current = state;
    if (current.id.isNotEmpty) {
      await ref.read(draftStoreProvider).deleteItem(current.id);
    }
    await ref.read(draftStoreProvider).clear();
    state = const ComposeDraft();
  }

  /// Uploads the attached captured media (if any) and publishes the issue
  /// with the resulting media URLs. Falls back to the offline outbox on
  /// failure.
  Future<bool> submit({
    List<CapturedMedia> media = const [],
  }) async {
    _autosaveTimer?.cancel();
    final current = state;
    final repo = ref.read(feedRepositoryProvider);
    final outbox = ref.read(offlineOutboxProvider);

    final coords = await resolveComposeCoords(ref, current, media);
    final lat = coords.lat;
    final lng = coords.lng;

    List<String> mediaUrls = const [];
    List<String> uploadedMediaIds = const [];
    MediaService? mediaService;
    bool directSuccess = false;
    try {
      if (media.isNotEmpty) {
        final svc = ref.read(mediaServiceProvider);
        mediaService = svc;
        final capturedMediaStore = ref.read(capturedMediaStoreProvider);
        final results = <String>[];
        for (final m in media) {
          final result = await svc.uploadMedia(
            bytes: base64Decode(m.bytesBase64),
            isInAppCamera: true,
            capturedLat: m.capturedLat,
            capturedLng: m.capturedLng,
            isFuzzed: current.isFuzzed,
            capturedAt: m.capturedAt,
          );
          results.add(result.url);
          uploadedMediaIds = [...uploadedMediaIds, result.id];
          await capturedMediaStore.markUploaded(m.id, result.id);
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
      // Roll back media that were uploaded but never linked to an issue, so
      // the outbox retry doesn't duplicate them server-side.
      for (final mediaId in uploadedMediaIds) {
        try {
          await mediaService?.deleteMedia(mediaId);
        } catch (_) {}
      }
      await outbox.enqueue(
        current.copyWith(media: media, latitude: lat, longitude: lng),
      );
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