import 'dart:async';
import 'dart:js_interop';

import 'package:web/helpers.dart';

// TODO: remove when https://github.com/dart-lang/web/commit/4cb5811ed06
// is in a published release and the min constraint on pkg:web is updated
extension WebSocketEvents on WebSocket {
  Stream<Event> get onOpen => EventStreamProviders.openEvent.forTarget(this);
  Stream<MessageEvent> get onMessage =>
      EventStreamProviders.messageEvent.forTarget(this);
  Stream<CloseEvent> get onClose =>
      EventStreamProviders.closeEvent.forTarget(this);
  Stream<Event> get onError =>
      EventStreamProviders.errorEventSourceEvent.forTarget(this);
}

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
  )..binaryType = binaryType ?? 'list';

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
