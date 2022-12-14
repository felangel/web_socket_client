// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  group('ConnectionState', () {
    group('Connecting', () {
      test('supports value equality', () {
        expect(Connecting(), equals(Connecting()));
        expect(Connecting().hashCode, equals(Connecting().hashCode));
      });
    });

    group('Connected', () {
      test('supports value equality', () {
        expect(Connected(), equals(Connected()));
        expect(Connected().hashCode, equals(Connected().hashCode));
      });
    });

    group('Reconnecting', () {
      test('supports value equality', () {
        expect(Reconnecting(), equals(Reconnecting()));
        expect(Reconnecting().hashCode, equals(Reconnecting().hashCode));
      });
    });

    group('Reconnected', () {
      test('supports value equality', () {
        expect(Reconnected(), equals(Reconnected()));
        expect(Reconnected().hashCode, equals(Reconnected().hashCode));
      });
    });

    group('Disconnecting', () {
      test('supports value equality', () {
        expect(Disconnecting(), equals(Disconnecting()));
        expect(Disconnecting().hashCode, equals(Disconnecting().hashCode));
      });
    });

    group('Disconnected', () {
      test('supports value equality', () {
        const code = 42;
        const reason = 'reason';
        const error = 'oops';
        const stackTrace = StackTrace.empty;

        expect(Disconnected(), equals(Disconnected()));
        expect(Disconnected().hashCode, equals(Disconnected().hashCode));

        expect(
          Disconnected(
            code: code,
            reason: reason,
            error: error,
            stackTrace: stackTrace,
          ),
          equals(
            Disconnected(
              code: code,
              reason: reason,
              error: error,
              stackTrace: stackTrace,
            ),
          ),
        );
        expect(
          Disconnected(
            code: code,
            reason: reason,
            error: error,
            stackTrace: stackTrace,
          ).hashCode,
          equals(
            Disconnected(
              code: code,
              reason: reason,
              error: error,
              stackTrace: stackTrace,
            ).hashCode,
          ),
        );

        expect(
          Disconnected(),
          isNot(equals(Disconnected(code: code, reason: reason))),
        );
        expect(
          Disconnected().hashCode,
          isNot(equals(Disconnected(code: code, reason: reason).hashCode)),
        );
      });
    });
  });
}
