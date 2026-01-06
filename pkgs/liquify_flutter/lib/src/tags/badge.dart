import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BadgeTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BadgeTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      config.alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(_buildBadge(config, children));
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
      final children = _asWidgets(captured);
      config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      config.alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(_buildBadge(config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('badge').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endbadge').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'badge',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _BadgeConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _BadgeConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
        case 'text':
          config.label = value?.toString();
          break;
        case 'count':
          config.count = toInt(value);
          break;
        case 'maxCount':
          config.maxCount = toInt(value);
          break;
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'textColor':
          config.textColor = parseColor(value);
          break;
        case 'labelStyle':
        case 'textStyle':
          config.labelStyle = parseTextStyle(value);
          break;
        case 'smallSize':
          config.smallSize = toDouble(value);
          break;
        case 'largeSize':
          config.largeSize = toDouble(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'alignment':
          namedValues[name] = value;
          break;
        case 'isLabelVisible':
          config.isLabelVisible = toBool(value);
          break;
        case 'id':
        case 'key':
          break;
        default:
          handleUnknownArg('badge', name);
          break;
      }
    }
    return config;
  }
}

class _BadgeConfig {
  String? label;
  int? count;
  int? maxCount;
  Color? backgroundColor;
  Color? textColor;
  TextStyle? labelStyle;
  double? smallSize;
  double? largeSize;
  EdgeInsetsGeometry? padding;
  AlignmentGeometry? alignment;
  bool? isLabelVisible;
}

Widget _buildBadge(_BadgeConfig config, List<Widget> children) {
  final child = children.isEmpty ? null : wrapChildren(children);
  TextStyle? resolvedTextStyle = config.labelStyle;
  if (resolvedTextStyle == null && config.textColor != null) {
    resolvedTextStyle = TextStyle(color: config.textColor);
  } else if (resolvedTextStyle != null &&
      resolvedTextStyle.color == null &&
      config.textColor != null) {
    resolvedTextStyle = resolvedTextStyle.copyWith(color: config.textColor);
  }
  if (config.count != null) {
    return Badge.count(
      count: config.count!,
      maxCount: config.maxCount ?? 999,
      backgroundColor: config.backgroundColor,
      textColor: config.textColor,
      textStyle: resolvedTextStyle,
      smallSize: config.smallSize,
      largeSize: config.largeSize,
      padding: config.padding,
      alignment: config.alignment,
      isLabelVisible: config.isLabelVisible ?? true,
      child: child,
    );
  }
  final labelWidget = _resolveBadgeLabel(config.label, resolvedTextStyle);
  return Badge(
    backgroundColor: config.backgroundColor,
    textColor: config.textColor,
    textStyle: resolvedTextStyle,
    smallSize: config.smallSize,
    largeSize: config.largeSize,
    padding: config.padding,
    alignment: config.alignment,
    isLabelVisible: config.isLabelVisible ?? true,
    label: labelWidget,
    child: child,
  );
}

Widget? _resolveBadgeLabel(String? label, TextStyle? style) {
  if (label == null || label.trim().isEmpty) {
    return null;
  }
  return Text(label, style: style);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
