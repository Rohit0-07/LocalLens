import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../domain/captured_media.dart';

/// Persists the captured-media library as a JSON array under a single
/// LocalStore key (same drafts Hive box; no core-storage edits).
class CapturedMediaStore {
  CapturedMediaStore(this._store);

  final LocalStore _store;

  static const String _libraryKey = 'locallens_captured_media_v1';

  /// Serializes read-modify-write operations so concurrent saves/deletes do
  /// not clobber each other (each mutation re-reads the latest snapshot).
  Future<void> _serialized(Future<void> Function() action) {
    final previous = _tail;
    final next = previous.then((_) => action());
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _tail = Future.value();

  /// Loads every captured photo, newest first. Malformed entries are skipped.
  List<CapturedMedia> loadAll() {
    final raw = _store.getString(_libraryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = decoded
          .whereType<Map>()
          .map((e) {
            try {
              return CapturedMedia.fromJson(e.cast<String, Object?>());
            } catch (_) {
              return null;
            }
          })
          .whereType<CapturedMedia>()
          .toList();
      items.sort((a, b) {
        final at = a.capturedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.capturedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Upserts a captured photo by id, de-duping by base64 payload so the same
  /// capture never appears twice.
  Future<void> save(CapturedMedia media) => _serialized(() async {
        final items = loadAll();
        final byId = items.indexWhere((m) => m.id == media.id);
        final byBytes = items.indexWhere((m) => m.bytesBase64 == media.bytesBase64);
        if (byId >= 0) {
          items[byId] = media;
        } else if (byBytes >= 0) {
          items[byBytes] = media;
        } else {
          items.insert(0, media);
        }
        await _write(items);
      });

  Future<void> saveAll(List<CapturedMedia> items) async {
    for (final media in items) {
      await save(media);
    }
  }

  Future<void> delete(String id) => _serialized(() async {
        final items = loadAll();
        items.removeWhere((m) => m.id == id);
        await _write(items);
      });

  Future<void> deleteMany(List<String> ids) => _serialized(() async {
        final idSet = ids.toSet();
        final items = loadAll();
        items.removeWhere((m) => idSet.contains(m.id));
        await _write(items);
      });

  /// Records the server Media id after a successful upload so the library can
  /// soft-delete the server copy later.
  Future<void> markUploaded(String id, String remoteMediaId) => _serialized(() async {
        final items = loadAll();
        final index = items.indexWhere((m) => m.id == id);
        if (index < 0) return;
        items[index] = items[index].copyWith(remoteMediaId: remoteMediaId);
        await _write(items);
      });

  void clearAll() {
    _store.setString(_libraryKey, jsonEncode(const <Object>[]));
  }

  Future<void> _write(List<CapturedMedia> items) async {
    await _store.setString(
      _libraryKey,
      jsonEncode(items.map((m) => m.toJson()).toList()),
    );
  }
}