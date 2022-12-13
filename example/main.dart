// ignore_for_file: avoid_print
import 'package:web_socket_client/web_socket_client.dart';

void main() async {
  // Create a WebSocket client.
  final uri = Uri.parse('ws://localhost:8080');
  const backoff = ConstantBackoff(Duration(seconds: 1));
  final socket = WebSocket(uri: uri, backoff: backoff);

  // Listen for changes in the ready state.
  socket.readyStates.listen((state) => print('connection: "$state"'));

  // Listen for incoming messages.
  socket.messages.listen((message) {
    print('message: "$message"');
    // Close the connection.
    socket.close();
  });

  /// Wait for a connection to be established.
  await socket.readyStates.firstWhere((state) => state == ReadyState.open);

  // Send a message to the server.
  socket.send('ping');
}
