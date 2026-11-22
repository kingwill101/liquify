import 'package:liquify/src/filter_registry.dart';
import 'dart:math' as math;

import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/liquid_number.dart';

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
      final number = toLiquidNumber(value);
      return _integerOperand(value, number)
          ? number.abs()
          : preserveLiquidDecimal(number.abs().toDouble());
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
      num val = toLiquidNumber(value);
      num arg = toLiquidNumber(arguments[0]);
      final result = math.max(val, arg);
      return _preserveOperandKind(result == val ? value : arguments[0], result);
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
      num val = toLiquidNumber(value);
      num arg = toLiquidNumber(arguments[0]);
      final result = math.min(val, arg);
      return _preserveOperandKind(result == val ? value : arguments[0], result);
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
      return toLiquidNumber(value).ceil();
    };

/// Divides the input value by the argument.
///
/// Two integer operands use floor division. A decimal operand preserves a
/// decimal result unless integer arithmetic is explicitly requested.
///
/// [value]: The dividend. If null, treated as 0.
/// [arguments]: A list containing the divisor and an optional boolean to force integer arithmetic.
///
/// Examples:
/// ```
/// {{ 10 | divided_by: 3 }}
/// ```
/// Output: 3
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
      num dividend = toLiquidNumber(value);
      num divisor = arguments[0] == null ? 1 : toLiquidNumber(arguments[0]);
      bool integerArithmetic = arguments.length > 1
          ? arguments[1] as bool
          : false;

      // Prevent division by zero
      if (divisor == 0) return 0;

      if (_integerOperand(value, dividend) &&
          _integerOperand(arguments[0], divisor)) {
        final quotient = dividend ~/ divisor;
        final remainder = dividend.remainder(divisor);
        return remainder != 0 && dividend.isNegative != divisor.isNegative
            ? quotient - 1
            : quotient;
      }
      final quotient = dividend / divisor;
      return integerArithmetic
          ? quotient.floor()
          : preserveLiquidDecimal(quotient);
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
      return toLiquidNumber(value).floor();
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
      num val = toLiquidNumber(value);
      num arg = toLiquidNumber(arguments[0]);
      if ((_integerOperand(value, val) && _integerOperand(arguments[0], arg)) ||
          !val.isFinite ||
          !arg.isFinite) {
        return val - arg;
      }
      return preserveLiquidDecimal(
        _decimalOperation(val, arg, (left, right) => left - right),
      );
    };

final _decimalPattern = RegExp(r'^-?[0-9]+\.[0-9]+$');
final _integerPrefix = RegExp(r'^[+-]?[0-9]+(?:_[0-9]+)*');

/// Converts a filter operand using Liquid's numeric coercion rules.
num toLiquidNumber(Object? value) {
  if (value is LiquidDecimal) return value.value;
  if (value is num) return value;
  if (value is! String) return 0;
  final text = value.trim();
  if (_decimalPattern.hasMatch(text)) return double.parse(text);
  final digits = _integerPrefix.stringMatch(text);
  return digits == null ? 0 : int.tryParse(digits.replaceAll('_', '')) ?? 0;
}

bool _integerOperand(Object? input, num number) =>
    number is int &&
    input is! LiquidDecimal &&
    (input is! String || !_decimalPattern.hasMatch(input.trim()));

Object _preserveOperandKind(Object? input, num number) =>
    _integerOperand(input, number)
    ? number
    : preserveLiquidDecimal(number.toDouble());

final _ten = BigInt.from(10);

double _decimalOperation(
  num first,
  num second,
  BigInt Function(BigInt, BigInt) operation,
) {
  final (left, leftScale) = _decimalParts(first);
  final (right, rightScale) = _decimalParts(second);
  final scale = math.max(leftScale, rightScale);
  return _decimalValue(
    operation(
      left * _ten.pow(scale - leftScale),
      right * _ten.pow(scale - rightScale),
    ),
    scale,
  );
}

double _decimalValue(BigInt digits, int scale) =>
    double.parse('${digits}e${-scale}');

// Match Liquid's decimal arithmetic using the operands' decimal text.
(BigInt, int) _decimalParts(num value) {
  final parts = value.toString().split('e');
  final digits = parts.first.split('.');
  final fraction = digits.length == 2 ? digits.last : '';
  final exponent = parts.length == 2 ? int.parse(parts.last) : 0;
  return (BigInt.parse('${digits.first}$fraction'), fraction.length - exponent);
}

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
      num a = toLiquidNumber(value);
      num b = arguments[0] == null ? 1 : toLiquidNumber(arguments[0]);

      // Prevent modulo by zero
      if (b == 0) return 0;

      if ((_integerOperand(value, a) && _integerOperand(arguments[0], b)) ||
          !a.isFinite ||
          !b.isFinite) {
        final remainder = a.remainder(b);
        return remainder != 0 && remainder.isNegative != b.isNegative
            ? remainder + b
            : remainder;
      }
      return preserveLiquidDecimal(
        _decimalOperation(a, b, (left, right) {
          final remainder = left.remainder(right);
          return remainder != BigInt.zero &&
                  remainder.isNegative != right.isNegative
              ? remainder + right
              : remainder;
        }),
      );
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
      num val = toLiquidNumber(value);
      num arg = toLiquidNumber(arguments[0]);
      if ((_integerOperand(value, val) && _integerOperand(arguments[0], arg)) ||
          !val.isFinite ||
          !arg.isFinite) {
        return val * arg;
      }
      final (left, leftScale) = _decimalParts(val);
      final (right, rightScale) = _decimalParts(arg);
      return preserveLiquidDecimal(
        _decimalValue(left * right, leftScale + rightScale),
      );
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
      final valueNumber = toLiquidNumber(value);
      final precision = arguments.isEmpty
          ? 0
          : toLiquidNumber(arguments[0]).toInt();
      final isInteger = _integerOperand(value, valueNumber);
      if (isInteger && precision >= 0) return valueNumber;
      final (digits, scale) = _decimalParts(valueNumber);
      if (precision >= scale) {
        return precision == 0
            ? valueNumber.toInt()
            : _preserveOperandKind(value, valueNumber);
      }
      if (digits == BigInt.zero ||
          precision < scale - digits.abs().toString().length) {
        return isInteger || precision == 0 ? 0 : preserveLiquidDecimal(0.0);
      }
      final divisor = _ten.pow(scale - precision);
      final magnitude = digits.abs();
      var rounded = magnitude ~/ divisor;
      if ((magnitude % divisor) * BigInt.from(2) >= divisor) {
        rounded += BigInt.one;
      }
      if (digits.isNegative) rounded = -rounded;
      if (isInteger || precision == 0) {
        return (rounded * _ten.pow(-precision)).toInt();
      }
      return preserveLiquidDecimal(_decimalValue(rounded, precision));
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
      num val = toLiquidNumber(value);
      num arg = toLiquidNumber(arguments[0]);
      if ((_integerOperand(value, val) && _integerOperand(arguments[0], arg)) ||
          !val.isFinite ||
          !arg.isFinite) {
        return val + arg;
      }
      return preserveLiquidDecimal(
        _decimalOperation(val, arg, (left, right) => left + right),
      );
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
