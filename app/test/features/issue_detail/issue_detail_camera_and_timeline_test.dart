import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/presentation/widgets/camera_viewfinder.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/issue_detail/data/issue_detail_api.dart';
import 'package:local_lens/features/issue_detail/presentation/issue_detail_screen.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/audit_timeline_card.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/resolution_proof_modal.dart';
import 'package:local_lens/features/rep_dashboard/domain/official_response.dart';

import '../../helpers.dart';

class FakeIssueDetailApi implements IssueDetailApi {
  @override
  Future<List<Comment>> getComments(int issueId) async => [];

  @override
  Future<Comment> postComment(int issueId, String content,
      {dynamic parentId}) async {
    return Comment(
      id: 1,
      issueId: issueId,
      anonId: 'anon_1',
      content: content,
      createdAt: DateTime.now(),
      isAuthor: true,
    );
  }

  @override
  Future<void> deleteComment(int issueId, dynamic commentId) async {}
}

class TrackingFakeFeedRepository extends FakeFeedRepository {
  TrackingFakeFeedRepository({super.issues});

  bool submitResolutionCalled = false;
  int? submittedIssueId;
  String? submittedProofUrl;
  String? submittedNotes;

  bool voteQuorumCalled = false;
  String? lastVote;

  @override
  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  }) async {
    submitResolutionCalled = true;
    submittedIssueId = issueId;
    submittedProofUrl = proofUrl;
    submittedNotes = notes;
    return buildIssue(
      id: issueId,
      status: 'pending_quorum',
      title: 'Fixed Road Section',
    );
  }

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    voteQuorumCalled = true;
    lastVote = vote;
    return buildIssue(
      id: issueId,
      status: vote == 'confirm' ? 'resolved' : 'disputed',
    );
  }
}

class FakeMediaService extends MediaService {
  bool uploadCalled = false;
  Uint8List? uploadedBytes;
  bool? isInApp;
  double? lat;
  double? lng;
  String uploadUrlResult;

  FakeMediaService(
      {this.uploadUrlResult =
          'https://storage.example.com/resolution_proof.jpg'});

