import 'dart:async';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('WebSocket', () {
    final uri = Uri.parse('ws://localhost:8080');
    io.HttpServer? server;

    tearDown(() => server?.close());

    group('readyStates', () {
      test(
          'emits [connecting, closed] '
          'when not able to establish a connection.', () async {
        final socket = WebSocket(uri: uri);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.closed,
          ]),
        );
        expect(socket.readyState, equals(ReadyState.closed));

        socket.close();
      });

      test(
          'emits [connecting, open] '
          'when able to establish a connection.', () async {
        server = await createWebSocketServer();
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.open,
          ]),
        );
        expect(socket.readyState, equals(ReadyState.open));

        socket.close();
      });

      test(
          'emits [connecting, open] '
          'when able to establish a connection after retries.', () async {
        const port = 8080;
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:$port'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.closed,
          ]),
        );

        expect(socket.readyState, equals(ReadyState.closed));
        server = await createWebSocketServer(port: port);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(socket.readyState, equals(ReadyState.open));

        socket.close();
      });

      test(
          'emits [connecting, open] '
          'when able to re-establish a connection.', () async {
        const port = 8080;

        WebSocketChannel? channel;
        server = await createWebSocketServer(
          port: port,
          onConnection: (c) => channel = c,
        );

        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:$port'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.open,
          ]),
        );

        expect(socket.readyState, equals(ReadyState.open));

        await channel!.sink.close();
        await server!.close(force: true);

        expect(socket.readyState, equals(ReadyState.closed));

        server = await createWebSocketServer(
          port: port,
          onConnection: (c) => channel = c,
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.closed,
            ReadyState.open,
          ]),
        );

        expect(socket.readyState, equals(ReadyState.open));

        await channel!.sink.close();
        await server!.close(force: true);
        socket.close();
      });

      test(
          'emits [connecting, open, closing, closed] '
          'when close is called after establishing a connection.', () async {
        server = await createWebSocketServer();

        final readyStates = <ReadyState>[];
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        )..readyStates.listen(readyStates.add);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.open,
          ]),
        );

        socket.close();

        await server!.close();

        await expectLater(
          readyStates,
          equals([
            ReadyState.connecting,
            ReadyState.open,
            ReadyState.closing,
            ReadyState.closed,
          ]),
        );
        expect(socket.readyState, equals(ReadyState.closed));
      });
    });

    group('messages', () {
      test('emits nothing when connection is closed', () async {
        final messages = <dynamic>[];
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:8080'),
          backoff: const ConstantBackoff(Duration.zero),
        )..messages.listen(messages.add);

        await Future<void>.delayed(Duration.zero);

        socket.close();

        await Future<void>.delayed(Duration.zero);

        expect(messages, isEmpty);
      });

      test('emits messages when connection is open', () async {
        server = await createWebSocketServer(
          onConnection: (channel) {
            channel.sink
              ..add('ping')
              ..add('pong');
          },
        );

        final messages = <dynamic>[];
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        )..messages.listen(messages.add);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.open,
          ]),
        );

        expect(messages, equals(['ping', 'pong']));

        socket.close();
      });
    });

    group('send', () {
      test('does nothing when connection is closed', () async {
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:8080'),
          backoff: const ConstantBackoff(Duration.zero),
        );
        expect(() => socket.send(null), returnsNormally);

        socket.close();
      });

      test('sends message when connection is open', () async {
        final messages = <dynamic>[];
        server = await createWebSocketServer(
          onConnection: (channel) {
            channel.stream.listen(messages.add);
          },
        );

        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.open,
          ]),
        );

        socket
          ..send('ping')
          ..send('pong');

        await Future<void>.delayed(Duration.zero);

        expect(messages, equals(['ping', 'pong']));

        socket.close();
      });
    });

    group('close', () {
      test('does nothing when connection is closed', () async {
        final socket = WebSocket(uri: uri);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            ReadyState.connecting,
            ReadyState.closed,
          ]),
        );

        expect(socket.readyState, equals(ReadyState.closed));
        expect(socket.close, returnsNormally);
        expect(socket.readyState, equals(ReadyState.closed));
      });
    });
  });
}

Future<io.HttpServer> createWebSocketServer({
  void Function(WebSocketChannel channel)? onConnection,
  int port = 0,
}) async {
  final server = await io.HttpServer.bind('localhost', port);
  server.transform(io.WebSocketTransformer()).listen((webSocket) {
    if (onConnection != null) onConnection(IOWebSocketChannel(webSocket));
  });
  return server;
}
