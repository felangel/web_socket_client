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
