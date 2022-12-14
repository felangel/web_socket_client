// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// {@template connection_state}
/// The state of a WebSocket connection.
/// {@endtemplate}
abstract class ConnectionState {
  /// {@macro connection_state}
  const ConnectionState();
}

/// {@template connecting}
/// The WebSocket connection has not yet been established.
/// {@endtemplate}
class Connecting extends ConnectionState {
  /// {@macro connecting}
  const Connecting();

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Connecting;
  }
}

/// {@template connected}
/// The WebSocket connection is established and communication is possible.
/// {@endtemplate}
class Connected extends ConnectionState {
  /// {@macro connected}
  const Connected();

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Connected;
  }
}

/// {@template reconnecting}
/// The WebSocket connection was lost
/// and is in the process of being re-established.
/// {@endtemplate}
class Reconnecting extends ConnectionState {
  /// {@macro reconnecting}
  const Reconnecting();

  @override
  int get hashCode => 2;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Reconnecting;
  }
}

/// {@template reconnected}
/// The WebSocket connection was lost and has been re-established.
/// {@endtemplate}
class Reconnected extends ConnectionState {
  /// {@macro reconnected}
  const Reconnected();

  @override
  int get hashCode => 3;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Reconnected;
  }
}

/// {@template disconnecting}
/// The WebSocket connection is going through the closing handshake,
/// or the close() method has been invoked.
/// {@endtemplate}
class Disconnecting extends ConnectionState {
  /// {@macro disconnecting}
  const Disconnecting();

  @override
  int get hashCode => 4;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Disconnecting;
  }
}

/// {@template disconnected}
/// The WebSocket connection has been closed or could not be established.
/// {@endtemplate}
class Disconnected extends ConnectionState {
  /// {@macro disconnected}
  const Disconnected({this.code, this.reason, this.error, this.stackTrace});

  /// The error responsible for the disconnection.
  final Object? error;

  /// The stack trace responsible for the disconnection.
  final StackTrace? stackTrace;

  /// The WebSocket connection close code.
  final int? code;

  /// The WebSocket connection close reason.
  final String? reason;

  @override
  int get hashCode => Object.hashAll([code, reason]);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Disconnected &&
            code == other.code &&
            reason == other.reason &&
            other.error == error &&
            other.stackTrace == stackTrace;
  }
}
