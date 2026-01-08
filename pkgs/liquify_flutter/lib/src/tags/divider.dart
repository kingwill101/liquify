import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DividerTag extends WidgetTagBase with AsyncTag {
  DividerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    double? height;
    double? thickness;
    Object? color;
    double? indent;
    double? endIndent;
    BorderRadiusGeometry? radius;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'height':
          final value = evaluator.evaluate(arg.value);
          height = toDouble(value);
          namedValues[name] = value;
          break;
        case 'thickness':
          thickness = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'color':
          color = evaluator.evaluate(arg.value);
          namedValues[name] = color;
          break;
        case 'indent':
          indent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'endIndent':
          endIndent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'radius':
          radius = parseBorderRadiusGeometry(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('divider', name);
          break;
      }
    }
    final resolvedColor = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    final resolvedHeight = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    buffer.write(
      Divider(
        height: resolvedHeight ?? height,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: resolvedColor ?? parseColor(color),
        radius: radius,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    double? height;
    double? thickness;
    Object? color;
    double? indent;
    double? endIndent;
    BorderRadiusGeometry? radius;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'height':
          final value = evaluator.evaluate(arg.value);
          height = toDouble(value);
          namedValues[name] = value;
          break;
        case 'thickness':
          thickness = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'color':
          color = evaluator.evaluate(arg.value);
          namedValues[name] = color;
          break;
        case 'indent':
          indent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'endIndent':
          endIndent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'radius':
          radius = parseBorderRadiusGeometry(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('divider', name);
          break;
      }
    }
    final resolvedColor = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    final resolvedHeight = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    buffer.write(
      Divider(
        height: resolvedHeight ?? height,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: resolvedColor ?? parseColor(color),
        radius: radius,
      ),
    );
  }
}
