import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('BinaryExponentialBackoff', () {
    test('next() returns a binary exponentially increasing duration.', () {
      const initial = Duration(seconds: 1);
      const maximumStep = 3;
      final backoff = BinaryExponentialBackoff(
        initial: initial,
        maximumStep: maximumStep,
      );

      const expected = [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ];
      final actual = List.generate(expected.length, (_) => backoff.next());

      expect(actual, equals(expected));
    });

    test('next() does not exceed maximum duration.', () {
      const initial = Duration(seconds: 1);
      const maximumStep = 5;
      final backoff = BinaryExponentialBackoff(
        initial: initial,
        maximumStep: maximumStep,
      );

      const expected = [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 16),
        Duration(seconds: 16),
        Duration(seconds: 16),
        Duration(seconds: 16),
        Duration(seconds: 16),
      ];
      final actual = List.generate(expected.length, (_) => backoff.next());

      expect(actual, equals(expected));
    });

    test('reset() resets the backoff.', () {
      const initial = Duration(seconds: 1);
      const maximumStep = 5;
      final backoff = BinaryExponentialBackoff(
        initial: initial,
        maximumStep: maximumStep,
      );

      expect(backoff.next(), equals(initial));
      expect(backoff.next(), equals(initial * 2));
      expect(backoff.reset, returnsNormally);
      expect(backoff.next(), equals(initial));
    });
  });
}
