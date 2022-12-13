import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('LinearBackoff', () {
    test('next() returns a linearly incrementing duration.', () {
      const initial = Duration(seconds: 1);
      const increment = Duration(seconds: 2);
      final backoff = LinearBackoff(initial: initial, increment: increment);

      const intervals = 10;
      final expected = List.generate(
        intervals,
        (index) => initial + (increment * index),
      );
      final actual = List.generate(intervals, (_) => backoff.next());

      expect(actual, equals(expected));
    });

    test('next() does not exceed maximum duration.', () {
      const initial = Duration(seconds: 1);
      const increment = Duration(seconds: 2);
      const maximum = Duration(seconds: 5);
      final backoff = LinearBackoff(
        initial: initial,
        increment: increment,
        maximum: maximum,
      );

      const intervals = 10;
      final expected = List.generate(intervals, (index) {
        final value = initial + (increment * index);
        if (value >= maximum) return maximum;
        return value;
      });
      final actual = List.generate(intervals, (_) => backoff.next());

      expect(actual, equals(expected));
    });

    test('reset() resets the backoff.', () {
      const initial = Duration(seconds: 1);
      const increment = Duration(seconds: 2);
      const maximum = Duration(seconds: 5);
      final backoff = LinearBackoff(
        initial: initial,
        increment: increment,
        maximum: maximum,
      );

      expect(backoff.next(), equals(initial));
      expect(backoff.next(), equals(initial + increment));
      expect(backoff.reset, returnsNormally);
      expect(backoff.next(), equals(initial));
    });
  });
}
