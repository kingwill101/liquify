import 'package:intl/intl.dart';
import 'package:liquify/src/liquid_options.dart';
import 'package:timezone/timezone.dart' as tz;

/// A parsed date with timezone information.
///
/// Represents a date/time instant along with its local time representation,
/// timezone offset, and timezone name. This class encapsulates both the UTC
/// instant and the timezone-aware local representation.
class ParsedDate {
  /// The instant in UTC.
  final DateTime instantUtc;

  /// The local time in the target timezone.
  final DateTime localTime;

  /// The timezone offset from UTC.
  final Duration offset;

  /// The name of the timezone, if available.
  final String? timezoneName;

  /// Whether the timezone was explicitly specified in the source.
  final bool hasExplicitTimezone;

  ParsedDate({
    required this.instantUtc,
    required this.localTime,
    required this.offset,
    required this.timezoneName,
    required this.hasExplicitTimezone,
  });
}

/// Short weekday names in Chinese.
const Map<int, String> _zhWeekdaysShort = {
  DateTime.monday: '周一',
  DateTime.tuesday: '周二',
  DateTime.wednesday: '周三',
  DateTime.thursday: '周四',
  DateTime.friday: '周五',
  DateTime.saturday: '周六',
  DateTime.sunday: '周日',
};

/// Long weekday names in Chinese.
const Map<int, String> _zhWeekdaysLong = {
  DateTime.monday: '星期一',
  DateTime.tuesday: '星期二',
  DateTime.wednesday: '星期三',
  DateTime.thursday: '星期四',
  DateTime.friday: '星期五',
  DateTime.saturday: '星期六',
  DateTime.sunday: '星期日',
};

/// Long month names in Chinese.
const List<String> _zhMonthsLong = [
  '一月',
  '二月',
  '三月',
  '四月',
  '五月',
  '六月',
  '七月',
  '八月',
  '九月',
  '十月',
  '十一月',
  '十二月',
];

/// Formats a date pattern with locale support.
///
/// For Chinese locales (zh-cn), provides custom formatting for weekdays and
/// months. Falls back to [DateFormat] for other locales, with 'en_US' as the
/// final fallback if the specified locale is unavailable.
String _formatPattern(DateTime local, String pattern, String locale) {
  final normalized = locale.replaceAll('_', '-').toLowerCase();
  if (normalized == 'zh-cn') {
    switch (pattern) {
      case 'EEE':
        return _zhWeekdaysShort[local.weekday] ?? '';
      case 'EEEE':
        return _zhWeekdaysLong[local.weekday] ?? '';
      case 'MMM':
        return '${local.month}月';
      case 'MMMM':
        return _zhMonthsLong[local.month - 1];
    }
  }

  try {
    return DateFormat(pattern, locale).format(local);
  } catch (_) {
    return DateFormat(pattern, 'en_US').format(local);
  }
}

/// Parses a timezone offset from various input types.
///
/// Accepts:
/// - [Duration] objects (returned as-is)
/// - Numeric values (interpreted as minutes, negated for UTC offset)
/// - Strings like 'UTC', 'Z', '+05:30', '-0800', etc.
///
/// Returns `null` if the value cannot be parsed.
Duration? _parseOffset(dynamic value) {
  if (value == null) return null;
  if (value is Duration) return value;
  if (value is num) {
    final minutes = (value.toDouble()).round();
    return Duration(minutes: -minutes);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toUpperCase() == 'UTC' || trimmed == 'Z') {
      return Duration.zero;
    }
    final regex = RegExp(r'^([+-])(\d{2}):?(\d{2})$');
    final match = regex.firstMatch(trimmed);
    if (match != null) {
      final sign = match.group(1) == '-' ? -1 : 1;
      final hours = int.parse(match.group(2)!);
      final minutes = int.parse(match.group(3)!);
      final totalMinutes = sign * (hours * 60 + minutes);
      return Duration(minutes: totalMinutes);
    }
  }
  return null;
}

/// Converts a timezone offset to a string representation.
///
/// The [colon] parameter controls whether to include a colon separator
/// between hours and minutes (e.g., '+05:30' vs '+0530').
String _offsetToString(Duration offset, {bool colon = false}) {
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes < 0 ? '-' : '+';
  final absMinutes = totalMinutes.abs();
  final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absMinutes % 60).toString().padLeft(2, '0');
  return colon ? '$sign$hours:$minutes' : '$sign$hours$minutes';
}

