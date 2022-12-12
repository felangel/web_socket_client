// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('WebSocketClient', () {
    test('can be instantiated', () {
      expect(WebSocketClient(), isNotNull);
    });
  });
}
