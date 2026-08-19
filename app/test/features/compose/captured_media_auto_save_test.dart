import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/domain/captured_media.dart';
import 'package:local_lens/features/compose/data/captured_media_store.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/media_library_providers.dart';

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

class FakeCapturedMediaStore implements CapturedMediaStore {
  final List<CapturedMedia> items = [];

  @override
  List<CapturedMedia> loadAll() => List.of(items);

  @override
  Future<void> save(CapturedMedia media) async {
    items.add(media);
  }

  @override
  Future<void> saveAll(List<CapturedMedia> items) async {
    for (final m in items) {
      await save(m);
    }
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    items.removeWhere((m) => ids.contains(m.id));
  }

  @override
  Future<void> markUploaded(String id, String remoteMediaId) async {}

  @override
  void clearAll() {
    items.clear();
  }
}

class FakeMediaService extends MediaService {
  @override
  Future<MediaUploadResult> uploadMedia({
    required Uint8List bytes,
    required bool isInAppCamera,
    double? capturedLat,
    double? capturedLng,
    DateTime? capturedAt,
    bool isFuzzed = false,
    String? filename,
  }) async {
    return MediaUploadResult(
      id: 'media_auto_1',
      url: '/api/v1/media/files/media_auto_1.jpg',
      thumbnailUrl: '/api/v1/media/files/thumb_media_auto_1.jpg',
      isVerified: isInAppCamera && capturedLat != null && capturedLng != null,
      watermarkLabel: 'LocalLens Verified',
      derivedHash: 'hash_auto_1',
      latitude: capturedLat,
      longitude: capturedLng,
      isFuzzed: isFuzzed,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteMedia(String mediaId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer(FakeCapturedMediaStore store) {
    return ProviderContainer(
      overrides: [
        capturedMediaStoreProvider.overrideWithValue(store),
        mediaServiceProvider.overrideWithValue(FakeMediaService()),
        localStoreProvider.overrideWithValue(MemoryLocalStore()),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ...mockOverrides(
          authRepository: FakeAuthRepository(),
          feedRepository: FakeFeedRepository(),
        ),
      ],
    );
  }

  group('Captured media auto-save', () {
    test('un-published capture survives ComposeController.discard()', () async {
      final store = FakeCapturedMediaStore();
      final container = buildContainer(store);
      addTearDown(container.dispose);

      final captured = CapturedMedia(
        bytesBase64: 'aGVsbG8=',
        capturedLat: 19.11,
        capturedLng: 72.87,
        capturedAt: DateTime.utc(2026, 8, 19, 10, 30),
      );
      // The shutter handler persists the capture to the captured-media store.
      await store.save(captured);

      // Discarding the compose draft must NOT evict the captured media
      // (un-published captures persist, req #5).
      final controller = container.read(composeControllerProvider.notifier);
      controller.discard();

      expect(store.items, contains(captured));
    });

    test('capture with GPS carries coords and hasGps; without GPS does not',
        () {
      final withGps = CapturedMedia(
        bytesBase64: 'aGVsbG8=',
        capturedLat: 19.11,
        capturedLng: 72.87,
        capturedAt: DateTime.utc(2026, 8, 19, 10, 30),
      );
      expect(withGps.hasGps, isTrue);
      expect(withGps.capturedLat, 19.11);
      expect(withGps.capturedLng, 72.87);

      final withoutGps = CapturedMedia(bytesBase64: 'aGVsbG8=');
      expect(withoutGps.hasGps, isFalse);
    });
  });
}
