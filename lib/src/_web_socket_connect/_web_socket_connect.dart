/// Create a WebSocket connection.
Future<Stream<dynamic>> createConnection(
  String url, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  String? binaryType,
}) {
  throw UnsupportedError('No implementation of the api provided');
}
