import 'package:flutter/material.dart';
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
  environment.registerLocalFilter(
      'scroll_physics',
      (value, args, namedArgs) => parseScrollPhysics(value ?? (args.isNotEmpty ? args.first : null)));
  // Override the generated widget_state_property filter with a smarter one
  FilterRegistry.register(
      'widget_state_property',
      (value, args, namedArgs) =>
          _widgetStatePropertyValue(value, args, namedArgs));
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

/// Creates a WidgetStateProperty from a value.
/// 
/// This filter wraps values into WidgetStateProperty.all() so they can be used
/// in ButtonStyle and similar widget properties that expect WidgetStateProperty.
/// 
/// Usage:
/// ```liquid
/// {% assign bg_color = "#FF0000" | widget_state_property %}
/// {% filled_button style: {backgroundColor: bg_color} %}
/// ```
WidgetStateProperty<T>? _widgetStatePropertyValue<T>(
  dynamic value,
  List<dynamic> args,
  Map<String, dynamic> namedArgs,
) {
  if (value is WidgetStateProperty<T>) {
    return value;
  }
  if (value is WidgetStateProperty) {
    return value as WidgetStateProperty<T>;
  }
  
  // Try to parse value as Color if it looks like a color string
  final parsed = _parseWidgetStateValue(value);
  if (parsed != null) {
    return WidgetStateProperty.all(parsed as T);
  }
  
  // If value is already the target type, wrap it
  if (value != null) {
    return WidgetStateProperty.all(value as T);
  }
  
  return null;
}

/// Attempt to parse common value types for WidgetStateProperty
dynamic _parseWidgetStateValue(dynamic value) {
  if (value == null) return null;
  
  // Already a supported type
  if (value is Color || value is double || value is EdgeInsetsGeometry || 
      value is Size || value is BorderSide || value is OutlinedBorder ||
      value is TextStyle || value is MouseCursor) {
    return value;
  }
  
  // Try parsing as color (most common use case)
  final color = parseColor(value);
  if (color != null) {
    return color;
  }
  
  // Try parsing as double
  final num = toDouble(value);
  if (num != null) {
    return num;
  }
  
  // Try parsing as EdgeInsets
  final edgeInsets = parseEdgeInsetsGeometry(value);
  if (edgeInsets != null) {
    return edgeInsets;
  }
  
  // Return the original value if we can't parse it
  return value;
}
