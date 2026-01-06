import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SpacerTag extends WidgetTagBase with AsyncTag {
  SpacerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    double? size;
    double? width;
    double? height;
    int? flex;
    Widget? child;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'size':
          size = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'flex':
          flex = toInt(evaluator.evaluate(arg.value));
          break;
        case 'child':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            child = value;
          }
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('spacer', name);
          break;
      }
    }
    width = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    height = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      child = resolvedChild;
    }
    if (width == null && height == null && size == null && child == null) {
      buffer.write(Spacer(flex: flex ?? 1));
      return;
    }
    buffer.write(
      SizedBox(
        width: width ?? size,
        height: height ?? size,
        child: child,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    double? size;
    double? width;
    double? height;
    int? flex;
    Widget? child;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'size':
          size = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'flex':
          flex = toInt(evaluator.evaluate(arg.value));
          break;
        case 'child':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            child = value;
          }
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('spacer', name);
          break;
      }
    }
    width = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    height = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      child = resolvedChild;
    }
    if (width == null && height == null && size == null && child == null) {
      buffer.write(Spacer(flex: flex ?? 1));
      return;
    }
    buffer.write(
      SizedBox(
        width: width ?? size,
        height: height ?? size,
        child: child,
      ),
    );
  }
}
