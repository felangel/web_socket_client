import 'dart:async';
import 'dart:js_interop';

import 'package:web/helpers.dart';

/// Create a WebSocket connection.
Future<WebSocket> connect(
  String url, {
  Iterable<String>? protocols,
  Duration? pingInterval,
  String? binaryType,
}) async {
  final socket = WebSocket(
    url,
    protocols?.map((e) => e.toJS).toList().toJS ?? JSArray(),
  )
    // Either "blob" (default) or "arraybuffer".
    // https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/binaryType
    ..binaryType = binaryType ?? 'blob';

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
