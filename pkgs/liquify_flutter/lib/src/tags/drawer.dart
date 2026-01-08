import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DrawerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  DrawerTag(super.content, super.filters);

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
      final resolvedChild = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'child',
        parser: (value) => value is Widget ? value : null,
      );
      buffer.write(_buildDrawer(config, children, childOverride: resolvedChild));
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
      final resolvedChild = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'child',
        parser: (value) => value is Widget ? value : null,
      );
      buffer.write(_buildDrawer(config, children, childOverride: resolvedChild));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('drawer').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('enddrawer').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'drawer',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _DrawerConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _DrawerConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'shadowColor':
          config.shadowColor = parseColor(value);
          break;
        case 'surfaceTintColor':
          config.surfaceTintColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'width':
          config.width = toDouble(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'semanticLabel':
          config.semanticLabel = value?.toString();
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('drawer', name);
          break;
      }
    }
    return config;
  }
}

class _DrawerConfig {
  Color? backgroundColor;
  Color? shadowColor;
  Color? surfaceTintColor;
  double? elevation;
  double? width;
  ShapeBorder? shape;
  Clip? clipBehavior;
  String? semanticLabel;
  Widget? child;
}

Widget _buildDrawer(
  _DrawerConfig config,
  List<Widget> children, {
  Widget? childOverride,
}) {
  final child = childOverride ??
      config.child ??
      (children.isEmpty ? const SizedBox.shrink() : wrapChildren(children));
  return Drawer(
    backgroundColor: config.backgroundColor,
    shadowColor: config.shadowColor,
    surfaceTintColor: config.surfaceTintColor,
    elevation: config.elevation,
    width: config.width,
    shape: config.shape,
    clipBehavior: config.clipBehavior ?? Clip.none,
    semanticLabel: config.semanticLabel,
    child: child,
  );
}
