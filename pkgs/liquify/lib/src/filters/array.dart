import 'dart:math' as math;
import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/parser.dart' show parseInput;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/ast.dart' show ASTNode;

import 'package:liquify/src/filters/math.dart' show plus, toLiquidNumber;
import 'package:liquify/src/render_target.dart' show liquidValueToString;
import 'package:liquify/src/util.dart' show isTruthy;

Iterable<Object?> _arrayItems(Object? input) sync* {
  if (input is List) {
    for (final item in input) {
      if (item is List) {
        yield* _arrayItems(item);
      } else {
        yield item;
      }
    }
  } else if (input != null) {
    yield input;
  }
}

bool _canIndex(Object? value) =>
    value is Map || value is String || value is int;

Object? _property(Object? value, Object? key) {
  if (value is Map) return value[key];
  if (value is String) {
    if (key is String) return value.contains(key) ? key : null;
    if (key is int) {
      final chars = value.runes.toList();
      final index = key < 0 ? chars.length + key : key;
      return index >= 0 && index < chars.length
          ? String.fromCharCode(chars[index])
          : null;
    }
  }
  if (value is int && key is int) return key < 0 ? 0 : (value >> key) & 1;
  if (_canIndex(value)) {
    throw ArgumentError("Cannot select the property '$key'");
  }
  return null;
}

/// Cache for parsed Liquid expressions used by *_exp filters.
/// Key: expression string, Value: parsed AST nodes
final Map<String, List<ASTNode>> _expressionCache = {};

/// Converts the input value to uppercase.
///
/// Arguments: None
///
/// Example: {{ "hello" | upper }} => "HELLO"
dynamic upper(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) => value.toString().toUpperCase();

/// Converts the input value to lowercase.
///
/// Arguments: None
///
/// Example: {{ "HELLO" | lower }} => "hello"
dynamic lower(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) => value.toString().toLowerCase();

/// Returns the length of the input string or list.
///
/// Arguments: None
///
/// Example: {{ "hello" | length }} => 5
/// Example: {{ [1, 2, 3] | length }} => 3
dynamic length(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is String) return value.length;
  if (value is List) return value.length;
  return 0;
}

/// Joins elements of a list with a separator.
///
/// Arguments:
/// - separator (optional): The string to use as a separator. Default is a space.
///
/// Example: {{ [1, 2, 3] | join: ", " }} => "1, 2, 3"
dynamic join(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final separator = arguments.isNotEmpty
      ? liquidValueToString(arguments[0])
      : ' ';
  return _arrayItems(value).map(liquidValueToString).join(separator);
}

/// Returns the first item of a list or first character of a string.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | first }} => 1
dynamic first(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is String) {
    return value.isEmpty ? '' : String.fromCharCode(value.runes.first);
  }
  if (value is Map && value.isNotEmpty) {
    final entry = value.entries.first;
    return [entry.key, entry.value];
  }
  if (value is! List || value.isEmpty) return '';
  return value.first;
}

/// Returns the last item of a list or last character of a string.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | last }} => 3
dynamic last(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is String) {
    return value.isEmpty ? '' : String.fromCharCode(value.runes.last);
  }
  if (value is! List || value.isEmpty) return '';
  return value.last;
}

/// Reverses the order of elements in a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | reverse }} => [3, 2, 1]
dynamic reverse(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _arrayItems(value).toList().reversed.toList();
}

/// Returns the size (length) of a string or list.
///
/// Arguments: None
///
/// Example: {{ "hello" | size }} => 5
/// Example: {{ [1, 2, 3] | size }} => 3
dynamic size(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return switch (value) {
    String() => value.runes.length,
    List() => value.length,
    Map() => value.length,
    int() => 8,
    _ => 0,
  };
}

/// Sorts the elements of a list.
///
/// Arguments: None
///
/// Example: {{ [3, 1, 2] | sort }} => [1, 2, 3]
dynamic sort(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _sortItems(value, arguments.firstOrNull, ignoreCase: false);
}

