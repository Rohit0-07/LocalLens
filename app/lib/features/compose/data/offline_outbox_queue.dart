import 'dart:convert';
import 'dart:typed_data';

import '../../../core/storage/local_store.dart';
import '../../feed/domain/feed_repository.dart';
import '../../feed/presentation/feed_providers.dart';
import '../domain/captured_media.dart';
import '../domain/compose_draft.dart';
import 'media_service.dart';

class OfflineOutboxQueue {
  OfflineOutboxQueue(this._localStore, this._feedRepository, this._mediaService);

  final LocalStore _localStore;
  final FeedRepository _feedRepository;
  final MediaService _mediaService;

  static const String _outboxKey = 'locallens_outbox_queue_v1';
  static const String _attemptsKey = 'locallens_outbox_attempts_v1';
  static const int _maxAttempts = 5;

  int get pendingCount => getPendingQueue().length;

  Future<void> _inFlight = Future.value();

  /// Rejects concurrent flushes by deferring to the one already running, so a
  /// radio flap + app-start sync can't publish the same draft twice.
  Future<int> flush() {
    final running = _inFlight;
    final next = running.then((_) => _flushInternal());
    _inFlight = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  Future<int> _flushInternal() async {
    final queue = getPendingQueue();
    if (queue.isEmpty) return 0;

    final attempts = _loadAttempts();

    int successCount = 0;
    final remaining = <ComposeDraft>[];

    for (final draft in queue) {
      if ((attempts[draft.id] ?? 0) >= _maxAttempts) {
        // Permanently failing draft; drop it rather than retry forever.
        attempts.remove(draft.id);
        continue;
      }
      try {
        final coords = _resolveCoords(draft);
        final mediaUrls = <String>[];
        for (final media in draft.media) {
          final result = await _uploadMedia(media, draft.isFuzzed);
          mediaUrls.add(result.url);
        }
        await _feedRepository.createIssue(
          title: draft.title,
          description: draft.description,
          category: draft.category,
          latitude: coords.lat,
          longitude: coords.lng,
          isAnonymous: draft.isAnonymous,
          isFuzzed: draft.isFuzzed,
          isShielded: draft.isShielded,
          mediaUrls: mediaUrls,
        );
        attempts.remove(draft.id);
        successCount++;
      } catch (_) {
        attempts[draft.id] = (attempts[draft.id] ?? 0) + 1;
        if ((attempts[draft.id] ?? 0) < _maxAttempts) {
          remaining.add(draft);
        }
      }
    }

    await _saveQueue(remaining);
    await _saveAttempts(attempts);
    return successCount;
  }

  Map<String, int> _loadAttempts() {
    final raw = _localStore.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k as String, (v as num?)?.toInt() ?? 0));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAttempts(Map<String, int> attempts) async {
    await _localStore.setString(_attemptsKey, jsonEncode(attempts));
  }

  List<ComposeDraft> getPendingQueue() {
    final raw = _localStore.getString(_outboxKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => ComposeDraft.fromJson(item as Map<String, Object?>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> enqueue(ComposeDraft draft) async {
    final queue = getPendingQueue();
    queue.add(draft);
    await _saveQueue(queue);
  }

  Future<void> removeAt(int index) async {
    final queue = getPendingQueue();
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    await _saveQueue(queue);
  }

  Future<void> removeAll() async {
    await _saveQueue([]);
  }

  Future<void> _saveQueue(List<ComposeDraft> queue) async {
    final raw = jsonEncode(queue.map((d) => d.toJson()).toList());
    await _localStore.setString(_outboxKey, raw);
  }

  /// Resolves the issue coordinates for an outbox draft: explicit draft lock
  /// first, then the first attached photo's GPS, then the feed reference point.
  ({double lat, double lng}) _resolveCoords(ComposeDraft draft) {
    final gpsMedia = draft.media.where((m) => m.hasGps).firstOrNull;
    final lat = draft.latitude ?? gpsMedia?.capturedLat ?? defaultLatitude;
    final lng = draft.longitude ?? gpsMedia?.capturedLng ?? defaultLongitude;
    return (lat: lat, lng: lng);
  }

  Future<MediaUploadResult> _uploadMedia(
    CapturedMedia media,
    bool isFuzzed,
  ) async {
    Uint8List bytes;
    try {
      bytes = base64Decode(media.bytesBase64);
    } catch (_) {
      bytes = Uint8List(0);
    }
    return _mediaService.uploadMedia(
      bytes: bytes,
      isInAppCamera: true,
      capturedLat: media.capturedLat,
      capturedLng: media.capturedLng,
      isFuzzed: isFuzzed,
      capturedAt: media.capturedAt,
    );
  }
}