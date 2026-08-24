import 'dart:convert';
import 'dart:typed_data';

import '../../../core/storage/local_store.dart';
import '../../feed/domain/feed_repository.dart';
import '../../feed/presentation/feed_providers.dart';
import '../domain/captured_media.dart';
import '../domain/compose_draft.dart';
import 'media_service.dart';

/// Media uploaded during a previous flush attempt of the same draft, persisted
/// so retries skip re-upload instead of creating duplicate server rows.
class _UploadedMedia {
  const _UploadedMedia(this.id, this.url);

  final String id;
  final String url;

  Map<String, String> toJson() => {'id': id, 'url': url};

  static _UploadedMedia? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final url = json['url'];
    if (id is String && id.isNotEmpty && url is String && url.isNotEmpty) {
      return _UploadedMedia(id, url);
    }
    return null;
  }
}

class OfflineOutboxQueue {
  OfflineOutboxQueue(this._localStore, this._feedRepository, this._mediaService);

  final LocalStore _localStore;
  final FeedRepository _feedRepository;
  final MediaService _mediaService;

  static const String _outboxKey = 'locallens_outbox_queue_v1';
  static const String _attemptsKey = 'locallens_outbox_attempts_v1';
  static const String _uploadsKey = 'locallens_outbox_uploads_v1';
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
    final uploads = _loadUploads();

    int successCount = 0;
    final remaining = <ComposeDraft>[];

    for (final draft in queue) {
      if ((attempts[draft.id] ?? 0) >= _maxAttempts) {
        // Permanently failing draft; drop it rather than retry forever.
        attempts.remove(draft.id);
        await _deleteUnlinkedMedia(uploads.remove(draft.id) ?? <_UploadedMedia?>[]);
        continue;
      }
      try {
        final coords = _resolveCoords(draft);
        final uploaded = uploads.putIfAbsent(
          draft.id,
          () => List<_UploadedMedia?>.filled(
            draft.media.length,
            null,
            growable: true,
          ),
        );
        final mediaUrls = <String>[];
        for (var i = 0; i < draft.media.length; i++) {
          final existing = i < uploaded.length ? uploaded[i] : null;
          if (existing != null) {
            mediaUrls.add(existing.url);
            continue;
          }
          final result = await _uploadMedia(draft.media[i], draft.isFuzzed);
          while (uploaded.length <= i) {
            uploaded.add(null);
          }
          uploaded[i] = _UploadedMedia(result.id, result.url);
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
        uploads.remove(draft.id);
        attempts.remove(draft.id);
        successCount++;
      } catch (_) {
        attempts[draft.id] = (attempts[draft.id] ?? 0) + 1;
        if ((attempts[draft.id] ?? 0) < _maxAttempts) {
          remaining.add(draft);
        } else {
          // Draft exceeded its retry budget; roll back media that were
          // uploaded but never linked to an issue, mirroring the direct path.
          await _deleteUnlinkedMedia(uploads.remove(draft.id) ?? <_UploadedMedia?>[]);
        }
      }
    }

    await _saveQueue(remaining);
    await _saveAttempts(attempts);
    await _saveUploads(uploads);
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

  Map<String, List<_UploadedMedia?>> _loadUploads() {
    final raw = _localStore.getString(_uploadsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(
          k as String,
          (v as List<Object?>?)
                  ?.map(_UploadedMedia.fromJson)
                  .toList() ??
              <_UploadedMedia?>[],
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUploads(Map<String, List<_UploadedMedia?>> uploads) async {
    await _localStore.setString(
      _uploadsKey,
      jsonEncode(uploads.map(
        (k, v) => MapEntry(k, v.map((e) => e?.toJson()).toList()),
      )),
    );
  }

  /// Deletes server media rows that were uploaded but never linked to an
  /// issue, mirroring the direct-publish path's rollback.
  Future<void> _deleteUnlinkedMedia(List<_UploadedMedia?> uploaded) async {
    for (final entry in uploaded) {
      final id = entry?.id;
      if (id == null || id.isEmpty) continue;
      try {
        await _mediaService.deleteMedia(id);
      } catch (_) {}
    }
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