import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/features/map/data/map_api.dart';
import 'package:local_lens/features/map/presentation/controllers/map_controller.dart';
import 'package:local_lens/features/map/presentation/screens/map_screen.dart';
import 'package:local_lens/features/map/presentation/widgets/map_pin_preview_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockMapApi extends Mock implements MapApi {}

/// Instantly returns null so the notifier constructor doesn't block on GPS.
class _ImmediateNullLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  late MockMapApi mockMapApi;

  final samplePin1 = MapPin(
    id: 101,
    title: 'Huge Pothole on Main St',
    category: 'road',
    status: 'unacknowledged',
    latitude: 19.10,
    longitude: 72.85,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 12,
    createdAt: DateTime.now(),
  );

  final samplePin2 = MapPin(
    id: 102,
    title: 'Water Leakage Near School',
    category: 'water',
    status: 'in_progress',
    latitude: 19.08,
    longitude: 72.87,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 8,
    createdAt: DateTime.now(),
  );

  final samplePin3 = MapPin(
    id: 103,
    title: 'Broken Streetlight',
    category: 'lighting',
    status: 'resolved',
    latitude: 19.12,
    longitude: 72.86,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 15,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockMapApi = MockMapApi();
  });

  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        mapApiProvider.overrideWithValue(mockMapApi),
        // Override locationServiceProvider so the notifier constructor does not
        // block on real GPS during tests.
        locationServiceProvider.overrideWithValue(_ImmediateNullLocationService()),
        ...overrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Feature F-08-MAP Pin Clustering & Interactive Spatial Map Test Suite', () {
    // FE-MAP-01: MapScreen initial load, loading indicator, and rendering pins for all mock issues
    testWidgets('FE-MAP-01: MapScreen initial load and pin rendering', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1, samplePin2, samplePin3]);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      
      // Verify progress indicator appears during loading state before settlement
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify progress indicator disappears after load
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Verify all rendered map pins with Key('mapPin_<id>')
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_102')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_103')), findsOneWidget);
    });

    // FE-MAP-02: Filter chips selection updating map state and filtering rendered pins
    testWidgets('FE-MAP-02: Filter chip selection filters pins and updates state', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1, samplePin2, samplePin3]);

      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: 'road',
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify initial pins
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_102')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_103')), findsOneWidget);

      // Tap on 'road' category filter chip
      await tester.tap(find.byKey(const Key('mapFilterChip_road')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify map pins filtered down to road pin only
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_102')), findsNothing);
      expect(find.byKey(const Key('mapPin_103')), findsNothing);
    });

    // FE-MAP-03: Tapping map pin opens MapPinPreviewSheet with all required metadata fields
    testWidgets('FE-MAP-03: Tapping map pin opens preview sheet with complete details', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Tap on map pin 101
      await tester.tap(find.byKey(const Key('mapPin_101')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify preview sheet opens
      expect(find.byType(MapPinPreviewSheet), findsOneWidget);

      // Verify issue title, category badge, status badge, ward name, upvote count, and view details button
      expect(find.text('Huge Pothole on Main St'), findsOneWidget);
      expect(find.text('ROAD'), findsOneWidget);
      expect(find.text('Unacknowledged'), findsOneWidget);
      expect(find.text('Ward 45, Urban Central'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('View Issue Details'), findsOneWidget);
    });

    // FE-MAP-04: Tapping "Search this area" button calls API for updated bounds and updates map pins
    testWidgets('FE-MAP-04: Tapping Search this area calls API for updated bounds', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: 19.0,
            maxLat: 19.2,
            minLng: 72.8,
            maxLng: 72.9,
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      when(() => mockMapApi.getMapPins(
            minLat: 19.05,
            maxLat: 19.25,
            minLng: 72.82,
            maxLng: 72.92,
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1, samplePin2]);

      final container = ProviderContainer(
        overrides: [
          mapApiProvider.overrideWithValue(mockMapApi),
        ],
      );

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byKey(const Key('searchThisAreaButton')), findsNothing);

      // Update map bounds to dirty state
      container.read(mapPinsNotifierProvider.notifier).updateBounds(
            const MapBounds(minLat: 19.05, maxLat: 19.25, minLng: 72.82, maxLng: 72.92),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Search this area button is now visible
      expect(find.byKey(const Key('searchThisAreaButton')), findsOneWidget);

      // Tap search this area button
      await tester.tap(find.byKey(const Key('searchThisAreaButton')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Button disappears and new pins rendered
      expect(find.byKey(const Key('searchThisAreaButton')), findsNothing);
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_102')), findsOneWidget);
    });

    // FE-MAP-05: Error state handling and tap on Retry button
    testWidgets('FE-MAP-05: Error state rendering and retry button tap', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenThrow(Exception('Failed to fetch pins from server'));

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify error message and retry button
      expect(find.textContaining('Failed to load map pins'), findsOneWidget);
      expect(find.byKey(const Key('mapErrorRetryButton')), findsOneWidget);

      // Change API response to succeed on retry
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      // Tap retry button
      await tester.tap(find.byKey(const Key('mapErrorRetryButton')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Error message gone and pins rendered
      expect(find.textContaining('Failed to load map pins'), findsNothing);
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
    });

    // FE-MAP-06: Empty state rendering when no pins exist in bounding box
    testWidgets('FE-MAP-06: Empty state rendering when no pins exist in bounding box', (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify Key('mapEmptyState') card and text 'No issues found in this area'
      expect(find.byKey(const Key('mapEmptyState')), findsOneWidget);
      expect(find.text('No issues found in this area'), findsOneWidget);
    });
  });
}
