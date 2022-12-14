import 'dart:async';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('WebSocket', () {
    const port = 8080;
    const closeCode = 4200;
    const closeReason = '__reason__';
    final uri = Uri.parse('ws://localhost:$port');

    io.HttpServer? server;

    tearDown(() => server?.close(force: true));

    group('connection', () {
      test(
          'emits [connecting, disconnected, reconnecting] '
          'when not able to establish a connection.', () async {
        final socket = WebSocket(uri);

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            isDisconnected(
              whereError: isA<io.SocketException>(),
              whereStackTrace: isNotNull,
            ),
            const Reconnecting(),
          ]),
        );
        expect(socket.connection.state, equals(const Reconnecting()));

        socket.close();
      });

      test(
          'emits [connecting, connected] '
          'when able to establish a connection.', () async {
        server = await createWebSocketServer();
        final socket = WebSocket(
          Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            const Connected(),
          ]),
        );
        expect(socket.connection.state, equals(const Connected()));

        socket.close();
      });

      test(
          'emits [connecting, disconnected, reconnecting, reconnected] '
          'when able to establish a connection after retries.', () async {
        final socket = WebSocket(
          Uri.parse('ws://localhost:$port'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            isDisconnected(
              whereError: isA<io.SocketException>(),
              whereStackTrace: isNotNull,
            ),
            const Reconnecting(),
          ]),
        );

        expect(socket.connection.state, equals(const Reconnecting()));
        server = await createWebSocketServer(port: port);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(socket.connection.state, equals(const Reconnected()));

        socket.close();
      });

      test(
          'emits [connecting, connected, reconnecting, reconnected] '
          'when able to re-establish a connection.', () async {
        WebSocketChannel? channel;
        server = await createWebSocketServer(
          port: port,
          onConnection: (c) => channel = c,
        );

        final connectionStates = <ConnectionState>[];

        final socket = WebSocket(
          Uri.parse('ws://localhost:$port'),
          backoff: const ConstantBackoff(Duration.zero),
        )..connection.listen(connectionStates.add);

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            const Connected(),
          ]),
        );

        expect(socket.connection.state, equals(const Connected()));

        await channel!.sink.close(closeCode, closeReason);
        await server!.close(force: true);

        expect(
          connectionStates,
          equals([
            const Connecting(),
            const Connected(),
            const Disconnected(code: closeCode, reason: closeReason),
            const Reconnecting(),
          ]),
        );
        expect(socket.connection.state, equals(const Reconnecting()));

        server = await createWebSocketServer(
          port: port,
          onConnection: (c) => channel = c,
        );

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Reconnecting(),
            const Reconnected(),
          ]),
        );

        expect(socket.connection.state, equals(const Reconnected()));

        await channel!.sink.close();
        await server!.close(force: true);
        socket.close();
      });

      test(
          'emits [connecting, connected, disconnecting, disconnected] '
          'when close is called after establishing a connection.', () async {
        server = await createWebSocketServer();

        final connectionStates = <ConnectionState>[];
        final socket = WebSocket(
          Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        )..connection.listen(connectionStates.add);

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            const Connected(),
          ]),
        );

        socket.close(closeCode, closeReason);

        await server!.close();

        await expectLater(
          connectionStates,
          equals([
            const Connecting(),
            const Connected(),
            const Disconnecting(),
            const Disconnected(code: closeCode, reason: closeReason),
          ]),
        );
        expect(
          socket.connection.state,
          equals(
            const Disconnected(code: closeCode, reason: closeReason),
          ),
        );
      });
    });

    group('messages', () {
      test('emits nothing when connection is closed', () async {
        final messages = <dynamic>[];
        final socket = WebSocket(
          uri,
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
          Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        )..messages.listen(messages.add);

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            const Connected(),
          ]),
        );

        expect(messages, equals(['ping', 'pong']));

        socket.close();
      });
    });

    group('send', () {
      test('does nothing when connection is closed', () async {
        final socket = WebSocket(
          uri,
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
          Uri.parse('ws://localhost:${server!.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            const Connected(),
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
        final socket = WebSocket(uri);

        await expectLater(
          socket.connection,
          emitsInOrder([
            const Connecting(),
            isDisconnected(
              whereError: isA<io.SocketException>(),
              whereStackTrace: isNotNull,
            ),
            const Reconnecting(),
          ]),
        );

        expect(socket.connection.state, equals(const Reconnecting()));
        expect(socket.close, returnsNormally);
        await expectLater(
          socket.connection,
          emitsInOrder([const Disconnected()]),
        );
        expect(socket.connection.state, equals(const Disconnected()));
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

Matcher isDisconnected({
  Matcher? whereError,
  Matcher? whereStackTrace,
}) {
  return isA<Disconnected>()
      .having((d) => d.error, 'error', whereError)
      .having((d) => d.stackTrace, 'stackTrace', whereStackTrace);
}
