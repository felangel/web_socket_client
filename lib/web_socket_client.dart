/// A reusable WebSocket client for Dart.
library web_socket_client;

export 'src/backoff/backoff.dart' show Backoff;
export 'src/backoff/binary_exponential_backoff.dart'
    show BinaryExponentialBackoff;
export 'src/backoff/constant_backoff.dart' show ConstantBackoff;
export 'src/backoff/linear_backoff.dart' show LinearBackoff;
export 'src/connection.dart' show Connection;
export 'src/connection_state.dart'
    show
        Connected,
        Connecting,
        ConnectionState,
        Disconnected,
        Disconnecting,
        Reconnected,
        Reconnecting;
export 'src/web_socket.dart' show WebSocket;
