import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/domain/captured_media.dart';
import 'package:local_lens/features/compose/data/captured_media_store.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/media_library_providers.dart';
import 'package:local_lens/features/feed/domain/issue.dart';

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

class UploadCall {
  UploadCall({
    required this.bytes,
    required this.isInAppCamera,
    this.capturedLat,
    this.capturedLng,
    this.capturedAt,
    required this.isFuzzed,
    this.filename,
    required this.url,
  });

  final Uint8List bytes;
  final bool isInAppCamera;
  final double? capturedLat;
  final double? capturedLng;
  final DateTime? capturedAt;
  final bool isFuzzed;
  final String? filename;
  final String url;
}

/// FakeMediaService recording uploadMedia/deleteMedia calls (contract).
class FakeMediaService extends MediaService {
  final List<UploadCall> uploadCalls = [];
  final List<String> deleteCalls = [];

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
    final url = '/api/v1/media/files/media_${uploadCalls.length + 1}.jpg';
    uploadCalls.add(UploadCall(
      bytes: bytes,
      isInAppCamera: isInAppCamera,
      capturedLat: capturedLat,
      capturedLng: capturedLng,
      capturedAt: capturedAt,
      isFuzzed: isFuzzed,
      filename: filename,
      url: url,
    ));
    final verified = isInAppCamera && capturedLat != null && capturedLng != null;
    return MediaUploadResult(
      id: 'media_${uploadCalls.length}',
      url: url,
      thumbnailUrl: '/api/v1/media/files/thumb_media_${uploadCalls.length}.jpg',
      isVerified: verified,
      watermarkLabel: verified ? 'LocalLens Verified' : 'User Uploaded - Unverified',
      derivedHash: 'hash_${uploadCalls.length}',
      latitude: capturedLat,
      longitude: capturedLng,
      isFuzzed: isFuzzed,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    deleteCalls.add(mediaId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CreateIssueCall {
  CreateIssueCall({
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isAnonymous,
    required this.isFuzzed,
    required this.isShielded,
    required this.mediaUrls,
  });

  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final bool isAnonymous;
  final bool isFuzzed;
  final bool isShielded;
  final List<String> mediaUrls;
}

class TrackingFeedRepository extends FakeFeedRepository {
  final List<CreateIssueCall> createIssueCalls = [];

  @override
  Future<Issue> createIssue({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required bool isAnonymous,
    bool isFuzzed = false,
    bool isShielded = false,
    List<String> mediaUrls = const [],
  }) async {
    createIssueCalls.add(CreateIssueCall(
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      isAnonymous: isAnonymous,
      isFuzzed: isFuzzed,
      isShielded: isShielded,
      mediaUrls: List.of(mediaUrls),
    ));
    return buildIssue(title: title);
  }
}

class _FakeLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer({
    required FakeMediaService mediaService,
    required TrackingFeedRepository feedRepository,
  }) {
    return ProviderContainer(
      overrides: [
        capturedMediaStoreProvider.overrideWithValue(FakeCapturedMediaStore()),
        mediaServiceProvider.overrideWithValue(mediaService),
        localStoreProvider.overrideWithValue(MemoryLocalStore()),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ...mockOverrides(
          authRepository: FakeAuthRepository(),
          feedRepository: feedRepository,
        ),
      ],
    );
  }

  ComposeDraft buildDraft() {
    return ComposeDraft(
      title: 'Broken streetlight at corner',
      description: 'Dark area at night',
      category: 'lighting',
      latitude: 19.11,
      longitude: 72.87,
      isAnonymous: true,
    );
  }

  test(
      'submit passes GPS metadata + in-app flag to uploadMedia and coords + URL to createIssue',
      () async {
    final mediaService = FakeMediaService();
    final feedRepository = TrackingFeedRepository();
    final container = buildContainer(
      mediaService: mediaService,
      feedRepository: feedRepository,
    );
    addTearDown(container.dispose);

    final controller = container.read(composeControllerProvider.notifier);
    controller.update(buildDraft());

    final capturedAt = DateTime.utc(2026, 8, 19, 10, 30);
    final media = CapturedMedia(
      bytesBase64: 'aGVsbG8=',
      capturedLat: 19.11,
      capturedLng: 72.87,
      capturedAt: capturedAt,
    );

    await controller.submit(media: [media]);

    expect(mediaService.uploadCalls, hasLength(1));
    final upload = mediaService.uploadCalls.single;
    expect(upload.isInAppCamera, isTrue);
    expect(upload.capturedLat, 19.11);
    expect(upload.capturedLng, 72.87);
    expect(upload.capturedAt, capturedAt);

    expect(feedRepository.createIssueCalls, hasLength(1));
    final issue = feedRepository.createIssueCalls.single;
    expect(issue.latitude, 19.11);
    expect(issue.longitude, 72.87);
    expect(issue.mediaUrls, [upload.url]);
  });

  test('media without GPS falls back to draft latitude/longitude', () async {
    final mediaService = FakeMediaService();
    final feedRepository = TrackingFeedRepository();
    final container = buildContainer(
      mediaService: mediaService,
      feedRepository: feedRepository,
    );
    addTearDown(container.dispose);

    final controller = container.read(composeControllerProvider.notifier);
    controller.update(buildDraft());

    final media = CapturedMedia(bytesBase64: 'aGVsbG8='); // no GPS

    await controller.submit(media: [media]);

    expect(feedRepository.createIssueCalls, hasLength(1));
    final issue = feedRepository.createIssueCalls.single;
    expect(issue.latitude, 19.11); // draft fallback
    expect(issue.longitude, 72.87); // draft fallback
    expect(issue.mediaUrls, hasLength(1));
  });
}
