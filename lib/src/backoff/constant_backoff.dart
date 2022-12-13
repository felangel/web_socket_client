import 'package:web_socket_client/web_socket_client.dart';

/// {@template constant_backoff}
/// A constant backoff strategy.
/// This backoff strategy will always return the same value.
///
/// ```dart
/// ConstantBackoff(Duration(seconds: 1))
///   ..next() // Duration(seconds: 1)
///   ..next() // Duration(seconds: 1)
///   ..next(); // Duration(seconds: 1)
/// ```
/// {@endtemplate}
class ConstantBackoff implements Backoff {
  /// {@macro constant_backoff}
  const ConstantBackoff(this.duration);

  /// The constant backoff duration.
  final Duration duration;

  @override
  Duration next() => duration;

  @override
  void reset() {}
}
