import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BottomAppBarTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BottomAppBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(
        _buildBottomAppBar(evaluator, namedValues, config, children),
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
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(
        _buildBottomAppBar(evaluator, namedValues, config, children),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('bottom_app_bar').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endbottom_app_bar').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'bottom_app_bar',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _BottomAppBarConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _BottomAppBarConfig();
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? childValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        case 'color':
        case 'backgroundColor':
          config.color = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'shape':
          config.shape = parseNotchedShape(value);
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'surfaceTintColor':
          config.surfaceTintColor = parseColor(value);
          break;
        case 'shadowColor':
          config.shadowColor = parseColor(value);
          break;
        case 'height':
          config.height = toDouble(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'notchMargin':
          config.notchMargin = toDouble(value);
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('bottom_app_bar', name);
          break;
      }
    }

    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      config.child = resolvedChild;
    } else if (childValue != null) {
      config.child = childValue is Widget
          ? childValue
          : resolveTextWidget(childValue);
    }

    final ids = resolveIds(
      evaluator,
      'bottom_app_bar',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    return config;
  }
}

class _BottomAppBarConfig {
  Color? color;
  double? elevation;
  NotchedShape? shape;
  EdgeInsetsGeometry? padding;
  Color? surfaceTintColor;
  Color? shadowColor;
  double? height;
  Clip? clipBehavior;
  double? notchMargin;
  Widget? child;
  Key? widgetKey;
}

Widget _buildBottomAppBar(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _BottomAppBarConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);

  return BottomAppBar(
    key: config.widgetKey,
    color: config.color,
    elevation: config.elevation,
    shape: config.shape,
    padding: config.padding,
    surfaceTintColor: config.surfaceTintColor,
    shadowColor: config.shadowColor,
    height: config.height,
    clipBehavior: config.clipBehavior ?? Clip.none,
    notchMargin: config.notchMargin ?? 4.0,
    child: child,
  );
}
