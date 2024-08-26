import 'package:liquify/src/filter_registry.dart';
import 'dart:convert';

import 'package:liquify/src/filters/module.dart';

/// Returns the input value if it's not falsy, otherwise returns the default value.
///
/// Arguments:
/// - defaultValue (required): The value to return if the input is falsy.
/// - allowFalse (optional): If true, treats `false` as a non-falsy value. Default is false.
///
/// Examples:
/// ```
/// {{ null | default: 'Guest' }}  // Output: 'Guest'
/// {{ '' | default: 'Empty' }}    // Output: 'Empty'
/// {{ false | default: 'Nope' }}  // Output: 'Nope'
/// {{ false | default: 'Nope', true }}  // Output: false
/// {{ 'Hello' | default: 'Guest' }}  // Output: 'Hello'
/// ```
FilterFunction defaultFilter = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (arguments.isEmpty) {
    throw ArgumentError('default filter requires at least one argument');
  }
  dynamic defaultValue = arguments[0];
  bool allowFalse = arguments.length > 1 ? arguments[1] as bool : false;

  if (value is List || value is String) {
    return (value as dynamic).isEmpty ? defaultValue : value;
  }
  if (value == false && allowFalse) return false;
  return isFalsy(value) ? defaultValue : value;
};

/// Converts the input value to a JSON string.
///
/// Arguments:
/// - space (optional): Number of spaces for indentation. If not provided, the output is not indented.
///
/// Examples:
/// ```
/// {{ {'name': 'John', 'age': 30} | json }}  // Output: {"name":"John","age":30}
/// {{ {'name': 'John', 'age': 30} | json: 2 }}
/// // Output:
/// // {
/// //   "name": "John",
/// //   "age": 30
/// // }
/// ```
FilterFunction json = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  int? space = arguments.isNotEmpty ? arguments[0] as int? : null;
  return space != null && space > 0
      ? JsonEncoder.withIndent(' ' * space).convert(value)
      : JsonEncoder().convert(value);
};

/// Inspects the input value, handling circular references.
///
/// Arguments:
/// - space (optional): Number of spaces for indentation. If not provided, the output is not indented.
///
/// Examples:
/// ```
/// {% assign circular = {'a': {}} %}
/// {% assign circular.a.b = circular %}
/// {{ circular | inspect }}  // Output: {"a":{"b":"[Circular]"}}
/// {{ circular | inspect: 2 }}
/// // Output:
/// // {
/// //   "a": {
/// //     "b": "[Circular]"
/// //   }
/// // }
/// ```
FilterFunction inspect = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  int? space = arguments.isNotEmpty ? arguments[0] as int? : null;
  Set<dynamic> ancestors = {};

  dynamic serialize(dynamic object) {
    if (object is! Map && object is! List) return object;
    if (ancestors.contains(object)) return '[Circular]';
    ancestors.add(object);
    if (object is List) {
      var result = object.map(serialize).toList();
      ancestors.remove(object);
      return result;
    } else if (object is Map) {
      var result = {};
      object.forEach((key, value) {
        result[key] = serialize(value);
      });
      ancestors.remove(object);
      return result;
    }
    return object;
  }

  return space != null && space > 0
      ? JsonEncoder.withIndent(' ' * space).convert(serialize(value))
      : JsonEncoder().convert(serialize(value));
};

/// Converts the input value to an integer.
///
/// This filter doesn't take any arguments.
///
/// Examples:
/// ```
/// {{ 3.14 | to_integer }}  // Output: 3
/// {{ '42' | to_integer }}  // Output: 42
/// ```
FilterFunction toInteger = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  if (value is num) {
    return value.round();
  }
  return int.parse(value.toString());
};

/// Returns the input value without any processing (raw).
///
/// This filter doesn't take any arguments.
///
/// Examples:
/// ```
/// {% assign my_var = "<p>Hello, World!</p>" %}
/// {{ my_var | raw }}  // Output: <p>Hello, World!</p>
/// ```
FilterFunction raw = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  return value;
};

/// Helper function to check if a value is falsy.
bool isFalsy(dynamic value) {
  return value == null ||
      value == false ||
      (value is num && value == 0) ||
      (value is String && value.isEmpty) ||
      (value is Iterable && value.isEmpty);
}

class MiscModule extends Module {
  @override
  void register() {
    filters['default'] = defaultFilter;
    filters['json'] = json;
    filters['jsonify'] = json; // Alias for 'json'
    filters['inspect'] = inspect;
    filters['to_integer'] = toInteger;
    filters['raw'] = raw;
  }
}
