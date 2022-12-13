import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('LinearBackoff', () {
    test('next() returns a linearly incrementing duration.', () {
      const initial = Duration(seconds: 1);
      const increment = Duration(seconds: 2);
      final backoff = LinearBackoff(initial: initial, increment: increment);

      const expected = [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 5),
        Duration(seconds: 7),
        Duration(seconds: 9),
        Duration(seconds: 11),
        Duration(seconds: 13),
        Duration(seconds: 15),
        Duration(seconds: 17),
        Duration(seconds: 19),
      ];
      final actual = List.generate(expected.length, (_) => backoff.next());

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

      const expected = [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
      ];
      final actual = List.generate(expected.length, (_) => backoff.next());

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
