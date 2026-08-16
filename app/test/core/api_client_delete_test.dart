import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/core/network/api_exceptions.dart';

void main() {
  group('ApiClient.deleteJson', () {
    late HttpServer server;
    late String baseUrl;
    String? tokenToReturn;
    int unauthorizedCount = 0;

    setUp(() async {
      tokenToReturn = null;
      unauthorizedCount = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
    });

    ApiClient createClient({String? token}) {
      tokenToReturn = token;
      return ApiClient(
        baseUrl: baseUrl,
        accessTokenProvider: () => tokenToReturn,
        onUnauthorized: () {
          unauthorizedCount++;
        },
      );
    }

    test('sends HTTP DELETE and returns decoded JSON response', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'DELETE');
        expect(request.uri.path, '/issues/42/upvote');
        expect(request.headers.value('accept'), 'application/json');

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'id': 42, 'upvotes_count': 5, 'has_upvoted': false}));
        await request.response.close();
      });

      final client = createClient();
      final result = await client.deleteJson('/issues/42/upvote');

      expect(result, isA<Map<String, dynamic>>());
      final map = result as Map<String, dynamic>;
      expect(map['id'], 42);
      expect(map['upvotes_count'], 5);
      expect(map['has_upvoted'], false);
    });

    test('sends Authorization header when token is available', () async {
      String? capturedAuthHeader;
      server.listen((HttpRequest request) async {
        capturedAuthHeader = request.headers.value('authorization');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': true}));
        await request.response.close();
      });

      final client = createClient(token: 'jwt-delete-token-123');
      final result = await client.deleteJson('/items/1');

      expect(capturedAuthHeader, 'Bearer jwt-delete-token-123');
      expect((result as Map<String, dynamic>)['success'], true);
    });

    test('passes request body with JSON content when body is provided', () async {
      String? requestBody;
      server.listen((HttpRequest request) async {
        requestBody = await utf8.decoder.bind(request).join();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'deleted': true}));
        await request.response.close();
      });

      final client = createClient();
      final result = await client.deleteJson(
        '/resources/99',
        body: {'reason': 'duplicate'},
      );

      expect(requestBody, jsonEncode({'reason': 'duplicate'}));
      expect((result as Map<String, dynamic>)['deleted'], true);
    });

    test('handles 401 Unauthorized by invoking onUnauthorized and throwing ApiUnauthorizedException', () async {
      server.listen((HttpRequest request) async {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'detail': 'Token expired', 'code': 'unauthorized'}));
        await request.response.close();
      });

      final client = createClient();
      expect(
        () => client.deleteJson('/issues/10/upvote'),
        throwsA(isA<ApiUnauthorizedException>()),
      );

      try {
        await client.deleteJson('/issues/10/upvote');
      } catch (_) {}

      expect(unauthorizedCount, greaterThan(0));
    });

    test('maps 404 response to ApiServerException', () async {
      server.listen((HttpRequest request) async {
        request.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'detail': 'Issue not found', 'code': 'not_found'}));
        await request.response.close();
      });

      final client = createClient();
      expect(
        () => client.deleteJson('/issues/999/upvote'),
        throwsA(
          isA<ApiServerException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'not_found')
              .having((e) => e.message, 'message', 'Issue not found'),
        ),
      );
    });
  });
}
