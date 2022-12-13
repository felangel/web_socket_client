import 'package:web_socket_client/web_socket_client.dart';

/// {@template linear_backoff}
/// A linear backoff strategy.
/// This backoff strategy will increase the backoff duration
/// by a constant duration on each attempt.
///
/// A maximum duration can optionally be provided as an upper bound.
///
/// ```dart
/// final backoff = LinearBackoff(
///   initial: Duration(seconds: 1),
///   increment: Duration(seconds: 2),
///   maximum: Duration(seconds: 5),
/// );
///
/// backoff.next(); // Duration(seconds: 1)
/// backoff.next(); // Duration(seconds: 3)
/// backoff.next(); // Duration(seconds: 5);
/// backoff.next(); // Duration(seconds: 5);
/// ```
/// {@endtemplate}
class LinearBackoff implements Backoff {
  /// {@macro linear_backoff}
  LinearBackoff({
    required this.initial,
    required this.increment,
    this.maximum,
  }) : _current = initial;

  /// The initial backoff duration.
  final Duration initial;

  /// The amount to increment by after an attempt.
  final Duration increment;

  /// An optional maximum backoff duration.
  final Duration? maximum;

  Duration _current;

  @override
  Duration next() {
    final backoff = _current;
    final next = _current + increment;
    if (maximum == null || next <= maximum!) {
      _current = next;
    }
    return backoff;
  }

  @override
  void reset() {
    _current = initial;
  }
}
