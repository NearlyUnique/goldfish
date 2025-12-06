import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Creates a [MockClient] that returns the given response.
MockClient createMockClient({required http.Response response}) {
  return MockClient((request) async => response);
}

/// Creates a [MockClient] that captures request details.
MockClient createCapturingMockClient({
  required http.Response response,
  required void Function(http.Request) onRequest,
}) {
  return MockClient((request) async {
    onRequest(request);
    return response;
  });
}

/// Creates a [MockClient] that throws the given exception.
MockClient createThrowingMockClient({required Exception exception}) {
  return MockClient((request) {
    throw exception;
  });
}

/// Creates an [HttpPackageClient] with a mock client.
HttpPackageClient createMockHttpClient({
  MockClient? mockClient,
  http.Response? response,
}) {
  final client =
      mockClient ??
      (response != null
          ? createMockClient(response: response)
          : createMockClient(response: http.Response('{"elements": []}', 200)));
  return HttpPackageClient(client: client);
}

/// Creates an [OverpassClient] with a mock HTTP client.
OverpassClient createMockOverpassClient({
  MockClient? mockClient,
  http.Response? response,
}) {
  final httpClient = createMockHttpClient(
    mockClient: mockClient,
    response: response,
  );
  return OverpassClient(httpClient: httpClient);
}