List<Object?>? _sortItems(
  Object? input,
  Object? property, {
  required bool ignoreCase,
}) {
  final items = _arrayItems(input).toList();
  if (property != null && items.any((item) => !_canIndex(item))) return null;

  // Keep input order among equal keys, including case-insensitive ties.
  final keyed = [
    for (final (index, value) in items.indexed)
      (
        index: index,
        value: value,
        key: property == null ? value : _property(value, property),
      ),
  ];
  keyed.sort((a, b) {
    final left = a.key;
    final right = b.key;
    final int result;
    if (left == null || right == null) {
      result = left == null ? (right == null ? 0 : 1) : -1;
    } else if (ignoreCase) {
      result = liquidValueToString(
        left,
      ).toLowerCase().compareTo(liquidValueToString(right).toLowerCase());
    } else if (left is num && right is num) {
      result = left.compareTo(right);
    } else if (left is String && right is String) {
      result = left.compareTo(right);
    } else if (left == right && left is bool) {
      result = 0;
    } else {
      throw ArgumentError('Cannot sort values of incompatible types');
    }
    return result == 0 ? a.index.compareTo(b.index) : result;
  });
  return keyed.map((item) => item.value).toList();
}

/// Maps a property of each item in a list of objects.
///
/// Arguments:
/// - property: The name of the property to map.
///
/// Example: {{ [{"name": "Alice"}, {"name": "Bob"}] | map: "name" }} => ["Alice", "Bob"]
dynamic map(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (arguments.isEmpty) return value;
  final property = arguments[0];
  return _arrayItems(value)
      .map((item) => property == 'to_liquid' ? item : _property(item, property))
      .toList();
}

/// Filters a list of objects based on a property value.
///
/// Arguments:
/// - property: The name of the property to filter by.
/// - expected (optional): The expected value of the property.
///
/// Example: {{ [{"age": 20}, {"age": 30}] | where: "age", 30 }} => [{"age": 30}]
dynamic where(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _filterByProperty(value, arguments, rejectMatches: false);
}

Object? _filterByProperty(
  Object? input,
  List<dynamic> arguments, {
  required bool rejectMatches,
}) {
  if (arguments.isEmpty) return input;
  final result = <Object?>[];
  final property = arguments.first;
  final expected = arguments.elementAtOrNull(1);
  for (final item in _arrayItems(input)) {
    if (!_canIndex(item)) return null;
    final value = _property(item, property);
    final matches = expected == null ? isTruthy(value) : value == expected;
    if (matches != rejectMatches) result.add(item);
  }
  return result;
}

/// Removes duplicate elements from a list.
///
/// Arguments: None
///
/// Example: {{ [1, 2, 2, 3, 3] | uniq }} => [1, 2, 3]
dynamic uniq(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final property = arguments.firstOrNull;
  final keys = <Object?>{};
  final result = <Object?>[];
  for (final item in _arrayItems(value)) {
    if (property != null && !_canIndex(item)) return null;
    final key = property == null ? item : _property(item, property);
    if (keys.add(key)) result.add(item);
  }
  return result;
}

/// Extracts a subset of a list or string.
///
/// Arguments:
/// - start: The starting index of the slice.
/// - length (optional): The length of the slice. Default is 1.
///
/// Example: {{ [1, 2, 3, 4, 5] | slice: 1, 3 }} => [2, 3, 4]
/// Example: {{ "hello" | slice: 1, 3 }} => "ell"
dynamic slice(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final isList = value is List;
  final List<dynamic> items = isList
      ? value
      : liquidValueToString(value).runes.toList();
  final offset = toLiquidNumber(arguments.firstOrNull).toInt();
  final lengthArgument = arguments.elementAtOrNull(1);
  final int length = lengthArgument == null
      ? 1
      : toLiquidNumber(lengthArgument).toInt();
  final start = offset < 0 ? items.length + offset : offset;
  if (start < 0 || start >= items.length || length <= 0) {
    return isList ? [] : '';
  }

  final end = start + math.min<int>(length, items.length - start);
  final result = items.sublist(start, end);
  return isList ? result : String.fromCharCodes(result.cast<int>());
}

