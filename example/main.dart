// ignore_for_file: avoid_print
import 'package:web_socket_client/web_socket_client.dart';

void main() async {
  // Create a WebSocket client.
  final uri = Uri.parse('ws://localhost:8080');
  const backoff = ConstantBackoff(Duration(seconds: 1));
  final socket = WebSocket(uri, backoff: backoff);

  // Listen for changes in the connection state.
  socket.connection.listen((state) => print('state: "$state"'));

  // Listen for incoming messages.
  socket.messages.listen((message) {
    print('message: "$message"');

    // Send a message to the server.
    socket.send('ping');
  });

  await Future<void>.delayed(const Duration(seconds: 3));

  // Close the connection.
  socket.close();
}
