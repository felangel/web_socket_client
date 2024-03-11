import 'dart:io';

/// Create a WebSocket connection.
Future<WebSocket> createConnection(
  String url, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  String? binaryType,
}) async {
  return await WebSocket.connect(url, headers: headers, protocols: protocols)
    ..pingInterval = pingInterval;
}
