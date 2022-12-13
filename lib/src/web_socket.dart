import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

/// The default backoff strategy.
final _defaultBackoff = BinaryExponentialBackoff(
  initial: const Duration(milliseconds: 100),
  maximumStep: 7,
);

/// {@template web_socket}
/// A reusable WebSocket client for Dart.
/// {@endtemplate}
class WebSocket {
  /// {@macro web_socket}
  WebSocket({
    required this.uri,
    Iterable<String>? protocols,
    Backoff? backoff,
  })  : _protocols = protocols,
        _backoff = backoff ?? _defaultBackoff {
    _connect();
  }

  /// The [Uri] that was used to establish the WebSocket connection.
  final Uri uri;
  final Iterable<String>? _protocols;
  final Backoff _backoff;

  final _messageController = StreamController.broadcast();
  final _readyStateController =
      StreamController<WebSocketReadyState>.broadcast();

  StreamSubscription<dynamic>? _subscription;
  Timer? _backoffTimer;

  var __readyState = WebSocketReadyState.connecting;

  WebSocketReadyState get _readyState => __readyState;

  set _readyState(WebSocketReadyState state) {
    __readyState = state;
    _readyStateController.add(state);
  }

  WebSocketChannel? _channel;
  bool _isReconnecting = false;

  Future<void> _connect() async {
    if (_readyState.isConnected) return;

    final completer = Completer<void>();

    _channel = WebSocketChannel.connect(uri, protocols: _protocols);

    void attemptToReconnect() {
      if (!completer.isCompleted) completer.complete();
      if (!_isReconnecting) {
        _channel = null;
        _readyState = WebSocketReadyState.closed;
        _reconnect();
      }
    }

    _subscription?.cancel().ignore();
    _subscription = _channel!.stream.listen(
      (message) {
        if (!completer.isCompleted) completer.complete();
        if (_readyState.isNotConnected) _readyState = WebSocketReadyState.open;
        _messageController.add(message);
      },
      onError: (_, __) => attemptToReconnect(),
      onDone: attemptToReconnect,
      cancelOnError: false,
    );

    return completer.future;
  }

  Future<void> _reconnect() async {
    _isReconnecting = true;

    await _connect();

    if (_readyState.isConnected) {
      _isReconnecting = false;
      _backoff.reset();
      _backoffTimer?.cancel();
      return;
    }

    _backoffTimer?.cancel();
    _backoffTimer = Timer(_backoff.next(), _reconnect);
  }

  /// The stream of messages received from the WebSocket server.
  Stream<dynamic> get messages => _messageController.stream;

  /// The current [WebSocketReadyState].
  WebSocketReadyState get readyState => _readyState;

  /// A distinct stream of the [WebSocketReadyState].
  Stream<WebSocketReadyState> get readyStates async* {
    yield _readyState;
    yield* _readyStateController.stream.distinct();
  }

  /// Enqueues the specified data to be transmitted
  /// to the server over the WebSocket connection.
  void send(dynamic message) => _channel?.sink.add(message);

  /// Closes the connection and frees any resources.
  void close([int? code, String? reason]) {
    if (_readyState == WebSocketReadyState.closed) return;
    _readyState = WebSocketReadyState.closing;
    _backoffTimer?.cancel();
    Future.wait<void>([
      if (_channel != null) _channel!.sink.close(code, reason),
    ]).whenComplete(() {
      _readyState = WebSocketReadyState.closed;
      _messageController.close();
      _subscription?.cancel();
      _readyStateController.close();
    });
  }
}

extension on WebSocketReadyState {
  bool get isConnected {
    return this == WebSocketReadyState.open ||
        this == WebSocketReadyState.closing;
  }

  bool get isNotConnected => !isConnected;
}