/// Returns whether the string contains an explicit timezone indicator.
///
/// Checks for 'Z' suffix or offset patterns like '+05:30' or '-0800'.
bool _stringHasExplicitTimezone(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('Z') || trimmed.endsWith('z')) {
    return true;
  }
  return RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);
}

/// Parses a date value from various input types.
///
/// Accepts:
/// - [DateTime] and [tz.TZDateTime] objects
/// - Numeric timestamps (seconds since epoch)
/// - ISO 8601 date strings
/// - Special strings: 'now', 'today'
/// - `null` (optionally treated as epoch start if [treatNullAsEpoch] is true)
///
/// The [timezoneArgument] can specify a timezone name or offset to apply.
/// If not provided, uses [options.timezoneOffset] or the system local timezone.
///
/// Returns `null` if the value cannot be parsed.
ParsedDate? parseDateValue(
  dynamic value, {
  required LiquidOptions options,
  dynamic timezoneArgument,
  bool treatNullAsEpoch = false,
}) {
  DateTime? instantUtc;
  Duration? sourceOffset;
  String? sourceTimezoneName;
  bool sourceHasTimezone = false;

  void setFromDateTime(DateTime dt, {bool explicit = false}) {
    instantUtc = dt.toUtc();
    sourceOffset = dt.timeZoneOffset;
    sourceTimezoneName = dt.timeZoneName;
    sourceHasTimezone = explicit;
  }

  if (value == null) {
    if (!treatNullAsEpoch) {
      return null;
    }
    instantUtc =
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // epoch start
    sourceOffset = Duration.zero;
    sourceTimezoneName = 'UTC';
    sourceHasTimezone = true;
  } else if (value is DateTime) {
    setFromDateTime(value, explicit: value.isUtc);
  } else if (value is tz.TZDateTime) {
    setFromDateTime(value, explicit: true);
  } else if (value is num) {
    final milliseconds =
        (value.toDouble() * 1000).round(); // assume seconds since epoch
    instantUtc = DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    sourceOffset = Duration.zero;
    sourceTimezoneName = 'UTC';
    sourceHasTimezone = true;
  } else if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed == 'now' || trimmed == 'today') {
      final now = DateTime.now();
      setFromDateTime(now);
    } else if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      final milliseconds = (double.parse(trimmed) * 1000).round();
      instantUtc =
          DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
      sourceOffset = Duration.zero;
      sourceTimezoneName = 'UTC';
      sourceHasTimezone = true;
    } else {
      final hasExplicitTimezone = _stringHasExplicitTimezone(trimmed);
      Duration? explicitOffset;
      String? explicitTimezoneName;

      if (trimmed.endsWith('Z') || trimmed.endsWith('z')) {
        explicitOffset = Duration.zero;
        explicitTimezoneName = 'UTC';
      } else {
        final offsetMatch = RegExp(r'([+-]\d{2}:?\d{2})$').firstMatch(trimmed);
        if (offsetMatch != null) {
          explicitOffset = _parseOffset(offsetMatch.group(1));
        }
      }

      try {
        final parsed = DateTime.parse(trimmed);
        if (hasExplicitTimezone || parsed.isUtc) {
          setFromDateTime(parsed,
              explicit: hasExplicitTimezone || parsed.isUtc);
          if (explicitOffset != null) {
            sourceOffset = explicitOffset;
            sourceTimezoneName =
                explicitTimezoneName ?? _offsetToString(explicitOffset);
            sourceHasTimezone = true;
          } else if (hasExplicitTimezone) {
            sourceHasTimezone = true;
          }
        } else {
          final tzDate = tz.TZDateTime(
            tz.local,
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
          instantUtc = tzDate.toUtc();
          sourceOffset = tzDate.timeZoneOffset;
          sourceTimezoneName = tz.local.name;
          sourceHasTimezone = false;
        }
      } catch (_) {
        return null;
      }
    }
  } else {
    return null;
  }

  if (instantUtc == null) {
    return null;
  }

  Duration? targetOffset;
  String? timezoneName;

  TimeZoneResult? fromLocation(String name) {
    try {
      final location = tz.getLocation(name);
      final tzDate = tz.TZDateTime.from(instantUtc!, location);
      final naive = DateTime(
        tzDate.year,
        tzDate.month,
        tzDate.day,
        tzDate.hour,
        tzDate.minute,
        tzDate.second,
        tzDate.millisecond,
        tzDate.microsecond,
      );
      return TimeZoneResult(
        localTime: naive,
        offset: tzDate.timeZoneOffset,
        timezoneName: name,
      );
    } catch (_) {
      return null;
    }
  }

  // Helper to build result
  ParsedDate build(DateTime local, Duration offset, String? name,
          {bool explicit = false}) =>
      ParsedDate(
        instantUtc: instantUtc!,
        localTime: local,
        offset: offset,
        timezoneName: name,
        hasExplicitTimezone: explicit,
      );

  // 1. explicit timezone argument
  if (timezoneArgument != null) {
    if (timezoneArgument is String &&
        timezoneArgument.trim().isNotEmpty &&
        timezoneArgument.trim().toUpperCase() != 'NIL') {
      final tzResult = fromLocation(timezoneArgument.trim());
      if (tzResult != null) {
        return build(tzResult.localTime, tzResult.offset, tzResult.timezoneName,
            explicit: true);
      }
      final offset = _parseOffset(timezoneArgument);
      if (offset != null) {
        targetOffset = offset;
        timezoneName = _offsetToString(offset);
      }
    } else {
      final offset = _parseOffset(timezoneArgument);
      if (offset != null) {
        targetOffset = offset;
        timezoneName = _offsetToString(offset);
      }
    }
  }

  // 2. preserve original timezone if requested
  if (targetOffset == null &&
      timezoneName == null &&
      options.preserveTimezones &&
      sourceHasTimezone) {
    targetOffset = sourceOffset ?? Duration.zero;
    timezoneName = sourceTimezoneName ?? _offsetToString(targetOffset);
  }

  // 3. engine-level options
  if (targetOffset == null && timezoneName == null) {
    final optionTz = options.timezoneOffset;
    if (optionTz != null) {
      if (optionTz is String && optionTz.trim().isNotEmpty) {
        final tzResult = fromLocation(optionTz.trim());
        if (tzResult != null) {
          return build(
              tzResult.localTime, tzResult.offset, tzResult.timezoneName,
              explicit: true);
        }
      }
      final offset = _parseOffset(optionTz);
      if (offset != null) {
        targetOffset = offset;
        timezoneName = optionTz is String ? optionTz : _offsetToString(offset);
      }
    }
  }

  // 4. fall back to default (system local)
  if (targetOffset == null) {
    final location = tz.local;
    final tzLocalDate = tz.TZDateTime.from(instantUtc!, location);
    final shouldUseSystemLocal =
        location.name == 'UTC' && DateTime.now().timeZoneName != 'UTC';

    final DateTime localDate;
    final Duration offset;
    final String zoneName;

    if (shouldUseSystemLocal) {
      final systemLocal = instantUtc!.toLocal();
      localDate = DateTime(
        systemLocal.year,
        systemLocal.month,
        systemLocal.day,
        systemLocal.hour,
        systemLocal.minute,
        systemLocal.second,
        systemLocal.millisecond,
        systemLocal.microsecond,
      );
      offset = systemLocal.timeZoneOffset;
      zoneName = DateTime.now().timeZoneName;
    } else {
      localDate = DateTime(
        tzLocalDate.year,
        tzLocalDate.month,
        tzLocalDate.day,
        tzLocalDate.hour,
        tzLocalDate.minute,
        tzLocalDate.second,
        tzLocalDate.millisecond,
        tzLocalDate.microsecond,
      );
      offset = tzLocalDate.timeZoneOffset;
      zoneName = location.name;
    }

    return build(
      localDate,
      offset,
      zoneName,
      explicit: false,
    );
  }

  // apply numeric offset
  final local = instantUtc!.add(targetOffset);
  return build(
    DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    ),
    targetOffset,
    timezoneName ?? _offsetToString(targetOffset),
    explicit: true,
  );
}

