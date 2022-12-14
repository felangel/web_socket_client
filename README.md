# WebSocket Client

[![build][build_badge]][build_link]
[![coverage][coverage_badge]][build_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A reusable `WebSocket` client for Dart.

## Quick Start 🚀

```dart
// Create a WebSocket client.
final socket = WebSocket(Uri.parse('ws://localhost:8080'));

// Listen to messages from the server.
socket.messages.listen((message) {
  // Handle incoming messages.
});

// Send a message to the server.
socket.send('ping');

// Close the connection.
socket.close();
```

## Establishing a Connection 🔌

The `WebSocket` client will attempt to establish a connection immediately upon initialization. By default, a timeout will occur if establishing a connection exceeds 60 seconds but a custom `timeout` duration can be provided:

```dart
final uri = Uri.parse('ws://localhost:8080');

// Trigger a timeout if establishing a connection exceeds 10s.
final timeout = Duration(seconds: 10);
final socket = WebSocket(uri, timeout: timeout);
```

If the `WebSocket` client is not able to establish a connection, it will automatically attempt to reconnect using the provided `Backoff` strategy. By default, a `BinaryExponentialBackoff` is used but a custom `backoff` can be provided:

```dart
final uri = Uri.parse('ws://localhost:8080');

// Wait a constant 1s between reconnection attempts.
const backoff = ConstantBackoff(Duration(seconds: 1));
final socket = WebSocket(uri, backoff: backoff);
```

## Detecting the Connection 🔌

The `WebSocket` client exposes a `connection` which can be used to query the connection state at any given time as well as listen to real-time changes in the connection state.

```dart
final uri = Uri.parse('ws://localhost:8080');
final socket = WebSocket(uri);

// Listen to changes in the connection state.
socket.connection.listen((state) {
  // Handle changes in the connection state.
});

// Query the current connection state.
final connectionState = socket.connection.state;
```

[build_badge]: https://github.com/felangel/web_socket_client/actions/workflows/main.yaml/badge.svg
[build_link]: https://github.com/felangel/web_socket_client/actions/workflows/main.yaml
[coverage_badge]: https://raw.githubusercontent.com/felangel/web_socket_client/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_badge]: https://img.shields.io/pub/v/web_socket_client.svg
[pub_link]: https://pub.dartlang.org/packages/web_socket_client
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
