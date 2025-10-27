import 'package:intl/intl.dart';
import 'package:liquify/src/filters/date.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

String _formatOffset(Duration offset, {required bool includeColon}) {
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes < 0 ? '-' : '+';
  final absMinutes = totalMinutes.abs();
  final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absMinutes % 60).toString().padLeft(2, '0');
  return includeColon ? '$sign$hours:$minutes' : '$sign$hours$minutes';
}

void main() {
  setUp(() {
    ensureTimezonesInitialized();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('Date Filters', () {
    test('date filter', () {
      expect(date('2023-05-15', ['%Y-%m-%d'], {}), equals('2023-05-15'));
      expect(date('2023-05-15', ['%B %-d, %Y'], {}), equals('May 15, 2023'));
      expect(
        date('now', ['%Y-%m-%d'], {}),
        equals(
          DateFormat('yyyy-MM-dd').format(tz.TZDateTime.now(tz.local)),
        ),
      );
    });

    test('date_to_xmlschema filter', () {
      final localDate = tz.TZDateTime(tz.local, 2023, 5, 15);
      final offset =
          _formatOffset(localDate.timeZoneOffset, includeColon: true);
      expect(dateToXmlschema('2023-05-15', [], {}),
          equals('2023-05-15T00:00:00$offset'));
    });

    test('date_to_rfc822 filter', () {
      final localDate = tz.TZDateTime(tz.local, 2023, 5, 15);
      final weekday = DateFormat('EEE', 'en_US').format(localDate);
      final month = DateFormat('MMM', 'en_US').format(localDate);
      final offset =
          _formatOffset(localDate.timeZoneOffset, includeColon: false);
      expect(dateToRfc822('2023-05-15', [], {}),
          equals('$weekday, 15 $month 2023 00:00:00 $offset'));
    });

    test('date_to_string filter', () {
      expect(dateToString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(
          dateToString('2023-05-15', ['ordinal'], {}), equals('15th May 2023'));
      expect(dateToString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });

    test('date_to_long_string filter', () {
      expect(dateToLongString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal'], {}),
          equals('15th May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });
  });
}
