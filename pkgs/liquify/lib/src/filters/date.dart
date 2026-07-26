import 'package:liquify/src/filters/module.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

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

      // If format contains %, treat it as strftime; otherwise pass directly to DateFormat.
      if (format.contains('%')) {
        return _applyStrftime(date, format);
      }
      return DateFormat(format).format(date);
    };

tz.Location? _resolveTimezone(dynamic arg) {
  if (arg is int || arg is double) {
    final offset = Duration(minutes: -(arg as num).toInt());
    return tz.Location('', [], [], [
      tz.TimeZone(offset, isDst: false, abbreviation: ''),
    ]);
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
        return tz.Location('', [], [], [
          tz.TimeZone(total, isDst: false, abbreviation: ''),
        ]);
      } catch (e) {
        return null;
      }
    }
  }
  return null;
}

/// Applies a strftime-style format string to a TZDateTime.
String _applyStrftime(tz.TZDateTime date, String format) {
  final buffer = StringBuffer();

  for (var i = 0; i < format.length; i++) {
    final char = format[i];
    if (char != '%') {
      buffer.write(char);
      continue;
    }

    if (i + 1 >= format.length) {
      buffer.write('%');
      break;
    }

    final next = format[++i];
    if (next == '%') {
      buffer.write('%');
      continue;
    }

    if (next == '-') {
      if (i + 1 >= format.length) {
        buffer.write('%-');
        break;
      }
      final specifier = format[++i];
      buffer.write(_formatStrftime(date, specifier, pad: false));
      continue;
    }

    if (next == ':') {
      if (i + 1 >= format.length) {
        buffer.write('%:');
        break;
      }
      final specifier = format[++i];
      if (specifier == 'z') {
        buffer.write(_formatOffset(date.timeZoneOffset, withColon: true));
      } else {
        buffer.write('%:$specifier');
      }
      continue;
    }

    buffer.write(_formatStrftime(date, next));
  }

  return buffer.toString();
}

String _formatStrftime(
  tz.TZDateTime date,
  String specifier, {
  bool pad = true,
}) {
  switch (specifier) {
    case 'a':
      return DateFormat('EEE').format(date);
    case 'A':
      return DateFormat('EEEE').format(date);
    case 'b':
      return DateFormat('MMM').format(date);
    case 'B':
      return DateFormat('MMMM').format(date);
    case 'Y':
      return DateFormat('yyyy').format(date);
    case 'y':
      return DateFormat('yy').format(date);
    case 'm':
      return pad
          ? date.month.toString().padLeft(2, '0')
          : date.month.toString();
    case 'd':
      return pad ? date.day.toString().padLeft(2, '0') : date.day.toString();
    case 'e':
      return date.day.toString().padLeft(2, ' ');
    case 'H':
      return pad ? date.hour.toString().padLeft(2, '0') : date.hour.toString();
    case 'I':
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return pad ? hour.toString().padLeft(2, '0') : hour.toString();
    case 'M':
      return pad
          ? date.minute.toString().padLeft(2, '0')
          : date.minute.toString();
    case 'S':
      return pad
          ? date.second.toString().padLeft(2, '0')
          : date.second.toString();
    case 'p':
      return date.hour < 12 ? 'AM' : 'PM';
    case 'P':
      return date.hour < 12 ? 'am' : 'pm';
    case 's':
      return (date.millisecondsSinceEpoch ~/ 1000).toString();
    case 'z':
      return _formatOffset(date.timeZoneOffset, withColon: false);
    case 'Z':
      return date.timeZoneName;
    case 'q':
      return _getOrdinalDay(date.day);
    default:
      return '%$specifier';
  }
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
    return tz.TZDateTime.fromMillisecondsSinceEpoch(loc, value.toInt() * 1000);
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
  } else if (value is tz.TZDateTime) {
    return location == null ? value : tz.TZDateTime.from(value, loc);
  } else if (value is DateTime) {
    if (value.isUtc) {
      return tz.TZDateTime.from(value, loc);
    }
    return tz.TZDateTime(
      loc,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
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
