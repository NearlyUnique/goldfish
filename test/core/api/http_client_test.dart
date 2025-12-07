import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:http/http.dart' as http;

import 'test_helpers.dart';

void main() {
  group('HttpPackageClient', () {
    group('post', () {
      test('successfully sends POST request with headers and body', () async {
        // Arrange
        final url = Uri.parse('https://example.com/api');
        final headers = {'Content-Type': 'application/json'};
        const body = '{"key": "value"}';
        final expectedResponse = http.Response('{"success": true}', 200);

        final capturedCalls = <Map<String, dynamic>>[];
        final mockClient = createCapturingMockClient(
          response: expectedResponse,
          onRequest: (request) {
            capturedCalls.add({
              'url': request.url,
              'headers': request.headers,
              'body': request.body,
            });
          },
        );
        final httpPackageClient = createMockHttpClient(mockClient: mockClient);

        // Act
        final result = await httpPackageClient.post(
          url,
          headers: headers,
          body: body,
        );

        // Assert
        expect(result.statusCode, equals(200));
        expect(result.body, equals('{"success": true}'));
        expect(capturedCalls, hasLength(1));
        expect(capturedCalls.first['url'], equals(url));
        expect(capturedCalls.first['headers'], equals(headers));
        expect(capturedCalls.first['body'], equals(body));
      });

      test('successfully sends POST request without headers or body', () async {
        // Arrange
        final url = Uri.parse('https://example.com/api');
        final expectedResponse = http.Response('OK', 200);

        final capturedCalls = <Map<String, dynamic>>[];
        final mockClient = createCapturingMockClient(
          response: expectedResponse,
          onRequest: (request) {
            capturedCalls.add({
              'url': request.url,
              'headers': request.headers,
              'body': request.body,
            });
          },
        );
        final httpPackageClient = createMockHttpClient(mockClient: mockClient);

        // Act
        final result = await httpPackageClient.post(url);

        // Assert
        expect(result.statusCode, equals(200));
        expect(result.body, equals('OK'));
        expect(capturedCalls, hasLength(1));
        expect(capturedCalls.first['url'], equals(url));
        expect(capturedCalls.first['headers'], isEmpty);
        expect(capturedCalls.first['body'], isEmpty);
      });

      test('propagates network errors from http client', () async {
        // Arrange
        final url = Uri.parse('https://example.com/api');
        final exception = http.ClientException('Network error');

        final mockClient = createThrowingMockClient(exception: exception);
        final httpPackageClient = createMockHttpClient(mockClient: mockClient);

        // Act & Assert
        expect(
          () => httpPackageClient.post(url),
          throwsA(isA<http.ClientException>()),
        );
      });

      test('handles HTTP error responses', () async {
        // Arrange
        final url = Uri.parse('https://example.com/api');
        final errorResponse = http.Response('Not Found', 404);

        final httpPackageClient = createMockHttpClient(response: errorResponse);

        // Act
        final result = await httpPackageClient.post(url);

        // Assert
        expect(result.statusCode, equals(404));
        expect(result.body, equals('Not Found'));
      });

      test('creates new http.Client when none provided', () {
        // Arrange & Act
        final client = HttpPackageClient();

        // Assert
        expect(client, isA<HttpPackageClient>());
        // The internal client should be a real http.Client instance
        // We can verify this by making a real request (but we'll skip that
        // in unit tests to avoid network dependencies)
      });
    });
  });
}