/// Removes any nil values from an array.
///
/// Arguments: None
///
/// Example: {{ [1, null, 2, "", 3] | compact }} => [1, 2, "", 3]
dynamic compact(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final property = arguments.firstOrNull;
  final result = <Object?>[];
  for (final item in _arrayItems(value)) {
    if (property != null && !_canIndex(item)) return null;
    if ((property == null ? item : _property(item, property)) != null) {
      result.add(item);
    }
  }
  return result;
}

/// Concatenates (joins together) multiple arrays.
///
/// Arguments:
/// - array: The array to concatenate with the input array.
///
/// Example: {{ [1, 2] | concat: [3, 4] }} => [1, 2, 3, 4]
dynamic concat(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final array = arguments.firstOrNull;
  if (array is! List) {
    throw ArgumentError('Concat filter requires an array argument');
  }
  return [..._arrayItems(value), ...array];
}

/// Creates an array excluding the objects with a given property value.
///
/// Arguments:
/// - property: The name of the property to filter by.
/// - expected (optional): The value to reject. If not provided, rejects truthy values.
///
/// Example: {{ [{"type": "kitchen"}, {"type": "living"}] | reject: "type", "kitchen" }} => [{"type": "living"}]
dynamic reject(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _filterByProperty(value, arguments, rejectMatches: true);
}

/// Pushes an element to the end of an array (non-destructive).
///
/// Arguments:
/// - element: The element to push to the array.
///
/// Example: {{ [1, 2] | push: 3 }} => [1, 2, 3]
dynamic push(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.isEmpty) return value;
  final element = arguments[0];
  return [...value, element];
}

/// Removes and returns the last element from an array (non-destructive).
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | pop }} => [1, 2]
dynamic pop(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || value.isEmpty) return value;
  return value.sublist(0, value.length - 1);
}

/// Removes and returns the first element from an array (non-destructive).
///
/// Arguments: None
///
/// Example: {{ [1, 2, 3] | shift }} => [2, 3]
dynamic shift(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || value.isEmpty) return value;
  return value.sublist(1);
}

/// Adds an element to the beginning of an array (non-destructive).
///
/// Arguments:
/// - element: The element to add to the beginning of the array.
///
/// Example: {{ [2, 3] | unshift: 1 }} => [1, 2, 3]
dynamic unshift(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.isEmpty) return value;
  final element = arguments[0];
  return [element, ...value];
}

/// Finds the first element in an array that matches a property value.
///
/// Arguments:
/// - property: The name of the property to search by.
/// - expected (optional): The value to match. If not provided, finds first truthy value.
///
/// Example: {{ [{"name": "Alice"}, {"name": "Bob"}] | find: "name", "Bob" }} => {"name": "Bob"}
dynamic find(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _findPropertyMatch(value, arguments)?.$2;
}

/// Finds the index of the first element in an array that matches a property value.
///
/// Arguments:
/// - property: The name of the property to search by.
/// - expected (optional): The value to match. If not provided, finds first truthy value.
///
/// Example: {{ [{"name": "Alice"}, {"name": "Bob"}] | find_index: "name", "Bob" }} => 1
dynamic findIndex(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _findPropertyMatch(value, arguments)?.$1;
}

(int, Object?)? _findPropertyMatch(Object? input, List<dynamic> arguments) {
  if (arguments.isEmpty) return null;
  final property = arguments.first;
  final expected = arguments.elementAtOrNull(1);
  for (final (index, item) in _arrayItems(input).indexed) {
    if (!_canIndex(item)) return null;
    final value = _property(item, property);
    if (expected == null ? isTruthy(value) : value == expected) {
      return (index, item);
    }
  }
  return null;
}

/// Sums numeric values in an array.
///
/// Arguments:
/// - property (optional): The name of the property to sum.
///
/// Example: {{ [1, 2, 3] | sum }} => 6
/// Example: {{ [{"price": 10}, {"price": 20}] | sum: "price" }} => 30
dynamic sum(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  final property = arguments.firstOrNull;
  final items = _arrayItems(value);
  final values = property == null
      ? items
      : _arrayItems(items.map((item) => _property(item, property)).toList());
  return values.fold<num>(
    0,
    (total, item) => plus(total, [toLiquidNumber(item)], {}) as num,
  );
}