/// A timezone conversion result.
///
/// Contains the local time, offset, and timezone name for a specific instant
/// in a particular timezone.
class TimeZoneResult {
  /// The local time in the timezone.
  final DateTime localTime;

  /// The timezone offset from UTC.
  final Duration offset;

  /// The name of the timezone.
  final String? timezoneName;

  TimeZoneResult({
    required this.localTime,
    required this.offset,
    required this.timezoneName,
  });
}

/// Returns the ordinal suffix for a day number.
///
/// Examples: 1 → 'st', 2 → 'nd', 3 → 'rd', 4 → 'th', 11 → 'th'.
String _ordinalSuffix(int value) {
  if (value >= 11 && value <= 13) {
    return 'th';
  }
  switch (value % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

/// Formats a date using strftime-style format specifiers.
///
/// Supports standard strftime tokens like %Y (year), %m (month), %d (day),
/// %H (hour), etc., with optional modifiers like - (no padding), _ (space
/// padding), and : (for colon in timezone offsets).
///
/// The [locale] from [options] is used for localized strings like weekday
/// and month names.
String formatStrftime(
  ParsedDate parsed,
  String format,
  LiquidOptions options,
) {
  final locale = options.disableIntl ? 'en_US' : (options.locale ?? 'en_US');
  final buffer = StringBuffer();
  final local = parsed.localTime;
  final offset = parsed.offset;
  final timezoneName = parsed.timezoneName;
  final instantUtc = parsed.instantUtc;

  String formatNumber(int value, int width,
          {bool spacePad = false, bool noPadding = false}) =>
      noPadding
          ? value.toString()
          : value.toString().padLeft(width, spacePad ? ' ' : '0');

  int hour12(int hour) {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }

  for (var i = 0; i < format.length; i++) {
    final char = format[i];
    if (char != '%') {
      buffer.write(char);
      continue;
    }
    if (i + 1 >= format.length) {
      buffer.write('%');
      continue;
    }

    var modifier = '';
    var tokenIndex = i + 1;
    var next = format[tokenIndex];

    if (next == '-' || next == '_' || next == '^' || next == '#') {
      modifier = next;
      tokenIndex++;
      if (tokenIndex >= format.length) {
        buffer.write('%$modifier');
        break;
      }
      next = format[tokenIndex];
    }

    if (next == ':' && tokenIndex + 1 < format.length) {
      final following = format[tokenIndex + 1];
      if (following == 'z' || following == 'Z') {
        buffer.write(_offsetToString(offset, colon: true));
        i = tokenIndex + 1;
        continue;
      }
    }

    String resolveToken(String token) {
      switch (token) {
        case '%':
          return '%';
        case 'a':
          return _formatPattern(local, 'EEE', locale);
        case 'A':
          return _formatPattern(local, 'EEEE', locale);
        case 'b':
        case 'h':
          return _formatPattern(local, 'MMM', locale);
        case 'B':
          return _formatPattern(local, 'MMMM', locale);
        case 'c':
          try {
            return DateFormat.yMd(locale).add_jm().format(local);
          } catch (_) {
            return DateFormat.yMd('en_US').add_jm().format(local);
          }
        case 'C':
          return formatNumber(local.year ~/ 100, 2);
        case 'd':
          return formatNumber(local.day, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'e':
          return formatNumber(local.day, 2, spacePad: true);
        case 'F':
          return formatStrftime(parsed, '%Y-%m-%d', options);
        case 'H':
          return formatNumber(local.hour, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'I':
          return formatNumber(hour12(local.hour), 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'j':
          final startOfYear = DateTime(local.year, 1, 1);
          final dayOfYear =
              local.difference(startOfYear).inDays + 1; // 1-indexed
          return formatNumber(dayOfYear, 3);
        case 'k':
          return formatNumber(local.hour, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'l':
          return formatNumber(hour12(local.hour), 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'L':
          return formatNumber(local.millisecond, 3);
        case 'M':
          return formatNumber(local.minute, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'm':
          return formatNumber(local.month, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 'n':
          return '\n';
        case 'P':
          return _formatPattern(local, 'a', locale).toLowerCase();
        case 'p':
          return _formatPattern(local, 'a', locale);
        case 'q':
          return _ordinalSuffix(local.day);
        case 'R':
          return formatStrftime(parsed, '%H:%M', options);
        case 'r':
          return formatStrftime(parsed, '%I:%M:%S %p', options);
        case 'S':
          return formatNumber(local.second, 2,
              noPadding: modifier == '-', spacePad: modifier == '_');
        case 's':
          return (instantUtc.millisecondsSinceEpoch ~/ 1000).toString();
        case 't':
          return '\t';
        case 'T':
          return formatStrftime(parsed, '%H:%M:%S', options);
        case 'u':
          final weekday = local.weekday == DateTime.sunday
              ? 7
              : local.weekday; // ISO Monday=1
          return weekday.toString();
        case 'w':
          return ((local.weekday % 7)).toString();
        case 'Y':
          return local.year.toString();
        case 'y':
          return formatNumber(local.year % 100, 2);
        case 'z':
          return _offsetToString(offset);
        case 'Z':
          return timezoneName ?? _offsetToString(offset);
        default:
          return token;
      }
    }

    final token = next;
    if (token == ':') {
      buffer.write(resolveToken(token));
      i = tokenIndex;
      continue;
    }

    buffer.write(resolveToken(token));
    i = tokenIndex;
  }
  return buffer.toString();
}

/// Formats a date as an XML Schema (ISO 8601) datetime string.
///
/// Returns a string in the format `YYYY-MM-DDTHH:MM:SS±HH:MM`.
String formatXmlSchema(ParsedDate parsed) {
  final local = parsed.localTime;
  final yyyy = local.year.toString().padLeft(4, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  final ss = local.second.toString().padLeft(2, '0');
  final offset = _offsetToString(parsed.offset, colon: true);
  return '$yyyy-$mm-${dd}T$hh:$min:$ss$offset';
}

/// Formats a date as an RFC 822 datetime string.
///
/// Returns a string in the format `Day, DD Mon YYYY HH:MM:SS ±HHMM`.
String formatRfc822(ParsedDate parsed, LiquidOptions options) {
  final locale = options.disableIntl ? 'en_US' : (options.locale ?? 'en_US');
  final weekday = _formatPattern(parsed.localTime, 'EEE', locale);
  final day = parsed.localTime.day.toString().padLeft(2, '0');
  final month = _formatPattern(parsed.localTime, 'MMM', locale);
  final year = parsed.localTime.year.toString().padLeft(4, '0');
  final hour = parsed.localTime.hour.toString().padLeft(2, '0');
  final minute = parsed.localTime.minute.toString().padLeft(2, '0');
  final second = parsed.localTime.second.toString().padLeft(2, '0');
  final offset = _offsetToString(parsed.offset);
  return '$weekday, $day $month $year $hour:$minute:$second $offset';
}

/// Formats a date as a short date string.
///
/// The output format varies based on the parameters:
/// - [ordinal]: Whether to include ordinal suffix (e.g., '1st', '2nd')
/// - [longMonth]: Whether to use full month name vs. abbreviation
/// - [usStyle]: Whether to use US-style month-first ordering
///
/// Examples:
/// - `01 Jan 2023` (default)
/// - `January 1st, 2023` (ordinal + usStyle + longMonth)
/// - `1st January 2023` (ordinal + longMonth)
String formatShortDate(
  ParsedDate parsed,
  LiquidOptions options, {
  bool ordinal = false,
  bool longMonth = false,
  bool usStyle = false,
}) {
  final locale = options.disableIntl ? 'en_US' : (options.locale ?? 'en_US');
  final day = parsed.localTime.day;
  final ordinalSuffix = _ordinalSuffix(day);

  if (ordinal && usStyle) {
    final monthName =
        _formatPattern(parsed.localTime, longMonth ? 'MMMM' : 'MMM', locale);
    final year = parsed.localTime.year;
    return '$monthName $day$ordinalSuffix, $year';
  }

  if (ordinal && !usStyle) {
    final monthName =
        _formatPattern(parsed.localTime, longMonth ? 'MMMM' : 'MMM', locale);
    final year = parsed.localTime.year;
    return '$day$ordinalSuffix $monthName $year';
  }

  if (usStyle) {
    final monthName =
        _formatPattern(parsed.localTime, longMonth ? 'MMMM' : 'MMM', locale);
    final year = parsed.localTime.year;
    return '$monthName ${day.toString().padLeft(2, '0')}, $year';
  }

  final dayStr = day.toString().padLeft(2, '0');
  final monthName =
      _formatPattern(parsed.localTime, longMonth ? 'MMMM' : 'MMM', locale);
  final year = parsed.localTime.year;
  return '$dayStr $monthName $year';
}
