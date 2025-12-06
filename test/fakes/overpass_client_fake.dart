import 'package:goldfish/core/api/overpass_client.dart';

/// Fake implementation of [OverpassClient] for testing.
class FakeOverpassClient implements OverpassClient {
  FakeOverpassClient({
    Future<OverpassResponse> Function(String query)? onPost,
  }) : onPost = onPost ?? _defaultPost;

  Future<OverpassResponse> Function(String query) onPost;

  @override
  Future<OverpassResponse> post(String query) => onPost(query);

  static Future<OverpassResponse> _defaultPost(String query) async =>
      const OverpassResponse(elements: []);
}