/// Sorts an array using case-insensitive lexicographic ordering.
///
/// Arguments: None
///
/// Example: {{ ["item10", "item2", "item1"] | sort_natural }} => ["item1", "item10", "item2"]
dynamic sortNatural(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  return _sortItems(value, arguments.firstOrNull, ignoreCase: true);
}

/// Groups an array's items by a given property.
///
/// Arguments:
/// - property: The name of the property to group by.
///
/// Example: {{ [{"type": "A"}, {"type": "B"}, {"type": "A"}] | group_by: "type" }}
/// Output: [{"name": "A", "items": [{"type": "A"}, {"type": "A"}]}, {"name": "B", "items": [{"type": "B"}]}]
dynamic groupBy(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.isEmpty) return value;
  final property = arguments[0].toString();

  Map<String, List<dynamic>> groups = {};

  for (final item in value) {
    if (item is! Map) continue;
    final groupKey = item[property]?.toString() ?? '';

    if (!groups.containsKey(groupKey)) {
      groups[groupKey] = [];
    }
    groups[groupKey]!.add(item);
  }

  return groups.entries
      .map((entry) => {'name': entry.key, 'items': entry.value})
      .toList();
}

/// Checks if an array contains items with a certain property value.
///
/// Arguments:
/// - property: The name of the property to check.
/// - expected (optional): The value to check for. If not provided, checks for truthy values.
///
/// Example: {{ [{"active": true}, {"active": false}] | has: "active", true }} => true
dynamic has(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.isEmpty) return false;
  final key = arguments[0];
  final property = key.toString();
  final expected = arguments.length > 1 ? arguments[1] : null;

  for (final item in value) {
    final itemValue = switch (item) {
      Map() => item[property],
      int() when key is int => key < 0 ? 0 : (item >> key) & 1,
      _ => null,
    };

    if (expected == null) {
      // Ruby integer indexing returns a bit, and both 0 and 1 are truthy.
      if (item is int && key is int) return true;
      // Check for truthy value
      if (itemValue != null &&
          itemValue != false &&
          !(itemValue is String && itemValue.isEmpty) &&
          !(itemValue is num && itemValue == 0)) {
        return true;
      }
    } else {
      if (itemValue == expected) {
        return true;
      }
    }
  }
  return false;
}

/// Filters a list of objects based on a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate (e.g., "item.type == 'kitchen'")
///
/// Example: {{ products | where_exp: "item", "item.type == 'kitchen'" }}
dynamic whereExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return value;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  return value.where((item) {
    final result = _evaluateLiquidExpression(item, itemName, expression);
    return result is bool ? result : false;
  }).toList();
}

/// Finds the first element in an array that matches a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate (e.g., "item.type == 'kitchen'")
///
/// Example: {{ products | find_exp: "item", "item.type == 'kitchen'" }}
dynamic findExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return null;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  for (final item in value) {
    final result = _evaluateLiquidExpression(item, itemName, expression);
    if (result is bool && result) {
      return item;
    }
  }
  return null;
}

/// Finds the index of the first element in an array that matches a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate (e.g., "item.type == 'kitchen'")
///
/// Example: {{ products | find_index_exp: "item", "item.type == 'kitchen'" }}
dynamic findIndexExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return -1;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  for (int i = 0; i < value.length; i++) {
    final result = _evaluateLiquidExpression(value[i], itemName, expression);
    if (result is bool && result) {
      return i;
    }
  }
  return -1;
}

/// Groups an array's items by a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate for grouping (e.g., "item.graduation_year | truncate: 3, ''")
///
/// Example: {{ members | group_by_exp: "item", "item.graduation_year" }}
dynamic groupByExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return value;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  Map<String, List<dynamic>> groups = {};

  for (final item in value) {
    final groupKey =
        _evaluateLiquidExpression(
          item,
          itemName,
          expression,
          returnValue: true,
        )?.toString() ??
        '';

    if (!groups.containsKey(groupKey)) {
      groups[groupKey] = [];
    }
    groups[groupKey]!.add(item);
  }

  return groups.entries
      .map((entry) => {'name': entry.key, 'items': entry.value})
      .toList();
}