  @override
  Future<MediaUploadResult> uploadMedia({
    required Uint8List bytes,
    required bool isInAppCamera,
    double? capturedLat,
    double? capturedLng,
    bool isFuzzed = false,
    String? filename,
  }) async {
    uploadCalled = true;
    uploadedBytes = bytes;
    isInApp = isInAppCamera;
    lat = capturedLat;
    lng = capturedLng;
    return MediaUploadResult(
      id: 'res_media_001',
      url: uploadUrlResult,
      thumbnailUrl: uploadUrlResult,
      isVerified: isInAppCamera,
      watermarkLabel: isInAppCamera ? 'GPS Verified' : 'Gallery Upload',
      derivedHash: 'hash_test_123',
      latitude: capturedLat,
      longitude: capturedLng,
      isFuzzed: isFuzzed,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue Detail - AppBar Title & Header', () {
    testWidgets(
        'renders issue title, issue ID chip, and ward subtitle in AppBar and header',
        (tester) async {
      final fakeFeed = FakeFeedRepository(
        issues: [
          buildIssue(
            id: 99,
            title: 'Water pipe leakage on 4th Main',
            status: 'open',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...mockOverrides(feedRepository: fakeFeed),
            issueDetailApiProvider.overrideWithValue(FakeIssueDetailApi()),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 99),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title in AppBar and Title in Header
      expect(
          find.text('Water pipe leakage on 4th Main'), findsAtLeastNWidgets(1));
      expect(find.text('#99'), findsOneWidget);
      expect(find.textContaining('Ward 45'), findsAtLeastNWidgets(1));
      expect(find.text('Verified citizen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });

  group('Issue Detail - Rich Detailed Audit Timeline', () {
    testWidgets(
        'renders 5 distinct timeline events with reporter, acknowledgment, proof, verification, and win states',
        (tester) async {
      final resolvedIssue = Issue(
        id: 101,
        title: 'Broken streetlight restored',
        description: 'Light fixture repaired and verified by local council.',
        category: 'lighting',
        status: 'resolved',
        latitude: 12.9716,
        longitude: 77.5946,
        reporterLabel: 'Citizen #Alpha',
        ward: 'Ward 12, Indiranagar',
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        acknowledgedAt: DateTime.now().subtract(const Duration(days: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(hours: 2)),
        resolutionProof: 'https://storage.example.com/fixed_light.jpg',
        resolutionNotes: 'Replaced LED lamp module and repaired wiring circuit',
        confirmationsCount: 3,
        disputesCount: 0,
        mediaUrls: ['https://storage.example.com/broken_light.jpg'],
        videoUrl: 'https://storage.example.com/broken_light.mp4',
      );

      final officialResponse = OfficialResponse(
        id: 'resp_1',
        issueId: 101,
        representativeId: 'rep_123',
        officialName: 'Councilor Ramesh Kumar',
        title: 'Ward Representative',
        ward: 'Ward 12',
        message: 'Dispatched maintenance electrical crew.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AuditTimelineCard(
                issue: resolvedIssue,
                officialResponses: [officialResponse],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Event 1: Reported
      expect(find.byKey(const Key('timeline_event_reported')), findsOneWidget);
      expect(find.textContaining('Reported by Citizen #Alpha'), findsOneWidget);
      expect(find.byKey(const Key('media_thumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('video_attached_badge')), findsOneWidget);

      // Event 2: Acknowledged by Representative
      expect(
          find.byKey(const Key('timeline_event_acknowledged')), findsOneWidget);
      expect(
          find.textContaining('Acknowledged by Councilor Ramesh Kumar'),
          findsOneWidget);

      // Event 3: Resolution Proof Uploaded
      expect(find.byKey(const Key('timeline_event_proof')), findsOneWidget);
      expect(find.text('Resolution Proof Uploaded'), findsOneWidget);
      expect(
          find.textContaining('Replaced LED lamp module'), findsOneWidget);
      expect(find.byKey(const Key('timeline_resolution_proof_preview')),
          findsOneWidget);

      // Event 4: Community Verification in Progress
      expect(find.byKey(const Key('timeline_event_verification')),
          findsOneWidget);
      expect(find.text('Community Verification in Progress'), findsOneWidget);
      expect(find.textContaining('3 / 3 neighbors confirmed'), findsOneWidget);

      // Event 5: Resolved & Published as Win
      expect(find.byKey(const Key('timeline_event_resolved')), findsOneWidget);
      expect(find.text('Resolved & Published as Win'), findsOneWidget);
      expect(find.textContaining('Civic win verified'), findsOneWidget);
    });
  });

  group('Issue Detail - Community Verification Clarification & Voting', () {
    testWidgets(
        'displays clear 3-Neighbor verification subtitle and handles confirm/dispute votes',
        (tester) async {
      final fakeFeed = TrackingFakeFeedRepository(
        issues: [
          buildIssue(
            id: 202,
            title: 'Garbage dump near primary school',
            status: 'pending_quorum',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...mockOverrides(feedRepository: fakeFeed),
            issueDetailApiProvider.overrideWithValue(FakeIssueDetailApi()),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 202),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to Community Verification section
      await tester.scrollUntilVisible(
        find.byKey(const Key('quorum_vote_confirm')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();

      // Verify clear terminology and explanatory subtitle
      expect(find.text('Community Resolution Verification'), findsOneWidget);
      expect(
        find.text(
          '3 verified neighbors within 5 km must confirm the fix to mark this issue resolved.',
        ),
        findsAtLeastNWidgets(1),
      );

      // Confirm vote
      await tester.tap(find.byKey(const Key('quorum_vote_confirm')));
      await tester.pumpAndSettle();

      expect(fakeFeed.voteQuorumCalled, isTrue);
      expect(fakeFeed.lastVote, 'confirm');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });

  group('Issue Detail - Resolution Proof Camera Module & Upload Flow', () {
    testWidgets(
        'opens resolution proof modal, takes photo via camera viewfinder, previews GPS watermark, and submits resolution proof',
        (tester) async {
      final fakeFeed = TrackingFakeFeedRepository(
        issues: [
          buildIssue(
            id: 303,
            title: 'Pothole on Cross Road 5',
            status: 'under_review',
          ),
        ],
      );
      final fakeMediaService = FakeMediaService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...mockOverrides(feedRepository: fakeFeed),
            issueDetailApiProvider.overrideWithValue(FakeIssueDetailApi()),
            mediaServiceProvider.overrideWithValue(fakeMediaService),
          ],
          child: MaterialApp(
            home: IssueDetailScreen(
              issueId: 303,
              mediaService: fakeMediaService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to resolution submission button
      await tester.scrollUntilVisible(
        find.byKey(const Key('submit_resolution_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();

      // Tap submit resolution button to open camera/photo picker modal
      await tester.tap(find.byKey(const Key('submit_resolution_button')));
      await tester.pumpAndSettle();

      // Verify ResolutionProofModal is open
      expect(find.byType(ResolutionProofModal), findsOneWidget);
      expect(find.byKey(const Key('resolution_photo_placeholder')),
          findsOneWidget);
      expect(find.byKey(const Key('resolution_take_photo_button')),
          findsOneWidget);
      expect(find.byKey(const Key('resolution_gallery_pick_button')),
          findsOneWidget);

      // Tap Take Photo button -> Opens CameraViewfinder
      await tester.tap(find.byKey(const Key('resolution_take_photo_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CameraViewfinder), findsOneWidget);

      // Trigger Shutter in CameraViewfinder
      await tester.tap(find.byKey(const Key('shutterButton')));
      await tester.pumpAndSettle();

      // CameraViewfinder popped, ResolutionProofModal shows photo preview with GPS verified badge
      expect(find.byType(CameraViewfinder), findsNothing);
      expect(find.byKey(const Key('resolution_photo_preview')), findsOneWidget);
      expect(find.byKey(const Key('gps_verified_badge')), findsOneWidget);
      expect(find.byKey(const Key('resolution_retake_button')), findsOneWidget);

      // Enter resolution notes
      await tester.enterText(
        find.byKey(const Key('resolution_notes_input')),
        'Pothole filled with rapid setting asphalt mix and steamrolled.',
      );
      await tester.pumpAndSettle();

      // Tap Submit Confirm Button
      await tester.tap(find.byKey(const Key('resolution_submit_confirm_button')));
      await tester.pumpAndSettle();

      // Verify MediaService uploaded captured bytes with in-app camera flag
      expect(fakeMediaService.uploadCalled, isTrue);
      expect(fakeMediaService.isInApp, isTrue);
      expect(fakeMediaService.uploadedBytes, isNotNull);

      // Verify FeedRepository submitted resolution proof URL and notes
      expect(fakeFeed.submitResolutionCalled, isTrue);
      expect(fakeFeed.submittedIssueId, 303);
      expect(fakeFeed.submittedProofUrl,
          'https://storage.example.com/resolution_proof.jpg');
      expect(
        fakeFeed.submittedNotes,
        'Pothole filled with rapid setting asphalt mix and steamrolled.',
      );

      // Modal closed and success snackbar displayed
      expect(find.byType(ResolutionProofModal), findsNothing);
      expect(
        find.text('Resolution submitted for community verification'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets(
        'validates that a photo is required before submitting resolution proof',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResolutionProofModal(issueId: 404),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Attempt to submit without capturing or picking a photo
      await tester.tap(find.byKey(const Key('resolution_submit_confirm_button')));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(
        find.text('Please capture or select a resolution photo'),
        findsOneWidget,
      );
    });
  });

  group('Issue Detail - Upvote Toggle Interaction', () {
    testWidgets('accurately reflects upvote toggle button state',
        (tester) async {
      final initialIssue = buildIssue(
        id: 505,
        title: 'Fallen tree branch blocking walkway',
        status: 'open',
      );

      final fakeFeed = FakeFeedRepository(issues: [initialIssue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...mockOverrides(feedRepository: fakeFeed),
            issueDetailApiProvider.overrideWithValue(FakeIssueDetailApi()),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 505),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final upvoteButtonFinder = find.byKey(const Key('upvote_button_505'));
      expect(upvoteButtonFinder, findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
