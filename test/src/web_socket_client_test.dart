import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('WebSocket', () {
    group('close', () {
      test('does nothing when connection is closed', () async {
        final client = WebSocket(
          uri: Uri.parse('ws://localhost:8080/ws'),
        );

        await expectLater(
          client.readyStates,
          emitsInOrder([WebSocketReadyState.closed]),
        );

        expect(client.readyState, equals(WebSocketReadyState.closed));
        expect(client.close, returnsNormally);
        expect(client.readyState, equals(WebSocketReadyState.closed));
      });
    });
  });
}
