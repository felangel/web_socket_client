import 'dart:async';
import 'dart:html';

/// Create a WebSocket connection.
Future<WebSocket> connect(
  String url, {
  Iterable<String>? protocols,
  Duration? pingInterval,
  String? binaryType,
}) async {
  final socket = WebSocket(url, protocols)..binaryType = binaryType;

  if (socket.readyState == 1) return socket;

  final completer = Completer<WebSocket>();

  unawaited(
    socket.onOpen.first.then((_) {
      completer.complete(socket);
    }),
  );

  unawaited(
    socket.onError.first.then((event) {
      final error = event is ErrorEvent ? event.error : null;
      completer.completeError(error ?? 'unknown error');
    }),
  );

  return completer.future;
}
