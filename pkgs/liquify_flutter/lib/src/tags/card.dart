import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class CardTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  CardTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    EdgeInsetsGeometry? padding;
    Color? color;
    Color? shadowColor;
    Color? surfaceTintColor;
    double? radius;
    double? elevation;
    ShapeBorder? shape;
    EdgeInsetsGeometry? margin;
    Clip? clipBehavior;
    bool? borderOnForeground;
    bool? semanticContainer;
    String? variant;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'shadowColor':
          shadowColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'surfaceTintColor':
          surfaceTintColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'radius':
          radius = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'elevation':
          elevation = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'shape':
          final value = evaluator.evaluate(arg.value);
          if (value is ShapeBorder) {
            shape = value;
          }
          break;
        case 'margin':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'borderOnForeground':
          borderOnForeground = toBool(evaluator.evaluate(arg.value));
          break;
        case 'semanticContainer':
          semanticContainer = toBool(evaluator.evaluate(arg.value));
          break;
        case 'variant':
          variant = evaluator.evaluate(arg.value)?.toString();
          break;
        default:
          handleUnknownArg('card', name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      margin = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'margin',
        parser: parseEdgeInsetsGeometry,
      );
      color = resolvePropertyValue<Color?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'color',
        parser: parseColor,
      );
      final paddingInsets = padding;
      final content = wrapChildren(children);
      final cardShape =
          shape ??
          (radius == null
              ? null
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ));
      final child = paddingInsets == null
          ? content
          : Padding(padding: paddingInsets, child: content);
      final normalized = variant?.toLowerCase().trim();
      if (normalized == 'filled') {
        buffer.write(
          Card.filled(
            color: color,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            elevation: elevation,
            shape: cardShape,
            borderOnForeground: borderOnForeground ?? true,
            margin: margin,
            clipBehavior: clipBehavior,
            semanticContainer: semanticContainer ?? true,
            child: child,
          ),
        );
        return;
      }
      if (normalized == 'outlined') {
        buffer.write(
          Card.outlined(
            color: color,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            elevation: elevation,
            shape: cardShape,
            borderOnForeground: borderOnForeground ?? true,
            margin: margin,
            clipBehavior: clipBehavior,
            semanticContainer: semanticContainer ?? true,
            child: child,
          ),
        );
        return;
      }
      buffer.write(
        Card(
          color: color,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: cardShape,
          borderOnForeground: borderOnForeground ?? true,
          margin: margin,
          clipBehavior: clipBehavior,
          semanticContainer: semanticContainer ?? true,
          child: child,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    EdgeInsetsGeometry? padding;
    Color? color;
    Color? shadowColor;
    Color? surfaceTintColor;
    double? radius;
    double? elevation;
    ShapeBorder? shape;
    EdgeInsetsGeometry? margin;
    Clip? clipBehavior;
    bool? borderOnForeground;
    bool? semanticContainer;
    String? variant;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'shadowColor':
          shadowColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'surfaceTintColor':
          surfaceTintColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'radius':
          radius = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'elevation':
          elevation = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'shape':
          final value = evaluator.evaluate(arg.value);
          if (value is ShapeBorder) {
            shape = value;
          }
          break;
        case 'margin':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'borderOnForeground':
          borderOnForeground = toBool(evaluator.evaluate(arg.value));
          break;
        case 'semanticContainer':
          semanticContainer = toBool(evaluator.evaluate(arg.value));
          break;
        case 'variant':
          variant = evaluator.evaluate(arg.value)?.toString();
          break;
        default:
          handleUnknownArg('card', name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      margin = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'margin',
        parser: parseEdgeInsetsGeometry,
      );
      color = resolvePropertyValue<Color?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'color',
        parser: parseColor,
      );
      final paddingInsets = padding;
      final content = wrapChildren(children);
      final cardShape =
          shape ??
          (radius == null
              ? null
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ));
      final child = paddingInsets == null
          ? content
          : Padding(padding: paddingInsets, child: content);
      final normalized = variant?.toLowerCase().trim();
      if (normalized == 'filled') {
        buffer.write(
          Card.filled(
            color: color,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            elevation: elevation,
            shape: cardShape,
            borderOnForeground: borderOnForeground ?? true,
            margin: margin,
            clipBehavior: clipBehavior,
            semanticContainer: semanticContainer ?? true,
            child: child,
          ),
        );
        return;
      }
      if (normalized == 'outlined') {
        buffer.write(
          Card.outlined(
            color: color,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            elevation: elevation,
            shape: cardShape,
            borderOnForeground: borderOnForeground ?? true,
            margin: margin,
            clipBehavior: clipBehavior,
            semanticContainer: semanticContainer ?? true,
            child: child,
          ),
        );
        return;
      }
      buffer.write(
        Card(
          color: color,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: cardShape,
          borderOnForeground: borderOnForeground ?? true,
          margin: margin,
          clipBehavior: clipBehavior,
          semanticContainer: semanticContainer ?? true,
          child: child,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('card').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endcard').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'card',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
