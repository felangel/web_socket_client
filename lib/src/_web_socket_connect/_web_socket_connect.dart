import 'dart:io';

/// Create a WebSocket connection.
Future<Stream<dynamic>> connect(
  String url, {
  Iterable<String>? protocols,
  Duration? pingInterval,
  String? binaryType,
  HttpClient? httpClient,
}) {
  throw UnsupportedError('No implementation of the api provided');
}
