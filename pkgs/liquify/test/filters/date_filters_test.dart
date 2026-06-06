import 'package:liquify/src/filters/date.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:test/test.dart';

void main() {
  setUp(() {
    ensureTimezonesInitialized();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
    tz.TZDateTime.now(tz.local);
  });

  group('Date Filters', () {
    group('construct', () {
      test('"now" with %Y', () {
        final year = tz.TZDateTime.now(tz.local).year.toString();
        expect(date('now', ['%Y'], {}), equals(year));
      });

      test('"today" with %Y', () {
        final year = tz.TZDateTime.now(tz.local).year.toString();
        expect(date('today', ['%Y'], {}), equals(year));
      });

      test('unix timestamp number', () {
        // Use a UTC-based timestamp: 2017-03-07T12:00:00Z
        final utcTs =
            DateTime.parse('2017-03-07T12:00:00Z').millisecondsSinceEpoch ~/
            1000;
        expect(
          date(utcTs, ['%Y-%m-%d'], {}),
          equals('2017-03-07'),
        );
      });

      test('unix timestamp string', () {
        final utcTs =
            DateTime.parse('2017-03-07T12:00:00Z').millisecondsSinceEpoch ~/
            1000;
        expect(
          date(utcTs.toString(), ['%Y-%m-%d'], {}),
          equals('2017-03-07'),
        );
      });

      test('null returns empty string', () {
        expect(date(null, ['%Y-%m-%dT%H:%M:%S'], {}), equals(''));
      });

      test('undefined (not in map) returns empty string', () {
        expect(date(null, ['%Y-%m-%dT%H:%M:%S'], {}), equals(''));
      });
    });

    group('strftime format specifiers', () {
      test('%a - abbreviated weekday', () {
        // 2024-07-21 is a Sunday; in America/New_York (EDT, UTC-4)
        // July 21 20:24 UTC = July 21 16:24 EDT, still Sunday
        expect(
          date('2024-07-21T20:24:00.000Z', ['%a'], {}),
          equals('Sun'),
        );
      });

      test('%A - full weekday', () {
        expect(
          date('2024-07-21T20:24:00.000Z', ['%A'], {}),
          equals('Sunday'),
        );
      });

      test('%b - abbreviated month', () {
        // 2024-07-31 20:24 UTC in America/New_York (EDT) = July 31
        expect(
          date('2024-07-31T20:24:00.000Z', ['%b'], {}),
          equals('Jul'),
        );
      });

      test('%B - full month', () {
        expect(
          date('2024-07-31T20:24:00.000Z', ['%B'], {}),
          equals('July'),
        );
      });

      test('%Y - 4-digit year', () {
        expect(date('2023-05-15', ['%Y'], {}), equals('2023'));
      });

      test('%y - 2-digit year', () {
        expect(date('2023-05-15', ['%y'], {}), equals('23'));
      });

      test('%m - zero-padded month', () {
        expect(date('2023-05-15', ['%m'], {}), equals('05'));
        expect(date('2023-11-15', ['%m'], {}), equals('11'));
      });

      test('%-m - unpadded month', () {
        expect(date('2023-05-15', ['%-m'], {}), equals('5'));
        expect(date('2023-11-15', ['%-m'], {}), equals('11'));
      });

      test('%d - zero-padded day', () {
        expect(date('2023-05-05', ['%d'], {}), equals('05'));
        expect(date('2023-05-15', ['%d'], {}), equals('15'));
      });

      test('%-d - unpadded day', () {
        expect(date('2023-05-05', ['%-d'], {}), equals('5'));
        expect(date('2023-05-15', ['%-d'], {}), equals('15'));
      });

      test('%H - zero-padded hour (00-23)', () {
        expect(date('2023-05-15T03:04:05', ['%H'], {}), equals('03'));
        expect(date('2023-05-15T14:04:05', ['%H'], {}), equals('14'));
      });

      test('%-H - unpadded hour (0-23)', () {
        expect(date('2023-05-15T03:04:05', ['%-H'], {}), equals('3'));
      });

      test('%I - zero-padded hour (01-12)', () {
        expect(date('2023-05-15T03:04:05', ['%I'], {}), equals('03'));
        expect(date('2023-05-15T14:04:05', ['%I'], {}), equals('02'));
      });

      test('%-I - unpadded hour (1-12)', () {
        expect(date('2023-05-15T03:04:05', ['%-I'], {}), equals('3'));
      });

      test('%M - zero-padded minute', () {
        expect(date('2023-05-15T03:04:05', ['%M'], {}), equals('04'));
      });

      test('%-M - unpadded minute', () {
        expect(date('2023-05-15T03:04:05', ['%-M'], {}), equals('4'));
      });

      test('%S - zero-padded second', () {
        expect(date('2023-05-15T03:04:05', ['%S'], {}), equals('05'));
      });

      test('%-S - unpadded second', () {
        expect(date('2023-05-15T03:04:05', ['%-S'], {}), equals('5'));
      });

      test('%p - uppercase am/pm', () {
        // Using DateTime directly to avoid timezone ambiguity
        expect(
          date(DateTime(2023, 5, 15, 3, 4, 5), ['%p'], {}),
          equals('AM'),
        );
        expect(
          date(DateTime(2023, 5, 15, 15, 4, 5), ['%p'], {}),
          equals('PM'),
        );
      });

      test('%P - lowercase am/pm', () {
        expect(
          date(DateTime(2023, 5, 15, 3, 4, 5), ['%P'], {}),
          equals('am'),
        );
        expect(
          date(DateTime(2023, 5, 15, 15, 4, 5), ['%P'], {}),
          equals('pm'),
        );
      });

      test('%e - space-padded day', () {
        expect(
          date('2023-05-05', ['%e'], {}),
          equals(' 5'),
        );
        expect(
          date('2023-05-15', ['%e'], {}),
          equals('15'),
        );
      });

      test('%% - literal percent', () {
        expect(date('2023-05-15', ['%%'], {}), equals('%'));
      });

      test('%s - unix timestamp seconds', () {
        final result = date('2023-05-15', ['%s'], {});
        expect(int.tryParse(result.toString()), isNotNull);
      });
    });

    group('combined strftime formats', () {
      test('%a %b %d %Y', () {
        expect(
          date('2024-07-21', ['%a %b %d %Y'], {}),
          equals('Sun Jul 21 2024'),
        );
      });

      test('%Y-%m-%dT%H:%M:%S', () {
        expect(
          date('2023-05-15T03:04:05', ['%Y-%m-%dT%H:%M:%S'], {}),
          equals('2023-05-15T03:04:05'),
        );
      });

      test('%a, %b %d, %y - the exact format from the bug report', () {
        expect(
          date(DateTime(2020, 1, 2, 3, 4, 5, 6), ['%a, %b %d, %y'], {}),
          equals('Thu, Jan 02, 20'),
        );
      });

      test('%B %-d, %Y', () {
        expect(
          date('2023-05-15', ['%B %-d, %Y'], {}),
          equals('May 15, 2023'),
        );
      });
    });

    group('timezone handling', () {
      test('timezone as second argument (minutes offset)', () {
        // 1990-12-31T23:00:00Z with offset 360 (-06:00) => 17:00
        expect(
          date('1990-12-31T23:00:00Z', ['%Y-%m-%dT%H:%M:%S', 360], {}),
          equals('1990-12-31T17:00:00'),
        );
      });

      test('timezone as IANA name argument', () {
        // 1990-12-31T23:00:00Z in Asia/Colombo (+05:30) => 1991-01-01T04:30:00
        expect(
          date(
            '1990-12-31T23:00:00Z',
            ['%Y-%m-%dT%H:%M:%S', 'Asia/Colombo'],
            {},
          ),
          equals('1991-01-01T04:30:00'),
        );
      });

      test('timezone with DST not active', () {
        // 2021-01-01T23:00:00Z in America/New_York (-05:00) => 18:00
        expect(
          date(
            '2021-01-01T23:00:00Z',
            ['%Y-%m-%dT%H:%M:%S', 'America/New_York'],
            {},
          ),
          equals('2021-01-01T18:00:00'),
        );
      });

      test('timezone with DST active', () {
        // 2021-06-01T23:00:00Z in America/New_York (-04:00) => 19:00
        expect(
          date(
            '2021-06-01T23:00:00Z',
            ['%Y-%m-%dT%H:%M:%S', 'America/New_York'],
            {},
          ),
          equals('2021-06-01T19:00:00'),
        );
      });

      test('%z - timezone offset in +HHMM format', () {
        final result = date('2023-05-15', ['%z'], {});
        expect(result, isA<String>());
        expect(
          result.toString(),
          matches(r'^[+-]\d{4}$'),
        );
      });

      test('%:z - timezone offset in +HH:MM format', () {
        final result = date('2023-05-15', ['%:z'], {});
        expect(result, isA<String>());
        expect(
          result.toString(),
          matches(r'^[+-]\d{2}:\d{2}$'),
        );
      });

      test('%Z - timezone name', () {
        final result = date('2023-05-15', ['%Z'], {});
        expect(result, isA<String>());
        expect(result.toString(), isNotEmpty);
      });
    });

    group('default format (no format argument)', () {
      test('returns yyyy-MM-dd when no format given', () {
        // Current default behavior
        final result = date('2023-05-15', [], {});
        expect(result, equals('2023-05-15'));
      });
    });

    group('edge cases', () {
      test('invalid string returns the string itself', () {
        expect(date('foo', ['%Y'], {}), equals('foo'));
      });

      test('empty string returns empty string', () {
        expect(date('', ['%Y'], {}), equals(''));
      });

      test('DateTime object preserves calendar components', () {
        expect(
          date(DateTime(2023, 5, 15), ['%Y-%m-%d'], {}),
          equals('2023-05-15'),
        );
      });

      test('TZDateTime object formats correctly', () {
        final dt = tz.TZDateTime(tz.local, 2023, 5, 15);
        expect(date(dt, ['%Y-%m-%d'], {}), equals('2023-05-15'));
      });

      test('date filter handles large timestamp values', () {
        // 1893470400 seconds = 2030-01-01T00:00:00Z
        // In America/New_York (EST): Dec 31 2029
        final result = date(1893470400, ['%Y-%m-%d'], {});
        expect(result, isA<String>());
        expect(result.toString().length, greaterThanOrEqualTo(10));
      });
    });

    group('date_to_xmlschema filter', () {
      test('formats date in XML Schema format', () {
        expect(
          dateToXmlschema('2023-05-15', [], {}),
          matches(r'^2023-05-15T00:00:00\.000[+-]\d{2}:\d{2}$'),
        );
      });

      test('formats date with offset', () {
        final result = dateToXmlschema('2023-05-15', [], {});
        expect(result, isA<String>());
        expect(result.toString().length, greaterThan(25));
      });
    });

    group('date_to_rfc822 filter', () {
      test('formats date in RFC 822 format', () {
        final result = dateToRfc822('2023-05-15', [], {});
        expect(result, isA<String>());
        expect(
          result,
          matches(r'^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}$'),
        );
      });

      test('RFC 822 day of week is correct', () {
        expect(
          dateToRfc822('2023-05-15', [], {}),
          startsWith('Mon'),
        );
      });
    });

    group('date_to_string filter', () {
      test('default non-ordinal UK style', () {
        expect(dateToString('2023-05-15', [], {}), equals('15 May 2023'));
      });

      test('ordinal style', () {
        expect(
          dateToString('2023-05-15', ['ordinal'], {}),
          equals('15th May 2023'),
        );
      });

      test('ordinal US style', () {
        expect(
          dateToString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'),
        );
      });

      test('11th ordinal', () {
        expect(
          dateToString('2023-11-11', ['ordinal'], {}),
          equals('11th Nov 2023'),
        );
      });

      test('render none if not valid', () {
        expect(dateToString('hello', ['ordinal', 'US'], {}), equals('hello'));
      });
    });

    group('date_to_long_string filter', () {
      test('default non-ordinal UK style', () {
        expect(
          dateToLongString('2023-05-15', [], {}),
          equals('15 May 2023'),
        );
      });

      test('ordinal style', () {
        expect(
          dateToLongString('2023-05-15', ['ordinal'], {}),
          equals('15th May 2023'),
        );
      });

      test('ordinal US style', () {
        expect(
          dateToLongString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'),
        );
      });

      test('ordinal UK with long month', () {
        expect(
          dateToLongString('2023-11-07', ['ordinal'], {}),
          equals('7th November 2023'),
        );
      });
    });
  });
}
