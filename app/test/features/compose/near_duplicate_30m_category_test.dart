import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/feed/data/feed_api.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late FeedApi feedApi;

  setUp(() {
    mockClient = MockApiClient();
    feedApi = FeedApi(mockClient);
  });

  group('Near Duplicate 30m & Category Matching Tests', () {
    test('checkNearDuplicates sends category and 30m (0.030 km) radius query params', () async {
      when(() => mockClient.getJson(
            '/issues/near-duplicate',
            query: any(named: 'query'),
          )).thenAnswer((invocation) async {
        final query = invocation.namedArguments[#query] as Map<String, dynamic>;
        expect(query['latitude'], equals(19.1136));
        expect(query['longitude'], equals(72.8697));
        expect(query['radius_km'], equals(0.030));
        expect(query['category'], equals('road'));

        return [
          {
            'id': 101,
            'title': 'Cracked asphalt patch',
            'category': 'road',
            'status': 'unacknowledged',
            'latitude': 19.1137,
            'longitude': 72.8698,
            'distance_meters': 18.5,
            'created_at': '2026-08-18T10:00:00Z',
          }
        ];
      });

      final dups = await feedApi.checkNearDuplicates(
        latitude: 19.1136,
        longitude: 72.8697,
        category: 'road',
        radiusKm: 0.030,
      );

      expect(dups.length, equals(1));
      expect(dups.first.id, equals(101));
      expect(dups.first.distanceMeters, equals(18.5));
      expect(dups.first.category, equals('road'));
    });
  });
}
