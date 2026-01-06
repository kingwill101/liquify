import 'package:intl/intl.dart';
import 'package:liquify/src/filters/date.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:test/test.dart';

void main() {
  setUp(() {
    ensureTimezonesInitialized();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('Date Filters', () {
    test('date filter', () {
      expect(date('2023-05-15', ['yyyy-MM-dd'], {}), equals('2023-05-15'));
      expect(date('2023-05-15', ['MMMM d, yyyy'], {}), equals('May 15, 2023'));
      expect(
        date('now', ['yyyy-MM-dd'], {}),
        equals(DateFormat('yyyy-MM-dd').format(tz.TZDateTime.now(tz.local))),
      );
    });

    test('date filter handles DateTime inputs', () {
      expect(
        date(DateTime(2023, 05, 15), ['yyyy-MM-dd'], {}),
        equals('2023-05-15'),
      );
    });

    test('date filter handles timestamp values', () {
      expect(date(1684123200, ['yyyy-MM-dd'], {}), equals('2023-05-15'));
      expect(date('1684123200', ['yyyy-MM-dd'], {}), equals('2023-05-15'));
    });

    test('date_to_xmlschema filter', () {
      expect(
        dateToXmlschema('2023-05-15', [], {}),
        equals('2023-05-15T00:00:00.000-04:00'),
      );
      expect(
        dateToXmlschema('2023-01-15', [], {}),
        equals('2023-01-15T00:00:00.000-05:00'),
      );
    });

    test('date_to_rfc822 filter', () {
      expect(
        dateToRfc822('2023-05-15', [], {}),
        equals('Mon, 15 May 2023 00:00:00 -0400'),
      );
      expect(
        dateToRfc822('2023-01-15', [], {}),
        equals('Sun, 15 Jan 2023 00:00:00 -0500'),
      );
    });

    test('date_to_string filter', () {
      expect(dateToString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(
        dateToString('2023-05-15', ['ordinal'], {}),
        equals('15th May 2023'),
      );
      expect(
        dateToString('2023-05-15', ['ordinal', 'US'], {}),
        equals('May 15th, 2023'),
      );
      expect(
        dateToString('2023-11-11', ['ordinal'], {}),
        equals('11th Nov 2023'),
      );
    });

    test('date_to_long_string filter', () {
      expect(dateToLongString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(
        dateToLongString('2023-05-15', ['ordinal'], {}),
        equals('15th May 2023'),
      );
      expect(
        dateToLongString('2023-05-15', ['ordinal', 'US'], {}),
        equals('May 15th, 2023'),
      );
      expect(
        dateToLongString('2023-11-11', ['ordinal', 'US'], {}),
        equals('November 11th, 2023'),
      );
    });
  });
}
