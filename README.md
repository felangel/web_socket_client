# WebSocket Client

[![build][build_badge]][build_link] [![coverage][coverage_badge]][build_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A simple `WebSocket` client for Dart which includes automatic reconnection
logic.

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

The `WebSocket` client will attempt to establish a connection immediately upon
initialization. By default, a timeout will occur if establishing a connection
exceeds 60 seconds but a custom `timeout` duration can be provided:

```dart
final uri = Uri.parse('ws://localhost:8080');

// Trigger a timeout if establishing a connection exceeds 10s.
final timeout = Duration(seconds: 10);
final socket = WebSocket(uri, timeout: timeout);
```

## Reconnecting 🔄

If the `WebSocket` client is not able to establish a connection, it will
automatically attempt to reconnect using the provided `Backoff` strategy. By
default, a `BinaryExponentialBackoff` is used but a custom `backoff` can be
provided.

There are three built-in backoff strategies but a custom backoff strategy can be
written by implementing the `Backoff` interface.

**ConstantBackoff**

This backoff strategy will make the `WebSocket` client wait a constant amount of
time between reconnection attempts.

```dart
// Wait a constant 1s between reconnection attempts.
// [1, 1, 1, ...]
const backoff = ConstantBackoff(Duration(seconds: 1));
final socket = WebSocket(uri, backoff: backoff);
```

**LinearBackoff**

This backoff strategy will make the `WebSocket` client wait a linearly
increasing amount of time until an optional maximum duration is reached.

```dart
// Initially wait 0s and increase the wait time by 1s until a maximum of 5s is reached.
// [0, 1, 2, 3, 4, 5, 5, 5, ...]
const backoff = LinearBackoff(
  initial: Duration(seconds: 0),
  increment: Duration(seconds: 1),
  maximum: Duration(seconds: 5),
);
final socket = WebSocket(uri, backoff: backoff);
```

**BinaryExponentialBackoff**

This backoff strategy will make the `WebSocket` client wait an exponentially
increasing amount of time until a maximum step is reached.

```dart
// Initially wait 1s and double the wait time until a maximum step of of 3 is reached.
// [1, 2, 4, 4, 4, ...]
const backoff = BinaryExponentialBackoff(
  initial: Duration(seconds: 1),
  maximumStep: 3
);
final socket = WebSocket(uri, backoff: backoff);
```

## Monitoring the Connection ⚡️

The `WebSocket` client exposes a `connection` object which can be used to query
the connection state at any given time as well as listen to real-time changes in
the connection state.

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

The connection state can be one of the following:

- **connecting**: the connection has not yet been established.
- **connected**: the connection is established and communication is possible.
- **reconnecting**: the connection was lost and is in the process of being
  re-established.
- **reconnected**: the connection was lost and has been re-established.
- **disconnecting**: the connection is going through the closing handshake or
  the `close` method has been invoked.
- **disconnected**: the WebSocket connection has been closed or could not be
  established.

_\* The disconnected connection state contains nullable fields for the close
code, close reason, error, and stack trace._

## Sending Messages 📤

Once a `WebSocket` connection has been established, messages can be sent to the
server via `send`:

```dart
final socket = WebSocket(Uri.parse('ws://localhost:8080'));

// Wait until a connection has been established.
await socket.connection.firstWhere((state) => state is Connected);

// Send a message to the server.
socket.send('ping');
```

## Receiving Messages 📥

Listen for incoming messages from the server via the `messages` stream:

```dart
final socket = WebSocket(Uri.parse('ws://localhost:8080'));

// Listen for incoming messages.
socket.messages.listen((message) {
  // Handle the incoming message.
});
```

## Protobuf 💬

If you're using `web_socket_client` on the web with Protobuf, you might
want to use `binaryType` when initializing the `WebSocket` class.
`binaryType` is only applicable on the web and is not used on desktop or mobile platforms.

```dart
final socket = WebSocket(Uri.parse('ws://localhost:8080'), binaryType: 'arraybuffer');
```

## Closing the Connection 🚫

Once a `WebSocket` connection is established, it will automatically attempt to
reconnect if the connection is disrupted. Calling `close()` will update the
connection state to `disconnecting`, perform the closing handshake, and set the
state to `disconnected`. At this point, the `WebSocket` client will not attempt
to reconnect and a new `WebSocket` client instance will need to be created in
order to establish a new connection.

```dart
final socket = WebSocket(Uri.parse('ws://localhost:8080'));

// Later, close the connection with an optional code and reason.
socket.close(1000, 'CLOSE_NORMAL');
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
