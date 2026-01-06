import 'package:flutter/widgets.dart';
import 'package:liquify/liquify.dart';
import 'package:media_break_points/media_break_points.dart';

import '../generated/type_filters.dart';
import '../tags/tag_helpers.dart';

void registerFlutterFilters(Environment environment) {
  environment.registerLocalFilter('responsive',
      (value, args, namedArgs) => _responsiveValue(environment, value, args, namedArgs));
  environment.registerLocalFilter(
      'value_for',
      (value, args, namedArgs) =>
          _responsiveValue(environment, value, args, namedArgs));
  environment.registerLocalFilter(
      'breakpoint_value',
      (value, args, namedArgs) =>
          _responsiveValue(environment, value, args, namedArgs));
  environment.registerLocalFilter(
      'edge_inset',
      (value, args, namedArgs) =>
          _edgeInsetValue(value, args, namedArgs));
  registerGeneratedTypeFilters(environment);
}

dynamic _responsiveValue(
  Environment environment,
  dynamic value,
  List<dynamic> args,
  Map<String, dynamic> namedArgs,
) {
  final context = environment.getRegister('_liquify_flutter_context');
  if (context is! BuildContext) {
    throw Exception(
      'responsive filter requires a BuildContext. Set environment register '
      '"_liquify_flutter_context" before rendering.',
    );
  }

  Map<String, dynamic>? mapValue;
  if (value is Map) {
    mapValue = Map<String, dynamic>.from(value);
  }

  dynamic fallback = namedArgs['default'] ?? namedArgs['fallback'];
  fallback ??= mapValue?['default'] ?? mapValue?['fallback'];
  if (fallback == null && args.isNotEmpty) {
    fallback = args.first;
  }
  if (fallback == null && mapValue == null) {
    fallback = value;
  }

  return valueFor<dynamic>(
    context,
    xs: namedArgs['xs'] ?? mapValue?['xs'],
    sm: namedArgs['sm'] ?? mapValue?['sm'],
    md: namedArgs['md'] ?? mapValue?['md'],
    lg: namedArgs['lg'] ?? mapValue?['lg'],
    xl: namedArgs['xl'] ?? mapValue?['xl'],
    xxl: namedArgs['xxl'] ?? mapValue?['xxl'],
    defaultValue: fallback,
  );
}

EdgeInsetsGeometry? _edgeInsetValue(
  dynamic value,
  List<dynamic> args,
  Map<String, dynamic> namedArgs,
) {
  if (namedArgs.isNotEmpty) {
    return edgeInsetsFromNamedValues(namedArgs);
  }
  if (value != null) {
    return _edgeInsetsFromValue(value);
  }
  if (args.isNotEmpty) {
    return _edgeInsetsFromValue(args.first);
  }
  return null;
}

EdgeInsetsGeometry? _edgeInsetsFromValue(Object? value) {
  if (value is EdgeInsetsGeometry) {
    return value;
  }
  final numeric = toDouble(value);
  if (numeric != null) {
    return EdgeInsets.all(numeric);
  }
  return parseEdgeInsetsGeometry(value);
}
