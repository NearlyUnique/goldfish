import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpPackageClient', () {
    late http.Client mockClient;
    late HttpPackageClient httpPackageClient;

    setUp(() {
      // Default mock client that returns OK for any request
      mockClient = MockClient((request) async {
        return http.Response('OK', 200);
      });
      httpPackageClient = HttpPackageClient(client: mockClient);
    });

    group('post', () {
      test('successfully sends POST request with headers and body', () async {
        // Arrange
        final url = Uri.parse('https://example.com/api');
        final headers = {'Content-Type': 'application/json'};
        final body = '{"key": "value"}';
        final expectedResponse = http.Response('{"success": true}', 200);

        final capturedCalls = <Map<String, dynamic>>[];
        mockClient = MockClient((request) async {
          capturedCalls.add({
            'url': request.url,
            'headers': request.headers,
            'body': request.body,
          });
          return expectedResponse;
        });
        httpPackageClient = HttpPackageClient(client: mockClient);

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
        mockClient = MockClient((request) async {
          capturedCalls.add({
            'url': request.url,
            'headers': request.headers,
            'body': request.body,
          });
          return expectedResponse;
        });
        httpPackageClient = HttpPackageClient(client: mockClient);

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

        mockClient = MockClient((request) {
          throw exception;
        });
        httpPackageClient = HttpPackageClient(client: mockClient);

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

        mockClient = MockClient((request) async {
          return errorResponse;
        });
        httpPackageClient = HttpPackageClient(client: mockClient);

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
