import 'package:liquify/src/filter_registry.dart';
import 'dart:math' as math;

import 'package:liquify/src/filters/module.dart';

/// Returns the absolute value of the input.
///
/// [value]: The number to process. If null, returns 0.
///
/// Example:
/// ```
/// {{ -5 | abs }}
/// ```
/// Output: 5
FilterFunction abs =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (value == null) return 0;
      return (value as num).abs();
    };

/// Returns the maximum of the input value and the argument.
///
/// [value]: The first number to compare. If null, treated as 0.
/// [arguments]: A list containing the second number to compare.
///
/// Example:
/// ```
/// {{ 5 | at_least: 10 }}
/// ```
/// Output: 10
FilterFunction atLeast =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('at_least expects 1 argument');
      num val = value == null ? 0 : value as num;
      num arg = arguments[0] == null ? 0 : arguments[0] as num;
      return math.max(val, arg);
    };

/// Returns the minimum of the input value and the argument.
///
/// [value]: The first number to compare. If null, treated as 0.
/// [arguments]: A list containing the second number to compare.
///
/// Example:
/// ```
/// {{ 15 | at_most: 10 }}
/// ```
/// Output: 10
FilterFunction atMost =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('at_most expects 1 argument');
      num val = value == null ? 0 : value as num;
      num arg = arguments[0] == null ? 0 : arguments[0] as num;
      return math.min(val, arg);
    };

/// Returns the smallest integer greater than or equal to the input value.
///
/// [value]: The number to process. If null, returns 0.
///
/// Example:
/// ```
/// {{ 5.1 | ceil }}
/// ```
/// Output: 6
FilterFunction ceil =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (value == null) return 0;
      return (value as num).ceil();
    };

/// Divides the input value by the argument.
///
/// [value]: The dividend. If null, treated as 0.
/// [arguments]: A list containing the divisor and an optional boolean for integer arithmetic.
///
/// Examples:
/// ```
/// {{ 10 | divided_by: 3 }}
/// ```
/// Output: 3.3333333333333335
///
/// ```
/// {{ 10 | divided_by: 3, true }}
/// ```
/// Output: 3
FilterFunction dividedBy =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) {
        throw ArgumentError('divided_by expects at least 1 argument');
      }
      num dividend = value == null ? 0 : value as num;
      num divisor = arguments[0] == null ? 1 : arguments[0] as num;
      bool integerArithmetic = arguments.length > 1
          ? arguments[1] as bool
          : false;

      // Prevent division by zero
      if (divisor == 0) return 0;

      return integerArithmetic
          ? (dividend / divisor).floor()
          : dividend / divisor;
    };

/// Returns the largest integer less than or equal to the input value.
///
/// [value]: The number to process. If null, returns 0.
///
/// Example:
/// ```
/// {{ 5.9 | floor }}
/// ```
/// Output: 5
FilterFunction floor =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (value == null) return 0;
      return (value as num).floor();
    };

/// Subtracts the argument from the input value.
///
/// [value]: The minuend. If null, treated as 0.
/// [arguments]: A list containing the subtrahend.
///
/// Example:
/// ```
/// {{ 10 | minus: 3 }}
/// ```
/// Output: 7
FilterFunction minus =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('minus expects 1 argument');
      num val = value == null ? 0 : value as num;
      num arg = arguments[0] == null ? 0 : arguments[0] as num;
      return val - arg;
    };

/// Returns the remainder of dividing the input value by the argument.
///
/// [value]: The dividend. If null, treated as 0.
/// [arguments]: A list containing the divisor.
///
/// Example:
/// ```
/// {{ 10 | modulo: 3 }}
/// ```
/// Output: 1
FilterFunction modulo =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('modulo expects 1 argument');
      num a = value == null ? 0 : value as num;
      num b = arguments[0] == null ? 1 : arguments[0] as num;

      // Prevent modulo by zero
      if (b == 0) return 0;

      return ((a % b) + b) % b; // This ensures the result is always positive
    };

/// Multiplies the input value by the argument.
///
/// [value]: The first factor. If null, treated as 0.
/// [arguments]: A list containing the second factor.
///
/// Example:
/// ```
/// {{ 5 | times: 3 }}
/// ```
/// Output: 15
FilterFunction times =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('times expects 1 argument');
      num val = value == null ? 0 : value as num;
      num arg = arguments[0] == null ? 0 : arguments[0] as num;
      return val * arg;
    };

/// Rounds the input value to the specified number of decimal places.
///
/// [value]: The number to round. If null, returns 0.
/// [arguments]: An optional list containing the number of decimal places.
///
/// Examples:
/// ```
/// {{ 5.6789 | round }}
/// ```
/// Output: 6
///
/// ```
/// {{ 5.6789 | round: 2 }}
/// ```
/// Output: 5.68
FilterFunction round =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (value == null) return 0;
      num v = value as num;
      int arg = arguments.isNotEmpty ? arguments[0] as int : 0;
      double amp = math.pow(10, arg).toDouble();
      return (v * amp).round() / amp;
    };

/// Adds the argument to the input value.
///
/// [value]: The first addend. If null, treated as 0.
/// [arguments]: A list containing the second addend.
///
/// Example:
/// ```
/// {{ 5 | plus: 3 }}
/// ```
/// Output: 8
FilterFunction plus =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('plus expects 1 argument');
      num val = value == null ? 0 : value as num;
      num arg = arguments[0] == null ? 0 : arguments[0] as num;
      return val + arg;
    };

class MathModule extends Module {
  @override
  void register() {
    filters['abs'] = abs;
    filters['at_least'] = atLeast;
    filters['at_most'] = atMost;
    filters['ceil'] = ceil;
    filters['divided_by'] = dividedBy;
    filters['floor'] = floor;
    filters['minus'] = minus;
    filters['modulo'] = modulo;
    filters['times'] = times;
    filters['round'] = round;
    filters['plus'] = plus;
  }
}
