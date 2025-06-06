import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel.dart'
    if (dart.library.io) 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel_io.dart'
    if (dart.library.js_interop) 'package:web_socket_client/src/_web_socket_channel/_web_socket_channel_html.dart';
import 'package:web_socket_client/src/_web_socket_connect/_web_socket_connect.dart'
    if (dart.library.io) 'package:web_socket_client/src/_web_socket_connect/_web_socket_connect_io.dart'
    if (dart.library.js_interop) 'package:web_socket_client/src/_web_socket_connect/_web_socket_connect_html.dart';
import 'package:web_socket_client/src/connection.dart';
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
  WebSocket(
    Uri uri, {
    Iterable<String>? protocols,
    Duration? pingInterval,
    Map<String, dynamic>? headers,
    Backoff? backoff,
    Duration? timeout,
    String? binaryType,
  })  : _uri = uri,
        _protocols = protocols,
        _pingInterval = pingInterval,
        _headers = headers,
        _backoff = backoff ?? _defaultBackoff,
        _timeout = timeout ?? _defaultTimeout,
        _binaryType = binaryType {
    _connect();
  }

  final Uri _uri;
  final Iterable<String>? _protocols;
  final Map<String, dynamic>? _headers;
  final Duration? _pingInterval;
  final Backoff _backoff;
  final Duration _timeout;
  final String? _binaryType;

  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionController = ConnectionController();
  StreamSubscription<dynamic>? _subscription;

  Timer? _backoffTimer;
  Duration _backoffDuration = Duration.zero;

  WebSocketChannel? _channel;

  bool get _isConnected {
    final connectionState = _connectionController.state;
    return connectionState is Connected ||
        connectionState is Reconnected ||
        connectionState is Disconnecting;
  }

  bool get _isReconnecting {
    return _connectionController.state == const Reconnecting();
  }

  bool get _isDisconnecting {
    return _connectionController.state == const Disconnecting();
  }

  bool _isClosedByClient = false;

  Future<void> _connect() async {
    if (_isConnected) return;

    void attemptToReconnect([Object? error, StackTrace? stackTrace]) {
      if (_isClosedByClient || _isReconnecting || _isDisconnecting) return;
      if (_backoffDuration >= _timeout) return _closeWithTimeout();
      _connectionController.add(
        Disconnected(
          code: _channel?.closeCode,
          reason: _channel?.closeReason,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      _channel = null;
      _reconnect();
    }

    try {
      final ws = await connect(
        _uri.toString(),
        protocols: _protocols,
        headers: _headers,
        pingInterval: _pingInterval,
        binaryType: _binaryType,
      ).timeout(_timeout);

      final connectionState = _connectionController.state;
      if (connectionState is Reconnecting) {
        _connectionController.add(const Reconnected());
      } else if (connectionState is Connecting) {
        _connectionController.add(const Connected());
      }

      _channel = getWebSocketChannel(ws);
      _subscription?.cancel().ignore();
      _subscription = _channel!.stream.listen(
        (message) {
          if (_messageController.isClosed) return;
          _messageController.add(message);
        },
        onDone: attemptToReconnect,
        cancelOnError: true,
      );
    } on Exception catch (error, stackTrace) {
      attemptToReconnect(error, stackTrace);
    }
  }

  Future<void> _reconnect() async {
    if (_backoffDuration >= _timeout) return _closeWithTimeout();
    if (_isClosedByClient || _isConnected) return;

    _connectionController.add(const Reconnecting());

    await _connect();

    if (_isClosedByClient || _isConnected) {
      _backoff.reset();
      _backoffTimer?.cancel();
      _backoffDuration = Duration.zero;
      return;
    }

    _backoffTimer?.cancel();
    final next = _backoff.next();
    _backoffDuration = _backoffDuration + next;
    _backoffTimer = Timer(next, _reconnect);
  }

  void _closeWithTimeout() => close(1006, 'connection timeout');

  /// The stream of messages received from the WebSocket server.
  Stream<dynamic> get messages => _messageController.stream;

  /// The WebSocket [Connection].
  Connection get connection => _connectionController;

  /// The subprotocol selected by the server.
  ///
  /// This is initially empty. After the connection is established the value is
  /// set to the subprotocol selected by the server. If no subprotocol is
  /// negotiated the value will remain empty.
  String get protocol => _channel?.protocol ?? '';

  /// Enqueues the specified data to be transmitted
  /// to the server over the WebSocket connection.
  void send(dynamic message) => _channel?.sink.add(message);

  /// Closes the connection and frees any resources.
  void close([int? code, String? reason]) {
    if (_isClosedByClient) return;
    _isClosedByClient = true;
    _backoffTimer?.cancel();
    _backoffDuration = Duration.zero;
    if (_isConnected) _connectionController.add(const Disconnecting());
    Future.wait<void>([
      if (_channel != null) _channel!.sink.close(code, reason),
    ]).whenComplete(() {
      _connectionController.add(Disconnected(code: code, reason: reason));
      _subscription?.cancel();
      _messageController.close();
      _connectionController.close();
    });
  }
}
