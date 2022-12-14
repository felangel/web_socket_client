import 'dart:html' as html;

import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Get am [HtmlWebSocketChannel] for the provided [socket].
WebSocketChannel getWebSocketChannel(html.WebSocket socket) {
  return HtmlWebSocketChannel(socket);
}
