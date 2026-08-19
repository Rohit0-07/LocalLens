import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/data/offline_outbox_queue.dart';
import 'package:local_lens/features/compose/domain/captured_media.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'flush uploads both captured media with metadata and creates issue with URLs + coords',
      () async {
    final store = MemoryLocalStore();
    final feedRepository = TrackingFeedRepository();
    final mediaService = FakeMediaService();
    final outbox = OfflineOutboxQueue(store, feedRepository, mediaService);

    final t1 = DateTime.utc(2026, 8, 19, 9, 0);
    final t2 = DateTime.utc(2026, 8, 19, 9, 5);
    final media1 = CapturedMedia(
      bytesBase64: 'aGVsbG8=',
      capturedLat: 19.11,
      capturedLng: 72.87,
      capturedAt: t1,
    );
    final media2 = CapturedMedia(
      bytesBase64: 'd29ybGQ=',
      capturedLat: 19.12,
      capturedLng: 72.88,
      capturedAt: t2,
    );

    final draft = ComposeDraft(
      title: 'Broken streetlight at corner',
      description: 'Dark area at night',
      category: 'lighting',
      isAnonymous: true,
      media: [media1, media2],
    );

    await outbox.enqueue(draft);
    expect(outbox.getPendingQueue(), hasLength(1));

    final flushed = await outbox.flush();
    expect(flushed, 1);
    expect(outbox.getPendingQueue(), isEmpty);

    // Both media uploaded with GPS metadata + in-app flag.
    expect(mediaService.uploadCalls, hasLength(2));
    expect(mediaService.uploadCalls[0].capturedLat, 19.11);
    expect(mediaService.uploadCalls[0].capturedLng, 72.87);
    expect(mediaService.uploadCalls[0].capturedAt, t1);
    expect(mediaService.uploadCalls[0].isInAppCamera, isTrue);
    expect(mediaService.uploadCalls[1].capturedLat, 19.12);
    expect(mediaService.uploadCalls[1].capturedLng, 72.88);
    expect(mediaService.uploadCalls[1].capturedAt, t2);
    expect(mediaService.uploadCalls[1].isInAppCamera, isTrue);

    // createIssue received both uploaded URLs + capture coords.
    expect(feedRepository.createIssueCalls, hasLength(1));
    final issue = feedRepository.createIssueCalls.single;
    expect(issue.mediaUrls, [
      mediaService.uploadCalls[0].url,
      mediaService.uploadCalls[1].url,
    ]);
    expect(issue.latitude, 19.11);
    expect(issue.longitude, 72.87);
  });
}
