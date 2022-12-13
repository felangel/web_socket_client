import 'package:web_socket_channel/web_socket_channel.dart';

/// Get a platform-specific WebSocketChannel for the provided [socket].
WebSocketChannel getWebSocketChannel(dynamic socket) {
  throw UnsupportedError('No implementation of the api provided');
}
