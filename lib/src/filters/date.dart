import 'package:liquify/src/filters/date_utils.dart';
import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/liquid_options.dart';
import 'package:timezone/data/latest.dart' as tz;

typedef FilterFunction = dynamic Function(dynamic value,
    List<dynamic> arguments, Map<String, dynamic> namedArguments);

bool _isInitialized = false;

void ensureTimezonesInitialized() {
  if (!_isInitialized) {
    tz.initializeTimeZones();
    _isInitialized = true;
  }
}

LiquidOptions _extractOptions(Map<String, dynamic> namedArguments) {
  final raw = namedArguments['_options'];
  return LiquidOptions.maybeFrom(raw) ?? const LiquidOptions();
}

String? _stringArg(dynamic argument) {
  if (argument == null) return null;
  final value = argument.toString();
  if (value.isEmpty || value.toLowerCase() == 'nil') {
    return null;
  }
  return value;
}

dynamic _fallbackValue(dynamic original) {
  if (original == null) {
    return '';
  }
  if (original is Map || original is Iterable || original is Set) {
    return '[object Object]';
  }
  return original.toString();
}

const _defaultDateFormat = '%A, %B %-d, %Y at %-l:%M %P %z';

FilterFunction date = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  final options = _extractOptions(namedArguments);
  final isNilLiteral = namedArguments['__input_is_nil'] == true;

  String? format = arguments.isNotEmpty ? _stringArg(arguments[0]) : null;
  dynamic timezoneArg =
      arguments.length > 1 ? arguments[1] : null; // optional timezone argument

  final parsed = parseDateValue(value,
      options: options,
      timezoneArgument: timezoneArg,
      treatNullAsEpoch: isNilLiteral);

  if (parsed == null) {
    return _fallbackValue(value);
  }

  final formatString = format ?? options.dateFormat ?? _defaultDateFormat;
  final formatted = formatStrftime(parsed, formatString, options);
  if (formatString.trim() == '%s') {
    return int.tryParse(formatted) ?? formatted;
  }
  return formatted;
};

FilterFunction dateToXmlschema = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  final options = _extractOptions(namedArguments);
  final parsed = parseDateValue(value,
      options: options,
      timezoneArgument: arguments.isNotEmpty ? arguments.first : null,
      treatNullAsEpoch: namedArguments['__input_is_nil'] == true);

  if (parsed == null) {
    return _fallbackValue(value);
  }
  return formatXmlSchema(parsed);
};

FilterFunction dateToRfc822 = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  final options = _extractOptions(namedArguments);
  final parsed = parseDateValue(value,
      options: options,
      timezoneArgument: arguments.isNotEmpty ? arguments.first : null,
      treatNullAsEpoch: namedArguments['__input_is_nil'] == true);

  if (parsed == null) {
    return _fallbackValue(value);
  }
  return formatRfc822(parsed, options);
};

FilterFunction dateToString = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  final options = _extractOptions(namedArguments);
  final parsed = parseDateValue(value,
      options: options,
      treatNullAsEpoch: namedArguments['__input_is_nil'] == true);

  if (parsed == null) {
    return _fallbackValue(value);
  }

  final type = arguments.isNotEmpty ? arguments[0]?.toString() ?? '' : '';
  final style = arguments.length > 1 ? arguments[1]?.toString() ?? '' : '';

  final ordinal = type == 'ordinal';
  final usStyle = style.toUpperCase() == 'US';

  return formatShortDate(parsed, options,
      ordinal: ordinal, longMonth: false, usStyle: usStyle);
};

FilterFunction dateToLongString = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  ensureTimezonesInitialized();
  final options = _extractOptions(namedArguments);
  final parsed = parseDateValue(value,
      options: options,
      treatNullAsEpoch: namedArguments['__input_is_nil'] == true);

  if (parsed == null) {
    return _fallbackValue(value);
  }

  final type = arguments.isNotEmpty ? arguments[0]?.toString() ?? '' : '';
  final style = arguments.length > 1 ? arguments[1]?.toString() ?? '' : '';

  final ordinal = type == 'ordinal';
  final usStyle = style.toUpperCase() == 'US';

  return formatShortDate(parsed, options,
      ordinal: ordinal, longMonth: true, usStyle: usStyle);
};

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
