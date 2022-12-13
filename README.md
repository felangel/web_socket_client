# WebSocket Client

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A reusable `WebSocket` client for Dart.

## Quick Start 🚀

```dart
// Create a WebSocket client.
final uri = Uri.parse('ws://localhost:8080');
final socket = WebSocket(uri: uri);

// Listen to messages from the server.
socket.message.listen((message) {
  // React to incoming messages.
});

// Send a message to the server.
socket.send('ping');
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
