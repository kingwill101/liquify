/// Preserves decimal values that JavaScript also identifies as integers.
final class LiquidDecimal {
  final double value;

  const LiquidDecimal._(this.value);

  num toJson() => value;

  @override
  String toString() {
    final text = value.toString();
    if (text.contains('.')) return text;
    final exponent = text.indexOf('e');
    return exponent == -1
        ? '$text.0'
        : '${text.substring(0, exponent)}.0${text.substring(exponent)}';
  }

  @override
  bool operator ==(Object other) =>
      other is LiquidDecimal && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

Object preserveLiquidDecimal(double value) =>
    value.isFinite && value is int ? LiquidDecimal._(value) : value;

dynamic unwrapLiquidNumber(Object? value) =>
    value is LiquidDecimal ? value.value : value;
