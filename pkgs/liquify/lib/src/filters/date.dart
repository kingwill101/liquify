import 'package:liquify/src/filters/module.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

typedef FilterFunction = dynamic Function(dynamic value,
    List<dynamic> arguments, Map<String, dynamic> namedArguments);

bool _isInitialized = false;

void ensureTimezonesInitialized() {
  if (!_isInitialized) {
    tz.initializeTimeZones();
    _isInitialized = true;
  }
}

/// Formats a date according to the specified format string.
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// - arguments[0]: (Optional) Format string (default: 'yyyy-MM-dd')
/// Example usage:
/// {{ "2023-05-15" | date: "MMMM d, yyyy" }} => May 15, 2023
FilterFunction date = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  tz.TZDateTime? date = parseDate(value);
  if (date == null) return value;

  String format = arguments.isNotEmpty ? arguments[0].toString() : 'yyyy-MM-dd';
  return DateFormat(format).format(date.toLocal());
};

/// Formats a date in XML Schema format.
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// Example usage:
/// {{ "2023-05-15" | date_to_xmlschema }} => 2023-05-15T00:00:00.000-04:00
FilterFunction dateToXmlschema = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  tz.TZDateTime? date = parseDate(value);
  if (date == null) return value;
  String offset = date.timeZoneOffset.inHours.abs().toString().padLeft(2, '0');
  String sign = date.timeZoneOffset.isNegative ? '-' : '+';
  return '${date.toIso8601String().split('.')[0]}.000$sign$offset:00';
};

/// Formats a date in RFC 822 format.
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// Example usage:
/// {{ "2023-05-15" | date_to_rfc822 }} => Mon, 15 May 2023 00:00:00 -0400
FilterFunction dateToRfc822 = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  tz.TZDateTime? date = parseDate(value);
  if (date == null) return value;
  String offset = date.timeZoneOffset.inHours.abs().toString().padLeft(2, '0');
  String sign = date.timeZoneOffset.isNegative ? '-' : '+';
  return '${DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(date)} $sign${offset}00';
};

/// Formats a date to a short string format.
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// - arguments[0]: (Optional) 'ordinal' for ordinal date
/// - arguments[1]: (Optional) 'US' for US-style formatting
/// Example usage:
/// {{ "2023-05-15" | date_to_string }} => 15 May 2023
/// {{ "2023-05-15" | date_to_string: "ordinal" }} => 15th May 2023
/// {{ "2023-05-15" | date_to_string: "ordinal", "US" }} => May 15th, 2023
FilterFunction dateToString = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  return stringifyDate(value, 'MMM', arguments);
};

/// Formats a date to a long string format.
/// Parameters:
/// - value: The date to format (can be a DateTime, String, or number)
/// - arguments[0]: (Optional) 'ordinal' for ordinal date
/// - arguments[1]: (Optional) 'US' for US-style formatting
/// Example usage:
/// {{ "2023-05-15" | date_to_long_string }} => 15 May 2023
/// {{ "2023-05-15" | date_to_long_string: "ordinal" }} => 15th May 2023
/// {{ "2023-05-15" | date_to_long_string: "ordinal", "US" }} => May 15th, 2023
FilterFunction dateToLongString = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  return stringifyDate(value, 'MMMM', arguments);
};

String stringifyDate(
    dynamic value, String monthFormat, List<dynamic> arguments) {
  tz.TZDateTime? date = parseDate(value);
  if (date == null) return value.toString();

  String type = arguments.isNotEmpty ? arguments[0].toString() : '';
  String style = arguments.length > 1 ? arguments[1].toString() : '';

  if (type == 'ordinal') {
    String day = _getOrdinalDay(date.day);
    return style == 'US'
        ? DateFormat('$monthFormat d, yyyy')
            .format(date)
            .replaceFirst(' ${date.day},', ' $day,')
        : DateFormat('d $monthFormat yyyy')
            .format(date)
            .replaceFirst('${date.day} ', '$day ');
  }

  return DateFormat('dd $monthFormat yyyy').format(date);
}

tz.TZDateTime? parseDate(dynamic value) {
  tz.Location location = tz.local;
  if (value == 'now' || value == 'today') {
    return tz.TZDateTime.now(location);
  } else if (value is num) {
    return tz.TZDateTime.fromMillisecondsSinceEpoch(
        location, value.toInt() * 1000);
  } else if (value is String) {
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return tz.TZDateTime.fromMillisecondsSinceEpoch(
          location, int.parse(value) * 1000);
    } else {
      DateTime? dateTime = DateTime.parse(value);
      return tz.TZDateTime(
          location,
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond);
    }
  } else if (value is DateTime) {
    return tz.TZDateTime.from(value, location);
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
