import 'package:bloc_preview/src/object_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseObjectNotation', () {
    test('keeps ISO-8601 datetime from object field as string', () {
      final result =
          parseObjectNotation(
                'Order(createdAt: 2026-05-05T12:13:14.123Z, status: Otwarta)',
              )
              as Map<String, dynamic>;

      expect(result['_type'], 'Order');
      expect(result['createdAt'], '2026-05-05T12:13:14.123Z');
      expect(result['status'], 'Otwarta');
    });

    test('keeps ISO-8601 datetime with timezone offset from map as string', () {
      final result =
          parseObjectNotation(
                '{createdAt: 2026-05-05T12:13:14+02:00, status: Open}',
              )
              as Map<String, dynamic>;

      expect(result['createdAt'], '2026-05-05T12:13:14+02:00');
      expect(result['status'], 'Open');
    });

    test('keeps UUID-like id starting with digits as string', () {
      final result =
          parseObjectNotation('Order(id: 123e4567-e89b-12d3-a456-426614174000)')
              as Map<String, dynamic>;

      expect(result['id'], '123e4567-e89b-12d3-a456-426614174000');
    });

    test('keeps URL with query params and ampersands untouched', () {
      final result =
          parseObjectNotation(
                'Channel(imageUrl: https://api.example.com/v1/orders/1019?source=mobile&lang=pl)',
              )
              as Map<String, dynamic>;

      expect(
        result['imageUrl'],
        'https://api.example.com/v1/orders/1019?source=mobile&lang=pl',
      );
    });

    test('keeps URL with commas in path untouched', () {
      final result =
          parseObjectNotation(
                'Channel(imageUrl: https://cdn.example.com/a,b,c/avatar.png, status: live)',
              )
              as Map<String, dynamic>;

      expect(result['imageUrl'], 'https://cdn.example.com/a,b,c/avatar.png');
      expect(result['status'], 'live');
    });

    test('keeps JWT-like token as string', () {
      final result =
          parseObjectNotation(
                'Auth(token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc-def_123.xyz)',
              )
              as Map<String, dynamic>;

      expect(
        result['token'],
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc-def_123.xyz',
      );
    });

    test('keeps semantic version as string', () {
      final result =
          parseObjectNotation('App(version: 1.0.0, build: 200)')
              as Map<String, dynamic>;

      expect(result['version'], '1.0.0');
      expect(result['build'], 200);
    });

    test('parses plain numeric tokens as numbers', () {
      final result =
          parseObjectNotation('Metrics(count: 1019, ratio: 12.5, retry: -3)')
              as Map<String, dynamic>;

      expect(result['count'], 1019);
      expect(result['ratio'], 12.5);
      expect(result['retry'], -3);
    });
  });
}
