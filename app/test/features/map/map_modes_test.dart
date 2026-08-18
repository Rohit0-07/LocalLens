import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/features/map/data/map_api.dart';
import 'package:local_lens/features/map/presentation/screens/map_screen.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/providers/ward_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockMapApi extends Mock implements MapApi {}
class MockWardRepository extends Mock implements WardRepository {}

class _ImmediateNullLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  late MockMapApi mockMapApi;
  late MockWardRepository mockWardRepo;

  final samplePin1 = MapPin(
    id: 201,
    title: 'Pothole on Linking Road',
    category: 'road',
    status: 'unacknowledged',
    latitude: 19.10,
    longitude: 72.85,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 5,
    createdAt: DateTime.now(),
  );

  final sampleWard1 = WardSummaryOut(
    slug: 'ward-45-urban-central',
    name: 'Ward 45, Urban Central',
    code: 'W-45',
    centerLatitude: 19.10,
    centerLongitude: 72.85,
    totalIssues: 24,
    activeIssues: 12,
    escalatedIssues: 3,
    resolvedIssues: 9,
    resolutionRatePct: 37.5,
  );

  setUp(() {
    mockMapApi = MockMapApi();
    mockWardRepo = MockWardRepository();

    when(() => mockMapApi.getMapPins(
          minLat: any(named: 'minLat'),
          maxLat: any(named: 'maxLat'),
          minLng: any(named: 'minLng'),
          maxLng: any(named: 'maxLng'),
          category: any(named: 'category'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => [samplePin1]);

    when(() => mockWardRepo.getWards()).thenAnswer(
      (_) async => WardListResponse(items: [sampleWard1], total: 1, limit: 20, offset: 0),
    );
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        mapApiProvider.overrideWithValue(mockMapApi),
        wardRepositoryProvider.overrideWithValue(mockWardRepo),
        locationServiceProvider.overrideWithValue(_ImmediateNullLocationService()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Map Screen Simulation Modes (Pins, Heatmap, Ward Map)', () {
    testWidgets('Renders segmented mode pills and switches to Heatmap mode', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Check all 3 mode pills exist
      expect(find.text('Pins'), findsOneWidget);
      expect(find.text('Heatmap'), findsOneWidget);
      expect(find.text('Ward Map'), findsOneWidget);

      // Tap on Heatmap mode
      await tester.tap(find.text('Heatmap'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Verify Heatmap legend appears
      expect(find.text('Density:'), findsOneWidget);
      expect(find.text('Hotspot'), findsOneWidget);
    });

    testWidgets('Switches to Ward Map mode and interacts with ward marker', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Tap on Ward Map mode
      await tester.tap(find.text('Ward Map'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Check ward marker renders with ward code W-45
      expect(find.byKey(const Key('wardMarker_ward-45-urban-central')), findsOneWidget);
      expect(find.text('W-45'), findsOneWidget);

      // Tap on the ward marker to open ward preview sheet
      await tester.tap(find.byKey(const Key('wardMarker_ward-45-urban-central')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Verify preview sheet with ward resolution info and CTA
      expect(find.text('View Ward Hub & Activity'), findsOneWidget);
      expect(find.text('38% Resolved'), findsOneWidget);
    });
  });
}
