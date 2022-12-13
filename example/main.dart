// ignore_for_file: avoid_print

import 'package:web_socket_client/web_socket_client.dart';

void main() async {
  var receivedMessage = false;

  // Create a WebSocket client.
  final socket = WebSocket(uri: Uri.parse('ws://localhost:8080/ws'));

  // Listen to changes in the ready state.
  socket.readyStates.listen((state) => print('connection: "$state"'));

  // Listen to incoming messages.
  socket.messages.listen((message) {
    print('message: "$message"');
    if (!receivedMessage) {
      receivedMessage = true;
      socket
        // Send a message to the server.
        ..send('pong')
        // Close the connection.
        ..close();
    }
  });
}
