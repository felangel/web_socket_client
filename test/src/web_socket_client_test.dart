import 'dart:async';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('WebSocket', () {
    final uri = Uri.parse('ws://localhost:8080');
    io.HttpServer server;

    group('readyStates', () {
      test(
          'emits [connecting, closed] '
          'when not able to establish a connection.', () async {
        final socket = WebSocket(uri: uri);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.connecting,
            WebSocketReadyState.closed,
          ]),
        );
        expect(socket.readyState, equals(WebSocketReadyState.closed));

        socket.close();
      });

      test(
          'emits [connecting, open] '
          'when able to establish a connection.', () async {
        server = await io.HttpServer.bind('localhost', 0);
        server.transform(io.WebSocketTransformer()).listen((webSocket) {
          final channel = IOWebSocketChannel(webSocket);
          channel.sink.add('pong');
        });

        addTearDown(server.close);

        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.connecting,
            WebSocketReadyState.open,
          ]),
        );
        expect(socket.readyState, equals(WebSocketReadyState.open));

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
            WebSocketReadyState.connecting,
            WebSocketReadyState.closed,
          ]),
        );

        expect(socket.readyState, equals(WebSocketReadyState.closed));

        server = await io.HttpServer.bind('localhost', port);
        server.transform(io.WebSocketTransformer()).listen((webSocket) {
          final channel = IOWebSocketChannel(webSocket);
          channel.sink.add('pong');
        });
        addTearDown(server.close);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(socket.readyState, equals(WebSocketReadyState.open));

        socket.close();
      });

      test(
          'emits [connecting, open] '
          'when able to re-establish a connection.', () async {
        const port = 8080;

        WebSocketChannel? channel;
        server = await io.HttpServer.bind('localhost', port);
        server.transform(io.WebSocketTransformer()).listen((webSocket) {
          channel = IOWebSocketChannel(webSocket);
          channel!.sink.add('pong');
        });
        addTearDown(server.close);

        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:$port'),
          backoff: const ConstantBackoff(Duration.zero),
        );

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.connecting,
            WebSocketReadyState.open,
          ]),
        );

        expect(socket.readyState, equals(WebSocketReadyState.open));

        await channel!.sink.close();
        await server.close(force: true);

        await Future<void>.delayed(Duration.zero);

        expect(socket.readyState, equals(WebSocketReadyState.closed));

        server = await io.HttpServer.bind('localhost', port);
        server.transform(io.WebSocketTransformer()).listen((webSocket) {
          channel = IOWebSocketChannel(webSocket);
          channel!.sink.add('pong');
        });

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.closed,
            WebSocketReadyState.open,
          ]),
        );
        expect(socket.readyState, equals(WebSocketReadyState.open));

        await channel!.sink.close();
        await server.close(force: true);
        socket.close();
      });

      test(
          'emits [connecting, open, closing, closed] '
          'when close is called after establishing a connection.', () async {
        server = await io.HttpServer.bind('localhost', 0);
        server.transform(io.WebSocketTransformer()).listen((webSocket) {
          final channel = IOWebSocketChannel(webSocket);
          channel.sink.add('pong');
        });
        addTearDown(() => server.close(force: true));

        final readyStates = <WebSocketReadyState>[];
        final socket = WebSocket(
          uri: Uri.parse('ws://localhost:${server.port}'),
          backoff: const ConstantBackoff(Duration.zero),
        )..readyStates.listen(readyStates.add);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.connecting,
            WebSocketReadyState.open,
          ]),
        );

        socket.close();

        await Future<void>.delayed(Duration.zero);

        await expectLater(
          readyStates,
          equals([
            WebSocketReadyState.connecting,
            WebSocketReadyState.open,
            WebSocketReadyState.closing,
            WebSocketReadyState.closed,
          ]),
        );
        expect(socket.readyState, equals(WebSocketReadyState.closed));
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
    });

    group('close', () {
      test('does nothing when connection is closed', () async {
        final socket = WebSocket(uri: uri);

        await expectLater(
          socket.readyStates,
          emitsInOrder([
            WebSocketReadyState.connecting,
            WebSocketReadyState.closed,
          ]),
        );

        expect(socket.readyState, equals(WebSocketReadyState.closed));
        expect(socket.close, returnsNormally);
        expect(socket.readyState, equals(WebSocketReadyState.closed));
      });
    });
  });
}
