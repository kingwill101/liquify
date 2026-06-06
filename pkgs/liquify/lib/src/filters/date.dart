import 'package:liquify/src/filters/module.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:d4_time_format/d4_time_format.dart';

typedef FilterFunction =
    dynamic Function(
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    );

bool _isInitialized = false;

void ensureTimezonesInitialized() {
  if (!_isInitialized) {
    tz.initializeTimeZones();
    _isInitialized = true;
  }
}

/// Formats a date according to the specified format string.
///
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// - arguments[0]: (Optional) Format string (default: 'yyyy-MM-dd')
/// - arguments[1]: (Optional) Timezone offset in minutes or IANA timezone name
FilterFunction date =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      ensureTimezonesInitialized();
      if (value == null) return '';

      String format = arguments.isNotEmpty
          ? arguments[0].toString()
          : 'yyyy-MM-dd';

      tz.Location? tzArg;
      if (arguments.length > 1 && arguments[1] != null) {
        tzArg = _resolveTimezone(arguments[1]);
      }

      tz.TZDateTime? date = parseDate(value, location: tzArg);
      if (date == null) return value;

      // If format contains %, treat as strftime; otherwise pass directly to DateFormat
      if (format.contains('%')) {
        return _applyStrftime(date, format);
      }
      return DateFormat(format).format(date);
    };

tz.Location? _resolveTimezone(dynamic arg) {
  if (arg is int || arg is double) {
    final offset = Duration(minutes: -(arg as num).toInt());
    return tz.Location(
      '',
      [],
      [],
      [tz.TimeZone(offset, isDst: false, abbreviation: '')],
    );
  } else if (arg is String) {
    try {
      return tz.getLocation(arg);
    } catch (_) {
      try {
        final sign = arg[0];
        final hours = int.parse(arg.substring(1, 3));
        final minutes = int.parse(arg.substring(3, 5));
        final offset = Duration(hours: hours, minutes: minutes);
        final total = sign == '-' ? -offset : offset;
        return tz.Location(
          '',
          [],
          [],
          [tz.TimeZone(total, isDst: false, abbreviation: '')],
        );
      } catch (e) {
        return null;
      }
    }
  }
  return null;
}

/// Applies a strftime-style format string to a TZDateTime using d4_time_format.
String _applyStrftime(tz.TZDateTime date, String format) {
  String processed = format
      .replaceAll('%P', '\x00P\x00')
      .replaceAll('%:z', '\x00:z\x00')
      .replaceAll('%Z', '\x00Z\x00')
      .replaceAll('%q', '\x00q\x00')
      .replaceAll('%z', '%Z');

  String result = timeFormat(processed)(date);

  return result
      .replaceAll('\x00P\x00', date.hour < 12 ? 'am' : 'pm')
      .replaceAll('\x00:z\x00', _formatOffset(date.timeZoneOffset, withColon: true))
      .replaceAll('\x00Z\x00', date.timeZoneName)
      .replaceAll('\x00q\x00', _getOrdinalDay(date.day));
}

String _formatOffset(Duration offset, {required bool withColon}) {
  final totalMinutes = offset.inMinutes.abs();
  final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
  final sign = offset.isNegative || offset.inMinutes < 0 ? '-' : '+';
  final sep = withColon ? ':' : '';
  return '$sign$hours$sep$minutes';
}

FilterFunction dateToXmlschema =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      ensureTimezonesInitialized();
      tz.TZDateTime? date = parseDate(value);
      if (date == null) return value;
      return '${date.toIso8601String().split('.')[0]}.000${_formatOffset(date.timeZoneOffset, withColon: true)}';
    };

FilterFunction dateToRfc822 =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      ensureTimezonesInitialized();
      tz.TZDateTime? date = parseDate(value);
      if (date == null) return value;
      final offset = _formatOffset(date.timeZoneOffset, withColon: false);
      return '${DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(date)} $offset';
    };

FilterFunction dateToString =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      ensureTimezonesInitialized();
      return stringifyDate(value, 'MMM', arguments);
    };

FilterFunction dateToLongString =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      ensureTimezonesInitialized();
      return stringifyDate(value, 'MMMM', arguments);
    };

String stringifyDate(
  dynamic value,
  String monthFormat,
  List<dynamic> arguments,
) {
  tz.TZDateTime? date = parseDate(value);
  if (date == null) return value.toString();

  String type = arguments.isNotEmpty ? arguments[0].toString() : '';
  String style = arguments.length > 1 ? arguments[1].toString() : '';

  if (type == 'ordinal') {
    String day = _getOrdinalDay(date.day);
    return style == 'US'
        ? DateFormat(
            '$monthFormat d, yyyy',
          ).format(date).replaceFirst(' ${date.day},', ' $day,')
        : DateFormat(
            'd $monthFormat yyyy',
          ).format(date).replaceFirst('${date.day} ', '$day ');
  }

  return DateFormat('dd $monthFormat yyyy').format(date);
}

tz.TZDateTime? parseDate(dynamic value, {tz.Location? location}) {
  tz.Location loc = location ?? tz.local;

  if (value == 'now' || value == 'today') {
    return tz.TZDateTime.now(loc);
  } else if (value is num) {
    return tz.TZDateTime.fromMillisecondsSinceEpoch(
      loc,
      value.toInt() * 1000,
    );
  } else if (value is String) {
    if (value.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return tz.TZDateTime.fromMillisecondsSinceEpoch(
        loc,
        int.parse(value) * 1000,
      );
    } else {
      try {
        DateTime dateTime = DateTime.parse(value);
        if (dateTime.isUtc) {
          return tz.TZDateTime.fromMillisecondsSinceEpoch(
            loc,
            dateTime.millisecondsSinceEpoch,
          );
        }
        return tz.TZDateTime(
          loc,
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
        );
      } catch (_) {
        return null;
      }
    }
  } else if (value is DateTime) {
    return tz.TZDateTime(
      loc,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
    );
  } else if (value is tz.TZDateTime) {
    return value;
  }
  return null;
}

String _getOrdinalDay(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

class DateModule extends Module {
  @override
  void register() {
    filters['date'] = date;
    filters['date_to_xmlschema'] = dateToXmlschema;
    filters['date_to_rfc822'] = dateToRfc822;
    filters['date_to_string'] = dateToString;
    filters['date_to_long_string'] = dateToLongString;
  }
}