/// Checks if an array contains items that match a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate (e.g., "item.active == true")
///
/// Example: {{ products | has_exp: "item", "item.active == true" }}
dynamic hasExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return false;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  for (final item in value) {
    final result = _evaluateLiquidExpression(item, itemName, expression);
    if (result is bool && result) {
      return true;
    }
  }
  return false;
}

/// Creates an array excluding objects that match a Liquid expression.
///
/// Arguments:
/// - itemName: The variable name for each iteration (e.g., "item")
/// - expression: A basic Liquid expression to evaluate (e.g., "item.type == 'kitchen'")
///
/// Example: {{ products | reject_exp: "item", "item.type == 'kitchen'" }}
dynamic rejectExp(
  dynamic value,
  List<dynamic> arguments,
  Map<String, dynamic> namedArguments,
) {
  if (value is! List || arguments.length < 2) return value;
  final itemName = arguments[0].toString();
  final expression = arguments[1].toString();

  return value.where((item) {
    final result = _evaluateLiquidExpression(item, itemName, expression);
    return result is bool ? !result : true;
  }).toList();
}

/// Helper function to evaluate Liquid expressions using the proper parser and evaluator.
/// This creates a proper Liquid expression and evaluates it with the item as context.
/// Uses caching for parsed expressions to avoid re-parsing the same expression for each array item.
dynamic _evaluateLiquidExpression(
  dynamic item,
  String itemName,
  String expression, {
  bool returnValue = false,
}) {
  try {
    // Create a complete Liquid expression by wrapping it in {{ }}
    final liquidExpression = '{{ $expression }}';

    // Check cache first, parse if not cached
    List<ASTNode> parsed =
        _expressionCache[liquidExpression] ??
        (_expressionCache[liquidExpression] = parseInput(liquidExpression));

    if (parsed.isEmpty) return returnValue ? null : false;

    // Create an evaluator with the item as context
    final context = Environment();
    if (item is Map) {
      // Set the item variable and also merge the item's properties into the context
      context.setVariable(itemName, item);
      for (final entry in item.entries) {
        if (entry.key is String) {
          context.setVariable(entry.key as String, entry.value);
        }
      }
    } else {
      context.setVariable(itemName, item);
    }

    final evaluator = Evaluator(context);

    // Evaluate the parsed expression
    final result = evaluator.evaluate(parsed.first);

    if (returnValue) {
      return result;
    }

    // For boolean context, check if the result is truthy
    return _isTruthy(result);
  } catch (e) {
    // If evaluation fails, return false for boolean context or null for value context
    return returnValue ? null : false;
  }
}

/// Helper function to check if a value is truthy
bool _isTruthy(dynamic value) {
  if (value == null || value == false) return false;
  if (value == true) return true;
  if (value is String && value.isEmpty) return false;
  if (value is num && value == 0) return false;
  if (value is List && value.isEmpty) return false;
  return true;
}

class ArrayModule extends Module {
  @override
  void register() {
    filters['upper'] = upper;
    filters['lower'] = lower;
    filters['length'] = length;
    filters['join'] = join;
    filters['first'] = first;
    filters['last'] = last;
    filters['size'] = size;
    filters['reverse'] = reverse;
    filters['sort'] = sort;
    filters['sort_natural'] = sortNatural;
    filters['map'] = map;
    filters['where'] = where;
    filters['where_exp'] = whereExp;
    filters['reject'] = reject;
    filters['reject_exp'] = rejectExp;
    filters['uniq'] = uniq;
    filters['slice'] = slice;
    filters['compact'] = compact;
    filters['concat'] = concat;
    filters['push'] = push;
    filters['pop'] = pop;
    filters['shift'] = shift;
    filters['unshift'] = unshift;
    filters['find'] = find;
    filters['find_exp'] = findExp;
    filters['find_index'] = findIndex;
    filters['find_index_exp'] = findIndexExp;
    filters['sum'] = sum;
    filters['group_by'] = groupBy;
    filters['group_by_exp'] = groupByExp;
    filters['has'] = has;
    filters['has_exp'] = hasExp;

    // Register dot notation support for array methods
    FilterRegistry.register('first', first, dotNotation: true);
    FilterRegistry.register('last', last, dotNotation: true);
    FilterRegistry.register('size', size, dotNotation: true);
  }
}
