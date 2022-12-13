/// The state of a WebSocket connection.
/// https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/readyState
enum WebSocketReadyState {
  /// The connection has not yet been established.
  connecting,

  /// The WebSocket connection is established and communication is possible.
  open,

  /// The connection is going through the closing handshake,
  /// or the close() method has been invoked.
  closing,

  /// The connection has been closed or could not be opened.
  closed,
}
