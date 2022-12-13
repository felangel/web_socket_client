import 'dart:async';
import 'dart:io' as io;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel.dart'
    if (dart.library.io) 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel_io.dart'
    if (dart.library.html) 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel_html.dart';
import 'package:web_socket_client/web_socket_client.dart';

/// The default backoff strategy.
final _defaultBackoff = BinaryExponentialBackoff(
  initial: const Duration(milliseconds: 100),
  maximumStep: 7,
);

/// The default connection timeout duration.
const _defaultTimeout = Duration(seconds: 60);

/// {@template web_socket}
/// A reusable WebSocket client for Dart.
/// {@endtemplate}
class WebSocket {
  /// {@macro web_socket}
  WebSocket({
    required this.uri,
    Iterable<String>? protocols,
    Backoff? backoff,
    Duration? pingInterval,
    Duration? timeout,
  })  : _protocols = protocols,
        _backoff = backoff ?? _defaultBackoff,
        _pingInterval = pingInterval,
        _timeout = timeout ?? _defaultTimeout {
    _connect();
  }

  /// The [Uri] that was used to establish the WebSocket connection.
  final Uri uri;
  final Iterable<String>? _protocols;
  final Backoff _backoff;
  final Duration? _pingInterval;
  final Duration _timeout;

  final _messageController = StreamController.broadcast();
  final _readyStateController = StreamController<ReadyState>.broadcast();

  StreamSubscription<dynamic>? _subscription;
  Timer? _backoffTimer;

  var __readyState = ReadyState.connecting;

  ReadyState get _readyState => __readyState;

  set _readyState(ReadyState state) {
    __readyState = state;
    _readyStateController.add(state);
  }

  WebSocketChannel? _channel;
  bool _isReconnecting = false;
  bool _isClosed = false;

  Future<void> _connect() async {
    if (_readyState.isConnected) return;

    void attemptToReconnect() {
      if (_isClosed || _isReconnecting) return;
      _channel = null;
      _readyState = ReadyState.closed;
      _reconnect();
    }

    try {
      final ws = await io.WebSocket.connect(
        uri.toString(),
        protocols: _protocols,
      ).timeout(_timeout);

      if (_readyState.isNotConnected) _readyState = ReadyState.open;

      ws
        ..pingInterval = _pingInterval
        ..listen(
          _messageController.add,
          onDone: attemptToReconnect,
          cancelOnError: true,
        );

      _channel = getWebSocketChannel(ws);
      _subscription?.cancel().ignore();
    } catch (_) {
      attemptToReconnect();
    }
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

  /// The current [ReadyState].
  ReadyState get readyState => _readyState;

  /// A distinct stream of the [ReadyState].
  Stream<ReadyState> get readyStates async* {
    yield _readyState;
    yield* _readyStateController.stream.distinct();
  }

  /// Enqueues the specified data to be transmitted
  /// to the server over the WebSocket connection.
  void send(dynamic message) => _channel?.sink.add(message);

  /// Closes the connection and frees any resources.
  void close([int? code, String? reason]) {
    if (_readyState == ReadyState.closed) return;
    _readyState = ReadyState.closing;
    _backoffTimer?.cancel();
    Future.wait<void>([
      if (_channel != null) _channel!.sink.close(code, reason),
    ]).whenComplete(() {
      _readyState = ReadyState.closed;
      _messageController.close();
      _subscription?.cancel();
      _readyStateController.close();
      _isClosed = true;
    });
  }
}

extension on ReadyState {
  bool get isConnected {
    return this == ReadyState.open || this == ReadyState.closing;
  }

  bool get isNotConnected => !isConnected;
}
