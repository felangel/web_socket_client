import 'dart:async';
import 'dart:js_interop';

import 'package:web/helpers.dart';

// TODO(mytja): remove when https://github.com/dart-lang/web/commit/4cb5811ed06
// is in a published release and the min constraint on pkg:web is updated
/// [WebSocketEvents] is an extension to the main [WebSocket] class from
/// package:web. It adds appropriate streams while https://github.com/dart-lang/web/commit/4cb5811ed06
/// is not yet published.
extension WebSocketEvents on WebSocket {
  /// [onOpen] is a [Stream], which returns [Event]s upon
  /// establishing new WebSocket connection.
  Stream<Event> get onOpen => EventStreamProviders.openEvent.forTarget(this);

  /// [onMessage] is a [Stream], which returns [MessageEvent]s upon
  /// receiving messages through the WebSocket connection.
  Stream<MessageEvent> get onMessage =>
      EventStreamProviders.messageEvent.forTarget(this);

  /// [onClose] is a [Stream], which returns [CloseEvent]s upon
  /// WebSocket closure.
  Stream<CloseEvent> get onClose =>
      EventStreamProviders.closeEvent.forTarget(this);

  /// [onError] is a [Stream], which returns [Event]s upon error.
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
