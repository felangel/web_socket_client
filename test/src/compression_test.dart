@TestOn('vm')
library;

import 'dart:async';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  test('compression is per client and preserved across reconnects', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    final offers = <String, List<String?>>{};
    final negotiated = <String, List<String?>>{};
    final sockets = <String, List<io.WebSocket>>{};
    final upgraded = StreamController<String>.broadcast();
    final serverSubscription = server.listen((request) async {
      final path = request.uri.path;
      offers.putIfAbsent(path, () => []).add(
            request.headers.value('sec-websocket-extensions'),
          );
      expect(request.headers.value('x-client'), path.substring(1));
      final socket = await io.WebSocketTransformer.upgrade(
        request,
        protocolSelector: (protocols) => protocols.first,
      );
      // Inspect the handshake: dart:io WebSocket.extensions returns an empty
      // string even when compression was negotiated.
      negotiated.putIfAbsent(path, () => []).add(
            request.response.headers.value('sec-websocket-extensions'),
          );
      sockets.putIfAbsent(path, () => []).add(socket);
      socket.listen(socket.add);
      upgraded.add(path);
    });
    final clients = <String, WebSocket>{};
    addTearDown(() async {
      for (final client in clients.values) {
        client.close();
      }
      for (final socket in sockets.values.expand((values) => values)) {
        await socket.close();
      }
      await server.close(force: true);
      await serverSubscription.cancel();
      await upgraded.close();
    });

    for (final path in ['/default', '/off']) {
      final uri = Uri.parse('ws://127.0.0.1:${server.port}$path');
      clients[path] = path == '/default'
          ? WebSocket(
              uri,
              headers: {'x-client': 'default'},
              protocols: ['nostr'],
            )
          : WebSocket(
              uri,
              compressionEnabled: false,
              headers: {'x-client': 'off'},
              protocols: ['nostr'],
            );
    }

    for (final entry in clients.entries) {
      final path = entry.key;
      final client = entry.value;
      await client.connection.firstWhere((state) => state is Connected);
      if (sockets[path]?.isNotEmpty != true) {
        await upgraded.stream.firstWhere((value) => value == path);
      }
      expect(client.protocol, 'nostr');
      final received = <dynamic>[];
      final messageSubscription = client.messages.listen(received.add);
      addTearDown(messageSubscription.cancel);

      for (var generation = 0; generation < 2; generation++) {
        final serverSocket = sockets[path]!.last;
        final expected =
            path == '/default' ? contains('permessage-deflate') : isNull;
        expect(offers[path]![generation], expected);
        expect(negotiated[path]![generation], expected);

        final echo = client.messages.take(2).toList();
        client
          ..send('generation $generation')
          ..send([1, 2, 3]);
        expect(await echo, [
          'generation $generation',
          [1, 2, 3],
        ]);

        if (generation == 0) {
          final reconnected =
              client.connection.firstWhere((state) => state is Reconnected);
          final nextSocket =
              upgraded.stream.firstWhere((value) => value == path);
          await serverSocket.close(4200, 'force reconnect');
          await reconnected;
          await nextSocket;
        }
      }
      expect(received, [
        'generation 0',
        [1, 2, 3],
        'generation 1',
        [1, 2, 3],
      ]);
      expect(offers[path], hasLength(2));
    }
  });
}
