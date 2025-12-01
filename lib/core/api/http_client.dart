import 'package:http/http.dart' as http;

/// Abstract interface for HTTP operations.
///
/// Provides a testable abstraction over HTTP client operations, allowing
/// for easy mocking in tests and swapping implementations.
abstract class HttpClient {
  /// Sends a POST request to the specified [url].
  ///
  /// Optionally includes [headers] and [body] in the request.
  ///
  /// Returns a [http.Response] containing the response from the server.
  ///
  /// Throws [http.ClientException] or other exceptions if the request fails.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  });
}

/// Concrete implementation of [HttpClient] using the `http` package.
///
/// This implementation wraps the standard `http.Client` to provide
/// HTTP POST functionality for the application.
class HttpPackageClient implements HttpClient {
  /// Creates a new [HttpPackageClient].
  ///
  /// Optionally accepts a [client] for dependency injection and testing.
  /// If not provided, creates a new [http.Client] instance.
  HttpPackageClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.post(url, headers: headers, body: body);
  }
}
