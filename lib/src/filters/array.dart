import 'dart:math' as math;
import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/filter_registry.dart';

/// Converts the input value to uppercase.
///
/// Arguments: None
///
/// Example: {{ "hello" | upper }} => "HELLO"
dynamic upper(dynamic value, List<dynamic> arguments,
        Map<String, dynamic> namedArguments) =>
    value.toString().toUpperCase();

/// Converts the input value to lowercase.
///
/// Arguments: None
///
/// Example: {{ "HELLO" | lower }} => "hello"
dynamic lower(dynamic value, List<dynamic> arguments,
        Map<String, dynamic> namedArguments) =>
    value.toString().toLowerCase();

/// Returns the length of the input string or list.
///
/// Arguments: None
///
/// Example: {{ "hello" | length }} => 5
/// Example: {{ [1, 2, 3] | length }} => 3
dynamic length(dynamic value, List<dynamic> arguments,
        Map<String, dynamic> namedArguments) =>
    value.toString().length;

/// Joins elements of a list with a separator.
///
/// Arguments:
/// - separator (optional): The string to use as a separator. Default is a space.
///
/// Example: {{ [1, 2, 3] | join: ", " }} => "1, 2, 3"
dynamic join(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List) return value;
  final separator = arguments.isNotEmpty ? arguments[0].toString() : ' ';
  return value.join(separator);
}

/// Returns the first element of a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | first }} => 1
dynamic first(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List || value.isEmpty) return '';
  return value.first;
}

/// Returns the last element of a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | last }} => 3
dynamic last(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List || value.isEmpty) return '';
  return value.last;
}

/// Reverses the order of elements in a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | reverse }} => [3, 2, 1]
dynamic reverse(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List) return value;
  return value.reversed.toList();
}

/// Returns the size (length) of a string or list.
///
/// Arguments: None
///
/// Example: {{ "hello" | size }} => 5
/// Example: {{ [1, 2, 3] | size }} => 3
dynamic size(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is String) return value.length;
  if (value is List) return value.length;
  return 0;
}

/// Sorts the elements of a list.
///
/// Arguments: None
///
/// Example: {{ [3, 1, 2] | sort }} => [1, 2, 3]
dynamic sort(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List) return value;
  final sorted = List.from(value);
  sorted.sort();
  return sorted;
}

/// Maps a property of each item in a list of objects.
///
/// Arguments:
/// - property: The name of the property to map.
///
/// Example: {{ [{"name": "Alice"}, {"name": "Bob"}] | map: "name" }} => ["Alice", "Bob"]
dynamic map(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List || arguments.isEmpty) return value;
  final property = arguments[0].toString();
  return value.map((item) => item is Map ? item[property] : null).toList();
}

/// Filters a list of objects based on a property value.
///
/// Arguments:
/// - property: The name of the property to filter by.
/// - expected (optional): The expected value of the property.
///
/// Example: {{ [{"age": 20}, {"age": 30}] | where: "age", 30 }} => [{"age": 30}]
dynamic where(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List || arguments.isEmpty) return value;
  final property = arguments[0].toString();
  final expected = arguments.length > 1 ? arguments[1] : null;
  return value.where((item) {
    if (item is! Map) return false;
    final itemValue = item[property];
    return expected == null ? itemValue != null : itemValue == expected;
  }).toList();
}

/// Removes duplicate elements from a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 2, 3, 3] | uniq }} => [1, 2, 3]
dynamic uniq(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List) return value;
  return value.toSet().toList();
}

/// Extracts a subset of a list or string.
///
/// Arguments:
/// - start: The starting index of the slice.
/// - length (optional): The length of the slice. Default is 1.
///
/// Example: {{ [1, 2, 3, 4, 5] | slice: 1, 3 }} => [2, 3, 4]
/// Example: {{ "hello" | slice: 1, 3 }} => "ell"
dynamic slice(dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is! List && value is! String) return value;

  final length = value is String ? value.length : (value as List).length;
  if (length == 0) return value is String ? '' : [];

  int start = arguments.isNotEmpty ? arguments[0] as int : 0;
  if (start < 0) start = math.max(length + start, 0);

  final sliceLength =
      arguments.length > 1 ? math.max(0, arguments[1] as int) : 1;
  final end = math.min(start + sliceLength, length);

  if (start >= length) return value is String ? '' : [];

  if (value is String) {
    return value.substring(start, end);
  } else {
    return (value as List).sublist(start, end);
  }
}

class ArrayModule extends Module {
  @override
  void register() {
    filters['upper'] = upper;
    filters['lower'] = lower;
    filters['length'] = length;
    filters['join'] = join;
    filters['reverse'] = reverse;
    filters['sort'] = sort;
    filters['map'] = map;
    filters['where'] = where;
    filters['uniq'] = uniq;
    filters['slice'] = slice;

    // Register dot notation support for array methods
    FilterRegistry.register('first', first, dotNotation: true);
    FilterRegistry.register('last', last, dotNotation: true);
    FilterRegistry.register('size', size, dotNotation: true);
  }
}
