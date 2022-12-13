/// {@template backoff}
/// An abstract backoff strategy.
/// {@endtemplate}
abstract class Backoff {
  /// Returns the next value in the series.
  Duration next();

  /// Resets the backoff to its initial state.
  void reset();
}
